import 'package:absensi_app/services/attendance_location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('AttendanceLocationService', () {
    test('uses the PT FollowMe workplace coordinates', () {
      expect(AttendanceLocationService.officeLatitude, -6.3417780);
      expect(AttendanceLocationService.officeLongitude, 106.6786672);
      expect(AttendanceLocationService.allowedRadiusMeters, 800);
    });

    test('describes the measured distance and GPS accuracy', () {
      expect(
        AttendanceLocationService.describeMeasurement(
          distanceMeters: 18,
          accuracyMeters: 6,
        ),
        'Lokasi Jitu • GPS ±6 m; jarak 18 m dari titik kerja.',
      );
      expect(
        AttendanceLocationService.describeMeasurement(
          distanceMeters: 795,
          accuracyMeters: 10,
        ),
        'GPS ±10 m; jarak 795 m dari titik kerja (radius 800 m).',
      );
    });

    test('explains when GPS accuracy is insufficient', () {
      expect(
        AttendanceLocationService.describeMeasurement(
          distanceMeters: 10,
          accuracyMeters: 150,
        ),
        'Akurasi GPS ±150 m. Aktifkan lokasi presisi dan coba di area terbuka.',
      );
    });

    test(
      'accepts a measured point when its accuracy margin is inside 800m',
      () {
        expect(
          AttendanceLocationService.isMeasurementWithinAllowedRadius(
            distanceMeters: 770,
            accuracyMeters: 20,
          ),
          isTrue,
        );
      },
    );

    test('rejects a point whose accuracy margin crosses the geofence', () {
      expect(
        AttendanceLocationService.isMeasurementWithinAllowedRadius(
          distanceMeters: 785,
          accuracyMeters: 20,
        ),
        isFalse,
      );
    });

    test('rejects invalid or unusable GPS accuracy measurements', () {
      for (final accuracyMeters in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          AttendanceLocationService.isMeasurementWithinAllowedRadius(
            distanceMeters: 10,
            accuracyMeters: accuracyMeters,
          ),
          isFalse,
        );
      }
    });

    test(
      'keeps the GPS accuracy requirement while allowing a wider radius',
      () {
        expect(
          AttendanceLocationService.isMeasurementWithinAllowedRadius(
            distanceMeters: 10,
            accuracyMeters: 101,
          ),
          isFalse,
        );
      },
    );

    test('bypasses only the workplace radius for the authorized account', () {
      final position = Position(
        longitude: 106.8,
        latitude: -6.2,
        timestamp: DateTime.utc(2026, 1, 1),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      final config = AttendanceGeofenceConfig.fromJson({
        'latitude': -6.3,
        'longitude': 106.9,
        'radius_meters': 150,
        'maximum_accuracy_meters': 25,
        'is_enforced': false,
      });

      expect(config.isEnforced, isFalse);
      expect(
        AttendanceLocationService.isWithinAllowedRadius(
          position,
          config: config,
        ),
        isTrue,
      );
      expect(
        AttendanceLocationService.isWithinAllowedRadius(
          position,
          config: AttendanceGeofenceConfig.fromJson({
            'latitude': -6.3,
            'longitude': 106.9,
            'radius_meters': 150,
            'maximum_accuracy_meters': 25,
            'is_enforced': true,
          }),
        ),
        isFalse,
      );
    });

    test('describes the account-scoped testing bypass clearly', () {
      expect(
        AttendanceLocationService.describeMeasurement(
          distanceMeters: 5000,
          accuracyMeters: 10,
          enforceWorkplaceGeofence: false,
        ),
        'Lokasi GPS siap; validasi titik kerja nonaktif khusus akun tester.',
      );
    });

    test('uses the server-provided radius and maximum accuracy', () {
      final config = AttendanceGeofenceConfig.fromJson({
        'latitude': '-6.2',
        'longitude': '106.8',
        'radius_meters': 150,
        'maximum_accuracy_meters': 25,
      });

      expect(
        AttendanceLocationService.isMeasurementWithinAllowedRadius(
          distanceMeters: 120,
          accuracyMeters: 20,
          radiusMeters: config.radiusMeters,
          maximumAccuracyMeters: config.maximumAccuracyMeters,
        ),
        isTrue,
      );
      expect(
        AttendanceLocationService.isMeasurementWithinAllowedRadius(
          distanceMeters: 131,
          accuracyMeters: 20,
          radiusMeters: config.radiusMeters,
          maximumAccuracyMeters: config.maximumAccuracyMeters,
        ),
        isFalse,
      );
      expect(config.latitude, -6.2);
      expect(config.longitude, 106.8);
    });

    test('rejects invalid server geofence configuration', () {
      expect(
        () => AttendanceGeofenceConfig.fromJson({
          'latitude': 0,
          'longitude': 0,
          'radius_meters': 0,
          'maximum_accuracy_meters': 100,
        }),
        throwsFormatException,
      );
    });
  });
}
