import 'dart:async';

import 'package:absensi_app/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ota_update/ota_update.dart';

void main() {
  tearDown(() {
    UpdateService.downloadStreamOverride = null;
    UpdateService.cancelDownloadOverride = null;
  });

  testWidgets('update button opens the download progress dialog', (
    tester,
  ) async {
    late BuildContext appContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            appContext = context;
            return const Scaffold(body: Text('Home'));
          },
        ),
      ),
    );

    UpdateService.showUpdatePrompt(
      appContext,
      '1.0.9',
      'https://app.example.test/releases/latest.apk',
      isRequired: true,
    );
    await tester.pump();
    expect(find.text('Pembaruan Wajib'), findsOneWidget);

    await tester.tap(find.text('Update Sekarang'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Pembaruan Wajib'), findsNothing);
    expect(
      find.text('Jangan tutup aplikasi sampai proses selesai'),
      findsOneWidget,
    );
  });

  testWidgets('finishes the installer handoff without leaving a spinner', (
    tester,
  ) async {
    UpdateService.downloadStreamOverride = (_) =>
        Stream<OtaEvent>.value(OtaEvent(OtaStatus.INSTALLING, '100'));
    UpdateService.cancelDownloadOverride = () async {};
    late BuildContext appContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            appContext = context;
            return const Scaffold(body: Text('Home'));
          },
        ),
      ),
    );

    UpdateService.showUpdatePrompt(
      appContext,
      '1.0.16',
      'https://app.example.test/releases/latest.apk',
      isRequired: true,
    );
    await tester.pump();
    await tester.tap(find.text('Update Sekarang'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Installer Android sudah dibuka. Selesaikan pemasangan, lalu kembali ke aplikasi.',
      ),
      findsOneWidget,
    );
    expect(find.text('Saya Sudah Selesai'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Saya Sudah Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Installer Android sudah dibuka.'), findsNothing);
  });

  testWidgets(
    'shows an explicit retry and manual download after a stalled download',
    (tester) async {
      final controller = StreamController<OtaEvent>();
      addTearDown(controller.close);
      UpdateService.downloadStreamOverride = (_) => controller.stream;
      UpdateService.cancelDownloadOverride = () async {};
      late BuildContext appContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              appContext = context;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );

      UpdateService.showUpdatePrompt(
        appContext,
        '1.0.16',
        'https://app.example.test/releases/latest.apk',
        isRequired: true,
      );
      await tester.pump();
      await tester.tap(find.text('Update Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 46));

      expect(
        find.textContaining('Tidak ada progres unduhan selama 45 detik'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Unduh lewat browser'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
