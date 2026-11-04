import 'dart:convert';
import 'dart:typed_data';

import 'package:absensi_app/api/api.service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'submits the early-leave multipart contract and accepts HTTP 201',
    () async {
      final adapter = _RecordingAdapter([
        const _MockResponse(201, {
          'success': true,
          'message': 'Pengajuan berhasil.',
          'data': {'status_approval': 'pending'},
        }),
      ]);

      final result = await _createApi(adapter).submitEarlyLeaveRequest(
        fileBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'proof.pdf',
        catatan: 'Keperluan keluarga',
        jamPulangRencana: '12:00',
      );

      expect(result['success'], isTrue);
      expect(result['statusCode'], 201);
      expect(result['message'], 'Pengajuan berhasil.');
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/absensi/izin'));
      final formData = request.data as FormData;
      expect(Map.fromEntries(formData.fields), {
        'status': 'izin',
        'catatan_admin': 'izin_pulang_cepat',
        'jam_pulang_rencana': '12:00',
        'keterangan_izin_sakit': 'Keperluan keluarga',
      });
      expect(formData.files.single.key, 'file_bukti');
      expect(formData.files.single.value.filename, 'proof.pdf');
      expect(
        request.contentType,
        startsWith(Headers.multipartFormDataContentType),
      );
    },
  );

  test('preserves backend validation and conflict messages', () async {
    final adapter = _RecordingAdapter([
      const _MockResponse(422, {
        'success': false,
        'message': 'Jam pulang harus setelah check-in.',
        'errors': {
          'jam_pulang_rencana': ['Jam pulang tidak valid.'],
        },
      }),
      const _MockResponse(409, {
        'success': false,
        'message': 'Sudah ada pengajuan yang menunggu persetujuan.',
      }),
    ]);

    final api = _createApi(adapter);
    final validation = await api.submitEarlyLeaveRequest(
      fileBytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'proof.jpg',
      catatan: 'Alasan',
      jamPulangRencana: '09:00',
    );
    final conflict = await api.submitEarlyLeaveRequest(
      fileBytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'proof.jpg',
      catatan: 'Alasan',
      jamPulangRencana: '12:00',
    );

    expect(validation['success'], isFalse);
    expect(validation['statusCode'], 422);
    expect(validation['message'], contains('Jam pulang harus setelah'));
    expect(validation['message'], contains('Jam pulang tidak valid.'));
    expect(conflict['success'], isFalse);
    expect(conflict['statusCode'], 409);
    expect(
      conflict['message'],
      'Sudah ada pengajuan yang menunggu persetujuan.',
    );
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
