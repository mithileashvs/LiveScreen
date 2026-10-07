/// The state machine states governing an AI Venue Capture session.
enum CaptureState {
  /// Session created, awaiting initial media or setup.
  initial,

  /// Visual evidence is being analyzed by worker.
  analyzing,

  /// Generating candidate 3D reconstruction draft.
  reconstructing,

  /// More visual evidence (specific photo viewpoint) is required.
  needsPhoto,

  /// Physical dimension measurement is required (scale calibration).
  needsMeasurement,

  /// Draft is ready for theatre admin inspection.
  readyForReview,

  /// Theatre admin is actively reviewing and auditing draft.
  reviewing,

  /// Draft confirmed by theatre admin into live configuration.
  confirmed,

  /// Pipeline encountered an unrecoverable failure.
  failed,

  /// Session was cancelled by theatre admin.
  cancelled,
}

extension CaptureStateLabel on CaptureState {
  String get label {
    switch (this) {
      case CaptureState.initial:
        return 'Initial';
      case CaptureState.analyzing:
        return 'Analyzing Evidence';
      case CaptureState.reconstructing:
        return 'Reconstructing Venue';
      case CaptureState.needsPhoto:
        return 'Additional Photos Required';
      case CaptureState.needsMeasurement:
        return 'Measurement Required';
      case CaptureState.readyForReview:
        return 'Ready for Review';
      case CaptureState.reviewing:
        return 'Reviewing Draft';
      case CaptureState.confirmed:
        return 'Confirmed';
      case CaptureState.failed:
        return 'Failed';
      case CaptureState.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == CaptureState.confirmed || this == CaptureState.cancelled;

  bool get requiresAdminAction =>
      this == CaptureState.needsPhoto ||
      this == CaptureState.needsMeasurement ||
      this == CaptureState.readyForReview ||
      this == CaptureState.reviewing;
}

/// Thrown when attempting an illegal transition in the capture state machine.
class InvalidCaptureStateTransitionException implements Exception {
  final CaptureState from;
  final CaptureState to;
  final String? message;

  const InvalidCaptureStateTransitionException({
    required this.from,
    required this.to,
    this.message,
  });

  @override
  String toString() =>
      message ??
      'Invalid capture state transition from ${from.name} to ${to.name}.';
}

/// Explicit transition rules and state machine coordinator.
class CaptureStateMachine {
  static const Map<CaptureState, Set<CaptureState>> _allowedTransitions = {
    CaptureState.initial: {
      CaptureState.analyzing,
      CaptureState.needsPhoto,
      CaptureState.cancelled,
    },
    CaptureState.analyzing: {
      CaptureState.reconstructing,
      CaptureState.needsPhoto,
      CaptureState.needsMeasurement,
      CaptureState.readyForReview,
      CaptureState.failed,
      CaptureState.cancelled,
    },
    CaptureState.reconstructing: {
      CaptureState.readyForReview,
      CaptureState.needsPhoto,
      CaptureState.needsMeasurement,
      CaptureState.failed,
      CaptureState.cancelled,
    },
    CaptureState.needsPhoto: {
      CaptureState.analyzing,
      CaptureState.needsMeasurement,
      CaptureState.failed,
      CaptureState.cancelled,
    },
    CaptureState.needsMeasurement: {
      CaptureState.analyzing,
      CaptureState.reconstructing,
      CaptureState.needsPhoto,
      CaptureState.failed,
      CaptureState.cancelled,
    },
    CaptureState.readyForReview: {
      CaptureState.reviewing,
      CaptureState.needsPhoto,
      CaptureState.needsMeasurement,
      CaptureState.confirmed,
      CaptureState.cancelled,
    },
    CaptureState.reviewing: {
      CaptureState.confirmed,
      CaptureState.readyForReview,
      CaptureState.needsPhoto,
      CaptureState.needsMeasurement,
      CaptureState.cancelled,
    },
    CaptureState.failed: {
      CaptureState.initial,
      CaptureState.analyzing,
      CaptureState.cancelled,
    },
    CaptureState.confirmed: {},
    CaptureState.cancelled: {},
  };

  /// Returns true if transitioning from [from] to [to] is permitted.
  static bool canTransition(CaptureState from, CaptureState to) {
    if (from == to) return true; // idempotent transition
    final allowed = _allowedTransitions[from];
    return allowed != null && allowed.contains(to);
  }

  /// Verifies transition validity and returns the new state, or throws
  /// [InvalidCaptureStateTransitionException] if invalid.
  static CaptureState transition(CaptureState current, CaptureState next) {
    if (!canTransition(current, next)) {
      throw InvalidCaptureStateTransitionException(
        from: current,
        to: next,
        message: 'Cannot transition from ${current.name} to ${next.name}. '
            'Allowed transitions from ${current.name} are: '
            '${_allowedTransitions[current]?.map((s) => s.name).join(', ') ?? 'none'}.',
      );
    }
    return next;
  }
}
