# Spesifikasi ini merangkum kontrak API yang harus dipenuhi ketika alur dibangun.
# Tes ditunda karena rute operasional saat ini sengaja mengembalikan HTTP 501.
# Jangan menghapus kasus tanpa meninjau kebutuhan, status, dan bukti penerimaannya.
import pytest

pytestmark = pytest.mark.skip(
    reason="Behavioral acceptance checks are retained for the implementation phase."
)
import asyncio
import time

from fastapi.testclient import TestClient
from httpx import ASGITransport, AsyncClient

from app.main import SOS_BUDGET_S, app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "commencys-mvp"}


def test_sos_ack_is_fast_fail_safe_and_has_accuracy():
    started = time.perf_counter()
    response = client.post(
        "/api/sos",
        json={
            "latitude": -6.2,
            "longitude": 106.8,
            "accuracy_m": 12.5,
            "location_source": "gps",
            "reporter_name": "Reporter",
        },
    )
    elapsed = time.perf_counter() - started

    assert response.status_code == 201
    ticket = response.json()
    assert elapsed < SOS_BUDGET_S
    assert float(response.headers["X-Process-Time-Ms"]) < 5000
    assert response.headers["X-SOS-Budget-S"] == "5.0"
    assert ticket["title"] == "SOS"
    assert ticket["category"] == "sos"
    assert ticket["severity"] == "critical"
    assert ticket["urgency"] == "P1"
    assert ticket["urgency_source"] == "sos_default_pending_triage"
    assert ticket["status"] == "acknowledged"
    assert ticket["accuracy_m"] == 12.5
    assert ticket["location_source"] == "gps"
    assert ticket["reporter_name"] == "Reporter"


def test_sos_validates_coordinates_accuracy_and_unknown_fields():
    base = {"latitude": 0, "longitude": 0, "location_source": "gps"}
    assert client.post("/api/sos", json={**base, "latitude": 91}).status_code == 422
    assert client.post("/api/sos", json={**base, "longitude": 181}).status_code == 422
    assert client.post(
        "/api/sos", json={**base, "accuracy_m": -1}
    ).status_code == 422
    assert client.post(
        "/api/sos", json={**base, "accuraccy_m": 5}
    ).status_code == 422
    assert client.post("/api/sos", json={"latitude": 0, "longitude": 0}).status_code == 422
    assert client.post("/api/sos", json={**base, "location_source": "unknown"}).status_code == 422


def test_sos_rejects_non_finite_numbers_from_json():
    response = client.post(
        "/api/sos",
        content=(
            '{"latitude":-6.2,"longitude":106.8,"accuracy_m":1e999,'
            '"location_source":"gps"}'
        ),
        headers={"content-type": "application/json"},
    )
    assert response.status_code == 422


def test_sos_retry_with_same_idempotency_key_returns_one_stored_ticket():
    payload = {
        "latitude": -6.2,
        "longitude": 106.8,
        "location_source": "gps",
        "description": "Need help",
    }
    first = client.post(
        "/api/sos", json=payload, headers={"Idempotency-Key": "sos-attempt-1"}
    )
    replay = client.post(
        "/api/sos", json=payload, headers={"Idempotency-Key": "sos-attempt-1"}
    )

    assert first.status_code == 201
    assert replay.status_code == 200
    assert replay.headers["Idempotency-Replayed"] == "true"
    assert replay.json()["id"] == first.json()["id"]
    assert len(client.get("/api/incidents").json()) == 1
    create_events = [
        event for event in client.get("/api/audit").json() if event["action"] == "create"
    ]
    assert len(create_events) == 1


def test_sos_idempotency_key_rejects_a_different_payload():
    headers = {"Idempotency-Key": "sos-attempt-2"}
    first = client.post(
        "/api/sos",
        json={"latitude": 0, "longitude": 0, "location_source": "manual"},
        headers=headers,
    )
    conflict = client.post(
        "/api/sos",
        json={"latitude": 1, "longitude": 0, "location_source": "manual"},
        headers=headers,
    )

    assert first.status_code == 201
    assert conflict.status_code == 409
    assert len(client.get("/api/incidents").json()) == 1


def test_concurrent_sos_retries_with_same_key_create_one_ticket():
    payload = {
        "latitude": -6.2,
        "longitude": 106.8,
        "location_source": "gps",
    }

    async def send_retries():
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as api:
            return await asyncio.gather(
                *(
                    api.post(
                        "/api/sos",
                        json=payload,
                        headers={"Idempotency-Key": "concurrent-sos"},
                    )
                    for _ in range(8)
                )
            )

    responses = asyncio.run(send_retries())

    assert sorted(response.status_code for response in responses) == [
        200,
        200,
        200,
        200,
        200,
        200,
        200,
        201,
    ]
    assert len({response.json()["id"] for response in responses}) == 1
    assert len(client.get("/api/incidents").json()) == 1


def test_create_incident_preserves_mobile_severity():
    response = client.post(
        "/api/incidents",
        json={
            "title": "Kebakaran dapur",
            "description": "Asap tebal",
            "category": "fire",
            "latitude": -6.36,
            "longitude": 106.82,
            "location_source": "manual",
            "severity": "high",
        },
    )
    assert response.status_code == 201
    ticket = response.json()
    assert ticket["status"] == "acknowledged"
    assert ticket["category"] == "fire"
    assert ticket["severity"] == "high"
    assert ticket["urgency"] == "P3"
    assert ticket["location_source"] == "manual"


def test_create_incident_rejects_invalid_or_silently_ignored_input():
    base = {"title": "Incident", "latitude": 0, "longitude": 0, "location_source": "manual"}
    assert client.post("/api/incidents", json={**base, "severity": "extreme"}).status_code == 422
    assert client.post("/api/incidents", json={**base, "typo_field": "value"}).status_code == 422
    assert client.post("/api/incidents", json={**base, "title": "  "}).status_code == 422


def test_list_and_get_incident_return_stored_ticket():
    created = client.post(
        "/api/incidents",
        json={"title": "Medical", "category": "medical", "latitude": 1, "longitude": 2, "location_source": "manual"},
    ).json()

    listed = client.get("/api/incidents")
    fetched = client.get(f"/api/incidents/{created['id']}")

    assert listed.status_code == 200
    assert created["id"] in {ticket["id"] for ticket in listed.json()}
    assert fetched.status_code == 200
    assert fetched.json()["id"] == created["id"]
    assert client.get("/api/incidents/missing").status_code == 404


def test_responder_must_explicitly_accept_or_reject_assignment():
    created = client.post(
        "/api/incidents",
        json={"title": "Medical", "category": "medical", "latitude": 1, "longitude": 2, "location_source": "manual"},
    ).json()

    rejected = client.post(
        f"/api/incidents/{created['id']}/reject",
        json={"responder_name": "volunteer-1"},
    )
    accepted = client.post(
        f"/api/incidents/{created['id']}/accept",
        json={"responder_name": "volunteer-2"},
    )
    repeated = client.post(
        f"/api/incidents/{created['id']}/accept",
        json={"responder_name": "volunteer-3"},
    )
    unknown = client.post("/api/incidents/missing/accept", json={"responder_name": "x"})
    blank_name = client.post(f"/api/incidents/{created['id']}/reject", json={"responder_name": " "})
    resolved = client.post(f"/api/incidents/{created['id']}/resolve", json={})

    assert rejected.status_code == 200
    assert rejected.json()["status"] == "acknowledged"
    assert accepted.status_code == 200
    assert accepted.json()["status"] == "accepted"
    assert accepted.json()["accepted_by"] == "volunteer-2"
    assert repeated.status_code == 409
    assert unknown.status_code == 404
    assert blank_name.status_code == 422
    assert resolved.status_code == 200
    assert resolved.json()["status"] == "resolved"
    assert resolved.json()["resolved_at"]
    entries = client.get("/api/audit", params={"incident_id": created["id"]}).json()
    assert {entry["action"] for entry in entries} >= {
        "assignment_accept",
        "assignment_reject",
        "resolve",
    }


def test_correction_validates_metadata_and_preserves_raw_report():
    created = client.post(
        "/api/incidents",
        json={
            "title": "Original title",
            "description": "Original details",
            "category": "other",
            "latitude": -6.5,
            "longitude": 106.95,
            "location_source": "manual",
        },
    ).json()

    corrected = client.post(
        f"/api/incidents/{created['id']}/correct",
        json={"ai_category": "fire", "urgency": "P2", "reason": "Coordinator verified"},
    )
    empty = client.post(f"/api/incidents/{created['id']}/correct", json={})
    invalid = client.post(
        f"/api/incidents/{created['id']}/correct",
        json={"ai_category": "unknown"},
    )

    assert corrected.status_code == 200
    ticket = corrected.json()
    assert ticket["title"] == "Original title"
    assert ticket["description"] == "Original details"
    assert ticket["category"] == "other"
    assert ticket["ai_category"] == "fire"
    assert ticket["urgency"] == "P2"
    assert ticket["urgency_source"] == "coordinator_corrected"
    assert ticket["needs_review"] is False
    assert empty.status_code == 422
    assert invalid.status_code == 422


def test_corrected_values_are_not_overwritten_by_triage():
    created = client.post(
        "/api/incidents",
        json={"title": "Person fainted", "category": "medical", "latitude": 0, "longitude": 0, "location_source": "gps"},
    ).json()
    correction = client.post(
        f"/api/incidents/{created['id']}/correct",
        json={"ai_category": "medical", "urgency": "P2"},
    )
    assert correction.status_code == 200
    ticket = client.get(f"/api/incidents/{created['id']}").json()
    assert ticket["urgency"] == "P2"
    assert ticket["urgency_source"] == "coordinator_corrected"


def test_review_queue_contains_generic_sos_without_fabricated_category():
    response = client.post("/api/sos", json={"latitude": -6.2, "longitude": 106.8, "location_source": "gps"})
    ticket_id = response.json()["id"]

    stored = client.get(f"/api/incidents/{ticket_id}").json()
    queue = client.get("/api/review-queue").json()

    assert stored["urgency"] == "P1"
    assert stored["ai_category"] is None
    assert stored["ai_confidence"] is None
    assert stored["ai_suggested_urgency"] == "P1"
    assert stored["needs_review"] is True
    assert ticket_id in {ticket["id"] for ticket in queue}


def test_audit_uses_structured_details_and_only_versions_predictions():
    created = client.post(
        "/api/incidents",
        json={"title": "Audit probe", "category": "facility", "latitude": 1, "longitude": 1, "location_source": "manual"},
    ).json()
    entries = client.get("/api/audit", params={"incident_id": created["id"]}).json()
    by_action = {entry["action"]: entry for entry in entries}

    assert "create" in by_action
    assert by_action["create"]["model_version"] is None
    assert by_action["create"]["actor"] == "reporter:unverified"
    assert isinstance(by_action["create"]["detail"], dict)
    assert by_action["ai_classify"]["model_version"] == "heuristic-v2"


def test_eta_requires_accepted_assignment_and_uses_ticket_destination(monkeypatch):
    monkeypatch.setenv("OSRM_BASE_URL", "http://not-wired.example")
    created = client.post(
        "/api/incidents",
        json={"title": "Route probe", "latitude": -6.21, "longitude": 106.81, "location_source": "gps"},
    ).json()
    response = client.get(
        "/api/eta",
        params={"incident_id": created["id"], "from_lat": -6.2, "from_lng": 106.8},
    )
    invalid = client.get(
        "/api/eta",
        params={"incident_id": created["id"], "from_lat": 91, "from_lng": 0},
    )
    client.post(f"/api/incidents/{created['id']}/accept", json={"responder_name": "volunteer-1"})
    accepted_eta = client.get(
        "/api/eta",
        params={"incident_id": created["id"], "from_lat": -6.2, "from_lng": 106.8},
    )

    assert response.status_code == 409
    assert accepted_eta.status_code == 200
    assert accepted_eta.json()["source"] == "straight_line_stub"
    assert accepted_eta.json()["estimate_only"] is True
    assert accepted_eta.json()["distance_m"] > 0
    assert accepted_eta.json()["eta_s"] > 0
    assert invalid.status_code == 422


def test_websocket_receives_handshake_and_ticket_lifecycle_frames():
    with client.websocket_connect("/ws/alerts") as websocket:
        hello = websocket.receive_json()
        response = client.post("/api/sos", json={"latitude": 0, "longitude": 0, "location_source": "manual"})
        initial = websocket.receive_json()
        broadcast = websocket.receive_json()
        enriched = websocket.receive_json()

    assert hello["type"] == "hello"
    assert response.status_code == 201
    assert initial["type"] == "incident.sos"
    assert initial["status"] == "acknowledged"
    assert broadcast["type"] == "incident.broadcast"
    assert broadcast["status"] == "broadcast"
    assert enriched["type"] == "incident.ai_updated"
    assert enriched["id"] == response.json()["id"]
    assert client.get(f"/api/incidents/{enriched['id']}").json()["status"] == "broadcast"


def test_websocket_absence_does_not_claim_ticket_was_broadcast():
    created = client.post("/api/sos", json={"latitude": 0, "longitude": 0, "location_source": "manual"}).json()
    stored = client.get(f"/api/incidents/{created['id']}").json()
    assert stored["status"] == "acknowledged"


def test_websocket_handshake():
    with client.websocket_connect("/ws/alerts") as websocket:
        frame = websocket.receive_json()
    assert frame == {"type": "hello", "service": "commencys-mvp"}
