class DistanceFormatter {
  /// Formats distance in meters to a readable string (e.g. "800 m", "2.1 km")
  static String format(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
