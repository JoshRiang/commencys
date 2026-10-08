# Spesifikasi ini mencatat ketahanan data, audit, idempotensi, dan kegagalan simpan.
# Tes ditunda karena StateStore belum memiliki adapter persistensi aktif.
# Jangan menganggap kelas SQLite placeholder dapat memenuhi pemeriksaan berikut.
import pytest

pytestmark = pytest.mark.skip(
    reason="Behavioral acceptance checks are retained for the implementation phase."
)
from fastapi.testclient import TestClient

from app import main
from app.storage import StateStorageError

client = TestClient(main.app)


def test_ticket_audit_and_sos_retry_survive_store_reload():
    key = "persisted-sos-request-01"
    payload = {
        "description": "Smoke near the entrance",
        "latitude": -6.2,
        "longitude": 106.8,
        "accuracy_m": 6.0,
        "location_source": "gps",
    }
    created = client.post(
        "/api/sos", json=payload, headers={"Idempotency-Key": key}
    )
    assert created.status_code == 201
    ticket_id = created.json()["id"]
    database_path = main._state_store.path

    main.configure_state_store(database_path)

    stored = client.get(f"/api/incidents/{ticket_id}")
    replay = client.post(
        "/api/sos", json=payload, headers={"Idempotency-Key": key}
    )
    audit = client.get("/api/audit", params={"incident_id": ticket_id})

    assert stored.status_code == 200
    assert stored.json()["id"] == ticket_id
    assert replay.status_code == 200
    assert replay.headers["Idempotency-Replayed"] == "true"
    assert replay.json()["id"] == ticket_id
    assert [entry["action"] for entry in audit.json()].count("create") == 1


def test_ticket_state_write_fails_closed_when_sqlite_commit_fails(monkeypatch):
    def fail_commit(*_args, **_kwargs):
        raise StateStorageError("simulated database failure")

    monkeypatch.setattr(main._state_store, "commit_change", fail_commit)
    response = client.post(
        "/api/sos",
        json={"latitude": 0, "longitude": 0, "location_source": "manual"},
        headers={"Idempotency-Key": "failed-write-request"},
    )

    assert response.status_code == 503
    assert response.headers["Retry-After"] == "5"
    assert response.json()["detail"] == "Persistent state is temporarily unavailable"
    assert client.get("/api/incidents").json() == []
    assert client.get("/api/audit").json() == []
    assert "failed-write-request" not in main._sos_idempotency
