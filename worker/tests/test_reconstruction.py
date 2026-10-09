import unittest
from worker.pipeline.worker import ReferenceVenueReconstructionWorker, UnavailableReconstructionWorker
from worker.contracts.input import VenueReconstructionInput, VenueCaptureMediaRef, LogicalVenueConstraints
from worker.contracts.result import ScaleStatus, ReconstructionUncertaintyState

class TestReconstructionWorker(unittest.TestCase):
    def setUp(self):
        self.worker = ReferenceVenueReconstructionWorker()

    def test_unavailable_worker(self):
        unavail = UnavailableReconstructionWorker()
        inp = VenueReconstructionInput(job_id="j1", session_id="s1")
        res = unavail.analyze(inp)
        self.assertFalse(res.is_success)
        self.assertEqual(res.state, ReconstructionUncertaintyState.UNSUPPORTED)

    def test_empty_evidence_generates_request(self):
        inp = VenueReconstructionInput(job_id="j1", session_id="s1", evidence=[])
        res = self.worker.analyze(inp)
        self.assertTrue(res.is_success)
        self.assertEqual(res.state, ReconstructionUncertaintyState.NEEDS_PHOTO)
        self.assertTrue(len(res.requests) > 0)

    def test_unknown_scale_does_not_fabricate_metrics(self):
        evidence = [
            VenueCaptureMediaRef(id="e1", session_id="s1", category="frontWall", filename="front.jpg"),
            VenueCaptureMediaRef(id="e2", session_id="s1", category="seating", filename="seats.jpg"),
        ]
        inp = VenueReconstructionInput(
            job_id="j1",
            session_id="s1",
            evidence=evidence,
            known_measurements={},
        )
        res = self.worker.analyze(inp)
        self.assertEqual(res.scale_status, ScaleStatus.UNKNOWN)
        # Room width must be None/unknown
        self.assertIsNone(res.room["width"]["value"])
        # Seating spacing must be None/unknown
        self.assertIsNone(res.seating["seatSpacing"]["value"])
        # Physical seats array must be empty
        self.assertEqual(len(res.seating["seats"]), 0)
        # Targeted scale measurement request must be present
        self.assertTrue(any(r.required_evidence_type == "measurement" for r in res.requests))

    def test_conflicting_rows_surfaced(self):
        evidence = [
            VenueCaptureMediaRef(id="e1", session_id="s1", category="frontWall", filename="front.jpg"),
            VenueCaptureMediaRef(id="e2", session_id="s1", category="seating", filename="seats_front_only.jpg"),
        ]
        inp = VenueReconstructionInput(
            job_id="j1",
            session_id="s1",
            evidence=evidence,
            logical_constraints=LogicalVenueConstraints(rows=12, seats_per_row=16),
            known_measurements={"roomWidth": 18.0},
        )
        res = self.worker.analyze(inp)
        self.assertEqual(res.state, ReconstructionUncertaintyState.CONFLICT)
        self.assertTrue(len(res.conflicts) > 0)
        self.assertIn("11", res.conflicts[0].detected_value)
        self.assertIn("12", res.conflicts[0].admin_constraint)

    def test_speakers_require_evidence(self):
        # Case A: with speaker evidence
        evidence_with_sp = [
            VenueCaptureMediaRef(id="sp1", session_id="s1", category="speakers", filename="speaker.jpg"),
        ]
        inp_sp = VenueReconstructionInput(job_id="j1", session_id="s1", evidence=evidence_with_sp)
        res_sp = self.worker.analyze(inp_sp)
        self.assertTrue(len(res_sp.speakers) > 0)

        # Case B: without speaker evidence
        evidence_no_sp = [
            VenueCaptureMediaRef(id="f1", session_id="s1", category="frontWall", filename="front.jpg"),
        ]
        inp_no_sp = VenueReconstructionInput(job_id="j1", session_id="s1", evidence=evidence_no_sp)
        res_no_sp = self.worker.analyze(inp_no_sp)
        self.assertEqual(len(res_no_sp.speakers), 0)

if __name__ == "__main__":
    unittest.main()
