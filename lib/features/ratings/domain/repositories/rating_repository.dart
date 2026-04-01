import '../entities/rating.dart';

abstract class RatingRepository {
  Future<Rating> submitRating({
    required String rentalId,
    required String rateeId,
    required int score,
    String? comment,
  });

  Future<bool> hasRated(String rentalId);
}
