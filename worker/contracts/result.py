from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, Dict, Any, List
from .observation import VenueObservation

class ScaleStatus(str, Enum):
    KNOWN = "known"
    CALIBRATED = "calibrated"
    UNKNOWN = "unknown"

class ReconstructionUncertaintyState(str, Enum):
    CONFIDENT = "confident"
    UNCERTAIN = "uncertain"
    CONFLICT = "conflict"
    NEEDS_MEASUREMENT = "needsMeasurement"
    NEEDS_PHOTO = "needsPhoto"
    UNSUPPORTED = "unsupported"

@dataclass
class VenueReconstructionConflict:
    id: str
    feature: str
    description: str
    admin_constraint: str
    detected_value: str
    suggested_resolution: str
    evidence_ids: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "feature": self.feature,
            "description": self.description,
            "adminConstraint": self.admin_constraint,
            "detectedValue": self.detected_value,
            "suggestedResolution": self.suggested_resolution,
            "evidenceIds": self.evidence_ids,
        }

@dataclass
class VenueCaptureRequest:
    id: str
    session_id: str
    theatre_id: str
    target: str
    reason: str
    required_evidence_type: str
    instruction: str
    priority: str = "medium"
    status: str = "pending"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "sessionId": self.session_id,
            "theatreId": self.theatre_id,
            "target": self.target,
            "reason": self.reason,
            "requiredEvidenceType": self.required_evidence_type,
            "instruction": self.instruction,
            "priority": self.priority,
            "status": self.status,
        }

@dataclass
class VenueReconstructionResult:
    job_id: str
    session_id: str
    theatre_id: Optional[str] = None
    revision: int = 1
    scale_status: ScaleStatus = ScaleStatus.UNKNOWN
    state: ReconstructionUncertaintyState = ReconstructionUncertaintyState.UNCERTAIN
    observations: List[VenueObservation] = field(default_factory=list)
    room: Dict[str, Any] = field(default_factory=dict)
    screen: Dict[str, Any] = field(default_factory=dict)
    seating: Dict[str, Any] = field(default_factory=dict)
    speakers: List[Dict[str, Any]] = field(default_factory=list)
    lighting: Dict[str, Any] = field(default_factory=dict)
    appearance: Dict[str, Any] = field(default_factory=dict)
    overall_confidence: float = 0.0
    evidence_links: Dict[str, List[str]] = field(default_factory=dict)
    requests: List[VenueCaptureRequest] = field(default_factory=list)
    conflicts: List[VenueReconstructionConflict] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    coordinate_convention: Dict[str, str] = field(default_factory=lambda: {
        "units": "metres",
        "origin": "front_wall_floor_center",
        "lateralAxis": "+X",
        "upAxis": "+Y",
        "forwardAxis": "+Z",
        "seatForwardFacing": "-Z",
    })
    is_success: bool = True
    error_message: Optional[str] = None
    worker_name: str = "VenueReconstructionWorker"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "jobId": self.job_id,
            "sessionId": self.session_id,
            "theatreId": self.theatre_id,
            "revision": self.revision,
            "scaleStatus": self.scale_status.value,
            "state": self.state.value,
            "observations": [o.to_dict() for o in self.observations],
            "room": self.room,
            "screen": self.screen,
            "seating": self.seating,
            "speakers": self.speakers,
            "lighting": self.lighting,
            "appearance": self.appearance,
            "overallConfidence": self.overall_confidence,
            "evidenceLinks": self.evidence_links,
            "requests": [r.to_dict() for r in self.requests],
            "conflicts": [c.to_dict() for c in self.conflicts],
            "warnings": self.warnings,
            "coordinateConvention": self.coordinate_convention,
            "isSuccess": self.is_success,
            "errorMessage": self.error_message,
            "workerName": self.worker_name,
        }
