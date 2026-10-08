"""Voice SOS: audio upload -> faster-whisper STT -> offline ID->EN -> SOS pipeline.

Budget: end-to-end (upload read + STT + translate + persist + ack) < 15 s
(VOICE_BUDGET_S). STT/translation run in threads off the event loop; the
ticket itself follows the exact same P1 fail-safe path as POST /api/sos
(persist + broadcast + background _enrich, never downgraded).

Models (both lazy-loaded on first request, PRELOAD=0 friendly):
  * STT: faster-whisper multilingual ``base`` (NOT .en — must hear
    Indonesian), CPU int8, 2 threads. ~145 MB weights, fully cached in
    ~/.cache/huggingface. Load ~1.8 s, ~5 s audio decodes in ~1.3 s.
  * Translation: Argos Translate ``translate-id_en`` (offline, zero-API,
    ~77 MB). First call warms up (~7 s), subsequent calls <0.2 s.
    The existing ``pretranslate_id_en`` gloss in laya_dispatch.py stays as
    the downstream backstop for Laya (it runs on the translated text too).

Fail-safe: empty/junk transcript or ANY STT/translator failure still
creates a P1 ticket (description falls back to "Voice SOS (unintelligible
audio)") — a voice SOS is never dropped and never 5xx for model reasons.
Only malformed requests (missing audio, bad coords, oversize) are 4xx.
"""

from __future__ import annotations

import logging
import os
import threading
import time

log = logging.getLogger("commencys.voice_sos")

#: End-to-end ack budget for voice SOS, seconds (STT+translate included).
VOICE_BUDGET_S = 15.0

#: faster-whisper model. MUST stay multilingual (no ".en" suffix) so
#: Indonesian speech is recognised. "base" ≈ 145 MB / fits low-RAM boxes.
WHISPER_MODEL_NAME = os.getenv("VOICE_SOS_WHISPER_MODEL", "base")
WHISPER_COMPUTE = os.getenv("VOICE_SOS_WHISPER_COMPUTE", "int8")
WHISPER_THREADS = int(os.getenv("VOICE_SOS_WHISPER_THREADS", "2"))

#: Reject uploads larger than this (413). 15 MB ≈ several minutes of audio.
MAX_AUDIO_BYTES = int(os.getenv("VOICE_SOS_MAX_BYTES",
                                str(15 * 1024 * 1024)))

_lock = threading.Lock()
_whisper_model = None
_translator_fn = None
_translator_failed = False

#: Whisper captioning artefacts / non-speech junk — never routed as reports.
_JUNK = {
    "", ".", "you", "thank you.", "thank you", "thanks for watching!",
    "thanks for watching.", "please subscribe.", "[blank_audio]",
    "[silence]", "bye.", "bye", "okay.", "so", "hmm", "uh", "um",
}


def _clean(text: str) -> str:
    t = (text or "").strip()
    if t.lower() in _JUNK:
        return ""
    if t and not any(c.isalnum() for c in t):
        return ""
    return t


def whisper_available() -> bool:
    try:
        __import__("faster_whisper")
        return True
    except ImportError:
        return False


def _get_model():
    """Lazy-load (and memoise) the faster-whisper model. Raises on failure."""
    global _whisper_model
    with _lock:
        if _whisper_model is not None:
            return _whisper_model
        from faster_whisper import WhisperModel
        started = time.perf_counter()
        _whisper_model = WhisperModel(
            WHISPER_MODEL_NAME, device="cpu",
            compute_type=WHISPER_COMPUTE, cpu_threads=WHISPER_THREADS)
        log.info("voice-sos: whisper '%s' loaded in %.2fs",
                 WHISPER_MODEL_NAME, time.perf_counter() - started)
        return _whisper_model


def _get_translator():
    """Lazy-load Argos id->en translation fn. Returns None if unavailable."""
    global _translator_fn, _translator_failed
    with _lock:
        if _translator_fn is not None:
            return _translator_fn
        if _translator_failed:
            return None
        try:
            import argostranslate.translate as _t
            langs = _t.get_installed_languages()
            src = next(l for l in langs if l.code == "id")
            dst = next(l for l in langs if l.code == "en")
            fn = src.get_translation(dst)
            # Warm-up inside the lock so first-request timing is honest.
            started = time.perf_counter()
            fn.translate("tes pemanasan")
            log.info("voice-sos: argos id->en ready (warmup %.2fs)",
                     time.perf_counter() - started)
            _translator_fn = fn.translate
            return _translator_fn
        except Exception as exc:  # noqa: BLE001 — translator is optional
            log.warning("voice-sos: argos id->en unavailable: %s", exc)
            _translator_failed = True
            return None


def transcribe_file(path: str) -> dict:
    """Transcribe an audio file. Auto-detects language (id or en expected).

    Returns {text, language, language_probability}. Empty text (not an
    exception) signals unintelligible audio — the caller fail-safes it.
    """
    model = _get_model()
    segments, info = model.transcribe(
        path,
        language=None,  # auto-detect: Indonesian or English callers
        beam_size=1,    # greedy: fastest, fine for short SOS utterances
        vad_filter=True,  # silence -> empty, not hallucinated captions
        condition_on_previous_text=False,
        temperature=0.0,
        no_speech_threshold=0.6,
        suppress_tokens=[-1],
    )
    text = _clean(" ".join(s.text for s in segments).strip())
    return {
        "text": text,
        "language": getattr(info, "language", None),
        "language_probability": round(
            float(getattr(info, "language_probability", 0.0) or 0.0), 3),
    }


def translate_id_en(text: str) -> tuple[str | None, str]:
    """Translate Indonesian text to English offline.

    Returns (translated_or_None, engine_name). Never raises — None means
    "translation unavailable, use the original text downstream".
    """
    if not text:
        return None, "none"
    try:
        fn = _get_translator()
        if fn is None:
            return None, "unavailable"
        out = (fn(text) or "").strip()
        return (out or None), "argos-id_en-1.9"
    except Exception as exc:  # noqa: BLE001 — translation is best-effort
        log.warning("voice-sos: translation failed: %s", exc)
        return None, "failed"
