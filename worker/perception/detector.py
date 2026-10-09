from typing import List, Dict, Any

class ObjectDetector:
    """Interface / contract for 2D/3D auditorium fixture detection models."""
    def detect_objects(self, media_id: str, storage_path: str) -> List[Dict[str, Any]]:
        return []
