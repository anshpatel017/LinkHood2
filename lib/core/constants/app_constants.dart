/// App-wide constants for RentNear
class AppConstants {
  AppConstants._();

  // Location defaults
  static const double defaultRadiusMeters = 500;
  static const double minRadiusMeters = 100;
  static const double maxRadiusMeters = 1000;

  // Rate limits
  static const int maxGeoRequestsPerDay = 3;

  // Image constraints
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxAvatarSizeBytes = 2 * 1024 * 1024; // 2MB

  // Pagination
  static const int itemsPerPage = 20;

  // Cache
  static const int maxCachedNotifications = 50;

  // Timing
  static const Duration requestExpiry = Duration(hours: 48);

  // Verified Neighbor thresholds
  static const int verifiedMinRentals = 3;
  static const double verifiedMinRating = 3.5;

  // Earnings estimate
  static const int avgRentalDaysPerMonth = 8;
}
