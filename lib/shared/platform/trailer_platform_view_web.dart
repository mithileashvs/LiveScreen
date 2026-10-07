import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Registers [viewType] as a browser `<iframe>` (provider embeds) or
/// `<video>` element (direct files) pointing at [playbackUrl], exactly as
/// `trailer_player.dart` did inline before this was extracted — same
/// element configuration, same `onLoad`/`onCanPlay`/`onError` wiring — just
/// behind a small function so the widget itself no longer needs to import
/// dart:html directly (see trailer_platform_view_stub.dart for why).
void registerTrailerView({
  required String viewType,
  required String playbackUrl,
  required bool usesEmbedFrame,
  required void Function() onReady,
  required void Function(String message) onError,
}) {
  if (usesEmbedFrame) {
    final frame = html.IFrameElement()
      ..src = playbackUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      // Provider players need these to offer play/pause and fullscreen.
      ..allow = 'accelerometer; autoplay; encrypted-media; picture-in-picture'
      ..allowFullscreen = true;

    frame.onLoad.listen((_) => onReady());

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) => frame);
  } else {
    final video = html.VideoElement()
      ..src = playbackUrl
      // The browser's native controls give play/pause, scrubbing, volume
      // and fullscreen for free, and behave the way people already expect.
      ..controls = true
      ..autoplay = false
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#000';

    video.onCanPlay.listen((_) => onReady());
    video.onError.listen((_) => onError(
          'The video could not be loaded. The link may be broken, blocked '
          'by the host, or in a format this browser cannot play.',
        ));

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) => video);
  }
}
