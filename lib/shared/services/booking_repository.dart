import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

/// Thrown when the requested seat is already booked (the SQL migration's
/// partial unique indexes are what actually enforce this — this class just
/// turns that database-level rejection into a message a screen can show
/// instead of a raw PostgrestException).
class SeatAlreadyBookedException implements Exception {
  final String message;
  const SeatAlreadyBookedException([this.message = 'This seat is already booked.']);
  @override
  String toString() => message;
}

abstract class BookingRepository {
  Future<BookingModel> createBooking({
    required String theatreId,
    String? showId,
    required String seatId,
  });

  Future<List<BookingModel>> getMyBookings();
}

class SupabaseBookingRepository implements BookingRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No authenticated user — cannot create a booking.');
    }
    return id;
  }

  @override
  Future<BookingModel> createBooking({
    required String theatreId,
    String? showId,
    required String seatId,
  }) async {
    final userId = _requireUserId();
    try {
      final row = await _client
          .from('bookings')
          .insert({
            'user_id': userId,
            'theatre_id': theatreId,
            'show_id': showId,
            'seat_id': seatId,
            'status': 'confirmed',
          })
          .select()
          .single();
      return BookingModel.fromRow(row);
    } on PostgrestException catch (e) {
      // Postgres unique_violation — one of the partial unique indexes in
      // the migration rejected a second booking for the same seat.
      if (e.code == '23505') {
        throw const SeatAlreadyBookedException();
      }
      rethrow;
    }
  }

  @override
  Future<List<BookingModel>> getMyBookings() async {
    final userId = _requireUserId();
    final rows = await _client
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return rows.map((r) => BookingModel.fromRow(r as Map<String, dynamic>)).toList();
  }
}

final BookingRepository bookingRepository = SupabaseBookingRepository();
