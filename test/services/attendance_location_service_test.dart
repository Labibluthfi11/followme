import 'package:absensi_app/services/attendance_location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceLocationService', () {
    test(
      'accepts a measured point when its accuracy margin is inside 100m',
      () {
        expect(
          AttendanceLocationService.isMeasurementWithinAllowedRadius(
            distanceMeters: 70,
            accuracyMeters: 20,
          ),
          isTrue,
        );
      },
    );

    test('rejects a point whose accuracy margin crosses the geofence', () {
      expect(
        AttendanceLocationService.isMeasurementWithinAllowedRadius(
          distanceMeters: 85,
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
  });
}
