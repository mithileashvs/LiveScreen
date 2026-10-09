from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, Dict, Any, List
from datetime import datetime

class CaptureJobStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    NEEDS_EVIDENCE = "needsEvidence"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

@dataclass
class VenueCaptureJob:
    id: str
    session_id: str
    theatre_id: str
    job_type: str = "general_reconstruction"
    status: CaptureJobStatus = CaptureJobStatus.PENDING
    progress: float = 0.0
    error_message: Optional[str] = None
    worker_id: Optional[str] = None
    revision: int = 1
    requested_capabilities: List[str] = field(default_factory=list)
    evidence_ids: List[str] = field(default_factory=list)
    payload: Dict[str, Any] = field(default_factory=dict)
    result_summary: Optional[Dict[str, Any]] = None
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    started_at: Optional[str] = None
    completed_at: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "sessionId": self.session_id,
            "theatreId": self.theatre_id,
            "jobType": self.job_type,
            "status": self.status.value,
            "progress": self.progress,
            "errorMessage": self.error_message,
            "workerId": self.worker_id,
            "revision": self.revision,
            "requestedCapabilities": self.requested_capabilities,
            "evidenceIds": self.evidence_ids,
            "payload": self.payload,
            "resultSummary": self.result_summary,
            "createdAt": self.created_at,
            "startedAt": self.started_at,
            "completedAt": self.completed_at,
        }
