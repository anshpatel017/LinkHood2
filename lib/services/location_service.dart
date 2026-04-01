import 'package:geolocator/geolocator.dart';
import '../core/errors/exceptions.dart';

/// GPS location service wrapper
class LocationService {
  /// Check and request location permissions, then get current position
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permissions are permanently denied. Please enable in Settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // minimum change in meters to trigger update
      ),
    );
  }

  /// Get last known position (faster, may return null)
  static Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }

  /// Calculate distance between two points in meters
  static double distanceBetween(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Listen to position changes
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // update every 50 meters
      ),
    );
  }
}
