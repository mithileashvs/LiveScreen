/// PART 10 (original) / shared-database task: this is now the ONE movie
/// record both the Producer dashboard and the Admin Studio's Movie tab
/// read/write — "do not create separate disconnected movie data for
/// Producer and Theatre Admin" — rather than two shape-alike-but-separate
/// models. `id`/`producerId`/`status` were added (all optional/defaulted,
/// so existing saved theatre configs with a locally-typed movie and no
/// producer link still load fine) to make that catalog possible:
/// - `producerId` is set when a Producer created this record; a theatre
///   admin who just types a movie in by hand instead leaves it null.
/// - `status` gates whether a theatre admin's Movie tab can see it in the
///   pick-from-catalog list (only `published` producer movies show there),
///   mirroring the same draft/published pattern as theatres.
class MovieContent {
  final String id;
  String title;
  String trailerPath;
  String thumbnail;
  String description;

  /// In seconds.
  int durationSeconds;

  /// Null when this record isn't (or isn't yet) tied to a Producer-owned
  /// catalog entry — e.g. a theatre admin typed it in directly.
  String? producerId;

  /// draft | published | archived — only meaningful when [producerId] is
  /// set; a plain string (not a shared enum) so this model doesn't have to
  /// import theatre_configuration.dart's TheatreStatus for an unrelated concept.
  String status;

  MovieContent({
    required this.id,
    this.title = '',
    this.trailerPath = '',
    this.thumbnail = '',
    this.description = '',
    this.durationSeconds = 0,
    this.producerId,
    this.status = 'draft',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'trailerPath': trailerPath,
        'thumbnail': thumbnail,
        'description': description,
        'durationSeconds': durationSeconds,
        'producerId': producerId,
        'status': status,
      };

  factory MovieContent.fromJson(Map<String, dynamic> json) {
    return MovieContent(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      trailerPath: json['trailerPath'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      producerId: json['producerId'] as String?,
      status: json['status'] as String? ?? 'draft',
    );
  }
}
