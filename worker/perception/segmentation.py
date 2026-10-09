from typing import List, Dict, Any

class SegmentationModel:
    """Interface / contract for semantic architectural segmentation models."""
    def segment(self, media_id: str, storage_path: str) -> List[Dict[str, Any]]:
        return []
