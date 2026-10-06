"""Laya AI dispatch — role/headcount inference with heuristic fallback.

Calls the live Laya agent (default http://127.0.0.1:8010) ``POST
/v1/systemone`` with dispatch questions over the incident ``report``
field (question instructions name the field in backticks, as Laya
requires). The Laya answer is mapped to::

    {required_roles, headcount, category, severity, reason, source}

CONSTRAINT: dispatch-auto must NEVER block on Laya. Every failure mode
(timeout, connection error, malformed answer) falls back to the existing
``ai_pipeline`` keyword heuristics and returns ``source: "fallback"``
instead of raising.

Laya question contract (verified against live :8010):
  * ``choice`` answers arrive as ``{"choice": <one of criteria>}``.
  * ``score`` answers arrive as ``{"score": <float>}`` where the float is
    the expected index (0-based) over ``criteria`` — so a 1..5 scale maps
    back via ``round(score) + 1``.
"""

from __future__ import annotations

import logging
import os
import re

import httpx

from .ai_pipeline import heuristic_scores, infer_urgency

log = logging.getLogger("commencys.laya")

LAYA_BASE_URL = os.getenv("LAYA_BASE_URL", "http://127.0.0.1:8010")
LAYA_TIMEOUT_S = float(os.getenv("LAYA_TIMEOUT_S", "15"))

#: Volunteer roles (spec: role-based targeted invites).
VALID_ROLES = {"medical", "fire", "rescue", "security", "driver",
               "coordinator"}

#: Laya is asked to choose ONE bundle (choice questions are single-label),
#: each bundle expands to concrete volunteer roles.
ROLE_BUNDLES: dict[str, list[str]] = {
    "medical_team": ["medical", "driver"],
    "fire_team": ["fire", "rescue"],
    "rescue_team": ["rescue", "medical"],
    "security_team": ["security", "coordinator"],
    "general_team": ["coordinator", "driver"],
}

#: Heuristic fallback: incident category -> roles to invite.
CATEGORY_ROLES: dict[str, list[str]] = {
    "medical": ["medical", "driver"],
    "fire": ["fire", "rescue"],
    "accident": ["rescue", "medical"],
    "security": ["security", "coordinator"],
    "facility": ["coordinator", "driver"],
    "sos": ["medical", "rescue"],
    "other": ["coordinator"],
}

CATEGORIES = ["medical", "fire", "accident", "security", "facility",
              "other"]

_URGENCY_SEVERITY = {"P1": 5, "P2": 4, "P3": 3, "P4": 2}
_URGENCY_HEADCOUNT = {"P1": 4, "P2": 3, "P3": 2, "P4": 2}

#: Indonesian -> English emergency gloss (offline, zero-dependency).
#: Laya's English model misclassifies raw Indonesian text with low
#: confidence (fire report -> "accident" @ 0.30), so the report is
#: pre-translated before the /v1/systemone call. The heuristic fallback
#: still runs on the ORIGINAL text (its keyword maps are Indonesian).
#: Sorted longest-first at use time so multi-word phrases win.
_ID_EN_GLOSS: dict[str, str] = {
    # fire
    "kebakaran besar": "large building fire",
    "kebakaran": "fire",
    "terbakar": "burning",
    "asap tebal": "thick smoke",
    "asap": "smoke",
    "api": "flames",
    "ledakan": "explosion",
    # medical
    "tidak sadarkan diri": "unconscious person",
    "tidak sadar": "unconscious",
    "pingsan": "fainted",
    "jantung": "heart attack",
    "sesak napas": "difficulty breathing",
    "sesak": "difficulty breathing",
    "berdarah": "bleeding heavily",
    "pendarahan": "bleeding",
    "luka parah": "severe injuries",
    "luka": "injured",
    "ambulans": "ambulance",
    "ambulance": "ambulance",
    "keracunan": "poisoning",
    "tenggelam": "drowning",
    # accident / rescue
    "kecelakaan beruntun": "multi-vehicle pileup accident",
    "kecelakaan": "traffic accident",
    "tabrak lari": "hit-and-run accident",
    "tabrak": "collision",
    "terjebak": "trapped",
    "tertimbun": "buried",
    "banjir bandang": "flash flood",
    "banjir": "flood",
    "gempa": "earthquake",
    "longsor": "landslide",
    # security
    "begal": "armed street robbery",
    "rampok": "robbery",
    "maling": "thief",
    "curi": "theft",
    "serang": "attack",
    "tawuran": "gang brawl",
    "penembakan": "shooting",
    # facility
    "bocor gas": "gas leak",
    "bocor": "leaking",
    "listrik": "electrical",
    "korsleting": "electrical short circuit",
    "genset": "generator",
    "lift": "elevator",
    # general
    "korban": "victim",
    "butuh": "needs",
    "segera": "urgently",
    "tolong": "help",
    "darurat": "emergency",
    "ruko": "shophouse",
    "lantai": "floor",
    "besar": "large",
}


def pretranslate_id_en(report: str) -> tuple[str, bool]:
    """Gloss Indonesian emergency terms to English for Laya.

    Returns (translated_report, was_translated). Matching is
    word-boundary aware (so ``api`` never fires inside ``tetapi``),
    longest-phrase-first; unmatched text passes through untouched.
    """
    text = report or ""
    hits = [k for k in _ID_EN_GLOSS
            if re.search(r"\b" + re.escape(k) + r"\b", text,
                         flags=re.IGNORECASE)]
    if not hits:
        return text, False
    out = text
    for key in sorted(hits, key=len, reverse=True):
        out = re.sub(r"\b" + re.escape(key) + r"\b", _ID_EN_GLOSS[key],
                     out, flags=re.IGNORECASE)
    return out, True


def _from_score_index(score: float, lo: int = 1, hi: int = 5) -> int:
    """Map Laya's 0-based expected-index score back onto a 1..5 scale."""
    try:
        value = int(round(float(score))) + 1
    except (TypeError, ValueError):
        return (lo + hi) // 2
    return max(lo, min(hi, value))


def dispatch_questions() -> dict:
    """Question set for Laya ``/v1/systemone`` (instructions name `report`)."""
    return {
        "category": {
            "type": "choice",
            "instructions": "Classify the emergency incident described in "
                            "the `report` field into exactly one category.",
            "criteria": CATEGORIES,
        },
        "severity": {
            "type": "score",
            "instructions": "Rate the severity of the incident in the "
                            "`report` field from 1 (minor) to 5 "
                            "(life-threatening, large scale).",
            "criteria": [1, 2, 3, 4, 5],
        },
        "needed_roles": {
            "type": "choice",
            "instructions": "Which responder team best fits the incident in "
                            "the `report` field? Choose exactly one team "
                            "bundle: medical_team (medics plus driver), "
                            "fire_team (firefighters plus rescue), "
                            "rescue_team (rescue plus medics), security_team "
                            "(security plus coordinator), general_team "
                            "(coordinator plus driver).",
            "criteria": sorted(ROLE_BUNDLES),
        },
        "headcount": {
            "type": "score",
            "instructions": "How many responders are needed for the incident "
                            "in the `report` field? Rate from 1 (one or two "
                            "people) to 5 (many crews).",
            "criteria": [1, 2, 3, 4, 5],
        },
    }


def heuristic_dispatch(report: str) -> dict:
    """Keyword-heuristic fallback (reuses ai_pipeline maps, never raises)."""
    text = report or ""
    scores = heuristic_scores(text)
    category = max(scores, key=lambda k: scores[k])
    urg = infer_urgency(text, category, "P3", is_sos=False)
    suggested = urg.get("suggested", "P3")
    roles = CATEGORY_ROLES.get(category, ["coordinator"])
    headcount = _URGENCY_HEADCOUNT.get(suggested, 2)
    return {
        "category": category,
        "severity": _URGENCY_SEVERITY.get(suggested, 3),
        "required_roles": roles,
        "headcount": headcount,
        "reason": (f"heuristic fallback: category={category} "
                   f"urgency~{suggested} -> roles={roles} x{headcount}"),
        "source": "fallback",
    }


async def dispatch_incident(report: str,
                            timeout: float = LAYA_TIMEOUT_S) -> dict:
    """Run Laya dispatch; on ANY failure return heuristic fallback.

    The report is pre-translated ID->EN (offline gloss) because Laya's
    English model misclassifies raw Indonesian text. The heuristic
    fallback runs on the ORIGINAL text (Indonesian keyword maps).

    Confidence gate: when Laya's own ``confidence`` is below 0.5 we do
    not trust its labels — heuristic fallback wins instead. Never
    raises for Laya-side problems — callers get a dict with ``source``
    set to ``"laya"`` or ``"fallback"``.
    """
    translated, was_translated = pretranslate_id_en(report)
    payload = {"state": {"report": translated or "(empty report)"},
               "questions": dispatch_questions()}
    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            resp = await client.post(f"{LAYA_BASE_URL}/v1/systemone",
                                     json=payload)
            resp.raise_for_status()
            body = resp.json()
            answers = (body.get("answers") or {})
        category_val = (answers.get("category") or {}).get("choice", "other")
        category = category_val if isinstance(category_val, str) else "other"
        if category not in CATEGORIES:
            category = "other"
        laya_conf: float | None = None
        try:
            raw_conf = body.get("confidence", answers.get("confidence"))
            laya_conf = float(raw_conf) if raw_conf is not None else None
        except (TypeError, ValueError):
            laya_conf = None
        if laya_conf is not None and laya_conf < 0.5:
            log.warning("Laya low confidence (%.2f); using fallback",
                        laya_conf)
            plan = heuristic_dispatch(report)
            plan["reason"] += f" [laya_conf={laya_conf:.2f}]"
            return plan
        bundle_val = (answers.get("needed_roles") or {}).get("choice")
        bundle = bundle_val if isinstance(bundle_val, str) else ""
        roles = ROLE_BUNDLES.get(bundle)
        if roles is None:  # Laya picked an unknown bundle — derive it
            roles = CATEGORY_ROLES.get(category, ["coordinator"])
            bundle = "derived_from_category"
        severity = _from_score_index(
            (answers.get("severity") or {}).get("score", 2))
        headcount = _from_score_index(
            (answers.get("headcount") or {}).get("score", 1))
        tag = "+pretranslated" if was_translated else ""
        return {
            "category": category,
            "severity": severity,
            "required_roles": roles,
            "headcount": headcount,
            "reason": (f"Laya{tag}: category={category} "
                       f"severity={severity} team={bundle} -> "
                       f"roles={roles} x{headcount}"),
            "source": "laya",
        }
    except Exception as exc:  # noqa: BLE001 — Laya must never break dispatch
        log.warning("Laya dispatch failed (%s); using heuristic fallback",
                    exc)
        return heuristic_dispatch(report)
