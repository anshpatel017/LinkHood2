import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/rental.dart';
import '../../domain/repositories/rental_repository.dart';
import '../models/rental_model.dart';

class RentalRepositoryImpl implements RentalRepository {
  final supa.SupabaseClient _supabase;

  RentalRepositoryImpl(this._supabase);

  @override
  Future<Rental> createRentalRequest({
    required String listingId,
    required String borrowerId,
    required String lenderId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalCost,
  }) async {
    try {
      final rentalId = const Uuid().v4();
      final newRental = RentalModel(
        id: rentalId,
        listingId: listingId,
        borrowerId: borrowerId,
        lenderId: lenderId,
        startDate: startDate,
        endDate: endDate,
        totalDays: endDate.difference(startDate).inDays + 1,
        totalCost: totalCost,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _supabase
          .from('rentals')
          .insert(newRental.toCreateJson())
          .select('''
            *,
            listings (title, price_per_day, image_urls),
            lender:lender_id (full_name, avatar_url),
            borrower:borrower_id (full_name, avatar_url)
          ''')
          .single();

      return RentalModel.fromJson(response, currentUserId: borrowerId);
    } catch (e) {
      throw ServerException('Failed to create rental request: $e');
    }
  }

  @override
  Future<List<Rental>> fetchUserRentals(String userId, {required bool asBorrower}) async {
    try {
      final roleColumn = asBorrower ? 'borrower_id' : 'lender_id';
      
      final response = await _supabase
          .from('rentals')
          .select('''
            *,
            listings (title, price_per_day, image_urls),
            lender:lender_id (full_name, avatar_url),
            borrower:borrower_id (full_name, avatar_url)
          ''')
          .eq(roleColumn, userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => RentalModel.fromJson(json as Map<String, dynamic>, currentUserId: userId))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch rentals: $e');
    }
  }

  @override
  Future<Rental> updateRentalStatus(String rentalId, String newStatus) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final response = await _supabase
          .from('rentals')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', rentalId)
          .select('''
            *,
            listings (title, price_per_day, image_urls),
            lender:lender_id (full_name, avatar_url),
            borrower:borrower_id (full_name, avatar_url)
          ''')
          .single();

      return RentalModel.fromJson(response, currentUserId: currentUserId);
    } catch (e) {
      throw ServerException('Failed to update rental status: $e');
    }
  }
}
