import '../models/theatre_configuration.dart';

/// PART 12: everything checked before a [TheatreConfiguration] is allowed
/// to move from Draft to Published. Saving a Draft never runs this — an
/// incomplete theatre is a perfectly normal thing to save mid-edit.
class TheatreValidation {
  /// Returns an empty list when the configuration is publishable, otherwise
  /// one human-readable message per problem found.
  static List<String> validateForPublish(TheatreConfiguration config) {
    final errors = <String>[];

    if (config.basicInfo.name.trim().isEmpty) {
      errors.add('Theatre name is required.');
    }

    errors.addAll(config.room.validate());
    errors.addAll(config.screen.validate());

    if (config.seats.isEmpty) {
      errors.add('At least one seat must be configured.');
    } else {
      final seenIds = <String>{};
      final duplicates = <String>{};
      for (final seat in config.seats) {
        if (!seenIds.add(seat.id)) {
          duplicates.add(seat.id);
        }
      }
      if (duplicates.isNotEmpty) {
        errors.add('Duplicate seat IDs found: ${duplicates.join(', ')}.');
      }
    }

    for (final speaker in config.speakers) {
      if (speaker.name.trim().isEmpty) {
        errors.add('Speaker "${speaker.id}" needs a name.');
      }
    }

    // Room/acoustic information always has sensible defaults (see
    // AcousticsConfig's constructor), so there's nothing further to
    // require here beyond the room dimensions already checked above.

    return errors;
  }
}
