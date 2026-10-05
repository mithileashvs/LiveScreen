/// VM-safe stand-in for [registerTrailerView].
///
/// Selected only when `dart.library.html` isn't available — the Dart VM
/// `flutter test` compiles against by default, and never true for a real
/// build/run of this app. See unity_iframe_bridge_stub.dart for the full
/// rationale; the same reasoning applies here. If this is ever actually
/// called on the VM, it throws rather than pretending to have registered a
/// playable view.
void registerTrailerView({
  required String viewType,
  required String playbackUrl,
  required bool usesEmbedFrame,
  required void Function() onReady,
  required void Function(String message) onError,
}) {
  throw UnsupportedError(
    'Trailer playback requires a web browser (dart:html unavailable on '
    'this platform). This should never be called outside a web build/run.',
  );
}
