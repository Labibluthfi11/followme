import 'package:absensi_app/models/absensi_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Absensi.statusLabel', () {
    test('shows completed when a present attendance has a checkout time', () {
      final attendance = Absensi(
        id: 1,
        userId: 1,
        status: 'hadir',
        checkOutAt: '2026-11-04T17:00:00',
      );

      expect(attendance.statusLabel, 'Selesai');
    });

    test('keeps the original status when checkout is not recorded', () {
      final attendance = Absensi(id: 1, userId: 1, status: 'hadir');

      expect(attendance.statusLabel, 'hadir');
    });

    test('does not replace leave status with completed', () {
      final attendance = Absensi(
        id: 1,
        userId: 1,
        status: 'izin',
        checkOutAt: '2026-11-04T17:00:00',
      );

      expect(attendance.statusLabel, 'izin');
    });
  });
}
