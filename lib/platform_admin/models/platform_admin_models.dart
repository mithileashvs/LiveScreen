import '../../admin/models/theatre_configuration.dart';
import '../../admin/models/movie_content.dart';

/// The five states shared by theatre verification, producer verification,
/// and (structurally, though movies use their own five-state set) content
/// review — kept as plain strings throughout this module to match the
/// database's text columns 1:1, rather than introducing an enum that would
/// need a mapping layer on every read/write.
const List<String> kVerificationStatuses = [
  'pending',
  'under_review',
  'verified',
  'rejected',
  'suspended',
];

const List<String> kMovieApprovalStatuses = [
  'draft',
  'submitted',
  'under_review',
  'approved',
  'rejected',
];

/// A theatre plus the display info about who owns it — everything the
/// Theatre Verification screen's list and review sheet need in one object.
class TheatreVerificationItem {
  final TheatreConfiguration theatre;
  final String ownerName;
  final String ownerEmail;

  const TheatreVerificationItem({
    required this.theatre,
    required this.ownerName,
    required this.ownerEmail,
  });
}

/// One producer account, as Platform Admin needs to see/review it.
class ProducerProfile {
  final String id;
  final String email;
  final String displayName;
  final String verificationStatus;
  final String? verificationReason;
  final DateTime createdAt;

  const ProducerProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.verificationStatus,
    required this.createdAt,
    this.verificationReason,
  });

  factory ProducerProfile.fromRow(Map<String, dynamic> row) {
    return ProducerProfile(
      id: row['id'] as String,
      email: row['email'] as String? ?? '',
      displayName: row['display_name'] as String? ?? '',
      verificationStatus: row['verification_status'] as String? ?? 'pending',
      verificationReason: row['verification_reason'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// A movie plus the display info about which producer submitted it.
class MovieApprovalItem {
  final MovieContent movie;
  final String producerName;
  final String producerEmail;

  const MovieApprovalItem({
    required this.movie,
    required this.producerName,
    required this.producerEmail,
  });
}

/// Overview page counts — every number here comes straight from the
/// database, never hardcoded or simulated.
class PlatformOverviewCounts {
  final int pendingTheatreVerifications;
  final int pendingProducerVerifications;
  final int pendingMovieApprovals;
  final int verifiedTheatres;
  final int verifiedProducers;
  final int publishedContent;

  const PlatformOverviewCounts({
    required this.pendingTheatreVerifications,
    required this.pendingProducerVerifications,
    required this.pendingMovieApprovals,
    required this.verifiedTheatres,
    required this.verifiedProducers,
    required this.publishedContent,
  });
}

/// One row from `verification_audit_log` — every verification/approval/
/// publish transition, whoever made it.
class AuditLogEntry {
  final String entity;
  final String entityId;
  final String action;
  final String? previousStatus;
  final String? newStatus;
  final String? reviewerId;
  final String? reason;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.entity,
    required this.entityId,
    required this.action,
    required this.createdAt,
    this.previousStatus,
    this.newStatus,
    this.reviewerId,
    this.reason,
  });

  factory AuditLogEntry.fromRow(Map<String, dynamic> row) {
    return AuditLogEntry(
      entity: row['entity'] as String,
      entityId: row['entity_id'] as String,
      action: row['action'] as String,
      previousStatus: row['previous_status'] as String?,
      newStatus: row['new_status'] as String?,
      reviewerId: row['reviewer'] as String?,
      reason: row['reason'] as String?,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Unified dashboard metrics for the redesigned Platform Admin dashboard.
/// Sourced strictly from the real LiveScreen database, never fabricated.
class PlatformDashboardMetrics {
  final int totalTheatres;
  final int totalProducers;
  final int totalMovies;
  final int totalUsers;

  final int pendingTheatres;
  final int pendingProducers;
  final int pendingMovies;

  final int totalBookings;
  final int activeShows;
  final int publishedTheatres;
  final int liveMovies;

  const PlatformDashboardMetrics({
    required this.totalTheatres,
    required this.totalProducers,
    required this.totalMovies,
    required this.totalUsers,
    required this.pendingTheatres,
    required this.pendingProducers,
    required this.pendingMovies,
    required this.totalBookings,
    required this.activeShows,
    required this.publishedTheatres,
    required this.liveMovies,
  });
}

/// A recent submission item (movie, theatre, or producer) displayed on
/// the Platform Admin Dashboard.
class PlatformRecentSubmission {
  final String id;
  final String type; // 'movie', 'theatre', 'producer'
  final String title;
  final DateTime submittedAt;
  final String status;
  final dynamic originalObject;

  const PlatformRecentSubmission({
    required this.id,
    required this.type,
    required this.title,
    required this.submittedAt,
    required this.status,
    this.originalObject,
  });
}
