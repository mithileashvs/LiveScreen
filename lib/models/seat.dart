/// Represents a single seat in the auditorium/venue.
enum SeatType { available, selected, booked, premium, recliner }

class SeatModel {
  final String row; // e.g. "A", "B", "G"
  final int number; // seat number within the row
  final double price;
  SeatType type;

  SeatModel({
    required this.row,
    required this.number,
    required this.price,
    required this.type,
  });

  String get label => '$row$number';
}
