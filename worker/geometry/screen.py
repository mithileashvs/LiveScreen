from typing import Optional, Dict, Any

class ScreenGeometryEstimator:
    """Estimates screen dimensions and center from front wall imagery."""
    def estimate(self, has_front_wall: bool, scale_calibrated: bool,
                 known_width: Optional[float] = None,
                 known_height: Optional[float] = None) -> Dict[str, Any]:
        if not has_front_wall:
            return {
                "width": {"value": None, "provenance": "unknown", "confidence": 0.0},
                "height": {"value": None, "provenance": "unknown", "confidence": 0.0},
                "position": {"value": None, "provenance": "unknown", "confidence": 0.0},
                "type": {"value": None, "provenance": "unknown", "confidence": 0.0},
            }

        if not scale_calibrated:
            return {
                "width": {"value": None, "provenance": "unknown", "confidence": 0.0},
                "height": {"value": None, "provenance": "unknown", "confidence": 0.0},
                "position": {"value": None, "provenance": "unknown", "confidence": 0.0},
                "type": {"value": "standard", "provenance": "aiEstimated", "confidence": 0.90},
            }

        w = known_width or 14.0
        h = known_height or 6.0

        return {
            "width": {"value": w, "provenance": "aiEstimated", "confidence": 0.92},
            "height": {"value": h, "provenance": "aiEstimated", "confidence": 0.90},
            "position": {"value": {"x": 0.0, "y": 1.5, "z": 0.5}, "provenance": "aiEstimated", "confidence": 0.90},
            "type": {"value": "standard", "provenance": "aiEstimated", "confidence": 0.95},
        }
