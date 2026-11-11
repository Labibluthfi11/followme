import 'dart:convert';
import 'dart:typed_data';

import 'package:absensi_app/api/api.service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses the authenticated attendance geofence response', () async {
    final api = _createApi(
      _RecordingAdapter([
        const _MockResponse(200, {
          'success': true,
          'data': {
            'latitude': -6.2,
            'longitude': 106.8,
            'radius_meters': 250,
            'maximum_accuracy_meters': 50,
          },
        }),
      ]),
    );

    final config = await api.fetchAttendanceGeofence();

    expect(config.latitude, -6.2);
    expect(config.longitude, 106.8);
    expect(config.radiusMeters, 250);
    expect(config.maximumAccuracyMeters, 50);
  });

  test('fetches HR request categories, policies, and personal history', () async {
    final adapter = _RecordingAdapter([
      const _MockResponse(200, {
        'success': true,
        'data': {
          'reimbursement_types': [
            {
              'id': 4,
              'name': 'Transport',
              'monthly_limit': 500000,
              'used_this_month': 100000,
            },
          ],
          'loan_policy': {'max_principal': 5000000, 'max_tenor_months': 12},
          'reimbursements': [],
          'loans': [],
        },
      }),
    ]);

    final result = await _createApi(adapter).fetchEmployeeHrRequests();

    expect(result['success'], isTrue);
    expect(
      (result['data'] as Map<String, dynamic>)['loan_policy'],
      {'max_principal': 5000000, 'max_tenor_months': 12},
    );
    expect(adapter.requests.single.uri.path, endsWith('/hr-requests'));
  });

  test('submits a reimbursement using the backend multipart contract', () async {
    final adapter = _RecordingAdapter([
      const _MockResponse(201, {
        'success': true,
        'message': 'Pengajuan reimbursement terkirim.',
        'data': {'id': 15, 'status': 'pending'},
      }),
    ]);

    final result = await _createApi(adapter).submitReimbursement(
      typeId: 4,
      amount: 125000,
      description: 'Transport ke kantor',
      receiptBytes: Uint8List.fromList([1, 2, 3]),
      receiptName: 'receipt.pdf',
    );

    expect(result['success'], isTrue);
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, endsWith('/hr-requests/reimbursements'));
    final formData = request.data as FormData;
    expect(Map.fromEntries(formData.fields), {
      'type_id': '4',
      'amount': '125000',
      'description': 'Transport ke kantor',
    });
    expect(formData.files.single.key, 'receipt');
    expect(formData.files.single.value.filename, 'receipt.pdf');
    expect(
      request.contentType,
      startsWith(Headers.multipartFormDataContentType),
    );
  });

  test('submits a loan request using the backend JSON contract', () async {
    final adapter = _RecordingAdapter([
      const _MockResponse(201, {
        'success': true,
        'message': 'Pengajuan kasbon terkirim.',
        'data': {'id': 22, 'status': 'pending'},
      }),
    ]);

    final result = await _createApi(adapter).submitLoanRequest(
      principal: 1500000,
      tenorMonths: 6,
      purpose: 'Biaya pendidikan anak',
    );

    expect(result['success'], isTrue);
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.uri.path, endsWith('/hr-requests/loans'));
    expect(adapter.requests.single.data, {
      'principal': 1500000,
      'tenor_months': 6,
      'purpose': 'Biaya pendidikan anak',
    });
  });
}

ApiService _createApi(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1/'))
    ..httpClientAdapter = adapter;
  return ApiService.withDio(dio);
}

class _MockResponse {
  const _MockResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._responses);

  final List<_MockResponse> _responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await requestStream?.drain<void>();
    final response = _responses.removeAt(0);
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
