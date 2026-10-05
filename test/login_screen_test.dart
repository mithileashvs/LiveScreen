import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/auth/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders cinematic login experience and components', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pump();

    // 1. Verify typography
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your LiveScreen account'), findsOneWidget);

    // 2. Verify all four role tabs exist
    expect(find.text('User'), findsOneWidget);
    expect(find.text('Theatre'), findsOneWidget);
    expect(find.text('Producer'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

    // Initial state is User demo
    expect(find.text('user_demo'), findsOneWidget);

    // 3. Switch to Theatre tab
    await tester.tap(find.text('Theatre'));
    await tester.pumpAndSettle();
    expect(find.text('theatre_demo'), findsOneWidget);

    // 4. Switch to Producer tab
    await tester.tap(find.text('Producer'));
    await tester.pumpAndSettle();
    expect(find.text('producer_demo'), findsOneWidget);

    // 5. Switch to Admin tab
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.text('platform_admin_demo'), findsOneWidget);

    // 6. Verify buttons and interactive actions
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    // 7. Verify password visibility toggle (initially obscured)
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    // 8. Tap Forgot Password
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Password reset instructions sent to your email.'), findsOneWidget);
  });
}
