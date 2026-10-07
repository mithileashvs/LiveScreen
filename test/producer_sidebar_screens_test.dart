import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/producer/screens/producer_profile_screen.dart';
import 'package:livescreen/producer/screens/producer_settings_screen.dart';
import 'package:livescreen/producer/screens/producer_help_screen.dart';
import 'package:livescreen/shared/widgets/admin/admin_sidebar.dart';

void main() {
  group('Producer Profile, Settings, and Help & Support Screens', () {
    testWidgets('ProducerProfileScreen renders profile header, account details, and sign out', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProducerProfileScreen(),
        ),
      );

      // Pump to let async futures settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Manage your producer account and company information.'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Catalog Overview'), findsOneWidget);
      expect(find.text('Session & Authentication'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('ProducerSettingsScreen renders preferences, theme info, security, and sign out', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProducerSettingsScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Account & Identity'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('Security & Access'), findsOneWidget);
      expect(find.text('Account Session'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Verify notification switches can be toggled
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
    });

    testWidgets('ProducerHelpScreen renders knowledge base, 6 topics, expandable FAQ, and support info', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProducerHelpScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Help & Support'), findsWidgets);
      expect(find.text('LiveScreen Producer Knowledge Base'), findsOneWidget);
      expect(find.text('Common Topics'), findsOneWidget);

      // Verify all 6 common topic cards are rendered
      expect(find.text('1. Submit a Movie'), findsOneWidget);
      expect(find.text('2. Manage My Movies'), findsOneWidget);
      expect(find.text('3. Approval & Verification'), findsOneWidget);
      expect(find.text('4. Trailers & Assets'), findsOneWidget);
      expect(find.text('5. Catalog Analytics'), findsOneWidget);
      expect(find.text('6. Account & Profile'), findsOneWidget);

      // Verify FAQ section and expand interaction
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      final firstFaq = find.text('How do I submit a movie for theatre distribution?');
      expect(firstFaq, findsOneWidget);

      await tester.ensureVisible(firstFaq);
      await tester.pumpAndSettle();

      await tester.tap(firstFaq);
      await tester.pumpAndSettle();
      expect(find.textContaining('Navigate to "Submit Movie"'), findsOneWidget);

      // Verify Support info card
      expect(find.text('Support & Direct Assistance'), findsOneWidget);
    });

    testWidgets('AdminSidebar activates Profile, Settings, and Help & Support correctly', (tester) async {
      const navItems = [
        AdminNavItemData(key: 'dashboard', label: 'Dashboard', icon: Icons.grid_view_rounded),
        AdminNavItemData(key: 'my_movies', label: 'My Movies', icon: Icons.theaters_outlined),
        AdminNavItemData(key: 'submit_movie', label: 'Submit Movie', icon: Icons.add_box_outlined),
        AdminNavItemData(key: 'assets', label: 'Trailers & Assets', icon: Icons.smart_display_outlined),
        AdminNavItemData(key: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
      ];

      String selectedKey = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSidebar(
              activeKey: 'profile',
              mainNavItems: navItems,
              onSelectKey: (key) => selectedKey = key,
            ),
          ),
        ),
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);

      // Tapping Settings calls onSelectKey with 'settings'
      await tester.tap(find.text('Settings'));
      expect(selectedKey, equals('settings'));

      // Tapping Help & Support calls onSelectKey with 'help'
      await tester.tap(find.text('Help & Support'));
      expect(selectedKey, equals('help'));
    });
  });
}
