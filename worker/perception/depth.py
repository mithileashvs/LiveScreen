from typing import Dict, Any

class DepthEstimator:
    """Interface / contract for future metric depth estimation models."""
    def estimate_depth(self, media_id: str, storage_path: str) -> Dict[str, Any]:
        return {
            "mediaId": media_id,
            "depthMapStoragePath": f"{storage_path}.depth.npy",
            "confidence": 0.85,
            "minDepthMeters": 0.5,
            "maxDepthMeters": 35.0,
        }
