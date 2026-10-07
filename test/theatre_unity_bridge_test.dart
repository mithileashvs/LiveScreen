import 'package:flutter_test/flutter_test.dart';

import 'package:livescreen/admin/models/acoustics_config.dart';
import 'package:livescreen/admin/models/room_config.dart';
import 'package:livescreen/admin/models/screen_config.dart';
import 'package:livescreen/admin/models/seat_config.dart';
import 'package:livescreen/admin/models/speaker_model.dart';
import 'package:livescreen/admin/models/theatre_configuration.dart';
import 'package:livescreen/admin/services/seat_layout_generator.dart';
import 'package:livescreen/admin/services/theatre_unity_bridge.dart';

/// The core regression this whole change exists to prevent: two differently
/// configured theatres must produce visibly different Unity payloads, and
/// neither may fall back to demo geometry.
TheatreConfiguration _theatre({
  required String id,
  required String name,
  required RoomConfig room,
  required ScreenConfig screen,
  required SeatLayoutParams layout,
  required int speakerCount,
}) {
  final speakers = <SpeakerModel>[];
  for (var i = 0; i < speakerCount; i++) {
    speakers.add(SpeakerModel(
      id: '$id-speaker-$i',
      name: 'Speaker ${i + 1}',
      position: Position3(x: i.toDouble(), y: 2.5, z: i * 1.5),
    ));
  }

  return TheatreConfiguration(
    id: id,
    basicInfo: TheatreBasicInfo(name: name),
    room: room,
    screen: screen,
    seats: SeatLayoutGenerator.generate(layout),
    speakers: speakers,
    acoustics: AcousticsConfig(),
    lastSeatLayout: layout,
  );
}

/// Theatre A: small room, modest screen, 5 rows x 6 seats, 2 speakers.
TheatreConfiguration _theatreA() => _theatre(
      id: 'theatre-a',
      name: 'Theatre A',
      room: RoomConfig(width: 20, length: 15, height: 7),
      screen: ScreenConfig(
        width: 12,
        height: 6,
        position: Position3(x: 0, y: 4, z: 1),
      ),
      layout: SeatLayoutParams(rows: 5, seatsPerRow: 6),
      speakerCount: 2,
    );

/// Theatre B: larger room, bigger and offset screen, 15 rows x 20 seats,
/// 6 speakers.
TheatreConfiguration _theatreB() => _theatre(
      id: 'theatre-b',
      name: 'Theatre B',
      room: RoomConfig(width: 30, length: 20, height: 10),
      screen: ScreenConfig(
        width: 22,
        height: 10,
        position: Position3(x: 1.5, y: 6, z: 2),
        rotationY: 8,
        type: ScreenType.imax,
      ),
      layout: SeatLayoutParams(rows: 15, seatsPerRow: 20),
      speakerCount: 6,
    );

void main() {
  group('two theatres produce different payloads', () {
    test('room, screen, seat and speaker values all differ', () {
      final a = TheatreUnityBridge.toUnityPayload(_theatreA());
      final b = TheatreUnityBridge.toUnityPayload(_theatreB());

      expect(a['theatreId'], isNot(b['theatreId']));

      expect(a['roomWidth'], 20);
      expect(b['roomWidth'], 30);
      expect(a['roomLength'], isNot(b['roomLength']));
      expect(a['roomHeight'], isNot(b['roomHeight']));

      expect(a['screenWidth'], isNot(b['screenWidth']));
      expect(a['screenHeight'], isNot(b['screenHeight']));
      expect(a['screenOffsetX'], 0);
      expect(b['screenOffsetX'], 1.5);
      expect(a['screenRotationY'], 0);
      expect(b['screenRotationY'], 8);
      expect(a['screenType'], 'standard');
      expect(b['screenType'], 'imax');

      expect((a['seats'] as List).length, 5 * 6);
      expect((b['seats'] as List).length, 15 * 20);

      expect((a['speakers'] as List).length, 2);
      expect((b['speakers'] as List).length, 6);
    });

    test('neither payload silently falls back to layout defaults', () {
      // SeatLayoutParams() defaults are 10 rows x 12 seats. The old bridge
      // substituted exactly these whenever lastSeatLayout was null, which
      // is how real theatres ended up with demo seating.
      for (final payload in [
        TheatreUnityBridge.toUnityPayload(_theatreA()),
        TheatreUnityBridge.toUnityPayload(_theatreB()),
      ]) {
        final isDefaultGrid = payload['rows'] == 10 && payload['seatsPerRow'] == 12;
        expect(isDefaultGrid, isFalse);
      }
    });

    test('both are marked as having saved configuration', () {
      expect(TheatreUnityBridge.hasSavedConfiguration(_theatreA()), isTrue);
      expect(TheatreUnityBridge.hasSavedConfiguration(_theatreB()), isTrue);
    });

    test('an untouched new theatre is not marked as configured', () {
      final fresh = TheatreConfiguration(id: 'brand-new');
      expect(TheatreUnityBridge.hasSavedConfiguration(fresh), isFalse);
    });
  });

  group('seat identity survives the bridge', () {
    test('web seat H5 maps to Unity seat H5 at the same position', () {
      final theatre = _theatreB(); // 15 rows, so H exists
      final webSeat = theatre.seats.firstWhere((s) => s.id == 'H5');

      final payload = TheatreUnityBridge.toUnityPayload(theatre);
      final seats = (payload['seats'] as List).cast<Map<String, dynamic>>();
      final unitySeat = seats.firstWhere((s) => s['id'] == 'H5');

      expect(unitySeat['row'], 'H');
      expect(unitySeat['number'], 5);
      expect(unitySeat['x'], webSeat.position.x);
      expect(unitySeat['y'], webSeat.position.y);
      expect(unitySeat['z'], webSeat.position.z);
    });

    test('every saved seat is sent, with its id and category', () {
      final theatre = _theatreA();
      final seats = (TheatreUnityBridge.toUnityPayload(theatre)['seats'] as List)
          .cast<Map<String, dynamic>>();

      expect(seats.length, theatre.seats.length);
      for (var i = 0; i < seats.length; i++) {
        expect(seats[i]['id'], theatre.seats[i].id);
        expect(seats[i]['category'], theatre.seats[i].category.name);
      }
    });

    test('a per-seat category override reaches Unity', () {
      final theatre = _theatreA();
      final target = theatre.seats.firstWhere((s) => s.id == 'C3');
      target.category = SeatCategory.recliner;

      final seats = (TheatreUnityBridge.toUnityPayload(theatre)['seats'] as List)
          .cast<Map<String, dynamic>>();
      final sent = seats.firstWhere((s) => s['id'] == 'C3');

      expect(sent['category'], 'recliner');
    });
  });

  group('speakers', () {
    test('disabled speakers are not sent to Unity', () {
      final theatre = _theatreA();
      theatre.speakers.first.enabled = false;

      final speakers = TheatreUnityBridge.toUnityPayload(theatre)['speakers'] as List;
      expect(speakers.length, 1);
    });

    test('channel and position are preserved', () {
      final theatre = _theatreA();
      theatre.speakers.first
        ..channel = SpeakerChannel.overhead
        ..position = Position3(x: -3, y: 6, z: 9);

      final speakers = (TheatreUnityBridge.toUnityPayload(theatre)['speakers'] as List)
          .cast<Map<String, dynamic>>();
      final sent = speakers.first;

      expect(sent['channel'], 'overhead');
      expect(sent['x'], -3);
      expect(sent['y'], 6);
      expect(sent['z'], 9);
    });
  });

  group('effectiveSeatLayout', () {
    test('derives the real layout when lastSeatLayout was never saved', () {
      final theatre = _theatreA();
      theatre.lastSeatLayout = null; // simulates an older/partial save

      final layout = TheatreUnityBridge.effectiveSeatLayout(theatre);

      // Must describe THIS theatre (5 x 6), not SeatLayoutParams' 10 x 12.
      expect(layout.rows, 5);
      expect(layout.seatsPerRow, 6);
    });

    test('prefers the saved layout when one exists', () {
      final theatre = _theatreB();
      final layout = TheatreUnityBridge.effectiveSeatLayout(theatre);
      expect(layout.rows, 15);
      expect(layout.seatsPerRow, 20);
    });
  });
}
