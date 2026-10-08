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


# ------------------------------------------------- volunteer registry tests
def test_volunteer_register_and_validation():
    r = client.post("/api/volunteers", json={
        "name": "Medic Andi", "phone": "+62812",
        "roles": ["medical", "driver"], "skills": ["CPR"],
        "latitude": -6.36, "longitude": 106.82,
    })
    assert r.status_code == 201
    body = r.json()
    assert body["name"] == "Medic Andi" and body["id"]
    assert set(body["roles"]) == {"medical", "driver"}

    bad = client.post("/api/volunteers", json={
        "name": "Bogus", "roles": ["sniper"],
        "latitude": -6.36, "longitude": 106.82,
    })
    assert bad.status_code == 422


def test_volunteer_list_and_role_filter():
    client.post("/api/volunteers", json={
        "name": "Fire Budi", "roles": ["fire"],
        "latitude": -6.361, "longitude": 106.821,
    })
    all_vols = client.get("/api/volunteers").json()
    assert any(v["name"] == "Fire Budi" for v in all_vols)
    fire_only = client.get("/api/volunteers",
                           params={"role": "fire"}).json()
    assert fire_only and all("fire" in v["roles"] for v in fire_only)
    cat_alias = client.get("/api/volunteers",
                           params={"category": "fire"}).json()
    assert {v["id"] for v in cat_alias} == {v["id"] for v in fire_only}


# ------------------------------------------------- Laya dispatch-auto tests
def _reg(name: str, roles: list, lat: float, lng: float) -> dict:
    return client.post("/api/volunteers", json={
        "name": name, "roles": roles,
        "latitude": lat, "longitude": lng,
    }).json()


def test_dispatch_auto_matching_picks_right_role(monkeypatch):
    """Mocked Laya plan (fire) must invite the fire volunteer, not others."""
    from fastapi.testclient import TestClient  # noqa: F401 (keeps parity)

    near_fire = _reg("Auto Fire", ["fire", "rescue"], -6.361, 106.821)
    far_security = _reg("Auto Security", ["security"], -6.9, 107.3)

    async def _fake_plan(report: str) -> dict:
        assert report  # incident text reaches the dispatcher
        return {"category": "fire", "severity": 4,
                "required_roles": ["fire", "rescue"], "headcount": 3,
                "reason": "test plan", "source": "laya"}

    monkeypatch.setattr("app.main.dispatch_incident", _fake_plan)
    tid = client.post("/api/incidents", json={
        "title": "Kebakaran ruko", "description": "Api besar lantai 2",
        "category": "fire", "latitude": -6.361, "longitude": 106.821,
    }).json()["id"]
    r = client.post(f"/api/incidents/{tid}/dispatch-auto")
    assert r.status_code == 200
    body = r.json()
    invited = {i["volunteer_id"] for i in body["invites"]}
    assert near_fire["id"] in invited
    assert far_security["id"] not in invited
    assert set(body["ticket"]["required_roles"]) == {"fire", "rescue"}
    assert set(body["ticket"]["invited"]) == invited
    assert body["reason"] == "test plan"
    entries = client.get("/api/audit",
                         params={"incident_id": tid}).json()
    assert "dispatch_auto" in {e["action"] for e in entries}

    # Manual override untouched: still transitions to dispatched.
    m = client.post(f"/api/incidents/{tid}/dispatch",
                    params={"volunteer": near_fire["name"]})
    assert m.status_code == 200 and m.json()["status"] == "dispatched"


def test_dispatch_auto_404_unknown_ticket():
    r = client.post("/api/incidents/doesnotexist/dispatch-auto")
    assert r.status_code == 404


def test_laya_down_fallback(monkeypatch):
    """Mocked Laya timeout -> heuristic fallback, never raises."""
    import httpx

    import app.laya_dispatch as ld

    class _Down:
        def __init__(self, *a, **k):
            pass

        async def __aenter__(self):
            raise httpx.ConnectTimeout("laya down")

        async def __aexit__(self, *exc):
            return False

    monkeypatch.setattr(httpx, "AsyncClient", _Down)
    import asyncio

    plan = asyncio.run(ld.dispatch_incident(
        "Kebakaran besar, asap tebal, korban terjebak"))
    assert plan["source"] == "fallback"
    assert plan["required_roles"]  # heuristic still yields roles
    assert plan["headcount"] >= 1 and plan["reason"]


def test_heuristic_dispatch_maps_keywords():
    import app.laya_dispatch as ld

    plan = ld.heuristic_dispatch("Orang pingsan butuh ambulans segera")
    assert plan["source"] == "fallback"
    assert "medical" in plan["required_roles"]


def test_pretranslate_id_en_glosses_fire_report():
    import app.laya_dispatch as ld

    out, flag = ld.pretranslate_id_en(
        "Kebakaran besar di ruko lantai 2, korban terjebak")
    assert flag is True
    assert "fire" in out.lower()
    assert "kebakaran" not in out.lower()


def test_pretranslate_id_en_word_boundaries():
    import app.laya_dispatch as ld

    # 'api' must not fire inside 'tetapi'; standalone 'api' still glosses.
    out, flag = ld.pretranslate_id_en("Tetapi tidak ada masalah")
    assert "tetapi" in out.lower()
    out2, flag2 = ld.pretranslate_id_en("Ada api di dapur")
    assert flag2 is True
    assert "tetapi" not in out2.lower() or "flames" in out2.lower()


def test_pretranslate_id_en_english_passthrough():
    import app.laya_dispatch as ld

    out, flag = ld.pretranslate_id_en(
        "Large building fire with trapped victims")
    assert flag is False
    assert out == "Large building fire with trapped victims"


def test_laya_low_confidence_falls_back(monkeypatch):
    """Laya answer with confidence < 0.5 -> heuristic fallback wins."""
    import app.laya_dispatch as ld

    class _LowConf:
        def __init__(self, *a, **k):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *exc):
            return False

        async def post(self, *a, **k):
            class _Resp:
                def raise_for_status(self):
                    pass

                def json(self):
                    return {"answers": {
                        "category": {"choice": "accident"},
                        "needed_roles": {"choice": "rescue_team"},
                        "severity": {"score": 1},
                        "headcount": {"score": 1},
                    }, "confidence": 0.30}

            return _Resp()

    import httpx

    monkeypatch.setattr(httpx, "AsyncClient", _LowConf)
    import asyncio

    plan = asyncio.run(ld.dispatch_incident("Kebakaran besar, api di mana"))
    assert plan["source"] == "fallback"
    assert "laya_conf=0.30" in plan["reason"]
    assert "fire" in plan["required_roles"]


def test_laya_sends_pretranslated_report(monkeypatch):
    """The /v1/systemone payload carries the EN gloss, not raw ID text."""
    import app.laya_dispatch as ld

    seen = {}

    class _Capture:
        def __init__(self, *a, **k):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *exc):
            return False

        async def post(self, url, json=None):
            seen["report"] = (json or {})["state"]["report"]

            class _Resp:
                def raise_for_status(self):
                    pass

                def json(self):
                    return {"answers": {
                        "category": {"choice": "fire"},
                        "needed_roles": {"choice": "fire_team"},
                        "severity": {"score": 3},
                        "headcount": {"score": 1},
                    }, "confidence": 0.9}

            return _Resp()

    import httpx

    monkeypatch.setattr(httpx, "AsyncClient", _Capture)
    import asyncio

    plan = asyncio.run(ld.dispatch_incident("Kebakaran di dapur"))
    assert plan["source"] == "laya"
    assert "+pretranslated" in plan["reason"]
    assert "kebakaran" not in seen["report"].lower()
    assert "fire" in seen["report"].lower()


# ------------------------------------------------------- voice SOS (/api/sos-voice)
def _voice_post(monkeypatch, audio: bytes = b"\x00\x01fake-audio",
                filename: str = "clip.m4a", **fields):
    """POST multipart /api/sos-voice with STT stubbed (no model load)."""
    import app.main as m

    def _fake_stt(path):
        return {"text": "tolong, kebakaran di dapur kos",
                "language": "id", "language_probability": 0.9}

    monkeypatch.setattr(m, "transcribe_file", _fake_stt)
    data = {"latitude": "-6.2", "longitude": "106.8"}
    data.update({k: str(v) for k, v in fields.items()})
    return client.post("/api/sos-voice", data=data,
                       files={"audio": (filename, audio, "audio/m4a")})


def test_sos_voice_creates_p1_ticket(monkeypatch):
    """Voice SOS acks 201 as P1 with the translated transcript in-line."""
    r = _voice_post(monkeypatch)
    assert r.status_code == 201
    body = r.json()
    assert body["title"] == "SOS (voice)"
    assert body["status"] == "acknowledged"
    assert body["urgency"] == "P1"
    assert body["urgency_source"] == "sos_voice_pending_triage"
    assert "tolong" in body["description"] or "kebakaran" in body["description"]
    assert r.headers.get("X-SOS-Budget-S") == "15.0"


def test_sos_voice_stt_failure_still_p1(monkeypatch):
    """STT/model failure fail-safes to an intelligible P1, never 5xx."""
    import app.main as m

    def _boom(path):
        raise RuntimeError("no model here")

    monkeypatch.setattr(m, "transcribe_file", _boom)
    r = client.post("/api/sos-voice",
                    data={"latitude": "-6.2", "longitude": "106.8"},
                    files={"audio": ("clip.m4a", b"\x00\x01", "audio/m4a")})
    assert r.status_code == 201
    body = r.json()
    assert body["urgency"] == "P1"
    assert "unintelligible" in body["description"]


def test_sos_voice_rejects_bad_input():
    """Empty audio and bad coords are 422 (malformed, not model errors)."""
    r = client.post("/api/sos-voice",
                    data={"latitude": "-6.2", "longitude": "106.8"},
                    files={"audio": ("clip.m4a", b"", "audio/m4a")})
    assert r.status_code == 422
    r = client.post("/api/sos-voice",
                    data={"latitude": "999", "longitude": "106.8"},
                    files={"audio": ("clip.m4a", b"\x00\x01", "audio/m4a")})
    assert r.status_code == 422


def test_sos_voice_helpers_unit():
    """_clean drops whisper junk; translate of empty text is a no-op."""
    from app.voice_sos import _clean, translate_id_en

    assert _clean("Thanks for watching!") == ""
    assert _clean("  ") == ""
    assert _clean("tolong, kebakaran!") != ""
    assert translate_id_en("") == (None, "none")
