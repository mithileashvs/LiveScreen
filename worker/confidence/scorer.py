from typing import List
from ..contracts.observation import VenueObservation

class ConfidenceScorer:
    """Computes overall confidence and per-feature confidence metrics."""
    @staticmethod
    def calculate_overall(observations: List[VenueObservation]) -> float:
        valid = [o.confidence for o in observations if o.confidence is not None and o.confidence > 0]
        if not valid:
            return 0.0
        return sum(valid) / len(valid)
