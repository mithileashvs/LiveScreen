import 'package:flutter/foundation.dart';
import '../models/theatre_configuration.dart';

/// Task section 7: "Selecting a theatre establishes the current theatre
/// context" — and that context must be the SAME one across every Admin
/// Studio screen, not each screen picking its own `.first` independently.
///
/// This is a plain in-memory ChangeNotifier singleton, the same pattern
/// already used for `authService`/`theatreRepository` elsewhere in this
/// app — deliberately not a full InheritedWidget/Provider tree, since nothing
/// else in this codebase uses one and introducing that pattern for just this
/// would be a second, inconsistent way of sharing state.
///
/// This class only holds which theatre id is selected — it does not fetch
/// or cache theatre data. Every screen still asks [TheatreRepository] (or
/// [TheatreAdminRepository]) for the real, current, RLS-filtered list and
/// data; this only remembers *which one of that list* the admin picked, so
/// a screen that opens after another already had one selected can restore
/// the same choice, and a screen that changes it can let others catch up
/// next time they read it (e.g. in `initState`, or by listening via
/// `addListener` for a screen that stays open across a switch).
class SelectedTheatreContext extends ChangeNotifier {
  String? _theatreId;

  String? get theatreId => _theatreId;

  void select(String? id) {
    if (_theatreId == id) return;
    _theatreId = id;
    notifyListeners();
  }

  /// Clears the selection — call on logout, so the next admin's session
  /// never starts pre-selecting a theatre id left over from a previous one.
  void clear() => select(null);

  /// Reconciles the current selection against `authorized` — this admin's
  /// own getMyTheatres() result — and returns the theatre every Admin
  /// Studio screen should now treat as selected, or null if this admin has
  /// no authorized theatres at all.
  ///
  /// If the previously-selected id is still present in `authorized`, it's
  /// kept as-is. Otherwise (nothing was selected yet, or the previous
  /// selection belongs to a theatre this admin is no longer/never was
  /// authorized for — e.g. a stale id left over from switching accounts
  /// without a full logout, or a relationship that was revoked) it is
  /// discarded and replaced with the first authorized theatre, or with no
  /// selection at all if `authorized` is empty. This is the one place that
  /// decision is made, so every screen that calls it agrees.
  TheatreConfiguration? resolve(List<TheatreConfiguration> authorized) {
    if (authorized.isEmpty) {
      clear();
      return null;
    }
    final stillValid = _theatreId != null && authorized.any((t) => t.id == _theatreId);
    final resolved = stillValid ? authorized.firstWhere((t) => t.id == _theatreId) : authorized.first;
    select(resolved.id);
    return resolved;
  }
}

final SelectedTheatreContext selectedTheatreContext = SelectedTheatreContext();
