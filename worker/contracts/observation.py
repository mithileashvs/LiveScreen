from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, Dict, Any, List

class ObservationType(str, Enum):
    ROOM_GEOMETRY = "roomGeometry"
    SCREEN = "screen"
    SEATING = "seating"
    SEAT = "seat"
    SPEAKER = "speaker"
    LIGHTING = "lighting"
    MATERIAL = "material"
    COLOR = "color"
    SCALE = "scale"
    OTHER = "other"

@dataclass
class VenueObservation:
    id: str
    type: ObservationType
    value: Dict[str, Any]
    confidence: Optional[float] = None
    provenance: str = "aiEstimated"
    evidence_ids: List[str] = field(default_factory=list)
    source: Optional[str] = None
    notes: Optional[str] = None
    revision: int = 1

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "type": self.type.value,
            "value": self.value,
            "confidence": self.confidence,
            "provenance": self.provenance,
            "evidenceIds": self.evidence_ids,
            "source": self.source,
            "notes": self.notes,
            "revision": self.revision,
        }
