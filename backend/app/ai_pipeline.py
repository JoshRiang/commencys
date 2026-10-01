"""Async AI pipeline stubs — IndoBERT classification + DBSCAN clustering.

CONSTRAINT (acceptance criterion 4): AI must NEVER block the
SOS hot path. Storage + initial broadcast happen synchronously (<5 s); these
coroutines run as FastAPI BackgroundTasks and only enrich metadata columns
(ai_category, ai_confidence, needs_review, cluster_id). Raw report fields are
never mutated (auditability, spec station 1).

Wiring points for the real models:
  * classify(): load a fine-tuned IndoBERT checkpoint (see
    docs/evaluation-monitoring.md for F1 / FN-priority targets) and replace
    the heuristic below. Respect CONFIDENCE_THRESHOLD: below it, flag
    needs_review=True for coordinator triage instead of auto-applying.
  * cluster(): replace the stub with PostGIS spatio-temporal pre-filter +
    sklearn DBSCAN (eps metres, time window); on false-merge the coordinator
    can clear cluster_id (see docs/db-schema.md — clustering columns are
    nullable metadata, never destructive).
"""

from __future__ import annotations

import asyncio
import logging
import math

log = logging.getLogger("commencys.ai")

#: Below this IndoBERT confidence, a ticket is flagged for human review
#: instead of auto-applying the predicted label (spec station 4).
CONFIDENCE_THRESHOLD = 0.65

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


def heuristic_scores(text: str) -> dict[str, float]:
    """Zero-dependency placeholder for IndoBERT inference (MVP stub)."""
    t = text.lower()
    scores = {k: 0.0 for k in _KEYWORDS} | {"other": 0.05}
    for cat, words in _KEYWORDS.items():
        hits = sum(1 for w in words if w in t)
        if hits:
            scores[cat] = min(0.55 + 0.1 * hits, 0.9)
    return scores


async def classify(ticket: dict) -> dict:
    """Enrich a stored ticket with IndoBERT label + confidence (async)."""
    await asyncio.sleep(0)  # yield; real model inference awaits here
    text = f"{ticket.get('title', '')} {ticket.get('description', '')}"
    scores = heuristic_scores(text)
    label = max(scores, key=lambda k: scores[k])
    conf = scores[label]
    ticket["ai_category"] = label
    ticket["ai_confidence"] = round(conf, 3)
    ticket["needs_review"] = conf < CONFIDENCE_THRESHOLD
    log.info("classified %s -> %s (%.2f)", ticket.get("id"), label, conf)
    return ticket


def haversine_m(a_lat: float, a_lng: float, b_lat: float, b_lng: float) -> float:
    """Great-circle distance in metres (DBSCAN eps pre-check helper)."""
    r = 6371000.0
    p1, p2 = math.radians(a_lat), math.radians(b_lat)
    dp = math.radians(b_lat - a_lat)
    dl = math.radians(b_lng - a_lng)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


async def cluster(ticket: dict, neighbours: list[dict],
                  eps_m: float = 150.0) -> dict:
    """DBSCAN stub: link ticket to a nearby open cluster (async)."""
    await asyncio.sleep(0)
    for other in neighbours:
        if other.get("id") == ticket.get("id"):
            continue
        if other.get("status") == "resolved":
            continue
        d = haversine_m(ticket["latitude"], ticket["longitude"],
                        other["latitude"], other["longitude"])
        if d <= eps_m and other.get("cluster_id"):
            ticket["cluster_id"] = other["cluster_id"]
            break
    else:
        if ticket.get("cluster_id") is None and neighbours:
            pass  # MVP: leave unclustered; real DBSCAN assigns new cluster
    log.info("clustered %s -> %s", ticket.get("id"), ticket.get("cluster_id"))
    return ticket
