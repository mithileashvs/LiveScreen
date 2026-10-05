import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/platform_admin/screens/platform_admin_dashboard_screen.dart';
import 'package:livescreen/shared/widgets/admin/admin_sidebar.dart';

void main() {
  group('PlatformAdminDashboardScreen Redesign Tests', () {
    testWidgets('renders sidebar, top header, greeting, KPIs, verifications, submissions, performance, and quick actions', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlatformAdminDashboardScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Sidebar branding and navigation
      expect(find.text('LiveScreen'), findsOneWidget); // Profile pill in top bar has subtitle 'LiveScreen'
      expect(find.text('EXPERIENCE BEFORE YOU BOOK'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Theatre Management'), findsOneWidget);
      expect(find.text('Producer Management'), findsOneWidget);
      expect(find.text('Movie & Content'), findsOneWidget);
      expect(find.text('Verifications'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Audit Logs'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('REAL VENUES.'), findsOneWidget);
      expect(find.text('REAL SEATS.'), findsOneWidget);
      expect(find.text('REAL EXPERIENCES.'), findsOneWidget);

      // 2. Top Bar
      expect(find.text('PLATFORM ADMIN'), findsOneWidget);
      expect(find.text('Search users, theatres, producers, movies...'), findsOneWidget);

      // 3. Greeting & Intro
      expect(find.text('Monitor LiveScreen operations, approvals, and platform activity.'), findsOneWidget);

      // 4. Four KPI Cards
      expect(find.text('Total Theatres'), findsOneWidget);
      expect(find.text('Total Producers'), findsOneWidget);
      expect(find.text('Total Movies'), findsOneWidget);
      expect(find.text('Total Users'), findsOneWidget);

      // 5. Verification & Approvals section and cards
      expect(find.text('Verification & Approvals'), findsOneWidget);
      expect(find.text('Review pending requests across the LiveScreen platform.'), findsOneWidget);
      expect(find.text('Theatre Verifications'), findsOneWidget);
      expect(find.text('Producer Verifications'), findsOneWidget);
      expect(find.text('Content Approvals'), findsOneWidget);

      // 6. Middle Content: Recent Submissions & Platform Performance
      expect(find.text('Recent Submissions'), findsOneWidget);
      expect(find.text('Platform Performance'), findsOneWidget);
      expect(find.text('Latest platform activity and engagement.'), findsOneWidget);
      expect(find.text('Total Bookings'), findsOneWidget);
      expect(find.text('Active Shows'), findsOneWidget);
      expect(find.text('Published Theatres'), findsOneWidget);
      expect(find.text('Live Movies'), findsOneWidget);

      // 7. Quick Admin Actions
      expect(find.text('Quick Admin Actions'), findsOneWidget);
      expect(find.text('Common platform management tasks.'), findsOneWidget);
      expect(find.text('Review Theatres'), findsOneWidget);
      expect(find.text('Review Producers'), findsOneWidget);
      expect(find.text('Review Content'), findsOneWidget);
      expect(find.text('Manage Users'), findsOneWidget);
      expect(find.text('View Audit Logs'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow on smaller screen dimensions', (tester) async {
      tester.view.physicalSize = const Size(800, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlatformAdminDashboardScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PLATFORM ADMIN'), findsOneWidget);
      expect(find.text('Total Theatres'), findsOneWidget);
      expect(find.text('Verification & Approvals'), findsOneWidget);
      expect(find.text('Recent Submissions'), findsOneWidget);
      expect(find.text('Platform Performance'), findsOneWidget);
    });

    testWidgets('sidebar is non-scrollable and stationary while main content area scrolls vertically', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlatformAdminDashboardScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify AdminSidebar contains NO Scrollable widget
      final sidebarFinder = find.byType(AdminSidebar);
      expect(sidebarFinder, findsOneWidget);

      final scrollableInSidebar = find.descendant(
        of: sidebarFinder,
        matching: find.byType(Scrollable),
      );
      expect(scrollableInSidebar, findsNothing);

      // 2. Verify main content area has a Scrollable widget
      final scrollableInContent = find.byType(SingleChildScrollView);
      expect(scrollableInContent, findsOneWidget);

      // 3. Record sidebar position and tagline position
      final initialDashboardPos = tester.getTopLeft(find.text('Dashboard'));
      final initialTaglinePos = tester.getTopLeft(find.text('REAL VENUES.'));

      // 4. Scroll the main dashboard content
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -250));
      await tester.pump();

      // 5. Verify sidebar items did NOT move even by 1 pixel
      final postScrollDashboardPos = tester.getTopLeft(find.text('Dashboard'));
      final postScrollTaglinePos = tester.getTopLeft(find.text('REAL VENUES.'));
      expect(postScrollDashboardPos, equals(initialDashboardPos));
      expect(postScrollTaglinePos, equals(initialTaglinePos));
    });

    testWidgets('sidebar renders cleanly on common heights (650, 720, 768, 800, 900, 1080) without overflow', (tester) async {
      const heights = [650.0, 720.0, 768.0, 800.0, 900.0, 1080.0];

      for (final height in heights) {
        tester.view.physicalSize = Size(1280, height);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: PlatformAdminDashboardScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(AdminSidebar), findsOneWidget);
        expect(find.text('Audit Logs'), findsOneWidget);
        expect(find.text('REAL EXPERIENCES.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('sidebar satisfies vertical hierarchy with large gap above separator and flexible gap before tagline', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlatformAdminDashboardScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final dashboardY = tester.getTopLeft(find.text('Dashboard')).dy;
      final auditLogsY = tester.getBottomLeft(find.text('Audit Logs')).dy;
      final separatorFinder = find.byKey(const Key('admin_sidebar_gold_separator'));
      expect(separatorFinder, findsOneWidget);
      final separatorY = tester.getTopLeft(separatorFinder).dy;
      final profileY = tester.getTopLeft(find.text('Profile')).dy;
      final settingsY = tester.getTopLeft(find.text('Settings')).dy;
      final helpY = tester.getTopLeft(find.text('Help & Support')).dy;
      final taglineY = tester.getTopLeft(find.text('REAL VENUES.')).dy;

      // 1. Verify vertical order
      expect(dashboardY, lessThan(auditLogsY));
      expect(auditLogsY, lessThan(separatorY));
      expect(separatorY, lessThan(profileY));
      expect(profileY, lessThan(settingsY));
      expect(settingsY, lessThan(helpY));
      expect(helpY, lessThan(taglineY));

      // 2. Verify large flexible gap above separator
      final gapAboveSeparator = separatorY - auditLogsY;
      expect(gapAboveSeparator, greaterThan(100.0));

      // 3. Verify flexible gap between Help & Support and Tagline
      final helpBottomY = tester.getBottomLeft(find.text('Help & Support')).dy;
      final gapBeforeTagline = taglineY - helpBottomY;
      expect(gapBeforeTagline, greaterThan(30.0));
    });

    testWidgets('AdminSidebar reproduces vertical hierarchy for Theatre Admin & Producer Admin', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Producer Admin (5 items)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSidebar(
              activeKey: 'dashboard',
              mainNavItems: const [
                AdminNavItemData(key: 'dashboard', label: 'Dashboard', icon: Icons.grid_view_rounded),
                AdminNavItemData(key: 'my_movies', label: 'My Movies', icon: Icons.theaters_outlined),
                AdminNavItemData(key: 'submit_movie', label: 'Submit Movie', icon: Icons.add_box_outlined),
                AdminNavItemData(key: 'assets', label: 'Trailers & Assets', icon: Icons.smart_display_outlined),
                AdminNavItemData(key: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
              ],
              onSelectKey: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      final analyticsBottomY = tester.getBottomLeft(find.text('Analytics')).dy;
      final separatorY = tester.getTopLeft(find.byKey(const Key('admin_sidebar_gold_separator'))).dy;
      final profileY = tester.getTopLeft(find.text('Profile')).dy;
      final helpBottomY = tester.getBottomLeft(find.text('Help & Support')).dy;
      final taglineY = tester.getTopLeft(find.text('REAL VENUES.')).dy;

      expect(analyticsBottomY, lessThan(separatorY));
      expect(separatorY, lessThan(profileY));
      expect(helpBottomY, lessThan(taglineY));

      // Gap above separator is large
      expect(separatorY - analyticsBottomY, greaterThan(200.0));
      // Gap before tagline is flexible
      expect(taglineY - helpBottomY, greaterThan(50.0));
    });
  });
}
