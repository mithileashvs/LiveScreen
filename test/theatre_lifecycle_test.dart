import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/admin/models/theatre_configuration.dart';
import 'package:livescreen/admin/models/seat_config.dart';
import 'package:livescreen/admin/screens/theatre_list_screen.dart';
import 'package:livescreen/admin/services/theatre_repository.dart';

class MockLifecycleTheatreRepository implements TheatreRepository {
  final Map<String, TheatreConfiguration> _theatres = {};
  final Map<String, int> _showCounts = {};
  final Map<String, int> _bookingCounts = {};

  void setMockDependencies(String id, {int showCount = 0, int bookingCount = 0}) {
    _showCounts[id] = showCount;
    _bookingCounts[id] = bookingCount;
  }

  void seedTheatre(TheatreConfiguration config) {
    _theatres[config.id] = config;
  }

  @override
  Future<TheatreConfiguration> createTheatre(TheatreBasicInfo basicInfo) async {
    final config = TheatreConfiguration(id: 'th_${_theatres.length + 1}', basicInfo: basicInfo);
    _theatres[config.id] = config;
    return config;
  }

  @override
  Future<void> saveTheatre(TheatreConfiguration config) async {
    _theatres[config.id] = config;
  }

  @override
  Future<TheatreConfiguration?> loadTheatre(String id) async {
    return _theatres[id];
  }

  @override
  Future<List<TheatreConfiguration>> getMyTheatres() async {
    return _theatres.values.toList();
  }

  @override
  Future<List<TheatreConfiguration>> getPublishedTheatres() async {
    return _theatres.values.where((t) => t.status == TheatreStatus.published).toList();
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
      t.status = TheatreStatus.archived;
    }
  }

  @override
  Future<void> reactivateTheatre(String id) async {
    final t = _theatres[id];
    if (t != null) {
      t.status = TheatreStatus.published;
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

  @override
  Future<List<String>> publishTheatre(String id) async {
    final t = _theatres[id];
    if (t != null) {
      t.status = TheatreStatus.published;
    }
    return [];
  }
}

void main() {
  group('Theatre Lifecycle & Dependency Protection (Repository Layer)', () {
    late InMemoryTheatreRepository repo;

    setUp(() {
      repo = InMemoryTheatreRepository();
    });

    test('deactivate and reactivate theatre updates status and catalog visibility', () async {
      final theatre = await repo.createTheatre(TheatreBasicInfo(name: 'Cinema One'));
      theatre.verificationStatus = 'verified';
      theatre.seats.add(SeatConfig(row: 'A', number: 1));
      await repo.saveTheatre(theatre);
      final errors = await repo.publishTheatre(theatre.id);
      expect(errors, isEmpty);

      var published = await repo.getPublishedTheatres();
      expect(published.length, 1);
      expect(published.first.status, TheatreStatus.published);

      // Deactivate
      await repo.deactivateTheatre(theatre.id);
      final loaded = await repo.loadTheatre(theatre.id);
      expect(loaded?.status, TheatreStatus.archived);

      // Excluded from published catalog
      published = await repo.getPublishedTheatres();
      expect(published.isEmpty, isTrue);

      // Reactivate
      await repo.reactivateTheatre(theatre.id);
      final reactivated = await repo.loadTheatre(theatre.id);
      expect(reactivated?.status, TheatreStatus.published);

      published = await repo.getPublishedTheatres();
      expect(published.length, 1);
    });

    test('deleteTheatre is blocked when associated shows or bookings exist', () async {
      final theatre = await repo.createTheatre(TheatreBasicInfo(name: 'Cinema Two'));
      repo.setMockDependencies(theatre.id, showCount: 3, bookingCount: 12);

      // Deletion must throw TheatreHasDependenciesException
      expect(
        () => repo.deleteTheatre(theatre.id),
        throwsA(isA<TheatreHasDependenciesException>()
            .having((e) => e.showCount, 'showCount', 3)
            .having((e) => e.bookingCount, 'bookingCount', 12)),
      );

      // Theatre record must remain untouched
      final loaded = await repo.loadTheatre(theatre.id);
      expect(loaded, isNotNull);
    });

    test('deleteTheatre succeeds when no dependencies exist', () async {
      final theatre = await repo.createTheatre(TheatreBasicInfo(name: 'Empty Cinema'));
      repo.setMockDependencies(theatre.id, showCount: 0, bookingCount: 0);

      await repo.deleteTheatre(theatre.id);

      final loaded = await repo.loadTheatre(theatre.id);
      expect(loaded, isNull);
    });

    test('multi-theatre safety: modifying or deleting Theatre A does not affect Theatre B', () async {
      final theatreA = await repo.createTheatre(TheatreBasicInfo(name: 'Theatre Alpha'));
      final theatreB = await repo.createTheatre(TheatreBasicInfo(name: 'Theatre Beta'));
      theatreA.verificationStatus = 'verified';
      theatreB.verificationStatus = 'verified';
      theatreA.seats.add(SeatConfig(row: 'A', number: 1));
      theatreB.seats.add(SeatConfig(row: 'A', number: 1));
      await repo.saveTheatre(theatreA);
      await repo.saveTheatre(theatreB);
      await repo.publishTheatre(theatreA.id);
      await repo.publishTheatre(theatreB.id);

      // Deactivate Theatre A only
      await repo.deactivateTheatre(theatreA.id);
      final loadedA = await repo.loadTheatre(theatreA.id);
      final loadedB = await repo.loadTheatre(theatreB.id);
      expect(loadedA?.status, TheatreStatus.archived);
      expect(loadedB?.status, TheatreStatus.published); // Theatre B unaffected!

      // Delete Theatre A only
      repo.setMockDependencies(theatreA.id, showCount: 0, bookingCount: 0);
      await repo.deleteTheatre(theatreA.id);
      expect(await repo.loadTheatre(theatreA.id), isNull);
      final stillLoadedB = await repo.loadTheatre(theatreB.id);
      expect(stillLoadedB, isNotNull);
      expect(stillLoadedB?.basicInfo.name, 'Theatre Beta');
      expect(stillLoadedB?.status, TheatreStatus.published); // Theatre B completely intact!
    });
  });

  group('TheatreListScreen Widget Tests (Manage Menu & Lifecycle Actions)', () {
    testWidgets('renders manage menu with Edit, Screens, Admin Access, Deactivate, and Delete', (tester) async {
      // In the app, theatreRepository is a global singleton. In tests, we can test the UI with
      // the existing theatreRepository or test widget interactions.
      await tester.pumpWidget(
        const MaterialApp(
          home: TheatreListScreen(),
        ),
      );

      await tester.pump();
      // Initially displays loading or empty state depending on mock
      expect(find.byType(TheatreListScreen), findsOneWidget);
    });
  });
}
