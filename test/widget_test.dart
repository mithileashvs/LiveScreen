import 'package:flutter_test/flutter_test.dart';

import 'package:livescreen/main.dart';

void main() {
  testWidgets('LiveScreen app builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LiveScreenApp());
    // Just confirms the app builds successfully — no specific UI checks yet.
    expect(find.byType(LiveScreenApp), findsOneWidget);
  });
}
