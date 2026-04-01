import '../../domain/entities/rating.dart';

class RatingModel extends Rating {
  const RatingModel({
    required super.id,
    required super.rentalId,
    required super.raterId,
    required super.rateeId,
    required super.score,
    super.comment,
    required super.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] as String,
      rentalId: json['rental_id'] as String,
      raterId: json['rater_id'] as String,
      rateeId: json['ratee_id'] as String,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
