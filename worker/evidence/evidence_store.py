from typing import List, Dict, Any
from ..contracts.input import VenueCaptureMediaRef

class EvidenceStore:
    """Partitions and organizes evidence by view category."""
    def __init__(self, evidence: List[VenueCaptureMediaRef]):
        self.evidence = evidence

    def filter_by_category(self, categories: List[str]) -> List[VenueCaptureMediaRef]:
        cats = set(c.lower() for c in categories)
        return [
            e for e in self.evidence
            if e.category.lower() in cats or any(c in e.filename.lower() for c in cats)
        ]

    def has_category(self, categories: List[str]) -> bool:
        return len(self.filter_by_category(categories)) > 0

    def get_ids_for_category(self, categories: List[str]) -> List[str]:
        return [e.id for e in self.filter_by_category(categories)]
