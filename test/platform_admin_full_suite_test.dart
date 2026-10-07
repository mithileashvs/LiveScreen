import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/platform_admin/screens/platform_admin_profile_screen.dart';
import 'package:livescreen/platform_admin/screens/platform_admin_settings_screen.dart';
import 'package:livescreen/platform_admin/screens/platform_admin_help_screen.dart';
import 'package:livescreen/platform_admin/screens/platform_verifications_screen.dart';
import 'package:livescreen/platform_admin/screens/platform_bookings_screen.dart';
import 'package:livescreen/platform_admin/screens/platform_users_screen.dart';
import 'package:livescreen/platform_admin/screens/platform_analytics_screen.dart';
import 'package:livescreen/platform_admin/screens/theatre_verification_screen.dart';
import 'package:livescreen/platform_admin/screens/theatre_ownership_verification_screen.dart';
import 'package:livescreen/platform_admin/screens/producer_verification_screen.dart';
import 'package:livescreen/platform_admin/screens/movie_approval_screen.dart';
import 'package:livescreen/platform_admin/screens/activity_log_screen.dart';

void main() {
  group('Platform Admin Master Theme Suite', () {
    testWidgets('PlatformAdminProfileScreen renders profile card and governance permissions', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: PlatformAdminProfileScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Profile'), findsAtLeastNWidgets(1));
      expect(find.text('Governance Privileges'), findsOneWidget);
      expect(find.text('Active Session'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('PlatformAdminSettingsScreen renders notification preferences and security status', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: PlatformAdminSettingsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Settings'), findsAtLeastNWidgets(1));
      expect(find.text('Administrative Notifications'), findsOneWidget);
      expect(find.text('Appearance & Theme Specs'), findsOneWidget);
      expect(find.text('Security & Access Governance'), findsOneWidget);
    });

    testWidgets('PlatformAdminHelpScreen renders operations center and topics', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: PlatformAdminHelpScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Help & Support'), findsAtLeastNWidgets(1));
      expect(find.text('Platform Admin Operations Center'), findsOneWidget);
      expect(find.text('Operational Workflows'), findsOneWidget);
      expect(find.text('Theatre Management'), findsAtLeastNWidgets(1));
      expect(find.text('Producer Management'), findsAtLeastNWidgets(1));
    });

    testWidgets('PlatformVerificationsScreen renders queue cards', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: PlatformVerificationsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Verifications'), findsAtLeastNWidgets(1));
      expect(find.text('Theatre Venues'), findsOneWidget);
      expect(find.text('Theatre Ownership'), findsOneWidget);
      expect(find.text('Producer Accounts'), findsOneWidget);
      expect(find.text('Content & Movies'), findsOneWidget);
    });

    testWidgets('PlatformBookingsScreen renders search and status filters', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: PlatformBookingsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Platform Bookings'), findsAtLeastNWidgets(1));
      expect(find.text('Search booking ID, customer ID, or seat...'), findsOneWidget);
      expect(find.text('All Bookings'), findsOneWidget);
      expect(find.text('Confirmed'), findsAtLeastNWidgets(1));
    });

    testWidgets('PlatformUsersScreen renders role filter chips', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: PlatformUsersScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Platform Users'), findsAtLeastNWidgets(1));
      expect(find.text('Total Accounts'), findsOneWidget);
      expect(find.text('All Roles'), findsOneWidget);
    });

    testWidgets('PlatformAnalyticsScreen renders metric categories', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: PlatformAnalyticsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Platform Analytics'), findsAtLeastNWidgets(1));
      expect(find.text('Total Confirmed Bookings'), findsOneWidget);
      expect(find.text('Active Published Shows'), findsOneWidget);
      expect(find.text('Live Film Catalog'), findsOneWidget);
      expect(find.text('Verified Theatres'), findsOneWidget);
    });

    testWidgets('ActivityLogScreen renders in master theme', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: ActivityLogScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Audit Logs'), findsAtLeastNWidgets(1));
      expect(find.text('All Entries'), findsOneWidget);
      expect(find.text('Theatres'), findsOneWidget);
      expect(find.text('Producers'), findsOneWidget);
      expect(find.text('Movies & Content'), findsOneWidget);
    });

    testWidgets('TheatreVerificationScreen renders in master theme', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: TheatreVerificationScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Theatre Management'), findsAtLeastNWidgets(1));
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('TheatreOwnershipVerificationScreen renders in master theme', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: TheatreOwnershipVerificationScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Theatre Ownership Authorizations'), findsAtLeastNWidgets(1));
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('ProducerVerificationScreen renders in master theme', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: ProducerVerificationScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Producer Management'), findsAtLeastNWidgets(1));
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('MovieApprovalScreen renders in master theme', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: MovieApprovalScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Movie & Content'), findsAtLeastNWidgets(1));
      expect(find.text('All'), findsOneWidget);
    });
  });
}
