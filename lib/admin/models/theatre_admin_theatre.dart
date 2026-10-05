import 'theatre_configuration.dart';

/// One row of the `theatre_admin_theatres` many-to-many relationship — the
/// actual source of truth for "which theatres may this admin manage" (see
/// [is_authorized_theatre_admin] in
/// supabase/migrations/0004_theatre_admin_identity.sql). Deliberately
/// separate from [TheatreConfiguration.verificationStatus]: that is
/// "is this venue itself verified"; [verificationStatus] here is
/// "is this admin authorized to manage this specific theatre" — the task's
/// section 5 requirement that these stay distinct concepts.
class TheatreAdminRelationship {
  final String id;
  final String adminId;
  final String theatreId;
  final String relationshipRole;

  /// pending | under_review | verified | rejected
  final String verificationStatus;
  final DateTime submittedAt;
  final DateTime? verifiedAt;

  const TheatreAdminRelationship({
    required this.id,
    required this.adminId,
    required this.theatreId,
    required this.relationshipRole,
    required this.verificationStatus,
    required this.submittedAt,
    this.verifiedAt,
  });

  factory TheatreAdminRelationship.fromRow(Map<String, dynamic> row) {
    return TheatreAdminRelationship(
      id: row['id'] as String,
      adminId: row['admin_id'] as String,
      theatreId: row['theatre_id'] as String,
      relationshipRole: row['relationship_role'] as String? ?? 'owner',
      verificationStatus: row['verification_status'] as String? ?? 'pending',
      submittedAt: DateTime.tryParse(row['submitted_at'] as String? ?? '') ?? DateTime.now(),
      verifiedAt: row['verified_at'] == null ? null : DateTime.tryParse(row['verified_at'] as String),
    );
  }
}

/// One theatre as it appears in "My Theatres" / the theatre switcher — the
/// theatre itself plus THIS admin's relationship to it, so the UI can show
/// "Pending verification" instead of a theatre just silently not being
/// selectable yet.
class MyTheatreItem {
  final TheatreConfiguration theatre;
  final TheatreAdminRelationship relationship;

  const MyTheatreItem({required this.theatre, required this.relationship});

  bool get isAuthorized => relationship.verificationStatus == 'verified';
}

/// A pending (or any-status) ownership submission plus the display info
/// Platform Admin's review screen needs, mirroring
/// [TheatreVerificationItem]'s shape in platform_admin_models.dart.
class TheatreOwnershipReviewItem {
  final TheatreAdminRelationship relationship;
  final TheatreConfiguration theatre;
  final String adminCode;
  final String organizationName;
  final String applicantName;
  final String applicantEmail;

  const TheatreOwnershipReviewItem({
    required this.relationship,
    required this.theatre,
    required this.adminCode,
    required this.organizationName,
    required this.applicantName,
    required this.applicantEmail,
  });
}
