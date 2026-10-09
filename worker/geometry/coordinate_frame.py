"""LiveScreen Coordinate Convention:
- Units: metres
- Unity: left-handed, Y-up
- Origin: front wall floor center (0,0,0)
- +X: right
- +Y: up
- +Z: front-to-back (into auditorium)
- Seat rotationY = 0: faces -Z (toward screen)
"""
from dataclasses import dataclass
from typing import Dict, Any

@dataclass
class CoordinateFrame:
    units: str = "metres"
    origin: str = "front_wall_floor_center"
    lateral_axis: str = "+X"
    up_axis: str = "+Y"
    forward_axis: str = "+Z"
    seat_forward_facing: str = "-Z"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "units": self.units,
            "origin": self.origin,
            "lateralAxis": self.lateral_axis,
            "upAxis": self.up_axis,
            "forwardAxis": self.forward_axis,
            "seatForwardFacing": self.seat_forward_facing,
        }
