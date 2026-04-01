/// Supabase table names and API constants
class ApiConstants {
  ApiConstants._();

  // Table names
  static const String usersTable = 'users';
  static const String listingsTable = 'listings';
  static const String rentalsTable = 'rentals';
  static const String requestsTable = 'requests';
  static const String userInventoryTable = 'user_inventory';
  static const String ratingsTable = 'ratings';
  static const String reportsTable = 'reports';
  static const String notificationsTable = 'notifications';

  // RPC function names
  static const String getNearbyListings = 'get_nearby_listings';
  static const String getNearbyInventoryUsers = 'get_nearby_inventory_users';
  static const String getRankedNearbyListings = 'get_ranked_nearby_listings';
  static const String isVerifiedNeighbor = 'is_verified_neighbor';

  // Edge functions
  static const String broadcastRequestFn = 'broadcast_request';

  // Storage buckets
  static const String listingImagesBucket = 'listing-images';
  static const String avatarsBucket = 'avatars';

  // Rental status values
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusDisputed = 'disputed';

  // Request status values
  static const String requestOpen = 'open';
  static const String requestFulfilled = 'fulfilled';
  static const String requestExpired = 'expired';
  static const String requestCancelled = 'cancelled';
}
