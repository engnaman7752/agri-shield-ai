import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationUtils {
  // Distance threshold in meters (200m)
  static const double distanceThreshold = 200.0;

  /// Haversine formula to calculate distance between two points in meters
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // Radius of Earth in km * 1000 for meters
  }

  /// Checks if current position is within threshold of target position
  /// Returns a record with (isWithin, actualDistance)
  static (bool, double) isWithinBoundary(Position current, double targetLat, double targetLon, {bool isDemoMode = false}) {
    final distance = calculateDistance(
      current.latitude, 
      current.longitude, 
      targetLat, 
      targetLon
    );

    // If we're in demo mode, we bypass the distance check for easier testing
    if (isDemoMode) {
      return (true, distance);
    }

    return (distance <= distanceThreshold, distance);
  }

  static bool _isAtDemoSite(Position current) {
    // Add your demo site coordinates here
    // Example: 23.2599, 77.4126 (Bhopal)
    const demoLat = 23.2599;
    const demoLon = 77.4126;
    
    final distance = calculateDistance(current.latitude, current.longitude, demoLat, demoLon);
    return distance < 1000; // Within 1km of demo site counts as "At Farm" for presentation
  }
}
