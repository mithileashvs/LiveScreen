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

  /// YouTube trailer URL used for normal web playback.
  String trailerUrl;

  /// Supabase Storage public URL or direct MP4/WebM video asset used for
  /// playback on the cinema screen inside the Unity 3D venue.
  String immersiveTrailerUrl;

  /// Backward-compatible alias for [trailerUrl].
  String get trailerPath => trailerUrl;
  set trailerPath(String value) => trailerUrl = value;

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

  /// draft | submitted | under_review | approved | rejected — Platform
  /// Admin's content-approval decision, kept separate from [status] which
  /// only tracks publish state. A Producer may move this between draft and
  /// submitted themselves (see MovieRepository.submitForReview/
  /// withdrawFromReview); only Platform Admin can set under_review/
  /// approved/rejected, and [status] can never become 'published' unless
  /// this is 'approved' — both enforced again at the database in
  /// 0002_platform_admin_verification.sql regardless of what this object
  /// says.
  String approvalStatus;

  /// Set by Platform Admin when rejecting or requesting changes.
  String? reviewReason;

  /// Spoken language of the movie (e.g. Tamil, English, Hindi, Telugu).
  String language;

  /// Primary genre category (e.g. Drama, Action, Thriller, Sci-Fi).
  String genre;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  MovieContent({
    required this.id,
    this.title = '',
    String trailerUrl = '',
    String? trailerPath,
    this.immersiveTrailerUrl = '',
    this.thumbnail = '',
    this.description = '',
    this.durationSeconds = 0,
    this.producerId,
    this.status = 'draft',
    this.approvalStatus = 'draft',
    this.reviewReason,
    this.language = 'English',
    this.genre = 'Drama',
    this.createdAt,
    this.updatedAt,
  }) : trailerUrl = trailerUrl.isNotEmpty ? trailerUrl : (trailerPath ?? '');

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'trailerUrl': trailerUrl,
        'trailerPath': trailerUrl,
        'immersiveTrailerUrl': immersiveTrailerUrl,
        'thumbnail': thumbnail,
        'description': description,
        'durationSeconds': durationSeconds,
        'producerId': producerId,
        'status': status,
        'approvalStatus': approvalStatus,
        'reviewReason': reviewReason,
        'language': language,
        'genre': genre,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory MovieContent.fromJson(Map<String, dynamic> json) {
    return MovieContent(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      trailerUrl: (json['trailerUrl'] ?? json['trailerPath']) as String? ?? '',
      immersiveTrailerUrl: json['immersiveTrailerUrl'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      producerId: json['producerId'] as String?,
      status: json['status'] as String? ?? 'draft',
      approvalStatus: json['approvalStatus'] as String? ?? 'draft',
      reviewReason: json['reviewReason'] as String?,
      language: json['language'] as String? ?? 'English',
      genre: json['genre'] as String? ?? 'Drama',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : (json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null),
    );
  }
}
