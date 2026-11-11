import 'package:absensi_app/services/attendance_location_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
