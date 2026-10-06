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

    Never raises for Laya-side problems — callers get a dict with
    ``source`` set to ``"laya"`` or ``"fallback"``.
    """
    payload = {"state": {"report": report or "(empty report)"},
               "questions": dispatch_questions()}
    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            resp = await client.post(f"{LAYA_BASE_URL}/v1/systemone",
                                     json=payload)
            resp.raise_for_status()
            answers = (resp.json().get("answers") or {})
        category_val = (answers.get("category") or {}).get("choice", "other")
        category = category_val if isinstance(category_val, str) else "other"
        if category not in CATEGORIES:
            category = "other"
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
        return {
            "category": category,
            "severity": severity,
            "required_roles": roles,
            "headcount": headcount,
            "reason": (f"Laya: category={category} severity={severity} "
                       f"team={bundle} -> roles={roles} x{headcount}"),
            "source": "laya",
        }
    except Exception as exc:  # noqa: BLE001 — Laya must never break dispatch
        log.warning("Laya dispatch failed (%s); using heuristic fallback",
                    exc)
        return heuristic_dispatch(report)
