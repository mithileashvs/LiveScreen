import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Owns the Unity WebGL `<iframe>` and the `window.postMessage` bridge to
/// it. This is exactly the mechanism `unity_experience_screen.dart` used
/// directly before it was extracted here — same iframe configuration, same
/// `window.onMessage` wiring, same `postMessage` calls — just behind a
/// small interface so the screen itself no longer needs to import
/// dart:html directly (see unity_iframe_bridge_stub.dart for why).
class UnityIframeBridge {
  final html.IFrameElement _iframe;
  StreamSubscription<html.MessageEvent>? _subscription;

  UnityIframeBridge({
    required String src,
    required String viewType,
    required void Function(String message) onMessage,
  }) : _iframe = html.IFrameElement()
          ..src = src
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'autoplay' {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) => _iframe);

    _subscription = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is String) onMessage(data);
    });
  }

  void postMessage(String message) {
    _iframe.contentWindow?.postMessage(message, '*');
  }

  void dispose() {
    _subscription?.cancel();
  }
}
