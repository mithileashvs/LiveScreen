// This is not the default counter-app smoke test — it pumps the real
// [LiveScreenApp], which is the correct thing to do to catch startup
// regressions. LiveScreenApp's route table reaches every screen in the
// app, including UnityExperienceScreen and TrailerPlayer, both of which
// use browser APIs for the Unity WebGL iframe and for HTML trailer
// playback. Those two now reach dart:html/dart:ui_web only through a
// conditional import (see lib/shared/platform/*_stub.dart vs *_web.dart),
// so this file's import graph compiles on the Dart VM too — the actual
// browser code is simply never selected there, and nothing in this test
// constructs either widget, so nothing tries to call it.
//
// `@TestOn('browser')` is kept anyway: this is fundamentally a
// full-app-startup test for a web app, so it belongs in the browser run.
// Under plain `flutter test` (VM) it's skipped; it runs for real under a
// browser platform run.
//
// NOTE ON THE FLAG: `flutter test -d chrome` does not appear to select
// the browser test platform for this project/SDK — both a plain
// `flutter test` and a `flutter test -d chrome` run failed identically,
// retrying under `-p vm`. The documented flag for this is
// `flutter test --platform chrome` (`-d <device>` is a `flutter run`/
// `flutter drive` flag). Use that instead if this still doesn't run.
@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:livescreen/main.dart';

void main() {
  testWidgets('LiveScreen app builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LiveScreenApp());
    // Just confirms the app builds successfully — no specific UI checks yet.
    expect(find.byType(LiveScreenApp), findsOneWidget);
  });
}
