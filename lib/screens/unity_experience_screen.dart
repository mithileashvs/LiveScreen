import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Embeds the Unity WebGL "seat experience" venue inside an iframe, and
/// bridges messages between Flutter and Unity.
///
/// IMPORTANT: each time this screen opens, it registers a brand-new,
/// uniquely-named iframe. Without this, re-opening the experience for a
/// second seat would silently reuse the very first iframe (already past
/// its "exited" state), so the new seat command never actually reaches a
/// live Unity instance. A small trade-off: Unity reloads fully each time
/// rather than being reused — a future optimization can keep one Unity
/// instance alive across seat picks instead.
class UnityExperienceScreen extends StatefulWidget {
  final String seatLabel;

  const UnityExperienceScreen({super.key, required this.seatLabel});

  @override
  State<UnityExperienceScreen> createState() => _UnityExperienceScreenState();
}

class _UnityExperienceScreenState extends State<UnityExperienceScreen> {
  // A counter that increases every time this screen is created, guaranteeing
  // a unique view type per visit instead of colliding with a previous one.
  static int _instanceCounter = 0;

  late final String _viewType;
  late final html.IFrameElement _iframe;
  bool _unityReady = false;
  bool _commandSent = false;

  @override
  void initState() {
    super.initState();

    _instanceCounter++;
    _viewType = 'unity-venue-iframe-$_instanceCounter';

    _iframe = html.IFrameElement()
      ..src = 'unity_venue/index.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'autoplay';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _iframe);

    html.window.onMessage.listen(_handleMessageFromUnity);
  }

  void _handleMessageFromUnity(html.MessageEvent event) {
    final data = event.data;
    if (data is! String) return;

    if (data == 'unity_ready') {
      _unityReady = true;
      _trySendExperienceCommand();
    } else if (data.startsWith('experience_exited')) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _trySendExperienceCommand() {
    if (_commandSent || !_unityReady) return;
    _commandSent = true;
    _iframe.contentWindow?.postMessage('experience_seat:${widget.seatLabel}', '*');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
