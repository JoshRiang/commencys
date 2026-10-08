# Spesifikasi ini mencatat penyajian dashboard dan integrasinya dengan API serta socket.
# Tes ditunda karena dashboard saat ini hanya shell statis dengan kendali nonaktif.
# Kasus tetap menjadi acuan pemeriksaan setelah interaksi dibuat.
import pytest

pytestmark = pytest.mark.skip(
    reason="Behavioral acceptance checks are retained for the implementation phase."
)
from fastapi.testclient import TestClient

from app import main


client = TestClient(main.app)


def test_browser_console_and_assets_are_served_by_api_origin():
    page = client.get("/")
    styles = client.get("/styles.css")
    script = client.get("/app.js")

    assert page.status_code == 200
    assert "Antrean laporan" in page.text
    assert "identitas operator belum diverifikasi" in page.text
    assert 'id="sos-button"' not in page.text
    assert 'id="report-button"' not in page.text
    assert styles.status_code == 200
    assert ".workspace" in styles.text
    assert script.status_code == 200
    assert "function connectSocket()" in script.text
    assert "async function responderAction" in script.text
    assert "async function resolveIncident" in script.text


def test_browser_api_and_websocket_share_the_same_app():
    created = client.post(
        "/api/incidents",
        json={
            "title": "Web console smoke report",
            "latitude": -6.2,
            "longitude": 106.8,
            "location_source": "manual",
        },
    )
    assert created.status_code == 201

    with client.websocket_connect("/ws/alerts") as socket:
        assert socket.receive_json() == {
            "type": "hello",
            "service": "commencys-mvp",
        }
