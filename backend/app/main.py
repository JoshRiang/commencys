"""Commencys backend skeleton (FastAPI) — MVP hot path.

Implements the critical path (acceptance criteria 2+4):
  * POST /api/sos and POST /api/incidents persist + acknowledge in <5 s.
  * IndoBERT/DBSCAN run as non-blocking BackgroundTasks (ai_pipeline.py).
  * Status transparency: acknowledged → broadcast → dispatched → resolved.
  * WS /ws/alerts fans out ticket frames to volunteers/coordinators.

MVP store is in-memory (process-local dict). The productionswap is
PostgreSQL/PostGIS behind the same function signatures — see
docs/db-schema.md for the DDL. Auth (JWT + RBAC, spec station 6) is a
documented TODO enforced at the gateway: docs/api-contract.md.
"""

from __future__ import annotations

import asyncio
import logging
import math
import os
import time
from typing import Any

from fastapi import BackgroundTasks, FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .ai_pipeline import classify, cluster
from .models import Incident, IncidentIn, SosIn, Status, Urgency

log = logging.getLogger("commencys")
logging.basicConfig(level=logging.INFO)

#: SOS end-to-end ack budget, seconds (spec criterion 2: strictly < 5 s).
SOS_BUDGET_S = 5.0

app = FastAPI(title="Commencys API", version="0.1.0-mvp")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_store: dict[str, dict[str, Any]] = {}
_lock = asyncio.Lock()
_sockets: set[WebSocket] = set()


# ---------------------------------------------------------------- helpers
async def _broadcast(frame: dict[str, Any]) -> None:
    dead: list[WebSocket] = []
    for ws in list(_sockets):
        try:
            await ws.send_json(frame)
        except Exception:  # noqa: BLE001 — flaky mobile networks (spec §3)
            dead.append(ws)
    for ws in dead:
        _sockets.discard(ws)


async def _enrich(ticket_id: str) -> None:
    """Background AI enrichment — never on the SOS hot path."""
    async with _lock:
        ticket = _store.get(ticket_id)
        if ticket is None:
            return
        neighbours = [t for t in _store.values() if t["id"] != ticket_id]
    try:
        await classify(ticket)
        await cluster(ticket, neighbours)
        async with _lock:
            _store[ticket_id] = ticket
        await _broadcast(ticket_to_frame(ticket, event="incident.ai_updated"))
    except Exception as exc:  # noqa: BLE001 — AI failure must not break SOS
        log.warning("AI enrichment failed for %s: %s", ticket_id, exc)


def ticket_to_frame(ticket: dict[str, Any], event: str) -> dict[str, Any]:
    frame = Incident(**ticket).to_ws_frame()
    frame["type"] = event
    return frame


@app.middleware("http")
async def _timing(request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - start) * 1000
    response.headers["X-Process-Time-Ms"] = f"{elapsed_ms:.1f}"
    return response


# ---------------------------------------------------------------- routes
@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "commencys-mvp"}


@app.get("/api/incidents")
async def list_incidents() -> list[dict[str, Any]]:
    async with _lock:
        return list(_store.values())


@app.post("/api/incidents", status_code=201)
async def create_incident(body: IncidentIn,
                          background: BackgroundTasks) -> JSONResponse:
    ticket = Incident(
        title=body.title,
        description=body.description,
        category=body.category.value,
        latitude=body.latitude,
        longitude=body.longitude,
        accuracy_m=body.accuracy_m,
        reporter_name=body.reporter_name,
        status=Status.ACKNOWLEDGED.value,
    ).model_dump()
    async with _lock:
        _store[ticket["id"]] = ticket
    background.add_task(_enrich, ticket["id"])
    asyncio.create_task(_broadcast(ticket_to_frame(ticket, "incident.created")))
    return JSONResponse(status_code=201, content=ticket)


@app.post("/api/sos", status_code=201)
async def send_sos(body: SosIn, background: BackgroundTasks) -> JSONResponse:
    """One-tap SOS. Defaults to P1 until AI/human triage refines it —
    false negatives must never be silently downgraded (spec §8)."""
    started = time.perf_counter()
    ticket = Incident(
        title="SOS",
        description=body.description or "One-tap SOS",
        category="sos",
        latitude=body.latitude,
        longitude=body.longitude,
        accuracy_m=body.accuracy_m,
        reporter_name=body.reporter_name,
        urgency=Urgency.P1.value,
        urgency_source="sos_default_pending_triage",
        status=Status.ACKNOWLEDGED.value,
    ).model_dump()
    async with _lock:
        _store[ticket["id"]] = ticket
    # Immediate fan-out: broadcast must not wait for AI (criterion 4).
    asyncio.create_task(_broadcast(ticket_to_frame(ticket, "incident.sos")))
    background.add_task(_enrich, ticket["id"])
    elapsed = time.perf_counter() - started
    log.info("SOS %s acked in %.3fs", ticket["id"], elapsed)
    headers = {"X-SOS-Budget-S": str(SOS_BUDGET_S)}
    if elapsed >= SOS_BUDGET_S:
        log.error("SOS budget breached: %.3fs", elapsed)
    return JSONResponse(status_code=201, content=ticket, headers=headers)


@app.post("/api/incidents/{ticket_id}/dispatch", status_code=200)
async def dispatch(ticket_id: str, volunteer: str = "volunteer") -> JSONResponse:
    """Volunteer accepts a ticket: acknowledged/broadcast → dispatched."""
    async with _lock:
        ticket = _store.get(ticket_id)
        if ticket is None:
            return JSONResponse(status_code=404,
                                content={"detail": "ticket not found"})
        ticket["status"] = Status.DISPATCHED.value
        ticket["dispatched_to"] = volunteer
    asyncio.create_task(
        _broadcast(ticket_to_frame(ticket, "incident.dispatched")))
    return JSONResponse(status_code=200, content=ticket)


@app.get("/api/eta")
async def eta(from_lat: float, from_lng: float,
              to_lat: float, to_lng: float) -> dict[str, Any]:
    """ETA stub. Production proxies OSRM /route/v1 (see docs/02-design.md);
    this fallback uses haversine @ 30 km/h and is labelled `source: stub`
    so clients never mistake it for a routed ETA (spec §3 trade-off)."""
    base = os.getenv("OSRM_BASE_URL", "")
    if base:
        return {"source": "osrm", "base_url": base, "note": "proxy TODO"}
    r = 6371000.0
    p1, p2 = math.radians(from_lat), math.radians(to_lat)
    dp, dl = math.radians(to_lat - from_lat), math.radians(to_lng - from_lng)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    metres = 2 * r * math.asin(math.sqrt(h))
    return {
        "source": "stub",
        "distance_m": round(metres, 1),
        "eta_s": round(metres / (30_000 / 3600)),
    }


@app.websocket("/ws/alerts")
async def alerts(ws: WebSocket) -> None:
    await ws.accept()
    _sockets.add(ws)
    try:
        await ws.send_json({"type": "hello", "service": "commencys-mvp"})
        while True:
            await ws.receive_text()  # heartbeat / client pings; stateless
    except WebSocketDisconnect:
        pass
    finally:
        _sockets.discard(ws)
