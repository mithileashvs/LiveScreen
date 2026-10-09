from typing import List, Dict, Any, Tuple
from ..contracts.input import VenueReconstructionInput, LogicalVenueConstraints
from ..contracts.result import VenueReconstructionResult, ScaleStatus, ReconstructionUncertaintyState, VenueCaptureRequest, VenueReconstructionConflict
from ..contracts.observation import VenueObservation, ObservationType
from ..evidence.evidence_store import EvidenceStore
from ..geometry.room import RoomGeometryEstimator
from ..geometry.screen import ScreenGeometryEstimator
from ..seating.seating_lattice import SeatingLatticeExtractor
from ..confidence.scorer import ConfidenceScorer

class MultiViewFusionEngine:
    """Fuses multi-view evidence fixtures into structured reconstruction observations."""
    def __init__(self):
        self.room_estimator = RoomGeometryEstimator()
        self.screen_estimator = ScreenGeometryEstimator()
        self.seating_extractor = SeatingLatticeExtractor()

    def fuse(self, inp: VenueReconstructionInput) -> VenueReconstructionResult:
        store = EvidenceStore(inp.evidence)
        revision = inp.revision
        observations: List[VenueObservation] = []
        requests: List[VenueCaptureRequest] = []
        conflicts: List[VenueReconstructionConflict] = []
        warnings: List[str] = []
        evidence_links: Dict[str, List[str]] = {}

        if not inp.evidence:
            requests.append(VenueCaptureRequest(
                id=f"req-init-{revision}",
                session_id=inp.session_id,
                theatre_id=inp.theatre_id or "theatre",
                target="Front Wall & Screen",
                reason="Initial visual evidence is required.",
                required_evidence_type="photo",
                instruction="Stand in the center aisle, eye height, facing front wall.",
                priority="critical"
            ))
            return VenueReconstructionResult(
                job_id=inp.job_id,
                session_id=inp.session_id,
                theatre_id=inp.theatre_id,
                revision=revision,
                scale_status=ScaleStatus.UNKNOWN,
                state=ReconstructionUncertaintyState.NEEDS_PHOTO,
                requests=requests,
                is_success=True,
                worker_name="ReferenceFusionEngine"
            )

        # Scale assessment
        has_measurements = len(inp.known_measurements) > 0
        has_measure_evidence = store.has_category(["measurement"])
        scale_status = ScaleStatus.KNOWN if has_measurements else (
            ScaleStatus.CALIBRATED if has_measure_evidence else ScaleStatus.UNKNOWN
        )
        scale_calibrated = scale_status != ScaleStatus.UNKNOWN

        if not scale_calibrated:
            observations.append(VenueObservation(
                id=f"obs-scale-{revision}",
                type=ObservationType.SCALE,
                value={"status": "unknown"},
                confidence=0.0,
                provenance="unknown",
                notes="Metric scale unknown.",
                revision=revision
            ))
            requests.append(VenueCaptureRequest(
                id=f"req-scale-{revision}",
                session_id=inp.session_id,
                theatre_id=inp.theatre_id or "theatre",
                target="Auditorium Scale Reference",
                reason="Metric scale cannot be established without guessing.",
                required_evidence_type="measurement",
                instruction="Measure the distance from the front wall to Row A or screen width.",
                priority="high"
            ))
        else:
            observations.append(VenueObservation(
                id=f"obs-scale-{revision}",
                type=ObservationType.SCALE,
                value={"status": "calibrated"},
                confidence=0.95,
                provenance="measured",
                revision=revision
            ))

        # Room geometry
        has_front = store.has_category(["frontwall", "front_wall", "screenstage", "screen_stage", "front"])
        has_rear = store.has_category(["rearwall", "rear_wall", "rear", "back"])
        room_data = self.room_estimator.estimate(
            has_front=has_front,
            has_rear=has_rear,
            scale_calibrated=scale_calibrated,
            known_width=inp.known_measurements.get("roomWidth"),
            known_length=inp.known_measurements.get("roomLength"),
            known_height=inp.known_measurements.get("roomHeight"),
        )
        if has_front and has_rear and scale_calibrated:
            f_ids = store.get_ids_for_category(["frontwall", "front"]) + store.get_ids_for_category(["rearwall", "rear"])
            observations.append(VenueObservation(
                id=f"obs-room-{revision}",
                type=ObservationType.ROOM_GEOMETRY,
                value={"width": room_data["width"]["value"]},
                confidence=0.88,
                provenance="aiEstimated",
                evidence_ids=f_ids,
                revision=revision
            ))

        # Screen geometry
        screen_data = self.screen_estimator.estimate(
            has_front_wall=has_front,
            scale_calibrated=scale_calibrated,
            known_width=inp.known_measurements.get("screenWidth"),
            known_height=inp.known_measurements.get("screenHeight"),
        )

        # Seating geometry
        has_seating = store.has_category(["seating", "seat"])
        seating_data = self.seating_extractor.extract(
            has_seating_media=has_seating,
            has_rear_media=has_rear,
            scale_calibrated=scale_calibrated,
            logical_constraints=inp.logical_constraints,
            known_spacing=inp.known_measurements.get("seatSpacing"),
            known_row_spacing=inp.known_measurements.get("rowSpacing"),
        )

        if has_seating:
            detected_rows = seating_data["rows"]["value"]
            target_rows = inp.logical_constraints.rows if inp.logical_constraints and inp.logical_constraints.rows else 12
            if inp.logical_constraints and inp.logical_constraints.rows and detected_rows != target_rows:
                conflict = VenueReconstructionConflict(
                    id=f"conflict-rows-{revision}",
                    feature="seating.rows",
                    description=f"I detected approximately {detected_rows} visible rows, but the venue configuration specifies {target_rows} rows.",
                    admin_constraint=f"{target_rows} rows",
                    detected_value=f"{detected_rows} rows",
                    suggested_resolution="Please provide a rear/side photo showing the missing row.",
                    evidence_ids=store.get_ids_for_category(["seating"])
                )
                conflicts.append(conflict)
                requests.append(VenueCaptureRequest(
                    id=f"req-rear-seating-{revision}",
                    session_id=inp.session_id,
                    theatre_id=inp.theatre_id or "theatre",
                    target="Rear Seating Rows",
                    reason=conflict.description,
                    required_evidence_type="photo",
                    instruction=f"Stand at back-right corner, face diagonally toward screen, showing rows 9-{target_rows}.",
                    priority="high"
                ))

        # Speakers (visual only, requires speaker evidence)
        has_speakers = store.has_category(["speakers", "speaker"])
        speakers: List[Dict[str, Any]] = []
        if has_speakers:
            sp_ids = store.get_ids_for_category(["speakers", "speaker"])
            speakers = [
                {"id": "sp-1", "name": "Surround L1", "type": "surround", "evidenceIds": sp_ids},
                {"id": "sp-2", "name": "Surround R1", "type": "surround", "evidenceIds": sp_ids},
            ]
            observations.append(VenueObservation(
                id=f"obs-sp-{revision}",
                type=ObservationType.SPEAKER,
                value={"count": 2},
                confidence=0.82,
                evidence_ids=sp_ids,
                revision=revision
            ))

        # Lighting
        has_lighting = store.has_category(["lighting", "ceiling", "light"])
        lighting: Dict[str, Any] = {}
        if has_lighting:
            l_ids = store.get_ids_for_category(["lighting", "ceiling"])
            lighting = {
                "ceilingLightsCount": {"value": 12, "provenance": "aiEstimated", "confidence": 0.78},
                "hasAisleLighting": {"value": True, "provenance": "aiEstimated", "confidence": 0.75},
                "estimatedLux": {"value": None, "provenance": "unknown", "confidence": 0.0},
            }

        # Appearance & Materials (global palette + independent per-wall finishes)
        has_materials = store.has_category(["material", "appearance", "finish"]) or has_front or has_seating or has_rear
        appearance: Dict[str, Any] = {}
        if has_materials:
            m_ids = store.get_ids_for_category(["material", "appearance"]) + store.get_ids_for_category(["frontwall", "front", "seating", "rearwall", "rear"])
            front_wall: Dict[str, Any] = {}
            if has_front:
                front_wall = {
                    "colorHex": {"value": "#1A1A1E", "provenance": "aiEstimated", "confidence": 0.78},
                    "materialType": {"value": "matte_proscenium_finish", "provenance": "aiEstimated", "confidence": 0.75},
                    "patternTreatment": {"value": "acoustic_baffles", "provenance": "aiEstimated", "confidence": 0.70},
                }

            left_wall: Dict[str, Any] = {}
            right_wall: Dict[str, Any] = {}
            if has_seating:
                left_wall = {
                    "colorHex": {"value": "#2C2D30", "provenance": "aiEstimated", "confidence": 0.75},
                    "materialType": {"value": "acoustic_fabric_panel", "provenance": "aiEstimated", "confidence": 0.72},
                    "patternTreatment": {"value": "fabric_baffles", "provenance": "aiEstimated", "confidence": 0.70},
                }
                right_wall = {
                    "colorHex": {"value": "#2C2D30", "provenance": "aiEstimated", "confidence": 0.75},
                    "materialType": {"value": "acoustic_fabric_panel", "provenance": "aiEstimated", "confidence": 0.72},
                    "patternTreatment": {"value": "fabric_baffles", "provenance": "aiEstimated", "confidence": 0.70},
                }

            rear_wall: Dict[str, Any] = {}
            if has_rear:
                rear_wall = {
                    "colorHex": {"value": "#25262A", "provenance": "aiEstimated", "confidence": 0.76},
                    "materialType": {"value": "diffuser_panel", "provenance": "aiEstimated", "confidence": 0.72},
                    "patternTreatment": {"value": "quadratic_residue_diffuser", "provenance": "aiEstimated", "confidence": 0.70},
                }

            appearance = {
                "wallColorHex": {"value": "#2C2D30", "provenance": "aiEstimated", "confidence": 0.75},
                "carpetColorHex": {"value": "#1E2024", "provenance": "aiEstimated", "confidence": 0.72},
                "wallMaterialType": {"value": "acoustic_fabric_panel", "provenance": "aiEstimated", "confidence": 0.70},
                "frontWall": front_wall,
                "leftWall": left_wall,
                "rightWall": right_wall,
                "rearWall": rear_wall,
            }

            observations.append(VenueObservation(
                id=f"obs-mat-{revision}",
                type=ObservationType.MATERIAL,
                value={"wallColor": "#2C2D30", "wallMaterial": "acoustic_fabric_panel"},
                confidence=0.73,
                evidence_ids=m_ids,
                revision=revision
            ))

        overall_conf = ConfidenceScorer.calculate_overall(observations)
        state = (
            ReconstructionUncertaintyState.CONFLICT if conflicts else (
                ReconstructionUncertaintyState.NEEDS_MEASUREMENT if any(r.required_evidence_type == "measurement" for r in requests) else (
                    ReconstructionUncertaintyState.NEEDS_PHOTO if requests else (
                        ReconstructionUncertaintyState.CONFIDENT if overall_conf >= 0.8 and scale_calibrated else ReconstructionUncertaintyState.UNCERTAIN
                    )
                )
            )
        )

        return VenueReconstructionResult(
            job_id=inp.job_id,
            session_id=inp.session_id,
            theatre_id=inp.theatre_id,
            revision=revision,
            scale_status=scale_status,
            state=state,
            observations=observations,
            room=room_data,
            screen=screen_data,
            seating=seating_data,
            speakers=speakers,
            lighting=lighting,
            appearance=appearance,
            overall_confidence=overall_conf,
            requests=requests,
            conflicts=conflicts,
            warnings=warnings,
            is_success=True,
            worker_name="ReferenceFusionEngine"
        )
