/// A minimal theatre + movie + time slot (spec: "do not overbuild
/// scheduling yet"). Shared between the Admin Studio (creates shows) and
/// the User-facing catalog (reads them) — one model, one table.
class ShowModel {
  final String id;
  final String theatreId;
  final String? movieId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // draft | published | cancelled | completed
  final double price;

  const ShowModel({
    required this.id,
    required this.theatreId,
    this.movieId,
    required this.startTime,
    this.endTime,
    this.status = 'draft',
    this.price = 0,
  });

  factory ShowModel.fromRow(Map<String, dynamic> row) {
    return ShowModel(
      id: row['id'] as String,
      theatreId: row['theatre_id'] as String,
      movieId: row['movie_id'] as String?,
      startTime: DateTime.parse(row['start_time'] as String),
      endTime: row['end_time'] == null ? null : DateTime.parse(row['end_time'] as String),
      status: row['status'] as String? ?? 'draft',
      price: (row['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
