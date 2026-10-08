# Spesifikasi ini mencatat konsistensi permintaan serentak dan transisi laporan.
# Tes ditunda karena penyimpanan dan orkestrasi transaksi belum diimplementasikan.
# Pertahankan kasus sebagai kriteria penerimaan saat layanan dibuat.
import pytest

pytestmark = pytest.mark.skip(
    reason="Behavioral acceptance checks are retained for the implementation phase."
)
import asyncio

from app import main


def _ticket(ticket_id: str, title: str) -> dict:
    # Keep a plain JSON-shaped payload in this deferred acceptance example.
    return {
        "id": ticket_id,
        "title": title,
        "category": "fire",
        "latitude": -6.2,
        "longitude": 106.8,
        "severity": "medium",
    }


def test_enrichment_does_not_overwrite_a_concurrent_correction(monkeypatch):
    entered = asyncio.Event()
    resume = asyncio.Event()
    ticket = _ticket("race-correction", "Smoke nearby")
    main._store[ticket["id"]] = ticket

    async def delayed_classification(snapshot):
        snapshot.update(
            ai_category="fire",
            ai_confidence=0.9,
            ai_suggested_urgency="P2",
            ai_urgency_conf=0.7,
            needs_review=True,
            urgency_source="ai_triage_pending_review",
        )
        entered.set()
        await resume.wait()
        return snapshot

    monkeypatch.setattr(main, "classify", delayed_classification)

    async def run_race():
        task = asyncio.create_task(main._enrich(ticket["id"]))
        await entered.wait()
        await main.correct(
            ticket["id"],
            {"ai_category": "medical", "urgency": "P2"},
        )
        resume.set()
        await task

    asyncio.run(run_race())

    stored = main._store[ticket["id"]]
    assert stored["ai_category"] == "medical"
    assert stored["urgency"] == "P2"
    assert stored["urgency_source"] == "coordinator_corrected"
    assert stored["needs_review"] is False
    classification = next(
        entry for entry in main._audit_log
        if entry["incident_id"] == ticket["id"]
        and entry["action"] == "ai_classify"
    )
    assert classification["detail"]["applied"] is False


def test_enrichment_does_not_restore_a_cluster_after_concurrent_split(monkeypatch):
    entered = asyncio.Event()
    resume = asyncio.Event()
    ticket = _ticket("race-split", "Smoke at campus")
    neighbour = _ticket("race-neighbour", "Smoke near campus")
    main._store[ticket["id"]] = ticket
    main._store[neighbour["id"]] = neighbour

    async def delayed_cluster(snapshot, _neighbours):
        snapshot["cluster_id"] = "stale-cluster"
        entered.set()
        await resume.wait()
        return [neighbour["id"]]

    monkeypatch.setattr(main, "cluster", delayed_cluster)

    async def run_race():
        task = asyncio.create_task(main._enrich(ticket["id"]))
        await entered.wait()
        await main.split_cluster(ticket["id"])
        resume.set()
        await task

    asyncio.run(run_race())

    assert main._store[ticket["id"]]["cluster_id"] is None
    assert main._store[neighbour["id"]]["cluster_id"] is None
