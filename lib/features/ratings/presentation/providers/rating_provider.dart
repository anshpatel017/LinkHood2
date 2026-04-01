import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/rating_repository.dart';
import '../../data/repositories/rating_repository_impl.dart';

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RatingRepositoryImpl(client);
});

final hasRatedProvider = FutureProvider.family<bool, String>((ref, rentalId) async {
  final repo = ref.watch(ratingRepositoryProvider);
  return repo.hasRated(rentalId);
});

final ratingControllerProvider = Provider<RatingController>((ref) {
  return RatingController(ref);
});

class RatingController {
  final Ref _ref;
  RatingController(this._ref);

  Future<void> submitRating({
    required String rentalId,
    required String rateeId,
    required int score,
    String? comment,
  }) async {
    final repo = _ref.read(ratingRepositoryProvider);
    await repo.submitRating(
      rentalId: rentalId,
      rateeId: rateeId,
      score: score,
      comment: comment,
    );
    // Refresh the check
    _ref.invalidate(hasRatedProvider(rentalId));
  }
}
