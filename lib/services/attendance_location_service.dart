import 'package:geolocator/geolocator.dart';

class AttendanceGeofenceConfig {
  const AttendanceGeofenceConfig({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.maximumAccuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;
  final double maximumAccuracyMeters;

  factory AttendanceGeofenceConfig.fromJson(Map<String, dynamic> json) {
    final latitude = double.parse(json['latitude'].toString());
    final longitude = double.parse(json['longitude'].toString());
    final radius = double.parse(json['radius_meters'].toString());
    final accuracy = double.parse(json['maximum_accuracy_meters'].toString());
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180 ||
        !radius.isFinite ||
        radius <= 0 ||
        !accuracy.isFinite ||
        accuracy <= 0) {
      throw const FormatException('Invalid attendance geofence configuration.');
    }

    return AttendanceGeofenceConfig(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radius,
      maximumAccuracyMeters: accuracy,
    );
  }
}

class AttendanceLocationService {
  static const double officeLatitude = -6.3417780;
  static const double officeLongitude = 106.6786672;
  static const double allowedRadiusMeters = 800;
  static const double maximumGpsAccuracyMeters = 100;

  static bool isMeasurementWithinAllowedRadius({
    required double distanceMeters,
    required double accuracyMeters,
    double radiusMeters = allowedRadiusMeters,
    double maximumAccuracyMeters = maximumGpsAccuracyMeters,
  }) {
    if (!distanceMeters.isFinite ||
        !accuracyMeters.isFinite ||
        !radiusMeters.isFinite ||
        !maximumAccuracyMeters.isFinite ||
        distanceMeters < 0 ||
        accuracyMeters <= 0 ||
        radiusMeters <= 0 ||
        maximumAccuracyMeters <= 0 ||
        accuracyMeters > maximumAccuracyMeters) {
      return false;
    }

    return distanceMeters + accuracyMeters <= radiusMeters;
  }

  static String describeMeasurement({
    required double distanceMeters,
    required double accuracyMeters,
    double radiusMeters = allowedRadiusMeters,
    double maximumAccuracyMeters = maximumGpsAccuracyMeters,
  }) {
    if (!accuracyMeters.isFinite || accuracyMeters <= 0) {
      return 'Akurasi GPS tidak terbaca. Periksa izin lokasi presisi.';
    }
    if (!distanceMeters.isFinite || distanceMeters < 0) {
      return 'Pembacaan lokasi GPS tidak valid. Coba perbarui lokasi.';
    }
    if (accuracyMeters > maximumAccuracyMeters) {
      return 'Akurasi GPS ±${accuracyMeters.round()} m. Aktifkan lokasi presisi dan coba di area terbuka.';
    }
    if (isMeasurementWithinAllowedRadius(
      distanceMeters: distanceMeters,
      accuracyMeters: accuracyMeters,
      radiusMeters: radiusMeters,
      maximumAccuracyMeters: maximumAccuracyMeters,
    )) {
      return 'Lokasi Jitu • GPS ±${accuracyMeters.round()} m; jarak ${distanceMeters.round()} m dari titik kerja.';
    }
    return 'GPS ±${accuracyMeters.round()} m; jarak ${distanceMeters.round()} m dari titik kerja (radius ${radiusMeters.round()} m).';
  }

  static double distanceFromWorkplace(
    Position position, {
    AttendanceGeofenceConfig? config,
  }) {
    return Geolocator.distanceBetween(
      config?.latitude ?? officeLatitude,
      config?.longitude ?? officeLongitude,
      position.latitude,
      position.longitude,
    );
  }

  static bool isWithinAllowedRadius(
    Position position, {
    AttendanceGeofenceConfig? config,
  }) {
    return isMeasurementWithinAllowedRadius(
      distanceMeters: distanceFromWorkplace(position, config: config),
      accuracyMeters: position.accuracy,
      radiusMeters: config?.radiusMeters ?? allowedRadiusMeters,
      maximumAccuracyMeters:
          config?.maximumAccuracyMeters ?? maximumGpsAccuracyMeters,
    );
  }
}
