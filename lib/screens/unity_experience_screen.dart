import 'package:flutter/material.dart';
import '../admin/models/movie_content.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/services/theatre_unity_bridge.dart';
import '../shared/platform/unity_iframe_bridge_stub.dart'
    if (dart.library.html) '../shared/platform/unity_iframe_bridge_web.dart';

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
/// [theatre] is REQUIRED but nullable, on purpose. It used to be optional
/// with a null default, and three call sites simply forgot to pass it —
/// which is the single biggest reason every theatre showed the same demo
/// room: with theatre == null this screen never sends a configuration at
/// all, so Unity keeps SampleScene's own VenueParameters. Making it
/// required means the analyzer forces every new call site to state, out
/// loud, which of the two cases it is:
///
///   * a REAL theatre  -> pass the TheatreConfiguration. Never null.
///   * a DEMO-DATA flow -> pass null explicitly, and the screen shows a
///     visible "Demo venue" badge so nobody mistakes the generic
///     auditorium for the theatre they actually booked.
///
/// IMPORTANT: each time this screen opens, it registers a brand-new,
/// uniquely-named iframe. Without this, re-opening the experience for a
/// second seat would silently reuse the very first iframe (already past
/// its "exited" state), so the new seat command never actually reaches a
/// live Unity instance. A small trade-off: Unity reloads fully each time
/// rather than being reused — a future optimization can keep one Unity
/// instance alive across seat picks instead.
///
/// WHY THE IFRAME/POSTMESSAGE WORK IS BEHIND A CONDITIONAL IMPORT
///
/// This used to call dart:html/dart:ui_web directly. That's fine for every
/// real build/run of this app, but this file is reachable from
/// lib/main.dart's route table, so `flutter test` (the Dart VM, where
/// dart:html doesn't exist) failed to even compile it — including for
/// tests that never construct this screen. ../shared/platform/
/// unity_iframe_bridge_*.dart isolates the iframe creation and
/// window.postMessage bridging behind `UnityIframeBridge`, so this screen
/// — and anything that merely imports it — compiles on both platforms. The
/// real (_web) implementation is always what real builds use; the VM-only
/// stub throws if it's ever actually constructed, rather than silently
/// pretending to work.
/// [movie] follows the same REQUIRED-but-nullable convention as [theatre],
/// for the same reason: it forces every call site to state out loud
/// whether there's a real movie behind this seat, rather than letting the
/// Watch Trailer affordance silently vanish because a new call site forgot
/// to wire it up. Pass null only for flows that genuinely have no movie
/// context (e.g. a demo-data booking) — the Watch Trailer button below
/// simply doesn't render in that case.
class UnityExperienceScreen extends StatefulWidget {
  final String seatLabel;
  final TheatreConfiguration? theatre;
  final MovieContent? movie;

  const UnityExperienceScreen({
    super.key,
    required this.seatLabel,
    required this.theatre,
    required this.movie,
  });

  @override
  State<UnityExperienceScreen> createState() => _UnityExperienceScreenState();
}

class _UnityExperienceScreenState extends State<UnityExperienceScreen> {
  // A counter that increases every time this screen is created, guaranteeing
  // a unique view type per visit instead of colliding with a previous one.
  static int _instanceCounter = 0;

  late final String _viewType;
  late final UnityIframeBridge _bridge;
  final GlobalKey<WatchTrailerInTheatreButtonState> _trailerButtonKey =
      GlobalKey<WatchTrailerInTheatreButtonState>();
  bool _unityReady = false;
  bool _configSent = false;
  bool _configAcked = false;
  bool _commandSent = false;

  /// Set when Unity reports it could not apply the configuration. Shown to
  /// the user instead of silently dropping them into a theatre that is not
  /// the one they selected.
  String? _configError;

  /// What Unity reported it actually built, echoed back in the ack. Useful
  /// for confirming Theatre A and Theatre B really did produce different
  /// venues rather than the same default room.
  String? _appliedSummary;

  @override
  void initState() {
    super.initState();

    _instanceCounter++;
    _viewType = 'unity-venue-iframe-$_instanceCounter';

    _bridge = UnityIframeBridge(
      src: 'unity_venue/index.html',
      viewType: _viewType,
      onMessage: _handleMessageFromUnity,
    );
  }

  @override
  void dispose() {
    try {
      _bridge.postMessage('stop_trailer');
    } catch (_) {}
    _bridge.dispose();
    super.dispose();
  }

  void _handleMessageFromUnity(String data) {
    if (data == 'unity_ready') {
      _unityReady = true;
      _trySendConfiguration();
      _trySendExperienceCommand();
    } else if (data.startsWith('configuration_loaded')) {
      // Ack format: configuration_loaded:<theatreId>:<seatCount>:<speakerCount>
      // (a bare 'configuration_loaded' from an older Unity build still works).
      final parts = data.split(':');
      if (parts.length >= 4) {
        _appliedSummary = 'theatre ${parts[1]} · ${parts[2]} seats · ${parts[3]} speakers';
        if (widget.theatre != null && parts[1] != widget.theatre!.id) {
          // Unity built a different theatre than the one requested. Loud,
          // because this is exactly the class of bug where a user ends up
          // looking at someone else's venue and nothing says so.
          debugPrint(
            'UnityExperienceScreen: requested theatre ${widget.theatre!.id} '
            'but Unity reports it applied ${parts[1]}.',
          );
        }
      }
      debugPrint('UnityExperienceScreen: Unity applied ${_appliedSummary ?? data}');
      _configAcked = true;
      _trySendExperienceCommand();
    } else if (data.startsWith('configuration_failed')) {
      final reason = data.contains(':') ? data.split(':').last : 'unknown';
      if (mounted) {
        setState(() {
          _configError =
              'This theatre\'s 3D configuration could not be loaded ($reason), '
              'so the immersive view was not opened.';
        });
      }
    } else if (data.startsWith('configuration_warning')) {
      final parts = data.split(':');
      final detail = parts.length >= 3 ? parts.sublist(2).join(':') : data;
      debugPrint('UnityExperienceScreen: Unity configuration warning — $detail');
    } else if (data.startsWith('experience_exited')) {
      if (mounted) Navigator.of(context).pop();
    } else if (data.startsWith('trailer_')) {
      // trailer_loading / trailer_ready / trailer_started / trailer_stopped
      // / trailer_error:<reason> — see TrailerScreenPlayer.cs.
      _trailerButtonKey.currentState?.handleUnityEvent(data);
    }
  }

  void _trySendConfiguration() {
    if (_configSent || !_unityReady || widget.theatre == null) return;
    _configSent = true;
    final json = TheatreUnityBridge.toUnityTheatreConfigJson(widget.theatre!);
    _bridge.postMessage('load_configuration:$json');
  }

  void _trySendExperienceCommand() {
    if (_commandSent || !_unityReady) return;
    // If a real theatre was provided, don't send the seat command until
    // Unity has actually applied that configuration — otherwise the
    // camera could arrive at a seat position computed from the WRONG
    // (Unity's own default) room dimensions.
    if (widget.theatre != null && !_configAcked) return;

    _commandSent = true;
    _bridge.postMessage('experience_seat:${widget.seatLabel}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _configError != null
            ? _ConfigurationErrorView(
                message: _configError!,
                onBack: () => Navigator.of(context).pop(),
              )
            : Column(
                children: [
                  // Deliberately OUTSIDE the Stack below, in ordinary
                  // layout flow rather than Positioned over the iframe.
                  // The iframe is a real browser element occupying the
                  // whole screen; a Flutter widget merely stacked "on top"
                  // of it can end up with its taps intercepted by the
                  // iframe instead — this bar's bounds never overlap the
                  // iframe's at all, so that can't happen here.
                  if (widget.movie != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: WatchTrailerInTheatreButton(
                          key: _trailerButtonKey,
                          movie: widget.movie!,
                          sendToUnity: _bridge.postMessage,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: HtmlElementView(viewType: _viewType)),
                        // Demo-data flows pass theatre: null deliberately.
                        // Say so on screen rather than letting a generic
                        // auditorium pass itself off as the user's actual
                        // theatre.
                        if (widget.theatre == null)
                          const Positioned(
                            top: 12,
                            left: 12,
                            child: _DemoVenueBadge(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Small pill button that plays [movie]'s trailer. Two different things
/// can happen when it's tapped, and the button doesn't need to know which
/// in advance — [TrailerSource.parse] decides:
///
///   * A direct video file -> sent to Unity (via [sendToUnity], the same
///     postMessage/SendMessage bridge already used for seat selection and
///     theatre configuration) to play ON the generated cinema screen
///     itself, via TrailerScreenPlayer.cs. This is the "how will the movie
///     actually look from this seat" experience.
///   * Anything else (YouTube, Vimeo, missing, unsupported) -> the same
///     full-screen TrailerScreen.open overlay every other Watch Trailer
///     button in the app uses. A WebGL mesh can only ever display a
///     decoded video texture — there's no way to put an embedded
///     YouTube/Vimeo *player* (itself a whole web page) onto a 3D
///     surface, so these can never play in-scene no matter what.
class WatchTrailerInTheatreButton extends StatefulWidget {
  final MovieContent movie;
  final void Function(String message) sendToUnity;

  const WatchTrailerInTheatreButton({super.key, required this.movie, required this.sendToUnity});

  @override
  State<WatchTrailerInTheatreButton> createState() => WatchTrailerInTheatreButtonState();
}

class WatchTrailerInTheatreButtonState extends State<WatchTrailerInTheatreButton> {
  bool _playingOnScreen = false;
  bool _loading = false;

  void _handleTap() {
    final immersiveUrl = widget.movie.immersiveTrailerUrl.trim();

    if (immersiveUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Immersive 3D trailer is not available for this movie.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_playingOnScreen || _loading) {
      widget.sendToUnity('stop_trailer');
      setState(() {
        _playingOnScreen = false;
        _loading = false;
      });
      return;
    }

    debugPrint(
      'UnityExperienceScreen: Watch Trailer tapped for "${widget.movie.title}" — '
      'sending play_trailer to Unity cinema screen with immersive URL: $immersiveUrl',
    );

    widget.sendToUnity('play_trailer:$immersiveUrl');
    // Optimistic loading state until Unity confirms trailer_ready/started
    setState(() => _loading = true);
  }

  /// Called by [UnityExperienceScreen] for every 'trailer_*' message from
  /// Unity — see TrailerScreenPlayer.cs for exactly when each fires.
  void handleUnityEvent(String event) {
    if (!mounted) return;
    if (event == 'trailer_loading') {
      setState(() {
        _loading = true;
        _playingOnScreen = false;
      });
    } else if (event == 'trailer_ready' || event == 'trailer_started') {
      setState(() {
        _loading = false;
        _playingOnScreen = true;
      });
    } else if (event == 'trailer_stopped') {
      setState(() {
        _loading = false;
        _playingOnScreen = false;
      });
    } else if (event.startsWith('trailer_error')) {
      final reason = event.contains(':') ? event.split(':').last : 'unknown';
      setState(() {
        _loading = false;
        _playingOnScreen = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play the trailer on the cinema screen ($reason).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImmersive = widget.movie.immersiveTrailerUrl.trim().isNotEmpty;

    final String label;
    final IconData icon;
    final Color color;

    if (!hasImmersive) {
      label = 'Immersive trailer unavailable';
      icon = Icons.videocam_off_outlined;
      color = Colors.white54;
    } else if (_loading) {
      label = 'Loading Trailer…';
      icon = Icons.hourglass_top;
      color = const Color(0xFFD4AF37);
    } else if (_playingOnScreen) {
      label = 'Stop Trailer';
      icon = Icons.stop_circle_outlined;
      color = const Color(0xFFD4AF37);
    } else {
      label = 'Watch Trailer (In Theatre)';
      icon = Icons.play_circle_outline;
      color = const Color(0xFFD4AF37);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _loading ? null : _handleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when Unity explicitly reports it could not apply this theatre's
/// configuration. Deliberately a dead end rather than a fallback into the
/// generic venue: showing someone a theatre that isn't the one they picked,
/// with no indication of the substitution, is the failure this whole change
/// exists to remove.
class _ConfigurationErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _ConfigurationErrorView({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 40),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onBack, child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}

/// Small, deliberately unobtrusive badge shown only when this screen was
/// opened WITHOUT a real theatre configuration (the DemoData booking
/// chain). Uses the existing LiveScreen palette — no new design language.
class _DemoVenueBadge extends StatelessWidget {
  const _DemoVenueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37)),
      ),
      child: const Text(
        'DEMO VENUE · not a configured theatre',
        style: TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
