import '../models/models.dart';
import 'draft_merge_engine.dart';
import 'venue_analyzer.dart';

/// Adapts a [VenueReconstructionWorker] into the UI-facing [VenueAnalyzer] interface.
/// This connects the asynchronous worker architecture to the Flutter capture screens
/// while preserving the strict architectural separation of concerns.
class WorkerVenueAnalyzerAdapter implements VenueAnalyzer {
  final VenueReconstructionWorker worker;
  final DraftMergeEngine mergeEngine;

  const WorkerVenueAnalyzerAdapter({
    required this.worker,
    this.mergeEngine = const DraftMergeEngine(),
  });

  @override
  String get name => worker.name;

  @override
  bool get isAvailable => worker.isAvailable;

  @override
  Future<VenueAnalysisResult> analyze(VenueAnalysisInput input) async {
    if (!worker.isAvailable) {
      return VenueAnalysisResult.unavailable();
    }

    final currentDraft = input.previousDraft ?? input.session.draft;

    final reconstructionInput = VenueReconstructionInput(
      jobId: 'job-${input.session.id}-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: input.session.id,
      theatreId: input.session.theatreId,
      evidence: input.evidence,
      baselineDraft: currentDraft,
      logicalConstraints: LogicalVenueConstraints(
        rows: currentDraft?.seating.rows.valueOrNull,
        seatsPerRow: currentDraft?.seating.seatsPerRow.valueOrNull,
        blockCount: currentDraft?.seating.blockCount,
        aisleAfterSeats: currentDraft?.seating.aisleAfterSeats ?? const [],
        rowSeatCounts: currentDraft?.seating.rowSeatCounts ?? const {},
        removedSeats: currentDraft?.seating.removedSeats ?? const {},
        aisleWidth: currentDraft?.seating.aisleWidth.valueOrNull,
      ),
      knownMeasurements: input.baselineConfig != null
          ? {
              'roomWidth': input.baselineConfig!.room.width,
              'roomLength': input.baselineConfig!.room.length,
              'roomHeight': input.baselineConfig!.room.height,
              'screenWidth': input.baselineConfig!.screen.width,
              'screenHeight': input.baselineConfig!.screen.height,
            }
          : const {},
      revision: 1,
    );

    try {
      final workerResult = await worker.analyze(reconstructionInput);

      if (!workerResult.isSuccess) {
        return VenueAnalysisResult.failed(
          workerResult.errorMessage ?? 'Reconstruction worker failed.',
          analyzerName: worker.name,
        );
      }

      final baselineDraft = currentDraft ??
          ReconstructionDraft(
            id: 'draft-${input.session.theatreId}',
            sessionId: input.session.id,
            theatreId: input.session.theatreId,
            createdAt: DateTime.now(),
          );

      final mergeResult = mergeEngine.merge(
        draft: baselineDraft,
        result: workerResult,
        logicalConstraints: reconstructionInput.logicalConstraints,
      );

      final legacyObservations = workerResult.observations.map((o) => VenueCaptureObservation(
        id: o.id,
        sessionId: input.session.id,
        theatreId: input.session.theatreId,
        featureType: o.type.name,
        confidence: o.confidence,
        evidenceIds: o.evidenceIds,
        data: o.value,
        observedAt: DateTime.now(),
      )).toList();

      final unresolvedFields = <String>[];
      final unresolvedReasons = <String, String>{};

      if (mergeResult.updatedDraft.room.width.isUnknown) {
        unresolvedFields.add('Room Dimensions');
        unresolvedReasons['Room Dimensions'] = 'Metric scale or boundary walls uncalibrated.';
      }
      if (mergeResult.updatedDraft.screen.width.isUnknown) {
        unresolvedFields.add('Screen Dimensions');
        unresolvedReasons['Screen Dimensions'] = 'Screen boundary or scale uncalibrated.';
      }
      if (mergeResult.updatedDraft.seating.seatSpacing.isUnknown) {
        unresolvedFields.add('Physical Seat Spacing');
        unresolvedReasons['Physical Seat Spacing'] = 'Seat-to-seat metric distance unmeasured.';
      }

      return VenueAnalysisResult(
        isSuccess: true,
        draft: mergeResult.updatedDraft,
        targetedRequests: mergeResult.newRequests,
        observations: legacyObservations,
        unresolvedFields: unresolvedFields,
        unresolvedReasons: unresolvedReasons,
        analyzerName: worker.name,
        overallConfidence: workerResult.overallConfidence,
        isWorkerAvailable: true,
      );
    } catch (e) {
      return VenueAnalysisResult.failed(e.toString(), analyzerName: worker.name);
    }
  }
}
