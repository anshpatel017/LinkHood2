import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';
import '../models/rating_model.dart';
import 'package:uuid/uuid.dart';

class RatingRepositoryImpl implements RatingRepository {
  final supa.SupabaseClient _supabase;

  RatingRepositoryImpl(this._supabase);

  @override
  Future<Rating> submitRating({
    required String rentalId,
    required String rateeId,
    required int score,
    String? comment,
  }) async {
    try {
      final raterId = _supabase.auth.currentUser!.id;
      final response = await _supabase.from('ratings').insert({
        'id': const Uuid().v4(),
        'rental_id': rentalId,
        'rater_id': raterId,
        'ratee_id': rateeId,
        'score': score,
        'comment': comment,
      }).select().single();

      return RatingModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to submit rating: $e');
    }
  }

  @override
  Future<bool> hasRated(String rentalId) async {
    try {
      final raterId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('ratings')
          .select('id')
          .eq('rental_id', rentalId)
          .eq('rater_id', raterId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
