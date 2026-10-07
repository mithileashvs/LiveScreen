import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/theatre_admin.dart';
import '../models/theatre_admin_theatre.dart';
import '../models/theatre_configuration.dart';
import 'theatre_repository.dart';

/// Everything about a Theatre Admin's *identity* and *which theatres they
/// may manage* — deliberately separate from [TheatreRepository], which
/// only ever deals with a single [TheatreConfiguration] by id and has no
/// concept of "whose" it is beyond `ownerId`.
///
/// Same pattern as [TheatreRepository]/`authService` elsewhere in this
/// app: an abstract contract, one real (Supabase) implementation, one
/// shared singleton instance every screen reads.
abstract class TheatreAdminRepository {
  /// This account's admin identity, or null if they haven't registered one
  /// yet (e.g. a `theatre_admin` profile created before this feature
  /// existed, and not covered by the 0004 migration's backfill because it
  /// owns no theatres yet).
  Future<TheatreAdmin?> getMyAdminProfile();

  /// Creates the admin identity for the current signed-in user. Throws if
  /// one already exists for this account (the database's unique
  /// constraint on profile_id is the real guarantee; this is a friendlier
  /// error on top of it).
  Future<TheatreAdmin> registerAdmin({
    required String organizationName,
    required String businessAddress,
    required String city,
    required String country,
    required String phone,
  });

  /// Every theatre this admin has ANY relationship with (pending, verified,
  /// or rejected) — "My Theatres" needs this, not just the verified ones,
  /// so a newly-added theatre can show as "Pending verification" instead
  /// of silently not appearing.
  Future<List<MyTheatreItem>> getMyTheatreRelationships();

  /// "Add Theatre": creates the theatre itself (via [TheatreRepository],
  /// same as CreateTheatreScreen already does — this does not duplicate
  /// that) and submits a PENDING ownership relationship for the current
  /// admin. The theatre is NOT fully manageable until Platform Admin
  /// approves that relationship (task section 3/5) — [saveTheatre] on it
  /// will still be rejected by RLS until then, same as any other
  /// unauthorized theatre_id.
  Future<TheatreConfiguration> addTheatre(TheatreBasicInfo basicInfo);
}

class SupabaseTheatreAdminRepository implements TheatreAdminRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot perform this operation.');
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

  @override
  Future<TheatreAdmin?> getMyAdminProfile() async {
    final userId = _requireUserId();
    final row = await _client.from('theatre_admins').select().eq('profile_id', userId).maybeSingle();
    if (row == null) return null;
    return TheatreAdmin.fromRow(row);
  }

  @override
  Future<TheatreAdmin> registerAdmin({
    required String organizationName,
    required String businessAddress,
    required String city,
    required String country,
    required String phone,
  }) async {
    final userId = _requireUserId();

    final existing = await getMyAdminProfile();
    if (existing != null) {
      throw StateError('An admin identity already exists for this account (${existing.adminCode}).');
    }

    // admin_code is intentionally omitted — generated server-side by the
    // theatre_admins_generate_code trigger (0004 migration). Passing one
    // here would do nothing (the trigger only fills it in when null/empty)
    // and there is no client-facing way to override it regardless.
    final inserted = await _client
        .from('theatre_admins')
        .insert({
          'profile_id': userId,
          'organization_name': organizationName,
          'business_address': businessAddress,
          'city': city,
          'country': country,
          'phone': phone,
        })
        .select()
        .single();

    return TheatreAdmin.fromRow(inserted);
  }

  @override
  Future<List<MyTheatreItem>> getMyTheatreRelationships() async {
    final admin = await getMyAdminProfile();
    if (admin == null) return const [];

    final rows = await _client
        .from('theatre_admin_theatres')
        .select('*, theatres(*)')
        .eq('admin_id', admin.id)
        .order('created_at');

    final items = <MyTheatreItem>[];
    for (final row in rows) {
      final theatreRow = row['theatres'] as Map<String, dynamic>?;
      if (theatreRow == null) continue; // theatre was deleted; relationship is orphaned
      items.add(MyTheatreItem(
        theatre: _theatreFromRow(theatreRow),
        relationship: TheatreAdminRelationship.fromRow(row),
      ));
    }
    return items;
  }

  @override
  Future<TheatreConfiguration> addTheatre(TheatreBasicInfo basicInfo) async {
    final admin = await getMyAdminProfile();
    if (admin == null) {
      throw StateError('Register a Theatre Admin identity before adding a theatre.');
    }

    // Reuses the exact same creation path CreateTheatreScreen already
    // uses — no second "create a theatre" implementation. owner_id is
    // still set to this admin's profile (legacy column, kept for anything
    // that still reads it directly), and the relationship row below is
    // what actually governs ongoing access per the 0004 migration.
    final config = await theatreRepository.createTheatre(basicInfo);

    await _client.from('theatre_admin_theatres').insert({
      'admin_id': admin.id,
      'theatre_id': config.id,
      'relationship_role': 'owner',
      // verification_status is omitted — defaults to 'pending' at the
      // database, and the enforce_theatre_admin_theatre_transition trigger
      // rejects a non-Platform-Admin caller trying to insert anything else.
    });

    return config;
  }
}

final TheatreAdminRepository theatreAdminRepository = SupabaseTheatreAdminRepository();
