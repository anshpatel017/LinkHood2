import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/rental.dart';
import '../../domain/repositories/rental_repository.dart';
import '../../data/repositories/rental_repository_impl.dart';

// Provides the RentalRepository
final rentalRepositoryProvider = Provider<RentalRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RentalRepositoryImpl(client);
});

// Provides the list of rentals where the user is the BORROWER
final myBorrowedRentalsProvider = FutureProvider<List<Rental>>((ref) async {
  final repo = ref.watch(rentalRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return repo.fetchUserRentals(user.id, asBorrower: true);
});

// Provides the list of rentals where the user is the LENDER
final myLentRentalsProvider = FutureProvider<List<Rental>>((ref) async {
  final repo = ref.watch(rentalRepositoryProvider);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return repo.fetchUserRentals(user.id, asBorrower: false);
});

// Controller to perform rental actions
final rentalControllerProvider = Provider<RentalController>((ref) {
  return RentalController(ref);
});

class RentalController {
  final Ref _ref;

  RentalController(this._ref);

  Future<void> createRequest({
    required String listingId,
    required String lenderId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalCost,
  }) async {
    final user = await _ref.read(currentUserProvider.future);
    if (user == null) throw Exception('Must be logged in to rent items.');

    final repo = _ref.read(rentalRepositoryProvider);
    await repo.createRentalRequest(
      listingId: listingId,
      borrowerId: user.id,
      lenderId: lenderId,
      startDate: startDate,
      endDate: endDate,
      totalCost: totalCost,
    );

    // Refresh borrower rentals
    _ref.invalidate(myBorrowedRentalsProvider);
  }

  Future<void> updateStatus(String rentalId, String status) async {
    final repo = _ref.read(rentalRepositoryProvider);
    await repo.updateRentalStatus(rentalId, status);
    
    // Refresh both rental lists
    _ref.invalidate(myBorrowedRentalsProvider);
    _ref.invalidate(myLentRentalsProvider);
  }
}
