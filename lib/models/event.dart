/// Represents a single bookable event (movie, concert, sport, etc.)
class EventModel {
  final String id;
  final String title;
  final String category; // Movies, Concerts, Sports, Theatre, Comedy, Events
  final String posterEmoji; // placeholder "poster" until real images are added
  final String genre;
  final String duration;
  final String language;
  final String description;
  final List<String> venueIds;

  /// Out of 10. Optional/defaulted so this stays backward compatible with
  /// every existing EventModel(...) call site.
  final double rating;

  const EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.posterEmoji,
    required this.genre,
    required this.duration,
    required this.language,
    required this.description,
    required this.venueIds,
    this.rating = 8.0,
  });
}
