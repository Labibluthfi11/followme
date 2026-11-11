import 'package:absensi_app/screens/home/hr_services_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the enabled employee services', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HrServicesScreen(employmentType: 'organik')),
    );

    expect(find.text('Pengajuan sakit'), findsOneWidget);
    expect(find.text('Pengajuan cuti'), findsOneWidget);
    expect(find.text('Pengajuan lembur'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Reimbursement'), 240);
    expect(find.text('Reimbursement'), findsOneWidget);
    expect(find.text('Kasbon / pinjaman'), findsOneWidget);
    expect(find.text('Ajukan penggantian biaya dengan bukti'), findsOneWidget);
    expect(find.text('Ajukan pinjaman dan pantau cicilan'), findsOneWidget);
  });

  testWidgets(
    'shows permission to report lateness only for non-organik staff',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HrServicesScreen(employmentType: 'freelance')),
      );

      expect(find.text('Lapor keterlambatan'), findsOneWidget);
      expect(find.text('Pengajuan izin'), findsOneWidget);
    },
  );
}
