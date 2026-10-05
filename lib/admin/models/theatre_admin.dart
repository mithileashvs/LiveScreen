/// A Theatre Admin's operator/business identity — deliberately separate
/// from `profiles` (which only carries auth-level id/email/role). One
/// `profiles` row with role 'theatre_admin' can log in; this is the
/// business behind that login: organization name, business address,
/// phone, and its own account-level verification status distinct from
/// any one theatre's.
///
/// [adminCode] (e.g. "TA-0001") is generated server-side — see the
/// `theatre_admins_generate_code` trigger in
/// supabase/migrations/0004_theatre_admin_identity.sql. It is internal:
/// never shown on the public/user-facing theatre discovery or booking UI
/// (section 9 of the task).
class TheatreAdmin {
  final String id;
  final String profileId;
  final String adminCode;
  String organizationName;
  String businessAddress;
  String city;
  String country;
  String phone;

  /// pending | under_review | verified | rejected | suspended — this
  /// account's own standing, not any particular theatre's. Only Platform
  /// Admin may change this (enforced by
  /// enforce_theatre_admin_transition in the same migration).
  String verificationStatus;
  String? verificationReason;
  final DateTime createdAt;

  TheatreAdmin({
    required this.id,
    required this.profileId,
    required this.adminCode,
    required this.organizationName,
    required this.businessAddress,
    required this.city,
    required this.country,
    required this.phone,
    required this.verificationStatus,
    required this.createdAt,
    this.verificationReason,
  });

  factory TheatreAdmin.fromRow(Map<String, dynamic> row) {
    return TheatreAdmin(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      adminCode: row['admin_code'] as String,
      organizationName: row['organization_name'] as String? ?? '',
      businessAddress: row['business_address'] as String? ?? '',
      city: row['city'] as String? ?? '',
      country: row['country'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      verificationStatus: row['verification_status'] as String? ?? 'pending',
      verificationReason: row['verification_reason'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
