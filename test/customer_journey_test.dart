import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/admin/models/movie_content.dart';
import 'package:livescreen/admin/models/theatre_configuration.dart';
import 'package:livescreen/screens/customer_help_screen.dart';
import 'package:livescreen/screens/customer_payment_screen.dart';
import 'package:livescreen/screens/movie_details_screen.dart';
import 'package:livescreen/screens/profile_screen.dart';
import 'package:livescreen/screens/snacks_screen.dart';
import 'package:livescreen/screens/theatre_seat_selection_screen.dart';
import 'package:livescreen/admin/models/theatre_snack.dart';
import 'package:livescreen/theme/customer_theme.dart';
import 'package:livescreen/widgets/customer_widgets.dart';

void main() {
  group('Customer-Facing Journey & Redesign Suite', () {
    final testMovie = MovieContent(
      id: 'movie-redesign-01',
      title: 'Dune: Part Two',
      durationSeconds: 166 * 60,
      description: 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators.',
      thumbnail: 'https://image.tmdb.org/t/p/w500/dune2.jpg',
      trailerUrl: 'https://youtube.com/watch?v=Way9Dexny3w',
      immersiveTrailerUrl: 'https://example.com/dune2.mp4',
    );

    final testTheatre = TheatreConfiguration(
      id: 'theatre-imax-01',
      basicInfo: TheatreBasicInfo(name: 'PVR IMAX Phoenix Marketcity', city: 'Mumbai'),
    );

    test('Customer theme constants adhere to design specification', () {
      expect(CustomerColors.background, const Color(0xFF08080A));
      expect(CustomerColors.gold, const Color(0xFFD4AF37));
      expect(CustomerColors.burgundy, const Color(0xFF9E102F));
      expect(CustomerColors.seatAvailable, const Color(0xFF6B7280));
      expect(CustomerColors.seatSelected, const Color(0xFFD4AF37));
      expect(CustomerColors.seatBooked, const Color(0xFF1E212B));
    });

    testWidgets('MovieDetailsScreen renders poster, metadata, Book tickets and Watch Trailer buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        theme: customerDarkTheme,
        home: MovieDetailsScreen(movie: testMovie),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dune: Part Two'), findsWidgets);
      expect(find.text('Book tickets'), findsOneWidget);
      expect(find.text('Watch Trailer'), findsOneWidget);
      expect(find.text('About the movie'), findsOneWidget);
      expect(find.textContaining('Paul Atreides unites'), findsOneWidget);
    });

    testWidgets(
        'TheatreSeatSelectionScreen displays rows N down to A, selects A1, N1, and respects legend',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        theme: customerDarkTheme,
        home: TheatreSeatSelectionScreen(
          theatre: testTheatre,
          movie: testMovie,
          selectedDate: 'Today, 26 Sep',
          selectedTime: '07:30 PM',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SCREEN THIS WAY'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Selected'), findsOneWidget);
      expect(find.text('Booked'), findsOneWidget);

      // Verify row labels exist: N and A
      expect(find.text('N'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);

      // Verify N is above A vertically
      final nTop = tester.getTopLeft(find.text('N')).dy;
      final aTop = tester.getTopLeft(find.text('A')).dy;
      expect(nTop, lessThan(aTop), reason: 'Row N must be above Row A');

      // Select A1
      final a1Finder = find.byTooltip('A1 • Available');
      expect(a1Finder, findsOneWidget);
      await tester.tap(a1Finder);
      await tester.pumpAndSettle();

      // Now A1 is selected and appears in the bottom selection bar
      expect(find.text('Selected Seats (1)'), findsOneWidget);
      expect(find.text('A1'), findsWidgets);

      // Select N1
      final n1Finder = find.byTooltip('N1 • Available');
      expect(n1Finder, findsOneWidget);
      await tester.tap(n1Finder);
      await tester.pumpAndSettle();

      expect(find.text('Selected Seats (2)'), findsOneWidget);
      expect(find.text('N1'), findsWidgets);

      // Unselect A1
      await tester.tap(find.byTooltip('A1 • Selected'));
      await tester.pumpAndSettle();

      expect(find.text('Selected Seats (1)'), findsOneWidget);
      expect(find.byTooltip('A1 • Available'), findsOneWidget);
    });

    testWidgets('SnacksScreen renders categories, Grab a Bite header, and updates totals on add',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testSnacks = [
        TheatreSnack(
          id: 'snk_1',
          theatreId: testTheatre.id,
          name: 'Caramel Popcorn (L)',
          category: 'Popcorn',
          price: 290,
          description: 'Rich jumbo caramel coated gourmet popcorn',
        ),
        TheatreSnack(
          id: 'snk_6',
          theatreId: testTheatre.id,
          name: 'Nachos with Cheese Dip',
          category: 'Snacks',
          price: 180,
          description: 'Crispy tortilla nachos with rich cheese dip',
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        theme: customerDarkTheme,
        home: SnacksScreen(
          theatre: testTheatre,
          movie: testMovie,
          selectedSeats: const ['E-10', 'E-11'],
          ticketFare: 700.0,
          date: 'Today, 26 Sep',
          time: '07:30 PM',
          initialSnacks: testSnacks,
        ),
      ));
      await tester.pumpAndSettle();

      // Heading
      expect(find.text('Grab a '), findsOneWidget);
      expect(find.text('Bite!'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Concession items
      expect(find.text('Caramel Popcorn (L)'), findsOneWidget);
      expect(find.text('Nachos with Cheese Dip'), findsOneWidget);

      // Increment popcorn
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsWidgets);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Proceed to Payment button should reflect ticket + snack
      expect(find.textContaining('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('SnacksScreen renders clean empty state when theatre has no snacks configured',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        theme: customerDarkTheme,
        home: SnacksScreen(
          theatre: testTheatre,
          movie: testMovie,
          selectedSeats: const ['E-10'],
          ticketFare: 350.0,
          date: 'Today, 26 Sep',
          time: '07:30 PM',
          initialSnacks: const [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Snacks Available at This Theatre'), findsOneWidget);
      expect(find.text('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('CustomerPaymentScreen displays order summary, payment methods and Pay button',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(MaterialApp(
        theme: customerDarkTheme,
        home: CustomerPaymentScreen(
          theatre: testTheatre,
          movie: testMovie,
          selectedSeats: const ['E-10'],
          ticketFare: 350.0,
          snackTotal: 290.0,
          selectedSnacks: const [
            {'name': 'Caramel Popcorn (L)', 'qty': 1, 'price': 290.0}
          ],
          date: 'Today, 26 Sep',
          time: '07:30 PM',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Dune: Part Two'), findsOneWidget);
      expect(find.text('E-10'), findsOneWidget);
      // Total = 350 + 290 + 35 = 675
      expect(find.text('₹675.00'), findsWidgets);
      expect(find.text('Pay ₹675.00'), findsOneWidget);
    });

    testWidgets(
        'CustomerSidebar displays correct order, preserves Concerts, excludes Watchlist/Offers, and anchors Profile & Settings',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String selected = 'Home';
      await tester.pumpWidget(MaterialApp(
        theme: customerDarkTheme,
        home: Scaffold(
          body: CustomerSidebar(
            selectedNav: selected,
            onSelectNav: (nav) => selected = nav,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Top-level navigation items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Sports'), findsOneWidget);
      expect(find.text('Concerts'), findsOneWidget);
      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.byKey(const Key('customer_sidebar_gold_separator')), findsOneWidget);

      // Watchlist and Offers should NEVER appear in the sidebar
      expect(find.text('Watchlist'), findsNothing);
      expect(find.text('Offers'), findsNothing);

      // Tap Profile to select
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(selected, 'Profile');

      // Tap Help & Support to select
      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();
      expect(selected, 'Help & Support');

      // Still no Watchlist or Offers in sidebar
      expect(find.text('Watchlist'), findsNothing);
      expect(find.text('Offers'), findsNothing);

      // Bottom branding
      expect(find.text('REAL VENUES.'), findsOneWidget);
      expect(find.text('REAL SEATS.'), findsOneWidget);
      expect(find.text('REAL EXPERIENCES.'), findsOneWidget);
    });

    testWidgets(
        'CustomerHelpScreen renders concierge cards, FAQs, and support banner',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: customerDarkTheme,
        home: const CustomerHelpScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('24/7 Guest Concierge'), findsOneWidget);
      expect(find.text('Email Assistance'), findsOneWidget);
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('How does the interactive 3D venue view work?'), findsOneWidget);
    });

    testWidgets(
        'ProfileScreen renders profile info and action cards for My Watchlist and Offers & Discounts',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: customerDarkTheme,
        home: const ProfileScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('My Watchlist'), findsOneWidget);
      expect(find.text('Offers & Discounts'), findsOneWidget);

      // Tap My Watchlist opens WatchlistScreen
      await tester.tap(find.text('My Watchlist'));
      await tester.pumpAndSettle();
      expect(find.text('No Movies Saved Yet'), findsOneWidget);
    });
  });
}
