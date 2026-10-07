import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/admin/models/movie_content.dart';
import 'package:livescreen/screens/unity_experience_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('WatchTrailerInTheatreButton (In-Theatre Unity Trailer)', () {
    testWidgets('displays "Immersive trailer unavailable" and shows SnackBar when immersiveTrailerUrl is empty', (tester) async {
      final sentMessages = <String>[];
      final movieNoImmersive = MovieContent(
        id: 'movie-leo',
        title: 'Leo',
        trailerUrl: 'https://www.youtube.com/watch?v=Po3jStA673E',
        immersiveTrailerUrl: '',
      );

      await tester.pumpWidget(buildTestableWidget(
        WatchTrailerInTheatreButton(
          movie: movieNoImmersive,
          sendToUnity: (msg) => sentMessages.add(msg),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Immersive trailer unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
      expect(find.text('Watch Trailer (In Theatre)'), findsNothing);

      // Tap the unavailable button
      await tester.tap(find.text('Immersive trailer unavailable'));
      await tester.pumpAndSettle();

      // Expect SnackBar informing user, and NO message sent to Unity
      expect(find.text('Immersive 3D trailer is not available for this movie.'), findsOneWidget);
      expect(sentMessages, isEmpty);
    });

    testWidgets('starts playback on Unity cinema screen when immersiveTrailerUrl is present', (tester) async {
      final sentMessages = <String>[];
      const testImmersiveUrl = 'https://ihuzxgnmxyyjafjipbnz.supabase.co/storage/v1/object/public/trailers/demo/trailer.mp4';
      final movieWithImmersive = MovieContent(
        id: 'movie-immersive',
        title: 'Immersive Film',
        trailerUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        immersiveTrailerUrl: testImmersiveUrl,
      );

      final key = GlobalKey<WatchTrailerInTheatreButtonState>();

      await tester.pumpWidget(buildTestableWidget(
        WatchTrailerInTheatreButton(
          key: key,
          movie: movieWithImmersive,
          sendToUnity: (msg) => sentMessages.add(msg),
        ),
      ));
      await tester.pumpAndSettle();

      // Initially displays Watch Trailer (In Theatre)
      expect(find.text('Watch Trailer (In Theatre)'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

      // Tap Watch Trailer
      await tester.tap(find.text('Watch Trailer (In Theatre)'));
      await tester.pump();

      // Verifies bridge message sent to Unity
      expect(sentMessages, equals(['play_trailer:$testImmersiveUrl']));
      expect(find.text('Loading Trailer…'), findsOneWidget);

      // Simulate Unity responding with trailer_started
      key.currentState?.handleUnityEvent('trailer_started');
      await tester.pumpAndSettle();

      expect(find.text('Stop Trailer'), findsOneWidget);
      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);

      // Tap Stop Trailer
      await tester.tap(find.text('Stop Trailer'));
      await tester.pump();

      expect(sentMessages, equals(['play_trailer:$testImmersiveUrl', 'stop_trailer']));
      expect(find.text('Watch Trailer (In Theatre)'), findsOneWidget);

      // Simulate Unity responding with trailer_stopped
      key.currentState?.handleUnityEvent('trailer_stopped');
      await tester.pumpAndSettle();

      expect(find.text('Watch Trailer (In Theatre)'), findsOneWidget);
    });

    testWidgets('handles Unity trailer error gracefully with a SnackBar', (tester) async {
      final sentMessages = <String>[];
      const testImmersiveUrl = 'https://example.com/bad_trailer.mp4';
      final movieWithImmersive = MovieContent(
        id: 'movie-err',
        title: 'Error Film',
        immersiveTrailerUrl: testImmersiveUrl,
      );

      final key = GlobalKey<WatchTrailerInTheatreButtonState>();

      await tester.pumpWidget(buildTestableWidget(
        WatchTrailerInTheatreButton(
          key: key,
          movie: movieWithImmersive,
          sendToUnity: (msg) => sentMessages.add(msg),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap Watch Trailer
      await tester.tap(find.text('Watch Trailer (In Theatre)'));
      await tester.pump();

      // Simulate Unity error event
      key.currentState?.handleUnityEvent('trailer_error:cannot_decode');
      await tester.pumpAndSettle();

      expect(find.text('Could not play the trailer on the cinema screen (cannot_decode).'), findsOneWidget);
      expect(find.text('Watch Trailer (In Theatre)'), findsOneWidget);
    });
  });
}
