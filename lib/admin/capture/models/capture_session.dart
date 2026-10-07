import 'capture_state.dart';
import 'reconstruction_draft.dart';

/// Top-level capture session model coordinating an AI venue capture lifecycle.
class VenueCaptureSession {
  final String id;
  final String theatreId;
  final CaptureState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final Map<String, dynamic> metadata;
  final ReconstructionDraft? draft;

  const VenueCaptureSession({
    required this.id,
    required this.theatreId,
    this.state = CaptureState.initial,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.metadata = const {},
    this.draft,
  });

  /// True if transition to [next] is legally allowed from current state.
  bool canTransitionTo(CaptureState next) =>
      CaptureStateMachine.canTransition(state, next);

  /// Performs state machine transition, throwing if invalid.
  VenueCaptureSession transitionTo(CaptureState next, {DateTime? now}) {
    final newState = CaptureStateMachine.transition(state, next);
    final timestamp = now ?? DateTime.now();
    return copyWith(
      state: newState,
      updatedAt: timestamp,
      confirmedAt: newState == CaptureState.confirmed ? timestamp : confirmedAt,
    );
  }

  VenueCaptureSession copyWith({
    CaptureState? state,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    Map<String, dynamic>? metadata,
    ReconstructionDraft? draft,
  }) {
    return VenueCaptureSession(
      id: id,
      theatreId: theatreId,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      metadata: metadata ?? this.metadata,
      draft: draft ?? this.draft,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'theatreId': theatreId,
        'state': state.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
        'metadata': metadata,
        'draft': draft?.toJson(),
      };

  factory VenueCaptureSession.fromJson(Map<String, dynamic> json) {
    final rawState = json['state'] as String?;
    final state = CaptureState.values.firstWhere(
      (s) => s.name == rawState,
      orElse: () => CaptureState.initial,
    );

    return VenueCaptureSession(
      id: json['id'] as String,
      theatreId: (json['theatreId'] ?? json['theatre_id']) as String,
      state: state,
      createdAt: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at']) as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
              (json['updatedAt'] ?? json['updated_at']) as String? ?? '') ??
          DateTime.now(),
      confirmedAt: json['confirmedAt'] != null || json['confirmed_at'] != null
          ? DateTime.tryParse(
              (json['confirmedAt'] ?? json['confirmed_at']) as String)
          : null,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      draft: json['draft'] != null || json['reconstruction_draft'] != null
          ? ReconstructionDraft.fromJson(
              (json['draft'] ?? json['reconstruction_draft'])
                  as Map<String, dynamic>)
          : null,
    );
  }
}
