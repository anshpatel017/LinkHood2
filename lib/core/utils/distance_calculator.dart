/// Distance display utilities
class DistanceCalculator {
  DistanceCalculator._();

  /// Format distance in meters to a human-readable string
  /// < 1000m → "300m away"
  /// >= 1000m → "1.2km away"
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m away';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km away';
    }
  }

  /// Short format without "away" suffix
  static String formatDistanceShort(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }
}
