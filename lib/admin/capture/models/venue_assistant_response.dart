import 'venue_assistant_message.dart';
import 'venue_assistant_action.dart';
import 'reconstruction_draft.dart';

/// The structured response returned by the [VenueAssistant] engine.
class VenueAssistantResponse {
  final VenueAssistantMessage message;
  final VenueAssistantAction? appliedAction;
  final ReconstructionDraft? updatedDraft;
  final bool requiresMeasurement;
  final String? targetedMeasurementPrompt;
  final String? clarificationQuestion;

  const VenueAssistantResponse({
    required this.message,
    this.appliedAction,
    this.updatedDraft,
    this.requiresMeasurement = false,
    this.targetedMeasurementPrompt,
    this.clarificationQuestion,
  });

  Map<String, dynamic> toJson() => {
        'message': message.toJson(),
        'appliedAction': appliedAction?.toJson(),
        'updatedDraft': updatedDraft?.toJson(),
        'requiresMeasurement': requiresMeasurement,
        'targetedMeasurementPrompt': targetedMeasurementPrompt,
        'clarificationQuestion': clarificationQuestion,
      };

  factory VenueAssistantResponse.fromJson(Map<String, dynamic> json) {
    return VenueAssistantResponse(
      message: VenueAssistantMessage.fromJson(
          json['message'] as Map<String, dynamic>),
      appliedAction: json['appliedAction'] != null
          ? VenueAssistantAction.fromJson(
              json['appliedAction'] as Map<String, dynamic>)
          : null,
      updatedDraft: json['updatedDraft'] != null
          ? ReconstructionDraft.fromJson(
              json['updatedDraft'] as Map<String, dynamic>)
          : null,
      requiresMeasurement: json['requiresMeasurement'] as bool? ?? false,
      targetedMeasurementPrompt:
          json['targetedMeasurementPrompt'] as String?,
      clarificationQuestion: json['clarificationQuestion'] as String?,
    );
  }
}
