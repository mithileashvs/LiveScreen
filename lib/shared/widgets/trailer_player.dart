import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../platform/trailer_platform_view_stub.dart'
    if (dart.library.html) '../platform/trailer_platform_view_web.dart';
import '../services/trailer_url.dart';

/// Plays a movie trailer inside the app.
///
/// WHY NO PACKAGE
///
/// pubspec.yaml has no video dependency, and this app is already web-only
/// (lib/screens/unity_experience_screen.dart uses browser APIs and is
/// reachable from the main navigation). On the web, `video_player` and
/// `youtube_player_iframe` both end up doing exactly what this does —
/// hosting an <iframe> or a <video> element through platformViewRegistry.
/// Adding a package here would buy indirection, not capability, so this
/// uses the platform view mechanism the project already established for
/// Unity. If the app ever ships to mobile, THAT is the point at which a
/// package earns its place.
///
/// Both element types are created once in initState and registered under a
/// unique view type, for the same reason UnityExperienceScreen does it:
/// reusing a view type across screen instances silently rebinds the second
/// screen to the first screen's dead element.
///
/// WHY THE PLATFORM VIEW REGISTRATION IS BEHIND A CONDITIONAL IMPORT
///
/// It used to call dart:html/dart:ui_web directly. That's fine for every
/// real build/run of this app (flutter build web, flutter run -d chrome,
/// flutter test --platform chrome), but lib/main.dart's route table
/// reaches this file, so `flutter test` (the Dart VM, where dart:html
/// doesn't exist) failed to even compile it — including for tests that
/// never construct this widget. ../platform/trailer_platform_view_*.dart
/// isolates just the handful of lines that actually touch dart:html/
/// dart:ui_web behind `registerTrailerView`, so this widget — and anything
/// that merely imports it — compiles on both platforms. The real (_web)
/// implementation is always what real builds use; the VM-only stub throws
/// if it's ever actually called, rather than silently pretending to work.
class TrailerPlayer extends StatefulWidget {
  final TrailerSource source;

  const TrailerPlayer({super.key, required this.source});

  @override
  State<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends State<TrailerPlayer> {
  static int _instanceCounter = 0;

  late final String _viewType;
  bool _loading = true;

  /// Set when the browser itself reports it cannot play the file — a dead
  /// link, a 404, or a codec it doesn't support. Only direct-file playback
  /// can report this; an iframe's internal failures belong to the provider
  /// and aren't visible to us.
  String? _playbackError;

  @override
  void initState() {
    super.initState();

    _instanceCounter++;
    _viewType = 'trailer-player-$_instanceCounter';

    final source = widget.source;

    registerTrailerView(
      viewType: _viewType,
      playbackUrl: source.playbackUrl,
      usesEmbedFrame: source.usesEmbedFrame,
      onReady: () {
        if (mounted) setState(() => _loading = false);
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _playbackError = message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_playbackError != null) {
      return _TrailerMessage(
        icon: Icons.videocam_off_rounded,
        message: _playbackError!,
        detail: widget.source.rawValue,
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: HtmlElementView(viewType: _viewType)),
        if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          ),
      ],
    );
  }
}

/// Full-screen trailer view. Opened as a normal route so the back button,
/// deep links and the existing navigation stack all keep working — and so
/// leaving the trailer can never disturb the booking/showtime flow beneath
/// it.
class TrailerScreen extends StatelessWidget {
  final String movieTitle;
  final TrailerSource source;

  const TrailerScreen({
    super.key,
    required this.movieTitle,
    required this.source,
  });

  /// Opens the trailer for [rawTrailerPath], or explains why it can't be
  /// played. Single entry point so every screen handles missing and invalid
  /// trailers identically.
  static void open(
    BuildContext context, {
    required String movieTitle,
    required String? rawTrailerPath,
  }) {
    final source = TrailerSource.parse(rawTrailerPath);

    if (!source.isPlayable) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Trailer unavailable', style: AppTextStyles.subheading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source.problem ?? 'This trailer cannot be played.',
                style: AppTextStyles.body,
              ),
              if (source.rawValue.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Saved value: ${source.rawValue}', style: AppTextStyles.caption),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrailerScreen(movieTitle: movieTitle, source: source),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          movieTitle.isEmpty ? 'Trailer' : '$movieTitle — Trailer',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: TrailerPlayer(source: source),
          ),
        ),
      ),
    );
  }
}

class _TrailerMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String detail;

  const _TrailerMessage({
    required this.icon,
    required this.message,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white54, size: 40),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
