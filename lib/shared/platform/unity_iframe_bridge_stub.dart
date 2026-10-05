/// VM-safe stand-in for [UnityIframeBridge].
///
/// This file is only ever selected by the conditional import in
/// unity_experience_screen.dart when `dart.library.html` is NOT available —
/// which is exactly the Dart VM `flutter test` compiles against by default,
/// and never true for an actual build/run of this app (`flutter build web`,
/// `flutter run -d chrome`, `flutter test --platform chrome` all compile
/// against the web target, where unity_iframe_bridge_web.dart is used
/// instead).
///
/// Its only job is to give `UnityExperienceScreen` something with the same
/// shape to compile against on the VM, so that files elsewhere in the app
/// that merely *import* unity_experience_screen.dart (without ever
/// constructing it) — like lib/main.dart's route table — can still be
/// compiled by `flutter test`. It deliberately does not pretend to work:
/// if anything ever actually constructs this on the VM, it throws
/// immediately rather than silently no-op'ing, so a real problem can never
/// be masked by this stub.
class UnityIframeBridge {
  UnityIframeBridge({
    required String src,
    required String viewType,
    required void Function(String message) onMessage,
  }) {
    throw UnsupportedError(
      'UnityIframeBridge requires a web browser (dart:html unavailable on '
      'this platform). This should never be constructed outside a web '
      'build/run.',
    );
  }

  void postMessage(String message) {
    throw UnsupportedError('UnityIframeBridge is web-only.');
  }

  void dispose() {}
}
