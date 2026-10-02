"""Async AI pipeline — heuristic-v2 (IndoBERT + DBSCAN stand-ins).

CONSTRAINT (acceptance criterion 4): AI must NEVER block the
SOS hot path. Storage + initial broadcast happen synchronously (<5 s); these
coroutines run as FastAPI BackgroundTasks and only enrich metadata columns
(ai_category, ai_confidence, needs_review, cluster_id, ai_suggested_urgency,
ai_urgency_conf). Raw report fields are never mutated (auditability, spec
station 1).

Guardrails (spec stations 4/8/9, docs/guardrails.md):
  * SOS tickets stay P1 fail-safe — AI never downgrades them.
  * AI never auto-downgrades ANY ticket below the reporter's urgency.
    When the text suggests a HIGHER urgency, the original `urgency` field is
    kept and the suggestion is exposed as `ai_suggested_urgency` (+ confidence)
    with `urgency_source='ai_triage_pending_review'` for coordinator triage.
    Only an explicit coordinator correction (POST .../correct) mutates
    `urgency`, stamped `urgency_source='coordinator_corrected'`.
  * Clustering is reversible: POST .../split clears `cluster_id`.

Wiring points for the real models:
  * classify()/infer_urgency(): load a fine-tuned IndoBERT checkpoint (see
    docs/evaluation-monitoring.md for F1 / FN-priority targets) and replace
    the heuristics below. Respect CONFIDENCE_THRESHOLD: below it, flag
    needs_review=True for coordinator triage instead of auto-applying.
  * cluster(): replace the stub with PostGIS spatio-temporal pre-filter +
    sklearn DBSCAN (eps metres, time window); on false-merge the coordinator
    can clear cluster_id via POST /api/incidents/{id}/split.
"""

from __future__ import annotations

import asyncio
import logging
import math
from datetime import datetime, timezone
from uuid import uuid4

log = logging.getLogger("commencys.ai")

#: Model version stamped on every audit entry (spec station 8).
MODEL_VERSION = "heuristic-v2"

#: Below this IndoBERT confidence, a ticket is flagged for human review
#: instead of auto-applying the predicted label (spec station 4).
CONFIDENCE_THRESHOLD = 0.65

#: DBSCAN-lite defaults: link tickets within 150 m AND a 30-minute window.
CLUSTER_EPS_M = 150.0
CLUSTER_WINDOW_MIN = 30.0

#: Urgency rank — lower index = more urgent. Comparisons always use this so
#: "downgrade" (moving to a higher index) is impossible to do by accident.
URGENCY_ORDER = {"P1": 0, "P2": 1, "P3": 2, "P4": 3}

_KEYWORDS: dict[str, list[str]] = {
    "fire": ["api", "kebakaran", "fire", "asap", "terbakar", "smoke"],
    "medical": [
        "pingsan", "jantung", "sesak", "medis", "medical", "luka",
        "trauma", "ambulans", "ambulance",
    ],
    "accident": ["tabrak", "kecelakaan", "accident", "jatuh", "crash"],
    "security": ["maling", "curi", "begal", "serang", "rampok", "crime"],
    "facility": ["listrik", "bocor", "genset", "fasilitas", "lift"],
}

#: Text signals that push urgency UP. P1 = life-threatening / trapped /
#: major fire; P2 = serious but not immediately life-threatening.
_P1_KEYWORDS = [
    "pingsan", "tidak sadar", "tak sadarkan", "jantung", "sesak",
    "henti napas", "berdarah", "pendarahan", "terjebak", "tertimbun",
    "kebakaran besar", "ledakan", "terbakar parah", "tenggelam",
    "gempa", "banjir bandang", "tawuran", "penembakan",
]
_P2_KEYWORDS = [
    "luka parah", "patah", "kecelakaan beruntun", "tabrak lari",
    "kebakaran", "asap tebal", "bocor gas", "korsleting",
    "begal", "rampok", "keracunan", "demam berdarah",
]

#: Categories considered the same incident when co-located in time+space.
#: `other` joins anything; `sos` joins actionable physical categories.
_COMPATIBLE: dict[str, set[str]] = {
    "medical": {"medical", "accident", "sos", "other"},
    "accident": {"accident", "medical", "sos", "other"},
    "fire": {"fire", "sos", "other"},
    "security": {"security", "sos", "other"},
    "facility": {"facility", "other"},
    "other": {"medical", "accident", "fire", "security", "facility",
              "other", "sos"},
    "sos": {"medical", "accident", "fire", "security", "other", "sos"},
}


def heuristic_scores(text: str) -> dict[str, float]:
    """Zero-dependency placeholder for IndoBERT inference (MVP stub)."""
    t = text.lower()
    scores = {k: 0.0 for k in _KEYWORDS} | {"other": 0.05}
    for cat, words in _KEYWORDS.items():
        hits = sum(1 for w in words if w in t)
        if hits:
            scores[cat] = min(0.55 + 0.1 * hits, 0.9)
    return scores


def _rank(urgency: str) -> int:
    return URGENCY_ORDER.get((urgency or "P3").upper(), 2)


def infer_urgency(text: str, category: str = "other",
                  reporter_urgency: str = "P3",
                  is_sos: bool = False) -> dict:
    """Suggest urgency P1–P4 from text + category.

    Never returns a suggestion below the reporter's urgency (no-downgrade
    guardrail); callers keep the original `urgency` field and expose the
    suggestion as metadata for coordinator review.
    """
    t = (text or "").lower()
    if is_sos:
        # Fail-safe: SOS is P1 by construction, AI agrees unconditionally.
        return {"suggested": "P1", "confidence": 1.0, "escalate": False}
    if any(k in t for k in _P1_KEYWORDS):
        suggested, conf = "P1", 0.8
    elif any(k in t for k in _P2_KEYWORDS):
        suggested, conf = "P2", 0.7
    elif (category or "other") in ("fire", "medical") and any(
            k in t for k in ("parah", "besar", "banyak korban", "menyebar")):
        suggested, conf = "P2", 0.6
    else:
        suggested, conf = (reporter_urgency or "P3").upper(), 0.5
    escalate = _rank(suggested) < _rank(reporter_urgency)
    if not escalate:
        # Clamp: the suggestion is never surfaced below what the reporter
        # already claimed — report the reporter's level instead.
        suggested = (reporter_urgency or "P3").upper()
    return {"suggested": suggested, "confidence": conf,
            "escalate": escalate}


async def classify(ticket: dict, is_sos: bool | None = None) -> dict:
    """Enrich a stored ticket with label + confidence + urgency hint."""
    await asyncio.sleep(0)  # yield; real model inference awaits here
    if is_sos is None:
        is_sos = ticket.get("category") == "sos" or str(
            ticket.get("urgency_source", "")).startswith("sos_default")
    text = f"{ticket.get('title', '')} {ticket.get('description', '')}"
    scores = heuristic_scores(text)
    label = max(scores, key=lambda k: scores[k])
    conf = scores[label]
    urg = infer_urgency(text, ticket.get("category", "other"),
                        ticket.get("urgency", "P3"), is_sos)
    ticket["ai_category"] = label
    ticket["ai_confidence"] = round(conf, 3)
    ticket["ai_suggested_urgency"] = urg["suggested"]
    ticket["ai_urgency_conf"] = round(urg["confidence"], 3)
    ticket["needs_review"] = bool(
        conf < CONFIDENCE_THRESHOLD or urg["escalate"])
    if urg["escalate"] and not is_sos:
        # Suggestion only — the urgency field itself is immutable to AI.
        ticket["urgency_source"] = "ai_triage_pending_review"
    log.info("classified %s -> %s (%.2f) urgency~%s%s",
             ticket.get("id"), label, conf, urg["suggested"],
             " ESCALATE-PENDING" if urg["escalate"] else "")
    return ticket


def haversine_m(a_lat: float, a_lng: float, b_lat: float, b_lng: float) -> float:
    """Great-circle distance in metres (DBSCAN eps pre-check helper)."""
    r = 6371000.0
    p1, p2 = math.radians(a_lat), math.radians(b_lat)
    dp = math.radians(b_lat - a_lat)
    dl = math.radians(b_lng - a_lng)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


def _parse_ts(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except ValueError:
        return None


def _compatible(a: str, b: str) -> bool:
    return b in _COMPATIBLE.get(a or "other", {"other"})


async def cluster(ticket: dict, neighbours: list[dict],
                  eps_m: float = CLUSTER_EPS_M,
                  window_min: float = CLUSTER_WINDOW_MIN) -> list[str]:
    """DBSCAN-lite: link tickets within eps_m AND a time window.

    Same-or-compatible category, unresolved tickets only. Returns the list
    of neighbour ids that were linked into a NEW cluster (caller backfills
    their `cluster_id` under lock); joining an existing cluster returns [].
    Mutates `ticket` in place. Fully reversible via POST .../split.
    """
    await asyncio.sleep(0)
    if ticket.get("status") == "resolved":
        return []
    t_ts = _parse_ts(ticket.get("created_at"))
    cands: list[dict] = []
    for other in neighbours:
        if other.get("id") == ticket.get("id"):
            continue
        if other.get("status") == "resolved":
            continue
        try:
            d = haversine_m(ticket["latitude"], ticket["longitude"],
                            other["latitude"], other["longitude"])
        except (KeyError, TypeError):
            continue
        if d > eps_m:
            continue
        o_ts = _parse_ts(other.get("created_at"))
        if t_ts and o_ts and abs(
                (t_ts - o_ts).total_seconds()) > window_min * 60:
            continue
        if not _compatible(ticket.get("category", "other"),
                           other.get("category", "other")):
            continue
        cands.append(other)
    if not cands:
        log.info("clustered %s -> %s (no candidates)",
                 ticket.get("id"), ticket.get("cluster_id"))
        return []
    for other in cands:
        if other.get("cluster_id"):
            ticket["cluster_id"] = other["cluster_id"]
            log.info("clustered %s -> %s (joined)",
                     ticket.get("id"), ticket["cluster_id"])
            return []
    new_id = uuid4().hex[:8]
    ticket["cluster_id"] = new_id
    linked = [c["id"] for c in cands if not c.get("cluster_id")]
    log.info("clustered %s -> %s (new, +%d linked)",
             ticket.get("id"), new_id, len(linked))
    return linked
