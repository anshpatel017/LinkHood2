import '../entities/request.dart';
import '../entities/request_response.dart';

abstract class RequestRepository {
  Future<ItemRequest> createRequest({
    required String category,
    required String itemName,
    required String description,
    double? budgetPerDay,
    int? durationDays,
    DateTime? startDate,
    DateTime? endDate,
    required double lat,
    required double lng,
  });

  /// Fetches open requests near the given location.
  Future<List<ItemRequest>> getNearbyRequests({
    required double lat,
    required double lng,
    double radiusMeters = 500,
  });

  /// Fetches all requests created by the current user.
  Future<List<ItemRequest>> getMyRequests(String userId);

  /// Offers one of the user's listings to fulfill a request.
  Future<void> offerListingToRequest({
    required String requestId,
    required String listingId,
  });

  /// Fetches all responses/offers for a specific request.
  Future<List<RequestResponse>> getRequestResponses(String requestId);

  /// Updates the status of a response (accept / decline).
  Future<void> updateResponseStatus(String responseId, String newStatus);
}
