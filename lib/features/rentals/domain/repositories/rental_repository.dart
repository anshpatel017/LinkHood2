import '../entities/rental.dart';

abstract class RentalRepository {
  /// Create a new rental request
  Future<Rental> createRentalRequest({
    required String listingId,
    required String borrowerId,
    required String lenderId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalCost,
  });

  /// Fetch rentals for the current user, either as a borrower or a lender
  Future<List<Rental>> fetchUserRentals(String userId, {required bool asBorrower});

  /// Update the status of a rental (e.g., 'accepted', 'rejected', 'completed', 'cancelled')
  Future<Rental> updateRentalStatus(String rentalId, String newStatus);
}
