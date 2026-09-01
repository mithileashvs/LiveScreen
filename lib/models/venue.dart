/// Represents a venue (cinema, arena, stadium) that hosts events.
class VenueModel {
  final String id;
  final String name;
  final String location;
  final List<String> screens; // e.g. "Screen 1", "Main Stage"

  const VenueModel({
    required this.id,
    required this.name,
    required this.location,
    required this.screens,
  });
}
