import '../models/models.dart';

/// Result of merging AI reconstruction worker observations into a [ReconstructionDraft].
class DraftMergeResult {
  final ReconstructionDraft updatedDraft;
  final List<VenueReconstructionConflict> conflicts;
  final List<String> warnings;
  final List<VenueCaptureRequest> newRequests;

  const DraftMergeResult({
    required this.updatedDraft,
    this.conflicts = const [],
    this.warnings = const [],
    this.newRequests = const [],
  });

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Controlled merge engine that incorporates AI worker reconstruction results
/// into an existing [ReconstructionDraft].
///
/// Principles:
/// 1. "AI assists reconstruction; it does not silently guess unknown measurements."
/// 2. Explicit admin logical constraints have strict priority over AI vision detections.
/// 3. Estimate Precedence: MEASURED > ADMIN_MEASURED > AI_ESTIMATED > INFERRED > UNKNOWN.
/// 4. Higher confidence AI estimates replace lower confidence AI estimates; unknown never overwrites known.
/// 5. Unknown metric scale keeps physical spacing UNKNOWN and physical seat array empty.
/// 6. Speakers require visual evidence; no placeholder or fabricated audio channels.
/// 7. Conflicting detections are surfaced as [VenueReconstructionConflict] and targeted requests.
/// 8. Live [TheatreConfiguration] is NEVER touched.
class DraftMergeEngine {
  const DraftMergeEngine();

  /// Merges [result] into [draft], respecting [logicalConstraints] and precedence rules.
  DraftMergeResult merge({
    required ReconstructionDraft draft,
    required VenueReconstructionResult result,
    LogicalVenueConstraints? logicalConstraints,
  }) {
    final conflicts = <VenueReconstructionConflict>[...result.conflicts];
    final warnings = <String>[...result.warnings];
    final newRequests = <VenueCaptureRequest>[...result.requests];

    // 1. Room Geometry Merge
    final mergedRoom = DraftRoomGeometry(
      width: _mergeEstimate(draft.room.width, result.room.width),
      length: _mergeEstimate(draft.room.length, result.room.length),
      height: _mergeEstimate(draft.room.height, result.room.height),
    );

    // 2. Screen Geometry Merge
    final mergedScreen = DraftScreen(
      width: _mergeEstimate(draft.screen.width, result.screen.width),
      height: _mergeEstimate(draft.screen.height, result.screen.height),
      position: _mergeEstimate(draft.screen.position, result.screen.position),
      rotationY: _mergeEstimate(draft.screen.rotationY, result.screen.rotationY),
      type: _mergeEstimate(draft.screen.type, result.screen.type),
    );

    // 3. Seating Merge with Strict Logical Constraint Protection
    final existingLattice = draft.seating;
    final workerLattice = result.seating;

    // Determine authoritative rows
    Estimate<int> mergedRows;
    final adminRows = logicalConstraints?.rows;
    if (adminRows != null) {
      mergedRows = Estimate<int>.adminMeasured(
        adminRows,
        source: 'admin_constraints',
      );
      if (workerLattice.rows.isKnown && workerLattice.rows.value != adminRows) {
        final conflict = VenueReconstructionConflict(
          id: 'conflict-rows-${result.revision}',
          feature: 'seating.rows',
          description: 'AI vision detected approximately ${workerLattice.rows.value} visible rows, '
              'but admin configuration specifies $adminRows rows.',
          adminConstraint: '$adminRows rows',
          detectedValue: '${workerLattice.rows.value} rows',
          suggestedResolution: 'Please provide a rear or side photo showing the missing row(s).',
          evidenceIds: workerLattice.rows.evidenceIds,
        );
        conflicts.add(conflict);
        newRequests.add(
          VenueCaptureRequest(
            id: 'req-conflict-rows-${result.revision}',
            sessionId: draft.sessionId,
            theatreId: draft.theatreId,
            target: 'Rear Seating Rows',
            reason: conflict.description,
            requiredEvidenceType: EvidenceType.photo,
            instruction: 'Please upload a photo from the rear-left corner looking toward the screen '
                'so rows 9–$adminRows are fully visible.',
            priority: RequestPriority.high,
            createdAt: DateTime.now(),
          ),
        );
      }
    } else if (existingLattice.rows.isKnown) {
      if (workerLattice.rows.isKnown &&
          workerLattice.rows.value != existingLattice.rows.value &&
          existingLattice.rows.provenance.precedence >= EstimateProvenance.adminMeasured.precedence) {
        mergedRows = existingLattice.rows;
        final conflict = VenueReconstructionConflict(
          id: 'conflict-rows-${result.revision}',
          feature: 'seating.rows',
          description: 'AI vision detected approximately ${workerLattice.rows.value} visible rows, '
              'but existing venue configuration specifies ${existingLattice.rows.value} rows.',
          adminConstraint: '${existingLattice.rows.value} rows',
          detectedValue: '${workerLattice.rows.value} rows',
          suggestedResolution: 'Admin row count preserved. Verify auditorium rear tiers.',
          evidenceIds: workerLattice.rows.evidenceIds,
        );
        conflicts.add(conflict);
      } else {
        mergedRows = _mergeEstimate(existingLattice.rows, workerLattice.rows);
      }
    } else {
      mergedRows = workerLattice.rows;
    }

    // Determine authoritative seatsPerRow
    Estimate<int> mergedSeatsPerRow;
    final adminSeatsPerRow = logicalConstraints?.seatsPerRow;
    if (adminSeatsPerRow != null) {
      mergedSeatsPerRow = Estimate<int>.adminMeasured(
        adminSeatsPerRow,
        source: 'admin_constraints',
      );
      if (workerLattice.seatsPerRow.isKnown &&
          workerLattice.seatsPerRow.value != adminSeatsPerRow) {
        warnings.add(
          'AI vision detected ${workerLattice.seatsPerRow.value} seats per row, '
          'but admin constraint of $adminSeatsPerRow was preserved.',
        );
      }
    } else if (existingLattice.seatsPerRow.isKnown &&
        existingLattice.seatsPerRow.provenance.precedence >= EstimateProvenance.adminMeasured.precedence &&
        workerLattice.seatsPerRow.isKnown &&
        workerLattice.seatsPerRow.value != existingLattice.seatsPerRow.value) {
      mergedSeatsPerRow = existingLattice.seatsPerRow;
      warnings.add(
        'Preserved existing seatsPerRow (${existingLattice.seatsPerRow.value}) over AI estimate (${workerLattice.seatsPerRow.value}).',
      );
    } else {
      mergedSeatsPerRow = _mergeEstimate(existingLattice.seatsPerRow, workerLattice.seatsPerRow);
    }

    // Physical seat metrics (scale-sensitive)
    final bool isScaleCalibrated = result.scaleStatus != ScaleStatus.unknown;

    Estimate<double> mergedSeatSpacing;
    Estimate<double> mergedRowSpacing;
    Estimate<double> mergedRowRise;
    Estimate<double> mergedAisleWidth;

    if (!isScaleCalibrated) {
      // Do NOT invent metric values when scale is unknown
      mergedSeatSpacing = existingLattice.seatSpacing.isKnown
          ? existingLattice.seatSpacing
          : const Estimate<double>.unknown();
      mergedRowSpacing = existingLattice.rowSpacing.isKnown
          ? existingLattice.rowSpacing
          : const Estimate<double>.unknown();
      mergedRowRise = existingLattice.rowRisePerRow.isKnown
          ? existingLattice.rowRisePerRow
          : const Estimate<double>.unknown();
      mergedAisleWidth = existingLattice.aisleWidth.isKnown
          ? existingLattice.aisleWidth
          : const Estimate<double>.unknown();
    } else {
      mergedSeatSpacing = _mergeEstimate(existingLattice.seatSpacing, workerLattice.seatSpacing);
      mergedRowSpacing = _mergeEstimate(existingLattice.rowSpacing, workerLattice.rowSpacing);
      mergedRowRise = _mergeEstimate(existingLattice.rowRisePerRow, workerLattice.rowRisePerRow);
      mergedAisleWidth = _mergeEstimate(existingLattice.aisleWidth, workerLattice.aisleWidth);
    }

    // Logical block and aisle structure
    final mergedAisleAfterSeats = logicalConstraints != null && logicalConstraints.aisleAfterSeats.isNotEmpty
        ? logicalConstraints.aisleAfterSeats
        : (existingLattice.aisleAfterSeats.isNotEmpty
            ? existingLattice.aisleAfterSeats
            : workerLattice.aisleAfterSeats);

    final mergedBlockCount = logicalConstraints?.blockCount ??
        existingLattice.blockCount ??
        workerLattice.blockCount;

    final mergedRowSeatCounts = Map<int, int>.from(existingLattice.rowSeatCounts);
    if (logicalConstraints != null && logicalConstraints.rowSeatCounts.isNotEmpty) {
      mergedRowSeatCounts.addAll(logicalConstraints.rowSeatCounts);
    } else if (mergedRowSeatCounts.isEmpty && workerLattice.rowSeatCounts.isNotEmpty) {
      mergedRowSeatCounts.addAll(workerLattice.rowSeatCounts);
    }

    final mergedRemovedSeats = Set<String>.from(existingLattice.removedSeats);
    if (logicalConstraints != null && logicalConstraints.removedSeats.isNotEmpty) {
      mergedRemovedSeats.addAll(logicalConstraints.removedSeats);
    } else if (mergedRemovedSeats.isEmpty && workerLattice.removedSeats.isNotEmpty) {
      mergedRemovedSeats.addAll(workerLattice.removedSeats);
    }

    // Physical seats list: never fabricate metre coordinates when scale is unknown
    List<DraftSeat> mergedSeats;
    if (!isScaleCalibrated) {
      // If scale is unknown, do not accept uncalibrated AI seat positions
      mergedSeats = existingLattice.seats;
    } else if (workerLattice.seats.isNotEmpty) {
      // Filter out any seats marked as removed
      mergedSeats = workerLattice.seats
          .where((s) => !mergedRemovedSeats.contains('${s.row}${s.number}'))
          .toList();
    } else {
      mergedSeats = existingLattice.seats;
    }

    final mergedLattice = DraftSeatLattice(
      rows: mergedRows,
      seatsPerRow: mergedSeatsPerRow,
      seatSpacing: mergedSeatSpacing,
      rowSpacing: mergedRowSpacing,
      rowRisePerRow: mergedRowRise,
      seats: mergedSeats,
      aisleAfterSeats: mergedAisleAfterSeats,
      blockCount: mergedBlockCount,
      rowSeatCounts: mergedRowSeatCounts,
      removedSeats: mergedRemovedSeats,
      aisleWidth: mergedAisleWidth,
    );

    // 4. Speakers Merge: strictly visual only and only with evidence IDs
    final validWorkerSpeakers = result.speakers.where((s) => s.evidenceIds.isNotEmpty).toList();
    final List<DraftVisualSpeaker> mergedSpeakers;
    if (validWorkerSpeakers.isNotEmpty) {
      mergedSpeakers = validWorkerSpeakers;
    } else if (draft.speakers.isNotEmpty) {
      mergedSpeakers = draft.speakers;
    } else {
      mergedSpeakers = const [];
    }

    // 5. Lighting Merge: no fabricated photometric values
    final mergedLighting = DraftLighting(
      ceilingLightsCount: _mergeEstimate(draft.lighting.ceilingLightsCount, result.lighting.ceilingLightsCount),
      aisleLightsCount: _mergeEstimate(draft.lighting.aisleLightsCount, result.lighting.aisleLightsCount),
      hasAisleLighting: _mergeEstimate(draft.lighting.hasAisleLighting, result.lighting.hasAisleLighting),
      // estimatedLux is kept unknown unless physically measured
      estimatedLux: draft.lighting.estimatedLux.provenance == EstimateProvenance.measured
          ? draft.lighting.estimatedLux
          : (result.lighting.estimatedLux.provenance == EstimateProvenance.measured
              ? result.lighting.estimatedLux
              : const Estimate<double>.unknown()),
    );

    // 6. Appearance Merge (global palette + independent per-wall finishes)
    final mergedAppearance = DraftAppearance(
      wallColorHex: _mergeEstimate(draft.appearance.wallColorHex, result.appearance.wallColorHex),
      carpetColorHex: _mergeEstimate(draft.appearance.carpetColorHex, result.appearance.carpetColorHex),
      wallMaterialType: _mergeEstimate(draft.appearance.wallMaterialType, result.appearance.wallMaterialType),
      frontWall: _mergeWallAppearance(draft.appearance.frontWall, result.appearance.frontWall),
      leftWall: _mergeWallAppearance(draft.appearance.leftWall, result.appearance.leftWall),
      rightWall: _mergeWallAppearance(draft.appearance.rightWall, result.appearance.rightWall),
      rearWall: _mergeWallAppearance(draft.appearance.rearWall, result.appearance.rearWall),
    );

    // 7. Overall Confidence
    final overallConfidence = result.isSuccess
        ? (result.overallConfidence > 0 ? result.overallConfidence : draft.overallConfidence)
        : draft.overallConfidence;

    // 8. Construct Updated ReconstructionDraft
    final updatedDraft = draft.copyWith(
      room: mergedRoom,
      screen: mergedScreen,
      seating: mergedLattice,
      speakers: mergedSpeakers,
      lighting: mergedLighting,
      appearance: mergedAppearance,
      overallConfidence: overallConfidence,
      isReviewed: false, // Reset review flag: admin must review new AI updates
    );

    return DraftMergeResult(
      updatedDraft: updatedDraft,
      conflicts: conflicts,
      warnings: warnings,
      newRequests: newRequests,
    );
  }

  /// Merges two estimates based on LiveScreen precedence rules:
  /// MEASURED > ADMIN_MEASURED > AI_ESTIMATED > INFERRED > UNKNOWN.
  /// If both are AI_ESTIMATED, the one with higher confidence wins.
  Estimate<T> _mergeEstimate<T>(Estimate<T> current, Estimate<T> candidate) {
    if (candidate.isUnknown) return current;
    if (current.isUnknown) return candidate;

    if (candidate.takesPrecedenceOver(current)) {
      return candidate;
    }
    return current;
  }

  /// Merges individual wall appearance attributes non-destructively.
  /// If candidate properties are unknown, current attributes are retained.
  DraftWallAppearance _mergeWallAppearance(
    DraftWallAppearance current,
    DraftWallAppearance candidate,
  ) {
    return DraftWallAppearance(
      colorHex: _mergeEstimate(current.colorHex, candidate.colorHex),
      materialType: _mergeEstimate(current.materialType, candidate.materialType),
      patternTreatment: _mergeEstimate(current.patternTreatment, candidate.patternTreatment),
    );
  }
}
