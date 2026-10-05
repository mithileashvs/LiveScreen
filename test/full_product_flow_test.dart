import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/admin/models/movie_content.dart';
import 'package:livescreen/admin/models/theatre_configuration.dart';
import 'package:livescreen/admin/models/screen_config.dart';
import 'package:livescreen/admin/models/speaker_model.dart';
import 'package:livescreen/admin/services/theatre_repository.dart';
import 'package:livescreen/admin/services/theatre_unity_bridge.dart';
import 'package:livescreen/screens/unity_experience_screen.dart';
import 'package:livescreen/auth/screens/login_screen.dart';

// In-memory mock implementing the TheatreRepository contract for the end-to-end journey
class MockEndToEndTheatreRepository implements TheatreRepository {
  final Map<String, TheatreConfiguration> _theatres = {};
  final Map<String, int> _showCounts = {};
  final Map<String, int> _bookingCounts = {};

  void seed({required TheatreConfiguration theatre, int showCount = 0, int bookingCount = 0}) {
    _theatres[theatre.id] = theatre;
    _showCounts[theatre.id] = showCount;
    _bookingCounts[theatre.id] = bookingCount;
  }

  @override
  Future<TheatreConfiguration> createTheatre(TheatreBasicInfo basicInfo) async {
    final t = TheatreConfiguration(id: 'th_${_theatres.length + 1}', basicInfo: basicInfo);
    _theatres[t.id] = t;
    return t;
  }

  @override
  Future<void> saveTheatre(TheatreConfiguration config) async => _theatres[config.id] = config;

  @override
  Future<TheatreConfiguration?> loadTheatre(String id) async => _theatres[id];

  @override
  Future<List<TheatreConfiguration>> getMyTheatres() async => _theatres.values.toList();

  @override
  Future<List<TheatreConfiguration>> getPublishedTheatres() async =>
      _theatres.values.where((t) => t.status == TheatreStatus.published).toList();

  @override
  Future<List<String>> publishTheatre(String id) async {
    final t = _theatres[id];
    if (t != null) {
      _theatres[id] = t.copyWith(status: TheatreStatus.published);
    }
    return [];
  }

  @override
  Future<TheatreDependencySummary> getTheatreDependencies(String id) async {
    return TheatreDependencySummary(
      showCount: _showCounts[id] ?? 0,
      bookingCount: _bookingCounts[id] ?? 0,
    );
  }

  @override
  Future<void> deactivateTheatre(String id) async {
    final t = _theatres[id];
    if (t != null) {
      _theatres[id] = t.copyWith(status: TheatreStatus.archived);
    }
  }

  @override
  Future<void> reactivateTheatre(String id) async {
    final t = _theatres[id];
    if (t != null) {
      _theatres[id] = t.copyWith(status: TheatreStatus.published);
    }
  }

  @override
  Future<void> deleteTheatre(String id) async {
    final deps = await getTheatreDependencies(id);
    if (deps.hasDependencies) {
      throw TheatreHasDependenciesException(
        theatreId: id,
        showCount: deps.showCount,
        bookingCount: deps.bookingCount,
      );
    }
    _theatres.remove(id);
  }
}

void main() {
  group('Full Product Flow End-to-End Audit', () {
    testWidgets('1. Login Portal: allows switching across all 4 role contexts', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      // Check all 4 roles exist as horizontal tabs
      expect(find.text('User'), findsOneWidget);
      expect(find.text('Theatre'), findsOneWidget);
      expect(find.text('Producer'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      // Verify role switching
      await tester.tap(find.text('Producer'));
      await tester.pumpAndSettle();
      expect(find.text('producer_demo'), findsOneWidget);

      await tester.tap(find.text('Theatre'));
      await tester.pumpAndSettle();
      expect(find.text('theatre_demo'), findsOneWidget);

      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(find.text('platform_admin_demo'), findsOneWidget);

      await tester.tap(find.text('User'));
      await tester.pumpAndSettle();
      expect(find.text('user_demo'), findsOneWidget);
    });

    test('2. Producer Flow: dual trailer preservation and metadata integrity', () {
      final initialMovie = MovieContent(
        id: 'mv-001',
        title: 'Cinematic Horizon',
        description: 'An epic space odyssey',
        trailerUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        immersiveTrailerUrl: 'https://example.com/trailers/horizon.mp4',
        durationSeconds: 142 * 60,
      );

      expect(initialMovie.trailerUrl, contains('youtube.com'));
      expect(initialMovie.immersiveTrailerUrl, contains('horizon.mp4'));

      // Simulate editing movie details while preserving both trailers
      initialMovie.title = 'Cinematic Horizon: Extended Cut';
      initialMovie.description = 'An expanded epic space odyssey with remastered visuals';

      expect(initialMovie.title, 'Cinematic Horizon: Extended Cut');
      expect(initialMovie.description, contains('remastered visuals'));
      expect(initialMovie.trailerUrl, contains('youtube.com'));
      expect(initialMovie.immersiveTrailerUrl, contains('horizon.mp4'));
    });

    test('3. Theatre Admin Flow: visual-only speakers & screen fit persistence', () async {
      final repo = MockEndToEndTheatreRepository();
      final theatre = TheatreConfiguration(
        id: 'theatre-1',
        basicInfo: TheatreBasicInfo(name: 'Grand IMAX', city: 'Metropolis'),
        screen: ScreenConfig(width: 22.0, height: 12.0),
        speakers: [
          SpeakerModel(
            id: 'sp-1',
            name: 'Screen Left',
            type: SpeakerType.frontLeft,
            position: Position3(x: -10.0, y: 3.0, z: 2.0),
          ),
          SpeakerModel(
            id: 'sp-2',
            name: 'Screen Right',
            type: SpeakerType.frontRight,
            position: Position3(x: 10.0, y: 3.0, z: 2.0),
          ),
          SpeakerModel(
            id: 'sp-3',
            name: 'Surround Rear',
            type: SpeakerType.rearSurround,
            position: Position3(x: 0.0, y: 4.0, z: -15.0),
          ),
        ],
        status: TheatreStatus.published,
      );

      repo.seed(theatre: theatre);

      // Verify visual-only speaker configuration
      final loaded = await repo.loadTheatre('theatre-1');
      expect(loaded, isNotNull);
      expect(loaded!.speakers.length, 3);
      expect(loaded.speakers[0].position.x, -10.0);
      expect(loaded.screen.width, 22.0);

      // Verify Unity bridge payload serialization
      final bridgePayload = TheatreUnityBridge.toUnityPayload(loaded);
      expect(bridgePayload.containsKey('speakers'), isTrue);
      final speakersList = bridgePayload['speakers'] as List;
      expect(speakersList.length, 3);
      expect(speakersList[0]['name'], 'Screen Left');
      expect(speakersList[0]['x'], -10.0);
      expect(bridgePayload['screenWidth'], 22.0);
      // Decoupling check: payload is visual configuration, no spatial audio emitter nodes injected
      expect(bridgePayload.containsKey('spatialAudioNode'), isFalse);
    });

    test('4. Platform Admin Flow: theatre lifecycle and dependency protection', () async {
      final repo = MockEndToEndTheatreRepository();
      final activeTheatre = TheatreConfiguration(
        id: 'th-active',
        basicInfo: TheatreBasicInfo(name: 'Cinema City', city: 'Downtown'),
        status: TheatreStatus.published,
      );

      // Seed with 2 active shows
      repo.seed(theatre: activeTheatre, showCount: 2);

      // Deactivate
      await repo.deactivateTheatre('th-active');
      var t = await repo.loadTheatre('th-active');
      expect(t!.status, TheatreStatus.archived);

      // Reactivate
      await repo.reactivateTheatre('th-active');
      t = await repo.loadTheatre('th-active');
      expect(t!.status, TheatreStatus.published);

      // Deletion protection: attempting delete while shows exist must throw TheatreHasDependenciesException
      expect(() => repo.deleteTheatre('th-active'), throwsA(isA<TheatreHasDependenciesException>()));

      // Clear dependencies and delete safely
      repo.seed(theatre: t, showCount: 0);
      await repo.deleteTheatre('th-active');
      expect(await repo.loadTheatre('th-active'), isNull);
    });

    testWidgets('5. Customer Flow: In-theatre trailer trigger and Unity message dispatch', (tester) async {
      final sentMessages = <String>[];
      const testTrailerUrl = 'https://example.com/trailers/epic.mp4';
      final movie = MovieContent(
        id: 'movie-epic',
        title: 'Epic Adventure',
        trailerUrl: 'https://youtube.com/watch?v=123',
        immersiveTrailerUrl: testTrailerUrl,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: WatchTrailerInTheatreButton(
              movie: movie,
              sendToUnity: (msg) => sentMessages.add(msg),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Watch Trailer (In Theatre)'), findsOneWidget);

      // Tap Watch Trailer
      await tester.tap(find.text('Watch Trailer (In Theatre)'));
      await tester.pumpAndSettle();

      // Verify Unity message sent with correct play_trailer command and immersive trailer URL
      expect(sentMessages.length, 1);
      expect(sentMessages[0], contains('play_trailer'));
      expect(sentMessages[0], contains(testTrailerUrl));
    });
  });
}
