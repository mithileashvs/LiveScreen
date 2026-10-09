from dataclasses import dataclass, field
from typing import Optional, Dict, Any, List, Set

@dataclass
class LogicalVenueConstraints:
    rows: Optional[int] = None
    seats_per_row: Optional[int] = None
    block_count: Optional[int] = None
    aisle_after_seats: List[int] = field(default_factory=list)
    row_seat_counts: Dict[int, int] = field(default_factory=dict)
    removed_seats: Set[str] = field(default_factory=set)
    aisle_width: Optional[float] = None

    def to_dict(self) -> Dict[str, Any]:
        d: Dict[str, Any] = {}
        if self.rows is not None:
            d["rows"] = self.rows
        if self.seats_per_row is not None:
            d["seatsPerRow"] = self.seats_per_row
        if self.block_count is not None:
            d["blockCount"] = self.block_count
        if self.aisle_after_seats:
            d["aisleAfterSeats"] = self.aisle_after_seats
        if self.row_seat_counts:
            d["rowSeatCounts"] = {str(k): v for k, v in self.row_seat_counts.items()}
        if self.removed_seats:
            d["removedSeats"] = list(self.removed_seats)
        if self.aisle_width is not None:
            d["aisleWidth"] = self.aisle_width
        return d

@dataclass
class VenueCaptureMediaRef:
    id: str
    session_id: str
    category: str
    media_type: str = "photo"
    filename: str = ""
    storage_path: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "sessionId": self.session_id,
            "category": self.category,
            "type": self.media_type,
            "filename": self.filename,
            "storagePath": self.storage_path,
            "metadata": self.metadata,
        }

@dataclass
class VenueReconstructionInput:
    job_id: str
    session_id: str
    theatre_id: Optional[str] = None
    evidence: List[VenueCaptureMediaRef] = field(default_factory=list)
    baseline_draft: Optional[Dict[str, Any]] = None
    logical_constraints: Optional[LogicalVenueConstraints] = None
    known_measurements: Dict[str, float] = field(default_factory=dict)
    coordinate_convention: Dict[str, str] = field(default_factory=lambda: {
        "units": "metres",
        "origin": "front_wall_floor_center",
        "lateralAxis": "+X",
        "upAxis": "+Y",
        "forwardAxis": "+Z",
        "seatForwardFacing": "-Z",
    })
    requested_analysis: List[str] = field(default_factory=lambda: [
        "room", "screen", "seating", "speakers", "lighting", "appearance"
    ])
    previous_observations: List[Dict[str, Any]] = field(default_factory=list)
    revision: int = 1

    def to_dict(self) -> Dict[str, Any]:
        return {
            "jobId": self.job_id,
            "sessionId": self.session_id,
            "theatreId": self.theatre_id,
            "evidence": [e.to_dict() for e in self.evidence],
            "baselineDraft": self.baseline_draft,
            "logicalConstraints": self.logical_constraints.to_dict() if self.logical_constraints else None,
            "knownMeasurements": self.known_measurements,
            "coordinateConvention": self.coordinate_convention,
            "requestedAnalysis": self.requested_analysis,
            "previousObservations": self.previous_observations,
            "revision": self.revision,
        }
