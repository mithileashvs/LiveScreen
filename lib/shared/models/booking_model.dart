/// Minimal persistent booking record (spec: "do not build a huge payment
/// system... create the minimal persistent booking structure necessary for
/// future development"). [showId] is nullable — a seat can be booked
/// directly against a theatre's configured seating even before the admin
/// has scheduled an explicit [ShowModel]; see bookings_theatre_seat_unique
/// in the SQL migration for how duplicate booking is still prevented in
/// that case.
class BookingModel {
  final String id;
  final String userId;
  final String theatreId;
  final String? showId;
  final String seatId;
  final String status; // confirmed | cancelled
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.theatreId,
    this.showId,
    required this.seatId,
    this.status = 'confirmed',
    this.createdAt,
  });

  factory BookingModel.fromRow(Map<String, dynamic> row) {
    return BookingModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      theatreId: row['theatre_id'] as String,
      showId: row['show_id'] as String?,
      seatId: row['seat_id'] as String,
      status: row['status'] as String? ?? 'confirmed',
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'].toString()) : null,
    );
  }
}
