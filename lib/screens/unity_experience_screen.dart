import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/services/theatre_unity_bridge.dart';

/// Embeds the Unity WebGL "seat experience" venue inside an iframe, and
/// bridges messages between Flutter and Unity.
///
/// [theatre] is the real Flutter -> Unity data connection: when provided,
/// this screen sends the theatre's actual configured room/screen/seating
/// numbers to Unity (via TheatreUnityBridge) BEFORE sending the seat
/// command, and waits for Unity to confirm it applied them
/// ('configuration_loaded') before proceeding — so the venue the user
/// actually sees is regenerated to match what its admin configured,
/// instead of whatever numbers happen to be set on Unity's own scene.
///
/// [theatre] is optional and defaults to null so the older demo-data flow
/// (lib/screens/seat_selection_screen.dart, which has no real
/// TheatreConfiguration to send) keeps working completely unchanged —
/// with theatre == null, this behaves exactly as it did before: send
/// 'experience_seat:<id>' the moment Unity reports ready, nothing else.
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
  final TheatreConfiguration? theatre;

  const UnityExperienceScreen({super.key, required this.seatLabel, this.theatre});

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
  bool _configSent = false;
  bool _configAcked = false;
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
      _trySendConfiguration();
      _trySendExperienceCommand();
    } else if (data == 'configuration_loaded') {
      _configAcked = true;
      _trySendExperienceCommand();
    } else if (data.startsWith('experience_exited')) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _trySendConfiguration() {
    if (_configSent || !_unityReady || widget.theatre == null) return;
    _configSent = true;
    final json = TheatreUnityBridge.toUnityVenueParametersJson(widget.theatre!);
    _iframe.contentWindow?.postMessage('load_configuration:$json', '*');
  }

  void _trySendExperienceCommand() {
    if (_commandSent || !_unityReady) return;
    // If a real theatre was provided, don't send the seat command until
    // Unity has actually applied that configuration — otherwise the
    // camera could arrive at a seat position computed from the WRONG
    // (Unity's own default) room dimensions.
    if (widget.theatre != null && !_configAcked) return;

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
