import unittest
from worker.contracts.job import VenueCaptureJob, CaptureJobStatus
from worker.contracts.input import VenueReconstructionInput, LogicalVenueConstraints, VenueCaptureMediaRef
from worker.contracts.result import VenueReconstructionResult, ScaleStatus, ReconstructionUncertaintyState
from worker.contracts.observation import VenueObservation, ObservationType

class TestWorkerContracts(unittest.TestCase):
    def test_job_serialization(self):
        job = VenueCaptureJob(
            id="job-1",
            session_id="session-1",
            theatre_id="theatre-1",
            status=CaptureJobStatus.RUNNING,
            progress=0.5,
            revision=2,
            requested_capabilities=["room", "screen"],
        )
        d = job.to_dict()
        self.assertEqual(d["id"], "job-1")
        self.assertEqual(d["status"], "running")
        self.assertEqual(d["revision"], 2)

    def test_logical_constraints_serialization(self):
        constraints = LogicalVenueConstraints(
            rows=12,
            seats_per_row=16,
            block_count=3,
            aisle_after_seats=[4, 12],
            row_seat_counts={1: 14},
            removed_seats={"A7"},
            aisle_width=1.2,
        )
        d = constraints.to_dict()
        self.assertEqual(d["rows"], 12)
        self.assertEqual(d["aisleAfterSeats"], [4, 12])
        self.assertEqual(d["rowSeatCounts"]["1"], 14)
        self.assertIn("A7", d["removedSeats"])

    def test_observation_serialization(self):
        obs = VenueObservation(
            id="obs-1",
            type=ObservationType.ROOM_GEOMETRY,
            value={"width": 18.0},
            confidence=0.91,
            provenance="aiEstimated",
            evidence_ids=["photo-1", "photo-2"],
        )
        d = obs.to_dict()
        self.assertEqual(d["type"], "roomGeometry")
        self.assertEqual(d["confidence"], 0.91)
        self.assertEqual(len(d["evidenceIds"]), 2)

if __name__ == "__main__":
    unittest.main()
