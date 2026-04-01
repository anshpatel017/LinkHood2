import '../entities/listing.dart';

abstract class ListingRepository {
  /// Fetches nearby listings using the PostGIS RPC, ranked by matching inventory.
  Future<List<Listing>> searchNearbyListings({
    required double lat,
    required double lng,
    required double radiusMeters,
    String? category,
  });

  /// Fetches a specific listing by its ID.
  Future<Listing> getListingById(String id);

  /// Fetches all listings owned by a specific user ID.
  Future<List<Listing>> getMyListings(String userId);

  /// Creates a new listing.
  Future<Listing> createListing(Listing listing, double lat, double lng);

  /// Updates an existing listing.
  Future<Listing> updateListing(Listing listing);

  /// Deletes a listing.
  Future<void> deleteListing(String id);
}
