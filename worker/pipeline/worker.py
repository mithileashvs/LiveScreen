from typing import Optional
from ..contracts.input import VenueReconstructionInput
from ..contracts.result import VenueReconstructionResult, ReconstructionUncertaintyState, ScaleStatus
from ..reconstruction.fusion import MultiViewFusionEngine

class UnavailableReconstructionWorker:
    """Production fallback when external GPU worker endpoint is unconnected."""
    def __init__(self, message: Optional[str] = None):
        self.message = message or "AI reconstruction worker is not connected."

    @property
    def is_available(self) -> bool:
        return False

    def analyze(self, inp: VenueReconstructionInput) -> VenueReconstructionResult:
        return VenueReconstructionResult(
            job_id=inp.job_id,
            session_id=inp.session_id,
            theatre_id=inp.theatre_id,
            revision=inp.revision,
            scale_status=ScaleStatus.UNKNOWN,
            state=ReconstructionUncertaintyState.UNSUPPORTED,
            is_success=False,
            error_message=self.message,
            worker_name="ProductionWorker (Disconnected)"
        )

class ReferenceVenueReconstructionWorker:
    """Deterministic reference worker implementation for testing and development."""
    def __init__(self):
        self.engine = MultiViewFusionEngine()

    @property
    def is_available(self) -> bool:
        return True

    def analyze(self, inp: VenueReconstructionInput) -> VenueReconstructionResult:
        return self.engine.fuse(inp)

    def refine(self, inp: VenueReconstructionInput, previous_result: VenueReconstructionResult) -> VenueReconstructionResult:
        inp.revision = previous_result.revision + 1
        return self.analyze(inp)
