import 'package:geolocator/geolocator.dart';

class AttendanceLocationService {
  static const double officeLatitude = -6.3357454;
  static const double officeLongitude = 106.9457406;
  static const double allowedRadiusMeters = 100;

  static bool isMeasurementWithinAllowedRadius({
    required double distanceMeters,
    required double accuracyMeters,
  }) {
    if (!distanceMeters.isFinite ||
        !accuracyMeters.isFinite ||
        distanceMeters < 0 ||
        accuracyMeters <= 0 ||
        accuracyMeters > allowedRadiusMeters) {
      return false;
    }

    return distanceMeters + accuracyMeters <= allowedRadiusMeters;
  }

  static double distanceFromWorkplace(Position position) {
    return Geolocator.distanceBetween(
      officeLatitude,
      officeLongitude,
      position.latitude,
      position.longitude,
    );
  }

  static bool isWithinAllowedRadius(Position position) {
    return isMeasurementWithinAllowedRadius(
      distanceMeters: distanceFromWorkplace(position),
      accuracyMeters: position.accuracy,
    );
  }
}
