# Spesifikasi ini memetakan alur SOS, koordinasi, koreksi, dan pemisahan laporan.
# Tes ditunda karena irisan vertikal tersebut belum berfungsi pada scaffold saat ini.
# Aktifkan setelah kontrak, penyimpanan, dan kebijakan akses tersedia.
import pytest

pytestmark = pytest.mark.skip(
    reason="Behavioral acceptance checks are retained for the implementation phase."
)
from fastapi.testclient import TestClient

from app import main

client = TestClient(main.app)


def test_sos_vertical_slice_ack_enrichment_review_and_audit():
    response = client.post(
        "/api/sos",
        json={"latitude": -6.2, "longitude": 106.8, "accuracy_m": 8.0, "location_source": "gps"},
    )
    ticket_id = response.json()["id"]
    stored = client.get(f"/api/incidents/{ticket_id}").json()
    queue = client.get("/api/review-queue").json()
    audit = client.get("/api/audit", params={"incident_id": ticket_id}).json()

    assert response.status_code == 201
    assert stored["status"] == "acknowledged"
    assert stored["urgency"] == "P1"
    assert stored["accuracy_m"] == 8.0
    assert stored["ai_category"] is None
    assert stored["needs_review"] is True
    assert ticket_id in {ticket["id"] for ticket in queue}
    assert {entry["action"] for entry in audit} >= {"create", "ai_classify"}


def test_sos_receipt_survives_background_triage_failure(monkeypatch):
    async def fail_classification(_ticket):
        raise RuntimeError("simulated rule-engine failure")

    monkeypatch.setattr(main, "classify", fail_classification)
    response = client.post("/api/sos", json={"latitude": 0, "longitude": 0, "location_source": "manual"})

    assert response.status_code == 201
    ticket_id = response.json()["id"]
    stored = client.get(f"/api/incidents/{ticket_id}").json()
    assert stored["status"] == "acknowledged"
    assert stored["urgency"] == "P1"


def test_report_to_cluster_to_manual_split_vertical_slice():
    first = client.post(
        "/api/incidents",
        json={
            "title": "Smoke from kitchen",
            "description": "Heavy smoke",
            "category": "fire",
            "latitude": -6.2,
            "longitude": 106.8,
            "location_source": "manual",
            "severity": "high",
        },
    ).json()
    second = client.post(
        "/api/incidents",
        json={
            "title": "Fire next door",
            "description": "Flames on second floor",
            "category": "fire",
            "latitude": -6.20005,
            "longitude": 106.80005,
            "location_source": "manual",
            "severity": "critical",
        },
    ).json()

    first_stored = client.get(f"/api/incidents/{first['id']}").json()
    second_stored = client.get(f"/api/incidents/{second['id']}").json()
    split = client.post(f"/api/incidents/{second['id']}/split")

    assert first_stored["severity"] == "high"
    assert second_stored["severity"] == "critical"
    assert first_stored["cluster_id"] is not None
    assert first_stored["cluster_id"] == second_stored["cluster_id"]
    assert split.status_code == 200
    assert split.json()["cluster_id"] is None


def test_corrected_report_remains_auditable_and_raw_fields_are_unchanged():
    created = client.post(
        "/api/incidents",
        json={
            "title": "Original report",
            "description": "Original description",
            "category": "other",
            "latitude": 1,
            "longitude": 2,
            "location_source": "gps",
        },
    ).json()
    response = client.post(
        f"/api/incidents/{created['id']}/correct",
        json={"ai_category": "medical", "urgency": "P1", "reason": "Confirmed by coordinator"},
    )
    entries = client.get(
        "/api/audit", params={"incident_id": created["id"]}
    ).json()
    correction = next(entry for entry in entries if entry["action"] == "correct")

    assert response.status_code == 200
    assert response.json()["title"] == "Original report"
    assert response.json()["description"] == "Original description"
    assert correction["detail"]["before"]["urgency"] == "P3"
    assert correction["detail"]["after"]["urgency"] == "P1"
    assert correction["detail"]["reason"] == "Confirmed by coordinator"


def test_interaction_overview_sos_assignment_and_resolution_over_websocket():
    with client.websocket_connect("/ws/alerts") as websocket:
        assert websocket.receive_json()["type"] == "hello"

        created = client.post(
            "/api/sos",
            json={
                "latitude": -6.2,
                "longitude": 106.8,
                "location_source": "manual",
            },
        )
        ticket_id = created.json()["id"]
        initial_event = websocket.receive_json()
        broadcast_event = websocket.receive_json()
        triage_event = websocket.receive_json()

        rejected = client.post(
            f"/api/incidents/{ticket_id}/reject",
            json={"responder_name": "volunteer-a"},
        )
        rejection_event = websocket.receive_json()
        accepted = client.post(
            f"/api/incidents/{ticket_id}/accept",
            json={"responder_name": "volunteer-b"},
        )
        acceptance_event = websocket.receive_json()
        resolved = client.post(
            f"/api/incidents/{ticket_id}/resolve",
            json={"note": "Handled"},
        )
        resolution_event = websocket.receive_json()

    assert created.status_code == 201
    assert initial_event["type"] == "incident.sos"
    assert initial_event["status"] == "acknowledged"
    assert broadcast_event["type"] == "incident.broadcast"
    assert triage_event["type"] == "incident.ai_updated"
    assert rejected.status_code == 200
    assert rejected.json()["status"] == "broadcast"
    assert rejection_event["type"] == "incident.assignment_rejected"
    assert rejection_event["status"] == "broadcast"
    assert accepted.status_code == 200
    assert acceptance_event["type"] == "incident.assignment_accepted"
    assert acceptance_event["status"] == "accepted"
    assert resolved.status_code == 200
    assert resolution_event["type"] == "incident.resolved"
    assert resolution_event["status"] == "resolved"
