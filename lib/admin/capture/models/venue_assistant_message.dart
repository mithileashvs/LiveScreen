import 'venue_assistant_action.dart';

/// The speaker role in a venue configuration conversation.
enum VenueAssistantRole {
  admin,
  assistant,
}

/// A conversation turn between the theatre admin and the AI Venue Assistant.
///
/// Messages are session-scoped and survive across popup open/close cycles
/// during an active capture/editing session.
class VenueAssistantMessage {
  final String id;
  final String sessionId;
  final VenueAssistantRole role;
  final String text;
  final DateTime createdAt;
  final VenueAssistantAction? action;
  final String? actionSummary;
  final bool requiresMeasurement;

  const VenueAssistantMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.text,
    required this.createdAt,
    this.action,
    this.actionSummary,
    this.requiresMeasurement = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'role': role.name,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'action': action?.toJson(),
        'actionSummary': actionSummary,
        'requiresMeasurement': requiresMeasurement,
      };

  factory VenueAssistantMessage.fromJson(Map<String, dynamic> json) {
    return VenueAssistantMessage(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      role: json['role'] == 'admin'
          ? VenueAssistantRole.admin
          : VenueAssistantRole.assistant,
      text: json['text'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      action: json['action'] != null
          ? VenueAssistantAction.fromJson(
              json['action'] as Map<String, dynamic>)
          : null,
      actionSummary: json['actionSummary'] as String?,
      requiresMeasurement: json['requiresMeasurement'] as bool? ?? false,
    );
  }
}
