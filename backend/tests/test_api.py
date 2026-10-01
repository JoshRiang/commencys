"""Commencys backend tests — spec acceptance criteria guards."""

import time

from fastapi.testclient import TestClient

from app.main import SOS_BUDGET_S, app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200 and r.json()["status"] == "ok"


def test_sos_ack_under_budget():
    """Criterion 2: SOS ack strictly < 5 s; criterion 4: stored immediately."""
    started = time.perf_counter()
    r = client.post("/api/sos", json={"latitude": -6.2, "longitude": 106.8})
    elapsed = time.perf_counter() - started
    assert r.status_code == 201
    body = r.json()
    assert body["status"] == "acknowledged"
    assert body["urgency"] == "P1"  # fail-safe default until triage
    assert elapsed < SOS_BUDGET_S


def test_create_incident_acknowledged():
    r = client.post("/api/incidents", json={
        "title": "Kebakaran dapur kos",
        "description": "Asap tebal dari lantai 2",
        "category": "fire",
        "latitude": -6.36,
        "longitude": 106.82,
    })
    assert r.status_code == 201
    assert r.json()["status"] == "acknowledged"
    assert r.json()["category"] == "fire"


def test_list_contains_created():
    r = client.get("/api/incidents")
    assert r.status_code == 200
    assert isinstance(r.json(), list) and len(r.json()) >= 1


def test_dispatch_transitions_status():
    created = client.post("/api/incidents", json={
        "title": " Orang pingsan di aula",
        "description": "Butuh bantuan medis",
        "category": "medical",
        "latitude": -6.36,
        "longitude": 106.83,
    }).json()
    r = client.post(f"/api/incidents/{created['id']}/dispatch",
                    params={"volunteer": "relawan-1"})
    assert r.status_code == 200
    assert r.json()["status"] == "dispatched"


def test_ws_hello():
    with client.websocket_connect("/ws/alerts") as ws:
        frame = ws.receive_json()
        assert frame["type"] == "hello"


def test_eta_stub_labelled():
    r = client.get("/api/eta", params={"from_lat": -6.2, "from_lng": 106.8,
                                       "to_lat": -6.21, "to_lng": 106.81})
    assert r.status_code == 200
    assert r.json()["source"] in ("stub", "osrm")
