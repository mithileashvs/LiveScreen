import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin/models/theatre_configuration.dart';
import '../../admin/models/theatre_admin_theatre.dart';
import '../../admin/models/movie_content.dart';
import '../models/platform_admin_models.dart';

/// Everything the Platform Admin Dashboard's four sections (Overview,
/// Theatre Verification, Producer Verification, Movie Approval — Activity
/// reads straight from `verification_audit_log`) need. Mirrors the same
/// one-repository-per-role pattern as [TheatreRepository]/[MovieRepository]:
/// every Platform Admin screen talks to this, never straight to
/// `Supabase.instance.client`.
///
/// Every read here relies on the `*_select_platform_admin` RLS policies
/// added in 0002_platform_admin_verification.sql (Platform Admin sees every
/// row, not just rows it owns). Every write here relies on the
/// `*_update_platform_admin` policies plus the `enforce_*_transition`
/// triggers — a non-Platform-Admin session calling these same methods would
/// be rejected by the database, not just hidden by this UI.
class PlatformAdminRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot perform this Platform Admin operation.');
    }
    return id;
  }

  TheatreConfiguration _theatreFromRow(Map<String, dynamic> row) {
    final configJson = Map<String, dynamic>.from(row['config'] as Map? ?? {});
    configJson['id'] = row['id'];
    final config = TheatreConfiguration.fromJson(configJson);
    config.verificationStatus = row['verification_status'] as String? ?? 'pending';
    config.reviewReason = row['review_reason'] as String?;
    config.ownerId = row['owner_id'] as String?;
    return config;
  }

  Future<Map<String, ProducerProfile>> _fetchProfilesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _client.from('profiles').select().inFilter('id', ids);
    return {
      for (final row in rows) row['id'] as String: ProducerProfile.fromRow(row),
    };
  }

  // ---------------------------------------------------------------------
  // Overview
  // ---------------------------------------------------------------------

  Future<int> _count(String table, Map<String, dynamic> eqFilters) async {
    PostgrestFilterBuilder<PostgrestList> query = _client.from(table).select('id');
    for (final entry in eqFilters.entries) {
      query = query.eq(entry.key, entry.value);
    }
    final rows = await query;
    return rows.length;
  }

  Future<PlatformOverviewCounts> getOverviewCounts() async {
    final results = await Future.wait([
      _count('theatres', {'verification_status': 'pending'}),
      _count('theatres', {'verification_status': 'under_review'}),
      _count('profiles', {'role': 'producer', 'verification_status': 'pending'}),
      _count('profiles', {'role': 'producer', 'verification_status': 'under_review'}),
      _count('movies', {'approval_status': 'submitted'}),
      _count('movies', {'approval_status': 'under_review'}),
      _count('theatres', {'verification_status': 'verified'}),
      _count('profiles', {'role': 'producer', 'verification_status': 'verified'}),
      _count('theatres', {'status': 'published'}),
      _count('movies', {'status': 'published'}),
    ]);

    return PlatformOverviewCounts(
      pendingTheatreVerifications: results[0] + results[1],
      pendingProducerVerifications: results[2] + results[3],
      pendingMovieApprovals: results[4] + results[5],
      verifiedTheatres: results[6],
      verifiedProducers: results[7],
      publishedContent: results[8] + results[9],
    );
  }

  Future<PlatformDashboardMetrics> getDashboardMetrics() async {
    int totalTheatres = 0;
    int totalProducers = 0;
    int totalMovies = 0;
    int totalUsers = 0;

    int pendingTheatres = 0;
    int pendingProducers = 0;
    int pendingMovies = 0;

    int totalBookings = 0;
    int activeShows = 0;
    int publishedTheatres = 0;
    int liveMovies = 0;

    try {
      final results = await Future.wait([
        _count('theatres', {}),
        _count('profiles', {'role': 'producer'}),
        _count('movies', {}),
        _count('profiles', {}),
        _count('theatres', {'verification_status': 'pending'}),
        _count('theatres', {'verification_status': 'under_review'}),
        _count('profiles', {'role': 'producer', 'verification_status': 'pending'}),
        _count('profiles', {'role': 'producer', 'verification_status': 'under_review'}),
        _count('movies', {'approval_status': 'submitted'}),
        _count('movies', {'approval_status': 'under_review'}),
        _count('theatres', {'status': 'published'}),
        _count('movies', {'status': 'published'}),
      ]);
      totalTheatres = results[0];
      totalProducers = results[1];
      totalMovies = results[2];
      totalUsers = results[3];
      pendingTheatres = results[4] + results[5];
      pendingProducers = results[6] + results[7];
      pendingMovies = results[8] + results[9];
      publishedTheatres = results[10];
      liveMovies = results[11];
    } catch (_) {}

    try {
      totalBookings = await _count('bookings', {});
    } catch (_) {}

    try {
      activeShows = await _count('shows', {'status': 'published'});
    } catch (_) {}

    return PlatformDashboardMetrics(
      totalTheatres: totalTheatres,
      totalProducers: totalProducers,
      totalMovies: totalMovies,
      totalUsers: totalUsers,
      pendingTheatres: pendingTheatres,
      pendingProducers: pendingProducers,
      pendingMovies: pendingMovies,
      totalBookings: totalBookings,
      activeShows: activeShows,
      publishedTheatres: publishedTheatres,
      liveMovies: liveMovies,
    );
  }

  Future<List<PlatformRecentSubmission>> getRecentSubmissions({int limit = 5}) async {
    final list = <PlatformRecentSubmission>[];

    try {
      final movieRows = await _client
          .from('movies')
          .select('id, title, approval_status, created_at')
          .order('created_at', ascending: false)
          .limit(limit);
      for (final r in movieRows) {
        list.add(PlatformRecentSubmission(
          id: r['id'] as String,
          type: 'movie',
          title: r['title'] as String? ?? 'Untitled Movie',
          submittedAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          status: r['approval_status'] as String? ?? 'submitted',
        ));
      }
    } catch (_) {}

    try {
      final theatreRows = await _client
          .from('theatres')
          .select('id, config, verification_status, created_at')
          .order('created_at', ascending: false)
          .limit(limit);
      for (final r in theatreRows) {
        final config = r['config'] as Map? ?? {};
        final name = (config['name'] as String?)?.trim() ?? 'Untitled Theatre';
        list.add(PlatformRecentSubmission(
          id: r['id'] as String,
          type: 'theatre',
          title: name.isNotEmpty ? name : 'Untitled Theatre',
          submittedAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          status: r['verification_status'] as String? ?? 'pending',
        ));
      }
    } catch (_) {}

    try {
      final producerRows = await _client
          .from('profiles')
          .select('id, display_name, email, verification_status, created_at')
          .eq('role', 'producer')
          .order('created_at', ascending: false)
          .limit(limit);
      for (final r in producerRows) {
        final name = (r['display_name'] as String?)?.trim();
        final email = r['email'] as String? ?? 'Producer';
        list.add(PlatformRecentSubmission(
          id: r['id'] as String,
          type: 'producer',
          title: (name != null && name.isNotEmpty) ? name : email,
          submittedAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          status: r['verification_status'] as String? ?? 'pending',
        ));
      }
    } catch (_) {}

    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  // ---------------------------------------------------------------------
  // Theatre verification
  // ---------------------------------------------------------------------

  /// [statusFilter] is one of [kVerificationStatuses], or null/'all' for
  /// every theatre regardless of verification status.
  Future<List<TheatreVerificationItem>> listTheatresForVerification({String? statusFilter}) async {
    PostgrestFilterBuilder<PostgrestList> query = _client.from('theatres').select();
    if (statusFilter != null && statusFilter != 'all') {
      query = query.eq('verification_status', statusFilter);
    }
    final rows = await query.order('created_at', ascending: false);
    final theatres = rows.map((r) => _theatreFromRow(r)).toList();

    final ownerIds = theatres.map((t) => t.ownerId).whereType<String>().toSet().toList();
    final owners = await _fetchProfilesByIds(ownerIds);

    return theatres
        .map((t) => TheatreVerificationItem(
              theatre: t,
              ownerName: owners[t.ownerId]?.displayName ?? 'Unknown owner',
              ownerEmail: owners[t.ownerId]?.email ?? '',
            ))
        .toList();
  }

  /// [newStatus] is one of [kVerificationStatuses]. [reason] is required by
  /// the calling UI for 'rejected'/'suspended'/'request changes', optional
  /// otherwise.
  Future<void> reviewTheatre({
    required String theatreId,
    required String newStatus,
    String? reason,
  }) async {
    final actorId = _requireUserId();
    final updated = await _client
        .from('theatres')
        .update({
          'verification_status': newStatus,
          'review_reason': reason,
          'reviewed_by': actorId,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', theatreId)
        .select();

    if (updated.isEmpty) {
      throw StateError(
        'Could not update theatre $theatreId — the current session may not be '
        'recognized as Platform Admin.',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Theatre OWNERSHIP verification — task section 5: reviewing who may
  // manage which theatre (theatre_admin_theatres), distinct from the venue
  // verification above (theatres.verification_status). Relies on the
  // `theatre_admin_theatres_select_platform_admin` /
  // `theatre_admin_theatres_update_platform_admin` RLS policies and the
  // `enforce_theatre_admin_theatre_transition` trigger added in
  // 0006_theatre_admin_identity.sql — a non-Platform-Admin session calling
  // reviewTheatreOwnership would be rejected by the trigger itself (it only
  // allows verification_status/verified_by/verified_at writes when
  // current_user_role() = 'platform_admin'), not just hidden by this UI.
  // ---------------------------------------------------------------------

  /// [statusFilter] is one of the `theatre_admin_theatres.verification_status`
  /// values from 0006 (pending | under_review | verified | rejected), or
  /// null/'all' for every submission regardless of status.
  Future<List<TheatreOwnershipReviewItem>> listTheatreOwnershipSubmissions({String? statusFilter}) async {
    // theatre_admins has TWO foreign keys into profiles — profile_id (the
    // operator this identity belongs to) and reviewed_by (which Platform
    // Admin, if any, reviewed the identity itself) — both added in 0006.
    // An unqualified `profiles(*)` embed is therefore ambiguous and
    // PostgREST rejects it outright; `profiles!profile_id(*)` pins the
    // embed to the operator's own profile, which is what this screen
    // (applicant name/email) actually wants.
    PostgrestFilterBuilder<PostgrestList> query = _client
        .from('theatre_admin_theatres')
        .select('*, theatres(*), theatre_admins(*, profiles!profile_id(*))');
    if (statusFilter != null && statusFilter != 'all') {
      query = query.eq('verification_status', statusFilter);
    }
    final rows = await query.order('submitted_at', ascending: false);

    final items = <TheatreOwnershipReviewItem>[];
    for (final row in rows) {
      final theatreRow = row['theatres'] as Map<String, dynamic>?;
      final adminRow = row['theatre_admins'] as Map<String, dynamic>?;
      if (theatreRow == null || adminRow == null) {
        continue; // theatre or admin identity was deleted; relationship is orphaned
      }
      final profileRow = adminRow['profiles'] as Map<String, dynamic>?;
      items.add(TheatreOwnershipReviewItem(
        relationship: TheatreAdminRelationship.fromRow(row),
        theatre: _theatreFromRow(theatreRow),
        adminCode: adminRow['admin_code'] as String? ?? '',
        organizationName: adminRow['organization_name'] as String? ?? '',
        applicantName: profileRow?['display_name'] as String? ?? '',
        applicantEmail: profileRow?['email'] as String? ?? '',
      ));
    }
    return items;
  }

  /// [newStatus] is one of the `theatre_admin_theatres.verification_status`
  /// values from 0006 (pending | under_review | verified | rejected).
  /// theatre_admin_theatres has no review_reason column (unlike
  /// theatres/movies/profiles), so — matching the screen, which never
  /// collects one for this call — none is written here. verified_by/
  /// verified_at are only set when the submission is actually being
  /// verified, matching what those column names mean (and what the
  /// detail screen displays as "Verified") — a reject/under-review action
  /// leaves them as they were rather than stamping a false "verified at"
  /// time on a submission that was not approved.
  Future<void> reviewTheatreOwnership({
    required String relationshipId,
    required String newStatus,
  }) async {
    final actorId = _requireUserId();
    final payload = <String, dynamic>{'verification_status': newStatus};
    if (newStatus == 'verified') {
      payload['verified_by'] = actorId;
      payload['verified_at'] = DateTime.now().toUtc().toIso8601String();
    }
    final updated = await _client
        .from('theatre_admin_theatres')
        .update(payload)
        .eq('id', relationshipId)
        .select();

    if (updated.isEmpty) {
      throw StateError(
        'Could not update ownership submission $relationshipId — the current session may not be '
        'recognized as Platform Admin.',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Producer verification
  // ---------------------------------------------------------------------

  Future<List<ProducerProfile>> listProducersForVerification({String? statusFilter}) async {
    PostgrestFilterBuilder<PostgrestList> query =
        _client.from('profiles').select().eq('role', 'producer');
    if (statusFilter != null && statusFilter != 'all') {
      query = query.eq('verification_status', statusFilter);
    }
    final rows = await query.order('created_at', ascending: false);
    return rows.map((r) => ProducerProfile.fromRow(r)).toList();
  }

  Future<void> reviewProducer({
    required String producerId,
    required String newStatus,
    String? reason,
  }) async {
    final actorId = _requireUserId();
    final updated = await _client
        .from('profiles')
        .update({
          'verification_status': newStatus,
          'verification_reason': reason,
          'reviewed_by': actorId,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', producerId)
        .select();

    if (updated.isEmpty) {
      throw StateError(
        'Could not update producer $producerId — the current session may not be '
        'recognized as Platform Admin.',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Movie / content approval
  // ---------------------------------------------------------------------

  Future<List<MovieApprovalItem>> listMoviesForApproval({String? statusFilter}) async {
    PostgrestFilterBuilder<PostgrestList> query = _client.from('movies').select();
    if (statusFilter != null && statusFilter != 'all') {
      query = query.eq('approval_status', statusFilter);
    }
    final rows = await query.order('created_at', ascending: false);

    final movies = rows.map((row) {
      return MovieContent(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        description: row['description'] as String? ?? '',
        trailerUrl: (row['trailer_url'] ?? row['trailer_path']) as String? ?? '',
        immersiveTrailerUrl: row['immersive_trailer_url'] as String? ?? '',
        thumbnail: row['thumbnail'] as String? ?? '',
        durationSeconds: row['duration_seconds'] as int? ?? 0,
        producerId: row['producer_id'] as String?,
        status: row['status'] as String? ?? 'draft',
        approvalStatus: row['approval_status'] as String? ?? 'draft',
        reviewReason: row['review_reason'] as String?,
      );
    }).toList();

    final producerIds = movies.map((m) => m.producerId).whereType<String>().toSet().toList();
    final producers = await _fetchProfilesByIds(producerIds);

    return movies
        .map((m) => MovieApprovalItem(
              movie: m,
              producerName: producers[m.producerId]?.displayName ?? 'Unknown producer',
              producerEmail: producers[m.producerId]?.email ?? '',
            ))
        .toList();
  }

  /// [newStatus] is one of [kMovieApprovalStatuses] (excluding 'draft',
  /// which only the producer sets by withdrawing).
  Future<void> reviewMovie({
    required String movieId,
    required String newStatus,
    String? reason,
  }) async {
    final actorId = _requireUserId();
    final updated = await _client
        .from('movies')
        .update({
          'approval_status': newStatus,
          'review_reason': reason,
          'reviewed_by': actorId,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', movieId)
        .select();

    if (updated.isEmpty) {
      throw StateError(
        'Could not update movie $movieId — the current session may not be '
        'recognized as Platform Admin.',
      );
    }
  }

  /// Platform Admin action to publish an approved movie so it enters
  /// the public catalog (`status = 'published'`).
  Future<void> publishMovie(String movieId) async {
    _requireUserId();
    final updated = await _client
        .from('movies')
        .update({
          'status': 'published',
        })
        .eq('id', movieId)
        .eq('approval_status', 'approved')
        .select();

    if (updated.isEmpty) {
      throw StateError(
        'Could not publish movie $movieId — the movie must be approved first, '
        'or the current session is not recognized as Platform Admin.',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Activity / audit log
  // ---------------------------------------------------------------------

  Future<List<AuditLogEntry>> getRecentActivity({int limit = 100}) async {
    final rows = await _client
        .from('verification_audit_log')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map((row) => AuditLogEntry.fromRow(row)).toList();
  }
}

final PlatformAdminRepository platformAdminRepository = PlatformAdminRepository();
