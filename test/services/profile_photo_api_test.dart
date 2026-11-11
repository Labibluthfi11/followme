import 'dart:convert';
import 'dart:typed_data';

import 'package:absensi_app/api/api.service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_io/io.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('profile-photo-test');
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test('uploads profile photo and requires a newly saved photo path', () async {
    final photo = File('${tempDirectory.path}/profile.jpg');
    await photo.writeAsBytes([1, 2, 3]);
    final adapter = _RecordingAdapter({
      'message': 'Profil berhasil diperbarui.',
      'user': _userJson(profilePhotoPath: 'profile-photos/new-photo.jpg'),
    });
    final api = _createApi(adapter);

    final result = await api.updateProfile(
      profilePhoto: photo,
      previousProfilePhotoPath: 'profile-photos/old-photo.jpg',
    );

    expect(result['success'], isTrue);
    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.uri.path, endsWith('/user/profile'));
    expect(adapter.request?.data, isA<FormData>());

    final formData = adapter.request!.data as FormData;
    expect(formData.fields, isEmpty);
    expect(formData.files.single.key, 'profile_photo');
    expect(formData.files.single.value.filename, 'profile.jpg');
    expect(formData.files.single.value.contentType?.mimeType, 'image/jpeg');
  });

  test(
    'does not report success when server returns the previous photo path',
    () async {
      final photo = File('${tempDirectory.path}/profile.jpg');
      await photo.writeAsBytes([1, 2, 3]);
      final api = _createApi(
        _RecordingAdapter({
          'message': 'Profil berhasil diperbarui.',
          'user': _userJson(profilePhotoPath: 'profile-photos/old-photo.jpg'),
        }),
      );

      final result = await api.updateProfile(
        profilePhoto: photo,
        previousProfilePhotoPath: 'profile-photos/old-photo.jpg',
      );

      expect(result['success'], isFalse);
      expect(result['message'], contains('belum mengonfirmasi foto baru'));
    },
  );

  test(
    'shows a friendly warning when identity fields cannot be changed',
    () async {
      final photo = File('${tempDirectory.path}/profile.jpg');
      await photo.writeAsBytes([1, 2, 3]);
      final api = _createApi(
        _RecordingAdapter({
          'message': 'The name field is prohibited.',
          'errors': {
            'name': ['The name field is prohibited.'],
            'id_karyawan': ['The id karyawan field is prohibited.'],
          },
        }, statusCode: 422),
      );

      final result = await api.updateProfile(
        profilePhoto: photo,
        previousProfilePhotoPath: 'profile-photos/old-photo.jpg',
      );

      expect(result['success'], isFalse);
      expect(
        result['message'],
        'Waduh, mau ubah-ubah data ya? No-no dulu! Nama, ID karyawan, dan departemen hanya bisa diubah HRD.',
      );
    },
  );

  test('shows the server warning without Laravel validation details', () async {
    final photo = File('${tempDirectory.path}/profile.jpg');
    await photo.writeAsBytes([1, 2, 3]);
    final api = _createApi(
      _RecordingAdapter({
        'message':
            'Waduh, mau ubah-ubah data ya? No-no dulu! Nama, ID karyawan, dan departemen hanya bisa diubah HRD.',
      }, statusCode: 422),
    );

    final result = await api.updateProfile(
      profilePhoto: photo,
      previousProfilePhotoPath: 'profile-photos/old-photo.jpg',
    );

    expect(result['success'], isFalse);
    expect(
      result['message'],
      'Waduh, mau ubah-ubah data ya? No-no dulu! Nama, ID karyawan, dan departemen hanya bisa diubah HRD.',
    );
  });
}

ApiService _createApi(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1/'))
    ..httpClientAdapter = adapter;
  return ApiService.withDio(dio);
}

Map<String, dynamic> _userJson({required String profilePhotoPath}) => {
  'id': 1,
  'name': 'Karyawan',
  'email': 'employee@example.com',
  'id_karyawan': 'EMP-01',
  'departemen': 'Operasional',
  'employment_type': 'organik',
  'profile_photo_path': profilePhotoPath,
  'profile_photo_url': 'https://api.example.test/$profilePhotoPath',
};

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.responseBody, {this.statusCode = 200});

  final Map<String, dynamic> responseBody;
  final int statusCode;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
