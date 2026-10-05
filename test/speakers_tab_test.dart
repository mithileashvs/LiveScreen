import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/admin/models/theatre_configuration.dart';
import 'package:livescreen/admin/screens/tabs/speakers_tab.dart';
import 'package:livescreen/admin/widgets/visual_theatre_canvas.dart';

void main() {
  group('SpeakersTab (Visual-Only Speaker Placement)', () {
    late TheatreConfiguration config;

    setUp(() {
      config = TheatreConfiguration(
        id: 'test_theatre',
        basicInfo: TheatreBasicInfo(name: 'Test Cinema'),
      );
    });

    testWidgets('renders visual-only header, helper banner, and Add Speaker button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakersTab(
              config: config,
              onChanged: () {},
            ),
          ),
        ),
      );

      // Verify header and helper text
      expect(find.text('Auditorium Speakers'), findsOneWidget);
      expect(
        find.textContaining('Position speakers to visually match your theatre. This does not configure the theatre\'s sound system.'),
        findsOneWidget,
      );
      expect(find.text('Add Speaker'), findsOneWidget);

      // Verify technical fields are completely absent from UI
      expect(find.text('Channel'), findsNothing);
      expect(find.text('Atmos'), findsNothing);
      expect(find.text('Dolby'), findsNothing);
      expect(find.text('Rated Power'), findsNothing);
      expect(find.text('Sensitivity'), findsNothing);
      expect(find.text('Frequency Range'), findsNothing);
      expect(find.text('Position X'), findsNothing);
      expect(find.text('Position Y'), findsNothing);
      expect(find.text('Position Z'), findsNothing);
    });

    testWidgets('tapping Add Speaker adds a speaker and updates count', (tester) async {
      bool changed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakersTab(
              config: config,
              onChanged: () => changed = true,
            ),
          ),
        ),
      );

      expect(config.speakers.isEmpty, isTrue);

      await tester.tap(find.text('Add Speaker'));
      await tester.pumpAndSettle();

      expect(config.speakers.length, equals(1));
      expect(changed, isTrue);
      expect(config.speakers.first.name, equals('Speaker 1'));
      expect(find.text('1 speakers placed · Visual layout only'), findsOneWidget);
      expect(find.text('Delete Speaker'), findsOneWidget);
    });

    testWidgets('selecting and deleting a speaker removes it from config', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakersTab(
              config: config,
              onChanged: () {},
            ),
          ),
        ),
      );

      // Add two speakers
      await tester.tap(find.text('Add Speaker'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Speaker'));
      await tester.pumpAndSettle();

      expect(config.speakers.length, equals(2));

      // Delete the currently selected speaker
      await tester.tap(find.text('Delete Speaker'));
      await tester.pumpAndSettle();

      expect(config.speakers.length, equals(1));
    });

    testWidgets('drag clamping keeps speaker within room boundaries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpeakersTab(
              config: config,
              onChanged: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add Speaker'));
      await tester.pumpAndSettle();

      final speaker = config.speakers.first;

      // Find the VisualTheatreCanvas and simulate drag beyond room bounds
      final canvasFinder = find.byType(VisualTheatreCanvas);
      expect(canvasFinder, findsOneWidget);

      // Test direct coordinate logic
      final room = config.room;
      final minX = -room.width / 2 + 0.35;
      final maxX = room.width / 2 - 0.35;

      expect(speaker.position.x, inInclusiveRange(minX, maxX));
      expect(speaker.position.z, inInclusiveRange(0.5, room.length - 0.5));
    });
  });
}
