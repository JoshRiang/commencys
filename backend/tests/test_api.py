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


def _wait_for_enrich(ticket_id: str, timeout: float = 5.0) -> dict:
    """Poll until background AI enrichment lands (ai_category set)."""
    deadline = time.perf_counter() + timeout
    last: dict = {}
    while time.perf_counter() < deadline:
        items = {t["id"]: t for t in client.get("/api/incidents").json()}
        last = items.get(ticket_id, {})
        if last.get("ai_category") is not None:
            return last
        time.sleep(0.05)
    return last


def test_sos_never_downgraded_by_ai():
    """Guardrail: SOS stays P1 — AI may not auto-downgrade."""
    r = client.post("/api/sos", json={"latitude": -6.2, "longitude": 106.8,
                                       "description": "laporan biasa saja"})
    tid = r.json()["id"]
    enriched = _wait_for_enrich(tid)
    assert enriched["urgency"] == "P1"
    assert enriched.get("ai_suggested_urgency") == "P1"


def test_ai_escalation_is_advisory_only():
    """AI suggesting higher urgency keeps the original field + flags review."""
    r = client.post("/api/incidents", json={
        "title": "Orang pingsan di aula",
        "description": "Tidak sadar, butuh ambulans segera",
        "category": "medical",
        "latitude": -6.36, "longitude": 106.83,
    })
    tid = r.json()["id"]
    enriched = _wait_for_enrich(tid)
    assert enriched["urgency"] == "P3"  # reporter default untouched
    assert enriched.get("ai_suggested_urgency") == "P1"
    assert enriched.get("urgency_source") == "ai_triage_pending_review"
    assert enriched["needs_review"] is True


def test_review_queue_lists_low_conf_ticket():
    r = client.post("/api/incidents", json={
        "title": "Laporan aneh xyzq",
        "description": "hal tidak jelas sama sekali",
        "category": "other",
        "latitude": -6.4, "longitude": 106.9,
    })
    tid = r.json()["id"]
    _wait_for_enrich(tid)
    q = client.get("/api/review-queue").json()
    assert tid in {t["id"] for t in q}


def test_cluster_and_split_clear_cluster():
    a = client.post("/api/incidents", json={
        "title": "Kebakaran ruko", "description": "Asap tebal",
        "category": "fire", "latitude": -6.361, "longitude": 106.821,
    }).json()
    b = client.post("/api/incidents", json={
        "title": "Kebakaran ruko sebelah",
        "description": "Api menyebar ke lantai 2",
        "category": "fire", "latitude": -6.36105, "longitude": 106.82105,
    }).json()
    ea, eb = _wait_for_enrich(a["id"]), _wait_for_enrich(b["id"])
    assert ea.get("cluster_id") and eb.get("cluster_id")
    assert ea["cluster_id"] == eb["cluster_id"]
    r = client.post(f"/api/incidents/{b['id']}/split")
    assert r.status_code == 200 and r.json()["cluster_id"] is None


def test_correct_updates_metadata_not_raw():
    created = client.post("/api/incidents", json={
        "title": "Judul asli", "description": "Deskripsi asli",
        "category": "other", "latitude": -6.5, "longitude": 106.95,
    }).json()
    _wait_for_enrich(created["id"])
    r = client.post(f"/api/incidents/{created['id']}/correct",
                    json={"ai_category": "fire", "urgency": "P2"})
    assert r.status_code == 200
    body = r.json()
    assert body["title"] == "Judul asli"  # raw immutable
    assert body["description"] == "Deskripsi asli"
    assert body["ai_category"] == "fire"
    assert body["urgency"] == "P2"
    assert body["urgency_source"] == "coordinator_corrected"
    assert body["needs_review"] is False


def test_audit_trail_records_lifecycle():
    created = client.post("/api/incidents", json={
        "title": "Audit probe", "description": "jejak audit",
        "category": "facility", "latitude": -6.55, "longitude": 106.99,
    }).json()
    _wait_for_enrich(created["id"])
    entries = client.get("/api/audit",
                         params={"incident_id": created["id"]}).json()
    actions = {e["action"] for e in entries}
    assert {"create", "ai_classify"} <= actions
    assert all(e["model_version"] == "heuristic-v2" for e in entries)
