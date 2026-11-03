import 'dart:convert';
import 'dart:typed_data';

import 'package:absensi_app/api/api.service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Password API contract', () {
    test(
      'uses the documented forgot-password routes and request fields',
      () async {
        final adapter = _RecordingAdapter([
          const _MockResponse(200, {'message': 'OTP sent'}),
          const _MockResponse(200, {'message': 'OTP valid'}),
          const _MockResponse(200, {'message': 'Password reset'}),
        ]);
        final api = _createApi(adapter);

        await api.sendOtp(email: 'person@example.com');
        await api.verifyOtp(email: 'person@example.com', otp: '123456');
        await api.resetPassword(
          email: 'person@example.com',
          otp: '123456',
          password: 'newpassword',
          passwordConfirmation: 'newpassword',
        );

        expect(
          adapter.requests.map((request) => request.method),
          everyElement('POST'),
        );
        expect(
          adapter.requests[0].uri.path,
          endsWith('/forgot-password/send-otp'),
        );
        expect(adapter.requests[0].data, {'email': 'person@example.com'});
        expect(
          adapter.requests[1].uri.path,
          endsWith('/forgot-password/verify-otp'),
        );
        expect(adapter.requests[1].data, {
          'email': 'person@example.com',
          'otp': '123456',
        });
        expect(
          adapter.requests[2].uri.path,
          endsWith('/forgot-password/reset-password'),
        );
        expect(adapter.requests[2].data, {
          'email': 'person@example.com',
          'otp': '123456',
          'password': 'newpassword',
          'password_confirmation': 'newpassword',
        });
      },
    );

    test(
      'uses PUT user/password with the agreed authenticated-change fields',
      () async {
        final adapter = _RecordingAdapter([
          const _MockResponse(200, {
            'message': 'Password berhasil diperbarui. Silakan login kembali.',
          }),
        ]);
        final result = await _createApi(adapter).updatePassword(
          currentPassword: 'oldpassword',
          password: 'newpassword',
          passwordConfirmation: 'newpassword',
        );

        expect(result['success'], isTrue);
        expect(adapter.requests.single.method, 'PUT');
        expect(adapter.requests.single.uri.path, endsWith('/user/password'));
        expect(adapter.requests.single.data, {
          'current_password': 'oldpassword',
          'password': 'newpassword',
          'password_confirmation': 'newpassword',
        });
      },
    );

    test('preserves backend OTP errors and rate-limit messages', () async {
      final adapter = _RecordingAdapter([
        const _MockResponse(422, {
          'message': 'OTP tidak valid.',
          'errors': {
            'otp': ['OTP salah atau kedaluwarsa.'],
          },
        }),
        const _MockResponse(429, {'message': 'Terlalu banyak percobaan.'}),
      ]);
      final api = _createApi(adapter);

      final invalidOtp = await api.verifyOtp(
        email: 'person@example.com',
        otp: '000000',
      );
      final rateLimited = await api.sendOtp(email: 'person@example.com');

      expect(invalidOtp['success'], isFalse);
      expect(invalidOtp['message'], contains('OTP salah atau kedaluwarsa.'));
      expect(invalidOtp['errors'], contains('otp'));
      expect(rateLimited['success'], isFalse);
      expect(rateLimited['message'], 'Terlalu banyak percobaan.');
    });

    test('shows backend password validation details', () async {
      final adapter = _RecordingAdapter([
        const _MockResponse(422, {
          'message': 'Data tidak valid.',
          'errors': {
            'current_password': ['The password is incorrect.'],
          },
        }),
      ]);
      final result = await _createApi(adapter).updatePassword(
        currentPassword: 'wrong-password',
        password: 'newpassword',
        passwordConfirmation: 'newpassword',
      );

      expect(result['success'], isFalse);
      expect(result['statusCode'], 422);
      expect(result['message'], contains('The password is incorrect.'));
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
