import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/shared/services/trailer_url.dart';

/// Covers the three scenarios the task calls out explicitly: a valid
/// trailer URL, a missing one, and an invalid one — plus the provider
/// link shapes a Producer is realistically going to paste in.
void main() {
  group('valid trailer URLs', () {
    test('youtube watch link resolves to an embed URL', () {
      final source =
          TrailerSource.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(source.kind, TrailerKind.youtube);
      expect(source.isPlayable, isTrue);
      expect(source.playbackUrl, contains('/embed/dQw4w9WgXcQ'));
    });

    test('youtu.be short link resolves to the same video id', () {
      final source = TrailerSource.parse('https://youtu.be/dQw4w9WgXcQ');
      expect(source.kind, TrailerKind.youtube);
      expect(source.playbackUrl, contains('dQw4w9WgXcQ'));
    });

    test('youtube link with extra query parameters still resolves', () {
      final source = TrailerSource.parse(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s&list=PLabc');
      expect(source.kind, TrailerKind.youtube);
      expect(source.playbackUrl, contains('dQw4w9WgXcQ'));
    });

    test('youtube embed and shorts links resolve', () {
      expect(
        TrailerSource.parse('https://www.youtube.com/embed/dQw4w9WgXcQ').kind,
        TrailerKind.youtube,
      );
      expect(
        TrailerSource.parse('https://www.youtube.com/shorts/dQw4w9WgXcQ').kind,
        TrailerKind.youtube,
      );
    });

    test('vimeo link resolves to the player URL', () {
      final source = TrailerSource.parse('https://vimeo.com/123456789');
      expect(source.kind, TrailerKind.vimeo);
      expect(source.playbackUrl, 'https://player.vimeo.com/video/123456789');
    });

    test('direct mp4 URL plays as a file, unchanged', () {
      const url = 'https://cdn.example.com/trailers/movie.mp4';
      final source = TrailerSource.parse(url);
      expect(source.kind, TrailerKind.directFile);
      expect(source.playbackUrl, url);
    });

    test('relative path to a video file is treated as a file', () {
      final source = TrailerSource.parse('assets/trailers/movie.webm');
      expect(source.kind, TrailerKind.directFile);
      expect(source.isPlayable, isTrue);
    });

    test('surrounding whitespace is tolerated', () {
      final source =
          TrailerSource.parse('  https://youtu.be/dQw4w9WgXcQ  ');
      expect(source.kind, TrailerKind.youtube);
    });

    test('scheme-less youtube links resolve', () {
      expect(
        TrailerSource.parse('youtube.com/watch?v=dQw4w9WgXcQ').kind,
        TrailerKind.youtube,
      );
      expect(
        TrailerSource.parse('www.youtube.com/watch?v=dQw4w9WgXcQ').kind,
        TrailerKind.youtube,
      );
      expect(
        TrailerSource.parse('youtu.be/dQw4w9WgXcQ').kind,
        TrailerKind.youtube,
      );
    });
  });

  group('missing trailer', () {
    test('null is missing, not an error', () {
      final source = TrailerSource.parse(null);
      expect(source.kind, TrailerKind.missing);
      expect(source.isPlayable, isFalse);
      expect(source.problem, isNotNull);
    });

    test('empty and whitespace-only values are missing', () {
      expect(TrailerSource.parse('').kind, TrailerKind.missing);
      expect(TrailerSource.parse('   ').kind, TrailerKind.missing);
    });
  });

  group('invalid trailer', () {
    test('a non-video web page is unsupported, with a reason', () {
      final source = TrailerSource.parse('https://example.com/about-the-film');
      expect(source.kind, TrailerKind.unsupported);
      expect(source.isPlayable, isFalse);
      expect(source.problem, isNotNull);
    });

    test('non-http schemes are rejected', () {
      final source = TrailerSource.parse('ftp://example.com/movie.mp4');
      expect(source.kind, TrailerKind.unsupported);
      expect(source.problem, contains('ftp'));
    });

    test('a youtube URL with no video id gets a youtube-specific message', () {
      final source = TrailerSource.parse('https://www.youtube.com/');
      expect(source.kind, TrailerKind.unsupported);
      expect(source.problem, contains('YouTube'));
    });

    test('plain text is unsupported and keeps the raw value for display', () {
      final source = TrailerSource.parse('coming soon');
      expect(source.kind, TrailerKind.unsupported);
      expect(source.rawValue, 'coming soon');
    });
  });

  group('validateProducerYouTubeUrl', () {
    test('accepts valid YouTube links', () {
      expect(
        TrailerSource.validateProducerYouTubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        isNull,
      );
      expect(
        TrailerSource.validateProducerYouTubeUrl('https://youtu.be/dQw4w9WgXcQ'),
        isNull,
      );
      expect(
        TrailerSource.validateProducerYouTubeUrl('https://www.youtube.com/embed/dQw4w9WgXcQ'),
        isNull,
      );
      expect(
        TrailerSource.validateProducerYouTubeUrl('youtube.com/watch?v=dQw4w9WgXcQ'),
        isNull,
      );
    });

    test('handles empty inputs according to allowEmpty', () {
      expect(TrailerSource.validateProducerYouTubeUrl(null, allowEmpty: true), isNull);
      expect(TrailerSource.validateProducerYouTubeUrl('', allowEmpty: true), isNull);
      expect(TrailerSource.validateProducerYouTubeUrl('   ', allowEmpty: true), isNull);

      expect(TrailerSource.validateProducerYouTubeUrl(null, allowEmpty: false), isNotNull);
      expect(TrailerSource.validateProducerYouTubeUrl('', allowEmpty: false), isNotNull);
    });

    test('rejects direct video files with helpful message', () {
      final error = TrailerSource.validateProducerYouTubeUrl('https://example.com/trailer.mp4');
      expect(error, isNotNull);
      expect(error, contains('Direct video files (.mp4/.webm) are not supported'));
      expect(error, contains('YouTube trailer URL'));
    });

    test('rejects Vimeo links with helpful message', () {
      final error = TrailerSource.validateProducerYouTubeUrl('https://vimeo.com/123456789');
      expect(error, isNotNull);
      expect(error, contains('Vimeo links are not supported'));
      expect(error, contains('YouTube trailer URL'));
    });

    test('rejects arbitrary web links and invalid YouTube URLs', () {
      final error1 = TrailerSource.validateProducerYouTubeUrl('https://example.com/movie');
      expect(error1, isNotNull);
      expect(error1, contains('valid YouTube'));

      final error2 = TrailerSource.validateProducerYouTubeUrl('https://www.youtube.com/');
      expect(error2, isNotNull);
      expect(error2, contains('video ID'));
    });
  });

  group('validateImmersiveVideoFile', () {
    test('accepts mp4 and webm files', () {
      expect(
        TrailerSource.validateImmersiveVideoFile(fileName: 'trailer.mp4', mimeType: 'video/mp4'),
        isNull,
      );
      expect(
        TrailerSource.validateImmersiveVideoFile(fileName: 'trailer.webm', mimeType: 'video/webm'),
        isNull,
      );
      expect(
        TrailerSource.validateImmersiveVideoFile(fileName: 'TRAILER.MP4'),
        isNull,
      );
      expect(
        TrailerSource.validateImmersiveVideoFile(fileName: 'my_movie_clip.webm'),
        isNull,
      );
    });

    test('rejects mov, avi, and mkv files', () {
      final errorMov = TrailerSource.validateImmersiveVideoFile(
        fileName: 'trailer.mov',
        mimeType: 'video/quicktime',
      );
      expect(errorMov, isNotNull);
      expect(errorMov, 'Immersive trailer must be an MP4 or WebM video.');

      final errorAvi = TrailerSource.validateImmersiveVideoFile(
        fileName: 'trailer.avi',
        mimeType: 'video/x-msvideo',
      );
      expect(errorAvi, isNotNull);
      expect(errorAvi, 'Immersive trailer must be an MP4 or WebM video.');

      final errorMkv = TrailerSource.validateImmersiveVideoFile(
        fileName: 'trailer.mkv',
        mimeType: 'video/x-matroska',
      );
      expect(errorMkv, isNotNull);
      expect(errorMkv, 'Immersive trailer must be an MP4 or WebM video.');
    });

    test('rejects non-video files and mismatched MIME types', () {
      final errorPng = TrailerSource.validateImmersiveVideoFile(
        fileName: 'poster.png',
        mimeType: 'image/png',
      );
      expect(errorPng, 'Immersive trailer must be an MP4 or WebM video.');

      final errorPdf = TrailerSource.validateImmersiveVideoFile(
        fileName: 'script.pdf',
        mimeType: 'application/pdf',
      );
      expect(errorPdf, 'Immersive trailer must be an MP4 or WebM video.');

      final errorMimeMismatch = TrailerSource.validateImmersiveVideoFile(
        fileName: 'trailer.mp4',
        mimeType: 'audio/mp3',
      );
      expect(errorMimeMismatch, 'Immersive trailer must be an MP4 or WebM video.');
    });
  });

  group('validateDirectVideoUrl', () {
    test('accepts valid direct mp4 and webm URLs', () {
      expect(
        TrailerSource.validateDirectVideoUrl('https://example.com/trailer.mp4'),
        isNull,
      );
      expect(
        TrailerSource.validateDirectVideoUrl('https://storage.supabase.co/trailers/t.webm'),
        isNull,
      );
      expect(
        TrailerSource.validateDirectVideoUrl(null, allowEmpty: true),
        isNull,
      );
    });

    test('rejects YouTube URLs and non-video links', () {
      expect(
        TrailerSource.validateDirectVideoUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        isNotNull,
      );
      expect(
        TrailerSource.validateDirectVideoUrl('https://youtu.be/dQw4w9WgXcQ'),
        isNotNull,
      );
      expect(
        TrailerSource.validateDirectVideoUrl('https://vimeo.com/123456789'),
        isNotNull,
      );
      expect(
        TrailerSource.validateDirectVideoUrl('https://example.com/trailer.mov'),
        isNotNull,
      );
    });
  });
}
