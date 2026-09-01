import '../models/event.dart';
import '../models/venue.dart';
import '../models/seat.dart';

/// Central place for all mock/demo data used in Phase 1.
/// Later, this will be replaced by real API calls — the rest
/// of the app should not need to change when that happens.
class DemoData {
  static const List<String> categories = [
    'Movies',
    'Concerts',
    'Sports',
    'Theatre',
    'Comedy',
    'Events',
  ];

  static const List<VenueModel> venues = [
    VenueModel(
      id: 'venue_1',
      name: 'LiveScreen Cinemas',
      location: 'Thanjavur',
      screens: ['Screen 1', 'Screen 2', 'Screen 3'],
    ),
    VenueModel(
      id: 'venue_2',
      name: 'LiveScreen Arena',
      location: 'Thanjavur',
      screens: ['Main Stage'],
    ),
    VenueModel(
      id: 'venue_3',
      name: 'LiveScreen Stadium',
      location: 'Thanjavur',
      screens: ['Ground A'],
    ),
  ];

  static const List<EventModel> events = [
    EventModel(
      id: 'event_1',
      title: 'Demo Movie',
      category: 'Movies',
      posterEmoji: '🎬',
      genre: 'Action',
      duration: '2h 20m',
      language: 'English',
      description:
          'A high-octane action thriller that keeps you at the edge of your seat from start to finish.',
      venueIds: ['venue_1'],
    ),
    EventModel(
      id: 'event_2',
      title: 'Demo Live Concert',
      category: 'Concerts',
      posterEmoji: '🎤',
      genre: 'Live Music',
      duration: '3h 00m',
      language: 'Multiple',
      description:
          'An electrifying live concert experience featuring your favorite artists on one stage.',
      venueIds: ['venue_2'],
    ),
    EventModel(
      id: 'event_3',
      title: 'Demo Championship',
      category: 'Sports',
      posterEmoji: '🏏',
      genre: 'Cricket',
      duration: '3h 30m',
      language: 'N/A',
      description:
          'Witness the championship showdown live, with every seat offering a unique view of the action.',
      venueIds: ['venue_3'],
    ),
    EventModel(
      id: 'event_4',
      title: 'Demo Theatre Show',
      category: 'Theatre',
      posterEmoji: '🎭',
      genre: 'Drama',
      duration: '2h 00m',
      language: 'English',
      description:
          'A gripping theatrical performance brought to life by a talented cast on an intimate stage.',
      venueIds: ['venue_1'],
    ),
  ];

  static List<String> showTimesFor(String eventId) {
    return ['10:00 AM', '1:30 PM', '5:00 PM', '8:30 PM'];
  }

  /// IMPORTANT: These numbers are deliberately kept IN SYNC with Unity's
  /// default VenueParameters (rows=15, seatsPerRow=20, aisleCount=1). If
  /// any of these change on either side, the other must match too —
  /// otherwise a seat ID picked here (like "G12") will point to a
  /// completely different physical seat in the 3D venue, and the visual
  /// layout (where the aisle gap sits) will no longer match either. Once
  /// a real backend exists, both sides will read from the same source
  /// instead of needing to be manually kept in sync like this.
  static const int seatsPerRow = 20;
  static const int aisleCount = 1;

  /// Returns the 1-based seat numbers *after which* a visual aisle gap
  /// should be drawn in a row.
  ///
  /// This mirrors Unity's SeatGenerator.CalculateAislePositions exactly:
  /// seatsPerRow is split into (aisleCount + 1) equal blocks, with a gap
  /// after each block boundary. For the current defaults (20 seats, 1
  /// aisle) that's a single gap after seat 10 — seats 1-10, gap, 11-20 —
  /// which is why the Unity screenshot shows two blocks of 10.
  static List<int> aisleGapsAfterSeatNumber() {
    if (aisleCount <= 0) return [];
    final int blockSize = seatsPerRow ~/ (aisleCount + 1);
    return [for (int i = 1; i <= aisleCount; i++) blockSize * i];
  }

  /// Generates the demo auditorium seat map.
  static List<SeatModel> generateSeats() {
    final List<SeatModel> seats = [];
    final rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O'];

    // A handful of seats marked as already booked, purely for demo variety.
    final bookedSeats = {'C4', 'C5', 'D7', 'E2', 'F9', 'G3', 'K12', 'L15'};

    for (final row in rows) {
      SeatType baseType;
      double price;

      // Mirrors Unity's SeatGenerator row-percentage logic: first ~15% of
      // rows are Recliner, next ~25% Premium, the rest Standard.
      final int rowIndex = rows.indexOf(row);
      final int totalRows = rows.length;

      if (rowIndex < (totalRows * 0.15).ceil()) {
        baseType = SeatType.recliner;
        price = 450;
      } else if (rowIndex < (totalRows * 0.4).ceil()) {
        baseType = SeatType.premium;
        price = 350;
      } else {
        baseType = SeatType.available;
        price = 220;
      }

      for (int i = 1; i <= seatsPerRow; i++) {
        final label = '$row$i';
        seats.add(
          SeatModel(
            row: row,
            number: i,
            price: price,
            type: bookedSeats.contains(label) ? SeatType.booked : baseType,
          ),
        );
      }
    }
    return seats;
  }
}
