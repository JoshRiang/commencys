# Spesifikasi ini mencatat mutu triase dan pengelompokan yang harus diuji kelak.
# Tes ditunda karena Laya, aturan urgensi, jarak, dan DBSCAN belum dijalankan.
# Kasus uji bukan bukti bahwa model atau algoritma sudah tersedia.
import pytest

pytestmark = pytest.mark.skip(
    reason="Behavioral acceptance checks are retained for the implementation phase."
)
import asyncio
import math

# Function imports are deferred with these acceptance examples until services exist.


def test_keyword_scores_match_words_not_substrings():
    assert heuristic_scores("terapi berlangsung")['fire'] == 0.0
    assert heuristic_scores("api terlihat")['fire'] > 0.0


def test_rule_urgency_only_escalates_and_never_downgrades():
    escalated = infer_urgency("orang tidak sadar", "medical", "P3")
    already_critical = infer_urgency("laporan biasa", "other", "P1")

    assert escalated == {"suggested": "P1", "confidence": 0.8, "escalate": True}
    assert already_critical == {"suggested": "P1", "confidence": 0.5, "escalate": False}


def test_sos_keeps_p1_and_does_not_invent_incident_type():
    ticket = {
        "title": "SOS",
        "description": "One-tap SOS",
        "category": "sos",
        "urgency": "P1",
        "urgency_source": "sos_default_pending_triage",
    }

    result = asyncio.run(classify(ticket))

    assert result["urgency"] == "P1"
    assert result["ai_category"] is None
    assert result["ai_confidence"] is None
    assert result["ai_suggested_urgency"] == "P1"
    assert result["needs_review"] is True


def test_low_rule_score_routes_report_for_human_review():
    ticket = {
        "title": "Unclear report",
        "description": "words without known keywords",
        "category": "other",
        "urgency": "P3",
    }

    result = asyncio.run(classify(ticket))

    assert result["ai_category"] == "other"
    assert result["ai_confidence"] == 0.05
    assert result["needs_review"] is True


def test_matcher_uses_distance_time_and_symmetric_category_compatibility():
    ticket = {
        "id": "new",
        "category": "medical",
        "latitude": -6.2,
        "longitude": 106.8,
        "status": "acknowledged",
        "created_at": "2026-10-02T00:10:00+00:00",
    }
    nearby = {
        "id": "old",
        "category": "accident",
        "latitude": -6.2001,
        "longitude": 106.8,
        "status": "acknowledged",
        "created_at": "2026-10-02T00:00:00+00:00",
    }

    linked = asyncio.run(cluster(ticket, [nearby]))

    assert haversine_m(-6.2, 106.8, -6.2001, 106.8) < CLUSTER_EPS_M
    assert ticket["cluster_id"]
    assert linked == ["old"]
    assert _compatible("medical", "accident") is True
    assert _compatible("fire", "medical") is False
    assert _compatible("medical", "fire") is False


def test_distance_rejects_non_finite_and_out_of_range_coordinates():
    for coordinates in (
        (math.nan, 0, 0, 0),
        (math.inf, 0, 0, 0),
        (91, 0, 0, 0),
        (0, 181, 0, 0),
    ):
        try:
            haversine_m(*coordinates)
        except ValueError:
            pass
        else:
            raise AssertionError(f"invalid coordinates accepted: {coordinates}")


def test_matcher_skips_neighbour_with_invalid_coordinates():
    ticket = {
        "id": "new",
        "category": "medical",
        "latitude": -6.2,
        "longitude": 106.8,
        "status": "acknowledged",
        "created_at": "2026-10-02T00:10:00+00:00",
    }
    invalid_neighbour = {
        "id": "invalid",
        "category": "medical",
        "latitude": math.nan,
        "longitude": 106.8,
        "status": "acknowledged",
        "created_at": "2026-10-02T00:10:00+00:00",
    }

    assert asyncio.run(cluster(ticket, [invalid_neighbour])) == []
    assert "cluster_id" not in ticket


def test_matcher_does_not_link_far_old_resolved_or_untimed_tickets():
    ticket = {
        "id": "new",
        "category": "fire",
        "latitude": -6.2,
        "longitude": 106.8,
        "status": "acknowledged",
        "created_at": "2026-10-02T00:40:00+00:00",
    }
    candidates = [
        {
            "id": "far",
            "category": "fire",
            "latitude": -6.21,
            "longitude": 106.8,
            "status": "acknowledged",
            "created_at": "2026-10-02T00:39:00+00:00",
        },
        {
            "id": "old",
            "category": "fire",
            "latitude": -6.2,
            "longitude": 106.8,
            "status": "acknowledged",
            "created_at": "2026-10-02T00:00:00+00:00",
        },
        {
            "id": "resolved",
            "category": "fire",
            "latitude": -6.2,
            "longitude": 106.8,
            "status": "resolved",
            "created_at": "2026-10-02T00:39:00+00:00",
        },
        {
            "id": "untimed",
            "category": "fire",
            "latitude": -6.2,
            "longitude": 106.8,
            "status": "acknowledged",
        },
    ]

    linked = asyncio.run(cluster(ticket, candidates))

    assert linked == []
    assert "cluster_id" not in ticket


def test_matcher_joins_an_existing_cluster_without_reassigning_members():
    ticket = {
        "id": "new",
        "category": "fire",
        "latitude": 1,
        "longitude": 1,
        "status": "acknowledged",
        "created_at": "2026-10-02T00:00:00+00:00",
    }
    existing = {
        "id": "existing",
        "category": "fire",
        "latitude": 1,
        "longitude": 1,
        "status": "acknowledged",
        "cluster_id": "cluster-1",
        "created_at": "2026-10-02T00:00:00+00:00",
    }

    linked = asyncio.run(cluster(ticket, [existing]))

    assert ticket["cluster_id"] == "cluster-1"
    assert linked == []
