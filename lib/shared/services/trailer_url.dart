/// Works out what a saved `movies.trailer_path` value actually IS, and what
/// URL can play it.
///
/// Deliberately pure Dart — no Flutter, no dart:html — so the rules below
/// are unit-testable and so the "what do we support?" question has exactly
/// one answer in the codebase instead of being re-guessed at every call
/// site.
///
/// WHAT IS SUPPORTED, AND WHY ONLY THIS
///
/// The Producer field is labelled "Trailer Path / URL" and is a free-text
/// box, so the saved value is whatever a producer typed. Rather than
/// pretending every string is playable, this classifies into the three
/// things the app can genuinely play in a browser today:
///
///   * YouTube  -> the standard privacy-friendly embed player
///   * Vimeo    -> the standard Vimeo embed player
///   * a direct video file (.mp4/.webm/.ogv/.ogg/.mov/.m4v) -> the
///     browser's own <video> element, which Flutter Web can host without
///     any extra package
///
/// Anything else is reported as unsupported WITH a reason, so the user
/// sees a clear message instead of a blank frame. No new dependency is
/// needed for any of the above.
enum TrailerKind {
  /// Plays in an iframe using the provider's embed player.
  youtube,
  vimeo,

  /// Plays in a plain HTML <video> element.
  directFile,

  /// Nothing was saved for this movie.
  missing,

  /// Something was saved, but it isn't a form that can be played.
  unsupported,
}

/// The result of classifying a saved trailer value.
class TrailerSource {
  final TrailerKind kind;

  /// The original saved value, untouched — useful for showing the user
  /// exactly what is stored when it turns out to be unplayable.
  final String rawValue;

  /// The URL to actually load. Empty for [TrailerKind.missing] and
  /// [TrailerKind.unsupported].
  final String playbackUrl;

  /// A plain-language explanation, set only when playback isn't possible.
  final String? problem;

  const TrailerSource._({
    required this.kind,
    required this.rawValue,
    this.playbackUrl = '',
    this.problem,
  });

  bool get isPlayable =>
      kind == TrailerKind.youtube ||
      kind == TrailerKind.vimeo ||
      kind == TrailerKind.directFile;

  /// True when the player should use an <iframe> rather than <video>.
  bool get usesEmbedFrame =>
      kind == TrailerKind.youtube || kind == TrailerKind.vimeo;

  /// Name of the provider, for UI labels. Empty when not applicable.
  String get providerLabel {
    switch (kind) {
      case TrailerKind.youtube:
        return 'YouTube';
      case TrailerKind.vimeo:
        return 'Vimeo';
      case TrailerKind.directFile:
        return 'Video file';
      case TrailerKind.missing:
      case TrailerKind.unsupported:
        return '';
    }
  }

  /// Video file extensions a browser's own <video> element can be relied on
  /// to handle. `.mov`/`.m4v` are included because they are usually H.264
  /// in practice, but the browser is still the final arbiter — if it can't
  /// decode one, the player surfaces the element's own error rather than
  /// this class guessing.
  static const _videoExtensions = <String>[
    '.mp4',
    '.webm',
    '.ogv',
    '.ogg',
    '.mov',
    '.m4v',
  ];

  /// YouTube IDs are 11 characters in practice; the range is widened
  /// slightly so a legitimate but unusual ID isn't rejected outright.
  static final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{6,20}$');
  static final _vimeoId = RegExp(r'^\d{6,12}$');

  /// Classifies [rawValue] — the value saved in `movies.trailer_path`.
  static TrailerSource parse(String? rawValue) {
    final value = (rawValue ?? '').trim();

    if (value.isEmpty) {
      return const TrailerSource._(
        kind: TrailerKind.missing,
        rawValue: '',
        problem: 'No trailer has been added for this movie yet.',
      );
    }

    String effectiveValue = value;
    if (!value.contains('://')) {
      final lower = value.toLowerCase();
      if (lower.startsWith('youtube.com/') ||
          lower.startsWith('www.youtube.com/') ||
          lower.startsWith('youtu.be/') ||
          lower.startsWith('m.youtube.com/')) {
        effectiveValue = 'https://$value';
      } else if (lower.startsWith('//')) {
        effectiveValue = 'https:$value';
      } else {
        if (_hasVideoExtension(value)) {
          return TrailerSource._(
            kind: TrailerKind.directFile,
            rawValue: value,
            playbackUrl: value,
          );
        }
        return TrailerSource._(
          kind: TrailerKind.unsupported,
          rawValue: value,
          problem:
              'This looks like a file path rather than a web address, and it '
              'does not end in a playable video format '
              '(${_videoExtensions.join(', ')}).',
        );
      }
    }

    final uri = Uri.tryParse(effectiveValue);
    if (uri == null || !uri.hasAuthority) {
      return TrailerSource._(
        kind: TrailerKind.unsupported,
        rawValue: value,
        problem: 'The saved trailer address could not be read as a valid URL.',
      );
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return TrailerSource._(
        kind: TrailerKind.unsupported,
        rawValue: value,
        problem:
            'Only http and https trailer links can be played (found '
            '"${uri.scheme}").',
      );
    }

    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

    final youtubeId = _youtubeIdFrom(host, uri);
    if (youtubeId != null) {
      // youtube-nocookie serves the same player without setting tracking
      // cookies until playback starts. rel=0 keeps the end screen from
      // promoting unrelated videos inside our own product.
      return TrailerSource._(
        kind: TrailerKind.youtube,
        rawValue: value,
        playbackUrl:
            'https://www.youtube-nocookie.com/embed/$youtubeId?rel=0&modestbranding=1',
      );
    }

    final vimeoId = _vimeoIdFrom(host, uri);
    if (vimeoId != null) {
      return TrailerSource._(
        kind: TrailerKind.vimeo,
        rawValue: value,
        playbackUrl: 'https://player.vimeo.com/video/$vimeoId',
      );
    }

    if (_hasVideoExtension(uri.path)) {
      return TrailerSource._(
        kind: TrailerKind.directFile,
        rawValue: value,
        playbackUrl: value,
      );
    }

    // Recognising the host but not the shape of the link is worth saying
    // separately — "your YouTube link is the wrong kind of YouTube link"
    // is far more actionable than "unsupported".
    if (host.contains('youtube') || host == 'youtu.be') {
      return TrailerSource._(
        kind: TrailerKind.unsupported,
        rawValue: value,
        problem:
            'This is a YouTube address, but no video ID could be found in it. '
            'Use a link like https://www.youtube.com/watch?v=VIDEOID or '
            'https://youtu.be/VIDEOID.',
      );
    }
    if (host.contains('vimeo')) {
      return TrailerSource._(
        kind: TrailerKind.unsupported,
        rawValue: value,
        problem:
            'This is a Vimeo address, but no video ID could be found in it. '
            'Use a link like https://vimeo.com/123456789.',
      );
    }

    return TrailerSource._(
      kind: TrailerKind.unsupported,
      rawValue: value,
      problem:
          'Trailers can be a YouTube link, a Vimeo link, or a direct video '
          'file (${_videoExtensions.join(', ')}). This link is none of those.',
    );
  }

  static bool _hasVideoExtension(String path) {
    final lower = path.toLowerCase();
    for (final extension in _videoExtensions) {
      if (lower.endsWith(extension)) return true;
    }
    return false;
  }

  static String? _youtubeIdFrom(String host, Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // https://youtu.be/VIDEOID
    if (host == 'youtu.be') {
      return segments.isNotEmpty && _youtubeId.hasMatch(segments.first)
          ? segments.first
          : null;
    }

    if (!host.endsWith('youtube.com') && !host.endsWith('youtube-nocookie.com')) {
      return null;
    }

    // https://www.youtube.com/watch?v=VIDEOID
    final queryId = uri.queryParameters['v'];
    if (queryId != null && _youtubeId.hasMatch(queryId)) return queryId;

    // https://www.youtube.com/embed/VIDEOID
    // https://www.youtube.com/shorts/VIDEOID
    // https://www.youtube.com/live/VIDEOID
    if (segments.length >= 2) {
      const idBearing = {'embed', 'shorts', 'live', 'v'};
      if (idBearing.contains(segments.first.toLowerCase()) &&
          _youtubeId.hasMatch(segments[1])) {
        return segments[1];
      }
    }

    return null;
  }

  static String? _vimeoIdFrom(String host, Uri uri) {
    if (!host.endsWith('vimeo.com')) return null;

    // Vimeo IDs are numeric, and the ID is the last numeric path segment —
    // which covers vimeo.com/123456789, player.vimeo.com/video/123456789
    // and channel/album style links alike.
    for (final segment in uri.pathSegments.reversed) {
      if (_vimeoId.hasMatch(segment)) return segment;
    }
    return null;
  }

  /// Validates a trailer URL input entered by a producer.
  ///
  /// Producer trailers are required to be YouTube URLs. Returns `null` if the
  /// input is valid or empty (when [allowEmpty] is true). If invalid, returns a
  /// user-friendly error message explaining why.
  static String? validateProducerYouTubeUrl(
    String? rawValue, {
    bool allowEmpty = true,
  }) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) {
      if (allowEmpty) return null;
      return 'Please provide a YouTube trailer URL.';
    }

    final source = parse(value);
    if (source.kind == TrailerKind.youtube) {
      return null;
    }

    if (source.kind == TrailerKind.directFile) {
      return 'Direct video files (.mp4/.webm) are not supported for producer trailers. '
          'Please provide a YouTube trailer URL (e.g. https://www.youtube.com/watch?v=... or https://youtu.be/...).';
    }

    if (source.kind == TrailerKind.vimeo) {
      return 'Vimeo links are not supported for producer trailers. '
          'Please provide a YouTube trailer URL.';
    }

    if (source.kind == TrailerKind.unsupported &&
        source.problem != null &&
        source.problem!.startsWith('This is a YouTube address')) {
      return source.problem;
    }

    return 'Please provide a valid YouTube trailer URL (e.g. https://www.youtube.com/watch?v=... or https://youtu.be/...).';
  }

  /// Validates a video file chosen by a producer for the immersive 3D trailer.
  ///
  /// Only `.mp4` and `.webm` files are accepted. Returns `null` if valid,
  /// or a user-facing error message: "Immersive trailer must be an MP4 or WebM video."
  static String? validateImmersiveVideoFile({
    required String fileName,
    String? mimeType,
  }) {
    final name = fileName.trim().toLowerCase();
    final hasAllowedExt = name.endsWith('.mp4') || name.endsWith('.webm');

    if (!hasAllowedExt) {
      return 'Immersive trailer must be an MP4 or WebM video.';
    }

    if (mimeType != null && mimeType.trim().isNotEmpty) {
      final mime = mimeType.trim().toLowerCase();
      // Allow video/mp4, video/webm, and generic octet-stream when extension is valid.
      final isAllowedMime = mime == 'video/mp4' ||
          mime == 'video/webm' ||
          mime == 'application/octet-stream';
      if (!isAllowedMime) {
        return 'Immersive trailer must be an MP4 or WebM video.';
      }
    }

    return null;
  }

  /// Low-level direct video URL validator for internal checks.
  static String? validateDirectVideoUrl(
    String? rawValue, {
    bool allowEmpty = true,
  }) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) {
      if (allowEmpty) return null;
      return 'Immersive trailer must be an MP4 or WebM video.';
    }

    final lower = value.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return 'Immersive trailer must be an MP4 or WebM video.';
    }

    final source = parse(value);
    if (source.kind == TrailerKind.directFile) {
      final uri = Uri.tryParse(value);
      final path = uri?.path.toLowerCase() ?? lower;
      if (path.endsWith('.mp4') || path.endsWith('.webm')) {
        return null;
      }
    }

    return 'Immersive trailer must be an MP4 or WebM video.';
  }
}
