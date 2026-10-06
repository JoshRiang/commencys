"""Commencys backend — Pydantic schemas (spec taxonomy).

Spec refs: acceptance criteria (§1), AI stations §4
(taxonomy + P1–P4 urgency), §7 (acknowledged vs dispatched transparency).
"""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import Any, Optional
from uuid import uuid4

from pydantic import BaseModel, Field


class Category(str, Enum):
    """Standardised incident-type taxonomy (spec station 4)."""

    MEDICAL = "medical"  # henti jantung, pingsan, trauma fisik
    ACCIDENT = "accident"  # lalin, jatuh dari ketinggian
    FIRE = "fire"  # kebakaran
    SECURITY = "security"  # pencurian, penyerangan, pelecehan
    FACILITY = "facility"  # kedaruratan fasilitas / lainnya
    OTHER = "other"


class Urgency(str, Enum):
    """P1-Kritis … P4-Rendah (spec station 4)."""

    P1 = "P1"
    P2 = "P2"
    P3 = "P3"
    P4 = "P4"


class Status(str, Enum):
    """Ticket lifecycle. `acknowledged` ≠ `dispatched` (spec §7, criterion 3)."""

    REPORTED = "reported"  # stored, pre-ack (transient)
    ACKNOWLEDGED = "acknowledged"  # system received + stored (Report Acknowledged)
    BROADCAST = "broadcast"  # notification fanned out to volunteers
    DISPATCHED = "dispatched"  # a volunteer accepted the task
    RESOLVED = "resolved"


class SosIn(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    accuracy_m: Optional[float] = Field(default=None, ge=0)
    description: Optional[str] = None
    photo_url: Optional[str] = None
    reporter_name: str = "Anonymous"


class IncidentIn(BaseModel):
    title: str
    description: str = ""
    category: Category = Category.OTHER
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    accuracy_m: Optional[float] = Field(default=None, ge=0)
    reporter_name: str = "Anonymous"


class CorrectIn(BaseModel):
    """Coordinator correction — raw title/description stay immutable."""

    ai_category: Optional[str] = None
    urgency: Optional[str] = None


class VolunteerIn(BaseModel):
    """Volunteer registration — roles drive targeted dispatch invites."""

    name: str
    phone: Optional[str] = None
    roles: list[str] = Field(default_factory=list)
    skills: list[str] = Field(default_factory=list)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class Volunteer(BaseModel):
    id: str = Field(default_factory=lambda: uuid4().hex[:12])
    name: str
    phone: Optional[str] = None
    roles: list[str] = Field(default_factory=list)
    skills: list[str] = Field(default_factory=list)
    latitude: float
    longitude: float
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )


class Incident(BaseModel):
    id: str = Field(default_factory=lambda: uuid4().hex[:12])
    title: str
    description: str = ""
    category: str = Category.OTHER.value
    latitude: float
    longitude: float
    accuracy_m: Optional[float] = None
    reporter_name: str = "Anonymous"
    urgency: str = Urgency.P3.value
    urgency_source: str = "reporter_default"
    status: str = Status.ACKNOWLEDGED.value
    ai_category: Optional[str] = None
    ai_confidence: Optional[float] = None
    needs_review: bool = False
    cluster_id: Optional[str] = None
    ai_suggested_urgency: Optional[str] = None
    ai_urgency_conf: Optional[float] = None
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    def to_ws_frame(self) -> dict[str, Any]:
        return {
            "type": "incident." + self.status,
            "id": self.id,
            "title": self.title,
            "category": self.category,
            "urgency": self.urgency,
            "status": self.status,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "created_at": self.created_at,
        }
