import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/admin/models/movie_content.dart';
import 'package:livescreen/producer/screens/movie_edit_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('MovieEditScreen dual-trailer UI', () {
    testWidgets('renders distinct YouTube trailer field and upload button for new movie', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const MovieEditScreen()));
      await tester.pumpAndSettle();

      expect(find.text('New Movie'), findsOneWidget);
      expect(find.text('YouTube Trailer'), findsOneWidget);
      expect(find.text('Used for normal trailer playback.'), findsOneWidget);

      expect(find.text('Immersive 3D Trailer'), findsOneWidget);
      expect(
        find.text('Used to play the trailer directly on the cinema screen in the 3D seat experience.'),
        findsOneWidget,
      );
      expect(find.text('Upload MP4 / WebM'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);

      // Verify no direct MP4 input text field exists for immersive trailer
      expect(find.text('Immersive Trailer URL'), findsNothing);
      expect(find.text('Direct MP4 / WebM URL'), findsNothing);
    });

    testWidgets('renders existing immersive trailer status and Replace Video button when existing has immersiveTrailerUrl', (tester) async {
      final existingMovie = MovieContent(
        id: 'movie-123',
        title: 'Test Feature',
        description: 'A test film',
        trailerUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        immersiveTrailerUrl: 'https://ihuzxgnmxyyjafjipbnz.supabase.co/storage/v1/object/public/trailers/demo/test.mp4',
        thumbnail: 'https://example.com/thumb.jpg',
        durationSeconds: 7200,
      );

      await tester.pumpWidget(buildTestableWidget(MovieEditScreen(existing: existingMovie)));
      await tester.pumpAndSettle();

      expect(find.text('Edit Movie'), findsOneWidget);
      expect(find.text('Test Feature'), findsOneWidget);
      expect(find.text('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), findsOneWidget);

      // Verify Immersive 3D Trailer shows existing indicator and Replace Video button
      expect(find.text('✓ Existing immersive trailer'), findsOneWidget);
      expect(find.text('Replace Video'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows validation snackbar if YouTube trailer URL is invalid', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const MovieEditScreen()));
      await tester.pumpAndSettle();

      // Enter title so title validation passes
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Valid Title');

      // Enter invalid YouTube URL
      await tester.enterText(find.widgetWithText(TextField, 'YouTube Trailer'), 'https://example.com/not_youtube');
      await tester.pumpAndSettle();

      // Tap Save
      final saveButton = find.widgetWithText(ElevatedButton, 'Save');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Should show validation error SnackBar
      expect(find.textContaining('Please provide a valid YouTube trailer URL'), findsOneWidget);
    });
  });
}
