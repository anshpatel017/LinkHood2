class Rating {
  final String id;
  final String rentalId;
  final String raterId;
  final String rateeId;
  final int score;
  final String? comment;
  final DateTime createdAt;

  const Rating({
    required this.id,
    required this.rentalId,
    required this.raterId,
    required this.rateeId,
    required this.score,
    this.comment,
    required this.createdAt,
  });
}
