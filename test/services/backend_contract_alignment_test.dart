import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/core/exceptions/app_exception.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'package:absensi_app/models/notification_model.dart';
import 'package:absensi_app/models/user_model.dart';
import 'package:absensi_app/pages/notifications_page.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sends the stored bearer token on authenticated requests', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = _RecordingAdapter([
      const _MockResponse(200, {
        'access_token': 'issued-token',
        'user': {'id': 42, 'name': 'Test User', 'email': 'test@example.com'},
      }),
      const _MockResponse(200, {
        'id': 42,
        'name': 'Test User',
        'email': 'test@example.com',
        'employment_type': 'freelance',
      }),
    ]);
    final api = ApiService(dio: _createDio(adapter));

    await api.login(email: 'test@example.com', password: 'password');
    final user = await api.getAuthenticatedUser();

    expect(user?.id, 42);
    expect(adapter.requests.last.uri.path, endsWith('/user'));
    expect(
      adapter.requests.last.headers['Authorization'],
      'Bearer issued-token',
    );
    expect(adapter.requests.last.headers['Accept'], 'application/json');
  });

  test(
    'clears the local session when an authenticated request gets 401',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final adapter = _RecordingAdapter([
        const _MockResponse(200, {
          'access_token': 'issued-token',
          'user': {'id': 42, 'name': 'Test User', 'email': 'test@example.com'},
        }),
        const _MockResponse(401, {'message': 'Unauthenticated.'}),
      ]);
      final api = ApiService(dio: _createDio(adapter));
      final authProvider = AuthProvider(apiService: api);
      await authProvider.initializationFuture;
      await authProvider.login(email: 'test@example.com', password: 'password');

      expect(authProvider.isAuthenticated, isTrue);
      await expectLater(
        api.getAuthenticatedUser(),
        throwsA(isA<AppException>()),
      );

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(await api.getToken(), isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey('user_data'), isFalse);
    },
  );

  test('does not send an unsupported self-registration request', () async {
    final adapter = _RecordingAdapter([]);
    final result = await ApiService.withDio(_createDio(adapter)).register(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password',
      passwordConfirmation: 'password',
      idKaryawan: 'EMP-1',
      departemen: 'IT',
      employmentType: 'freelance',
      workLocation: 'office',
    );

    expect(result['success'], isFalse);
    expect(result['statusCode'], 404);
    expect(result['message'], contains('hubungi HRD'));
    expect(adapter.requests, isEmpty);
  });

  test('parses Laravel user and notification field types', () {
    final user = User.fromJson({
      'id': '42',
      'name': 'Test User',
      'email': 'test@example.com',
      'id_karyawan': null,
      'departemen': null,
      'employment_type': 'freelance',
      'is_admin': 1,
      'sisa_cuti': null,
    });
    final notification = NotificationModel.fromJson({
      'id': 7,
      'title': 'Info',
      'message': 'Message',
      'type': 'info',
      'target_page': null,
      'target_id': null,
      'is_read': 1,
      'created_at': '2026-01-02T03:04:05.000000Z',
    });

    expect(user.id, 42);
    expect(user.idKaryawan, isNull);
    expect(user.departemen, isNull);
    expect(user.isAdmin, isTrue);
    expect(user.sisaCuti, isNull);
    expect(notification.isRead, isTrue);
    expect(notification.targetId, isNull);
  });

  testWidgets('Alfa notification stays unread until the user opens it', (
    tester,
  ) async {
    final notification = {
      'id': 7,
      'title': 'Tindak lanjut Alfa',
      'message': 'Anda mencapai Alfa ke-3 bulan ini.',
      'type': 'alfa_hrd_call_20261109',
      'target_page': null,
      'target_id': 42,
      'is_read': false,
      'created_at': '2026-11-09T16:59:00.000000Z',
    };
    final adapter = _RecordingAdapter([
      _MockResponse(200, {
        'success': true,
        'data': [notification],
      }),
      const _MockResponse(200, {
        'success': true,
        'message': 'Notifikasi ditandai sebagai dibaca',
      }),
      _MockResponse(200, {
        'success': true,
        'data': [
          {...notification, 'is_read': true},
        ],
      }),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          apiService: ApiService.withDio(_createDio(adapter)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tindak lanjut Alfa'), findsOneWidget);
    expect(adapter.requests.map((request) => request.method), ['GET']);

    await tester.tap(find.text('Tindak lanjut Alfa'));
    await tester.pumpAndSettle();

    expect(adapter.requests.map((request) => request.method), [
      'GET',
      'PUT',
      'GET',
    ]);
  });

  testWidgets('payroll notification opens the employee payslip screen', (
    tester,
  ) async {
    final notification = {
      'id': 8,
      'title': 'Slip gaji tersedia',
      'message': 'Slip gaji periode Oktober 2026 sudah tersedia di aplikasi.',
      'type': 'payroll_slip',
      'target_page': null,
      'target_id': 42,
      'is_read': false,
      'created_at': '2026-11-12T03:04:05.000000Z',
    };
    final adapter = _RecordingAdapter(
      [],
      responsesByPath: {
        '/api/v1/notifications': [
          _MockResponse(200, {
            'success': true,
            'data': [notification],
          }),
          _MockResponse(200, {
            'success': true,
            'data': [
              {...notification, 'is_read': true},
            ],
          }),
        ],
        '/api/v1/notifications/8/read': [
          const _MockResponse(200, {
            'success': true,
            'message': 'Notifikasi ditandai sebagai dibaca',
          }),
        ],
        '/api/v1/payroll/slips': [
          const _MockResponse(200, {'success': true, 'data': []}),
        ],
      },
    );
    final apiService = ApiService.withDio(_createDio(adapter));

    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: apiService,
        child: MaterialApp(home: NotificationsPage(apiService: apiService)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Slip gaji tersedia'));
    await tester.pumpAndSettle();

    expect(find.text('Slip Gaji'), findsOneWidget);
    expect(
      find.text(
        'Belum ada slip gaji yang tersedia. Slip akan muncul setelah payroll dikonfirmasi dibayar oleh HRD.',
      ),
      findsOneWidget,
    );
    expect(
      adapter.requests.any(
        (request) => request.uri.path.endsWith('/payroll/slips'),
      ),
      isTrue,
    );
  });

  test('parses the backend attendance detail resource shape', () {
    final absensi = Absensi.fromJson({
      'id': 12,
      'user_id': 42,
      'status': 'hadir',
      'jam_masuk': '08:15',
      'jam_keluar': '17:00',
      'is_late': true,
      'keterangan_telat': 'Terlambat',
      'foto_masuk_url': 'https://example.test/check-in.jpg',
      'foto_keluar_url': 'https://example.test/check-out.jpg',
      'lokasi_masuk': {'lat': '-6.2', 'long': '106.8'},
    });

    expect(absensi.id, 12);
    expect(absensi.checkInAt, '08:15');
    expect(absensi.checkOutAt, '17:00');
    expect(absensi.isLate, isTrue);
    expect(absensi.lateDurationText, 'Terlambat');
    expect(absensi.fotoPulangUrl, 'https://example.test/check-out.jpg');
    expect(absensi.lokasiMasuk, '-6.2,106.8');
  });

  test('resubmits a rejected leave with the required evidence field', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'flutter-api-contract-',
    );
    final evidence = File('${tempDirectory.path}/proof.jpg');
    await evidence.writeAsBytes([1, 2, 3]);
    final adapter = _RecordingAdapter([
      const _MockResponse(200, {'success': true, 'message': 'Resubmitted'}),
    ]);

    try {
      final result = await ApiService.withDio(
        _createDio(adapter),
      ).resubmitIzin(absensiId: 99, fileBukti: evidence, catatan: 'Alasan');

      expect(result['success'], isTrue);
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/absensi/izin/99/resubmit'));
      final formData = request.data as FormData;
      expect(Map.fromEntries(formData.fields), {
        'keterangan_izin_sakit': 'Alasan',
      });
      expect(formData.files.single.key, 'file_bukti');
    } finally {
      await tempDirectory.delete(recursive: true);
    }
  });
}

Dio _createDio(_RecordingAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1/'))
    ..httpClientAdapter = adapter;
}

class _MockResponse {
  const _MockResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(
    this._responses, {
    Map<String, List<_MockResponse>> responsesByPath = const {},
  }) : _responsesByPath = responsesByPath.map(
         (path, responses) => MapEntry(path, List.of(responses)),
       );

  final List<_MockResponse> _responses;
  final Map<String, List<_MockResponse>> _responsesByPath;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await requestStream?.drain<void>();
    final pathResponses = _responsesByPath[options.uri.path];
    final response = pathResponses != null && pathResponses.isNotEmpty
        ? pathResponses.removeAt(0)
        : _responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
