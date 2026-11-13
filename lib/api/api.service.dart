// lib/services/api_service.dart

import 'package:universal_io/io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/demo_preview.dart';
import '../core/exceptions/app_exception.dart';
import '../models/user_model.dart';
import '../models/absensi_model.dart';
import '../models/notification_model.dart';
import '../services/attendance_location_service.dart';

class ApiService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  static const String _authTokenKey = 'auth_token';
  Future<void> Function()? onUnauthorized;

  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 60),
              headers: {'Accept': 'application/json'},
            ),
          ) {
    _dio.options.headers.putIfAbsent('Accept', () => 'application/json');
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (DemoPreview.enabled) {
            return handler.reject(
              DioException(
                requestOptions: options,
                message: 'Network access is disabled in local preview mode.',
              ),
            );
          }
          final token = await _storage.read(key: _authTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              _hasBearerToken(e.requestOptions.headers)) {
            debugPrint(
              'Unauthorized request. Token might be expired or invalid. Attempting to clear token.',
            );
            final unauthorizedHandler = onUnauthorized;
            if (unauthorizedHandler == null) {
              await _deleteToken();
            } else {
              await unauthorizedHandler();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  @visibleForTesting
  ApiService.withDio(this._dio);

  bool _hasBearerToken(Map<String, dynamic> headers) {
    for (final entry in headers.entries) {
      final value = entry.value;
      if (entry.key.toLowerCase() == 'authorization' &&
          value is String &&
          value.toLowerCase().startsWith('bearer ')) {
        return true;
      }
    }
    return false;
  }

  // =========================================================================
  // SECTION AUTH
  // =========================================================================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String idKaryawan,
    required String departemen,
    required String employmentType,
    required String workLocation,
  }) async {
    return {
      'success': false,
      'statusCode': 404,
      'message':
          'Pendaftaran mandiri belum tersedia. Silakan hubungi HRD untuk membuat akun.',
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) {
        await _saveToken(response.data['access_token']);
        final dynamic userData = response.data['user'];
        if (userData != null && userData is Map<String, dynamic>) {
          return {
            'success': true,
            'user': User.fromJson(userData),
            'access_token': response.data['access_token'],
          };
        }
        return {
          'success': true,
          'message': 'Login successful, but user data not found or invalid.',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Login failed.',
        };
      }
    } on DioException catch (e) {
      return _handleDioError(e, 'Login failed');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('logout');
    } on DioException {
      // Ignore error
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _deleteToken();
    }
  }

  Future<Map<String, dynamic>> sendOtp({required String email}) async {
    try {
      final response = await _dio.post(
        'forgot-password/send-otp',
        data: {'email': email},
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'OTP telah dikirim ke email Anda.',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal mengirim OTP.',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal mengirim OTP', logResponse: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        'forgot-password/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP valid.',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'OTP tidak valid.',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal verifikasi OTP', logResponse: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        'forgot-password/reset-password',
        data: {
          'email': email,
          'otp': otp,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password berhasil direset.',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal reset password.',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal reset password', logResponse: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.put(
        'user/password',
        data: {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ??
              'Password berhasil diperbarui. Silakan login kembali.',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal mengganti password.',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal mengganti password', logResponse: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<User?> getAuthenticatedUser() async {
    try {
      final token = await _storage.read(key: _authTokenKey);
      if (token == null || token.isEmpty) {
        return null;
      }
      final response = await _dio.get('user');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic userData = response.data['data'] ?? response.data;
        if (userData is Map<String, dynamic>) {
          return User.fromJson(userData);
        } else {
          throw const FormatException('Unexpected user response from API.');
        }
      }
      throw const FormatException('Empty user response from API.');
    } on DioException catch (e) {
      final error = _handleDioError(e, 'Gagal memuat data akun.');
      throw AppException(
        message: error['message'] as String,
        statusCode: error['statusCode'] as int?,
        isNetworkError: error['isNetworkError'] == true,
        errors: error['errors'],
      );
    }
  }

  // =========================================================================
  // SECTION PROFILE
  // =========================================================================

  Future<Map<String, dynamic>> updateProfile({
    required File profilePhoto,
    String? previousProfilePhotoPath,
  }) async {
    try {
      final String fileName = profilePhoto.path.split('/').last;
      final String? mimeType = lookupMimeType(profilePhoto.path);
      final formData = FormData.fromMap({
        'profile_photo': await MultipartFile.fromFile(
          profilePhoto.path,
          filename: fileName,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      });

      final response = await _dio.post(
        'user/profile',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic userData = response.data['user'] ?? response.data['data'];
        if (userData != null && userData is Map<String, dynamic>) {
          final updatedUser = User.fromJson(userData);
          if (updatedUser.profilePhotoPath == null ||
              updatedUser.profilePhotoPath!.isEmpty ||
              updatedUser.profilePhotoPath == previousProfilePhotoPath) {
            return {
              'success': false,
              'message':
                  'Data profil tersimpan, tetapi server belum mengonfirmasi foto baru. Coba pilih foto yang lebih kecil dan simpan kembali.',
            };
          }
          return {
            'success': true,
            'message': response.data['message'],
            'user': updatedUser,
          };
        }
        return {
          'success': false,
          'message':
              'Server tidak mengonfirmasi penyimpanan foto profil. Coba lagi.',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to update profile.',
      };
    } on DioException catch (e) {
      final error = _handleDioError(e, 'Gagal mengupdate profil');
      final validationErrors = error['errors'];
      if (validationErrors is Map &&
          validationErrors.keys.any(
            (field) => const {
              'name',
              'id_karyawan',
              'departemen',
            }.contains(field.toString()),
          )) {
        error['message'] =
            'Waduh, mau ubah-ubah data ya? No-no dulu! Nama, ID karyawan, dan departemen hanya bisa diubah HRD.';
      }
      return error;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =========================================================================
  // SECTION ABSENSI
  // =========================================================================

  Future<Map<String, dynamic>> absenMasuk({
    required File foto,
    required double lat,
    required double lng,
    required double accuracyMeters,
    required String status,
    bool isMocked = false,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      String fileName = foto.path.split('/').last;
      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(foto.path, filename: fileName),
        'lat': lat,
        'lng': lng,
        'accuracy_meters': accuracyMeters,
        'status': status,
        'is_mocked': isMocked ? 1 : 0,
      });

      final response = await _dio.post(
        'absensi/masuk',
        data: formData,
        onSendProgress: onProgress,
      );
      if (response.data != null && response.data['data'] != null) {
        return {
          'success': true,
          'message': response.data['message'],
          'data': Absensi.fromJson(response.data['data']),
        };
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Absen masuk gagal');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> absenPulang({
    required File foto,
    required double lat,
    required double lng,
    required double accuracyMeters,
    String? tipe,
    String? keterangan,
    File? fileBukti,
    bool isMocked = false,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      String fileName = foto.path.split('/').last;
      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(foto.path, filename: fileName),
        'lat': lat,
        'lng': lng,
        'accuracy_meters': accuracyMeters,
        'is_mocked': isMocked ? 1 : 0,
        if (tipe != null) 'tipe': tipe,
        if (keterangan != null) 'keterangan_izin_sakit': keterangan,
      });

      if (fileBukti != null) {
        formData.files.add(
          MapEntry(
            'file_bukti',
            await MultipartFile.fromFile(
              fileBukti.path,
              filename: fileBukti.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        'absensi/pulang',
        data: formData,
        onSendProgress: onProgress,
      );
      if (response.data != null && response.data['data'] != null) {
        return {
          'success': true,
          'message': response.data['message'],
          'data': Absensi.fromJson(response.data['data']),
        };
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Absen pulang gagal');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> absenLembur({
    required File foto,
    required double lat,
    required double lng,
    required String jamMulai,
    required String jamSelesai,
    required bool istirahat,
    required String keterangan,
    required String goals,
    required List<File> hasilKerjaFiles,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      String fileName = foto.path.split('/').last;
      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(foto.path, filename: fileName),
        'lat': lat,
        'lng': lng,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'istirahat': istirahat ? '1' : '0',
        'keterangan': keterangan,
        'keterangan_goals': goals,
      });

      if (hasilKerjaFiles.isNotEmpty) {
        String hFileName2 = hasilKerjaFiles[0].path.split('/').last;
        formData.files.add(
          MapEntry(
            'foto_2',
            await MultipartFile.fromFile(
              hasilKerjaFiles[0].path,
              filename: hFileName2,
            ),
          ),
        );
      }

      if (hasilKerjaFiles.length > 1) {
        String hFileName3 = hasilKerjaFiles[1].path.split('/').last;
        formData.files.add(
          MapEntry(
            'foto_3',
            await MultipartFile.fromFile(
              hasilKerjaFiles[1].path,
              filename: hFileName3,
            ),
          ),
        );
      }

      if (hasilKerjaFiles.length > 2) {
        String hFileName4 = hasilKerjaFiles[2].path.split('/').last;
        formData.files.add(
          MapEntry(
            'foto_4',
            await MultipartFile.fromFile(
              hasilKerjaFiles[2].path,
              filename: hFileName4,
            ),
          ),
        );
      }

      if (hasilKerjaFiles.length > 3) {
        String hFileName5 = hasilKerjaFiles[3].path.split('/').last;
        formData.files.add(
          MapEntry(
            'foto_5',
            await MultipartFile.fromFile(
              hasilKerjaFiles[3].path,
              filename: hFileName5,
            ),
          ),
        );
      }

      if (hasilKerjaFiles.length > 4) {
        String hFileName6 = hasilKerjaFiles[4].path.split('/').last;
        formData.files.add(
          MapEntry(
            'foto_6',
            await MultipartFile.fromFile(
              hasilKerjaFiles[4].path,
              filename: hFileName6,
            ),
          ),
        );
      }

      final response = await _dio.post(
        'absensi/lembur',
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      if (response.data != null && response.data['data'] != null) {
        return {
          'success': true,
          'message': response.data['message'],
          'data': Absensi.fromJson(response.data['data']),
        };
      }
      return {
        'success': false,
        'message': 'Data absensi lembur tidak ditemukan.',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Absen lembur gagal');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Pengajuan lembur terpisah dari flow pulang
  /// Endpoint: POST /absensi/submit-lembur
  Future<Map<String, dynamic>> submitLembur({
    required String jamMulai,
    required String jamSelesai,
    required bool istirahat,
    required String keterangan,
    required String goals,
    required List<File> hasilKerjaFiles,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'istirahat': istirahat ? '1' : '0',
        'keterangan': keterangan,
        'keterangan_goals': goals,
      });

      for (int i = 0; i < hasilKerjaFiles.length && i < 5; i++) {
        String fieldName = i == 0 ? 'foto_bukti' : 'foto_${i + 1}';
        String fName = hasilKerjaFiles[i].path.split('/').last;
        formData.files.add(
          MapEntry(
            fieldName,
            await MultipartFile.fromFile(
              hasilKerjaFiles[i].path,
              filename: fName,
            ),
          ),
        );
      }

      final response = await _dio.post(
        'absensi/submit-lembur',
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      if (response.data != null) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Pengajuan lembur berhasil.',
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': 'Data tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Pengajuan lembur gagal');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Absensi>> getHistoryAbsensi({
    String? searchDate,
    int? month,
    int? year,
  }) async {
    try {
      Map<String, dynamic> queryParameters = {};
      if (searchDate != null) queryParameters['search_date'] = searchDate;
      if (month != null) queryParameters['month'] = month;
      if (year != null) queryParameters['year'] = year;

      final response = await _dio.get(
        'absensi/me',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((e) => Absensi.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const FormatException('Unexpected attendance response from API.');
    } on DioException catch (e) {
      final error = _handleDioError(e, 'Gagal mengambil riwayat absensi');
      throw AppException(
        message: error['message'] as String,
        statusCode: error['statusCode'] as int?,
        isNetworkError: error['isNetworkError'] == true,
        errors: error['errors'],
      );
    }
  }

  Future<Map<String, dynamic>> absenSakit({
    required File fileBukti,
    required String catatan,
    DateTime? startDate,
    DateTime? endDate,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      String fileName = fileBukti.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file_bukti': await MultipartFile.fromFile(
          fileBukti.path,
          filename: fileName,
        ),
        'keterangan_izin_sakit': catatan,
        'status': 'sakit',
        if (startDate != null)
          'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        if (endDate != null)
          'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      });

      final response = await _dio.post(
        'absensi/sakit',
        data: formData,
        onSendProgress: onProgress,
      );
      if (response.data != null) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Pengajuan izin sakit berhasil.',
        };
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal mengajukan izin sakit');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> absenIzin({
    required File fileBukti,
    required String catatan,
    required String catatanPanggilan,
    DateTime? startDate,
    DateTime? endDate,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      String fileName = fileBukti.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file_bukti': await MultipartFile.fromFile(
          fileBukti.path,
          filename: fileName,
        ),
        'keterangan_izin_sakit': catatan, // ✅ fix
        'catatan_admin': catatanPanggilan, // ✅ fix
        'status': 'izin', // ✅ tambah status
        if (startDate != null)
          'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        if (endDate != null)
          'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      });

      final response = await _dio.post(
        'absensi/izin',
        data: formData,
        onSendProgress: onProgress,
      );
      if (response.data != null) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Pengajuan izin berhasil.',
        };
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal mengajukan izin');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitEarlyLeaveRequest({
    required Uint8List fileBytes,
    required String fileName,
    required String catatan,
    required String jamPulangRencana,
  }) async {
    try {
      final extension = fileName.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
        'png' => MediaType('image', 'png'),
        'pdf' => MediaType('application', 'pdf'),
        _ => null,
      };
      final formData = FormData.fromMap({
        'status': 'izin',
        'catatan_admin': 'izin_pulang_cepat',
        'jam_pulang_rencana': jamPulangRencana,
        'keterangan_izin_sakit': catatan,
        'file_bukti': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: contentType,
        ),
      });

      final response = await _dio.post(
        'absensi/izin',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final responseData = response.data;
      if (response.statusCode == 201 &&
          responseData is Map<String, dynamic> &&
          responseData['success'] == true) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Pengajuan terkirim dan menunggu persetujuan HRD.',
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': responseData is Map<String, dynamic>
            ? responseData['message'] ?? 'Pengajuan pulang lebih awal gagal.'
            : 'Pengajuan pulang lebih awal gagal.',
      };
    } on DioException catch (e) {
      return _handleDioError(
        e,
        'Gagal mengajukan pulang lebih awal.',
        logResponse: false,
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> pengajuanTelat({
    required File fileBukti,
    required String keterangan,
    required int absensiId,
  }) async {
    try {
      String fileName = fileBukti.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file_bukti': await MultipartFile.fromFile(
          fileBukti.path,
          filename: fileName,
        ),
        'keterangan': keterangan,
        'absensi_id': absensiId,
      });

      final response = await _dio.post('absensi/telat', data: formData);
      if (response.data != null) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Pengajuan telat berhasil.',
          'late_minutes': response.data['late_minutes'],
        };
      }
      return {'success': false, 'message': 'Data tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal mengajukan keterangan telat');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =========================================================================
  // NEW METHODS: RESUBMIT
  // =========================================================================

  Future<Map<String, dynamic>> resubmitSakit({
    required int absensiId,
    required File fileBukti,
    required String catatan,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Map<String, dynamic> mapData = {
        'keterangan_izin_sakit': catatan,

        if (startDate != null)
          'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        if (endDate != null)
          'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      };

      FormData formData = FormData.fromMap(mapData);

      String fileName = fileBukti.path.split('/').last;
      formData.files.add(
        MapEntry(
          'file_bukti',
          await MultipartFile.fromFile(fileBukti.path, filename: fileName),
        ),
      );

      final response = await _dio.post(
        'absensi/sakit/$absensiId/resubmit',
        data: formData,
      );
      if (response.data != null) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Resubmit izin sakit berhasil.',
        };
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal resubmit izin sakit');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resubmitIzin({
    required int absensiId,
    required File fileBukti,
    required String catatan,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Map<String, dynamic> mapData = {
        'keterangan_izin_sakit': catatan,

        if (startDate != null)
          'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        if (endDate != null)
          'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      };

      FormData formData = FormData.fromMap(mapData);

      String fileName = fileBukti.path.split('/').last;
      formData.files.add(
        MapEntry(
          'file_bukti',
          await MultipartFile.fromFile(fileBukti.path, filename: fileName),
        ),
      );

      final response = await _dio.post(
        'absensi/izin/$absensiId/resubmit',
        data: formData,
      );
      if (response.data != null) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Resubmit izin berhasil.',
        };
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal resubmit izin');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resubmitLembur({
    required int absensiId,
    required List<File> hasilKerjaFiles,
    required double lat,
    required double lng,
    required String jamMulai,
    required String jamSelesai,
    required bool istirahat,
    required String keterangan,
    required String goals,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'lat': lat,
        'lng': lng,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'istirahat': istirahat ? '1' : '0',
        'keterangan': keterangan,
        'keterangan_goals': goals,
      });

      for (int i = 0; i < hasilKerjaFiles.length && i < 5; i++) {
        final fieldName = i == 0 ? 'foto' : 'foto_${i + 1}';
        String fName = hasilKerjaFiles[i].path.split('/').last;
        formData.files.add(
          MapEntry(
            fieldName,
            await MultipartFile.fromFile(
              hasilKerjaFiles[i].path,
              filename: fName,
            ),
          ),
        );
      }

      final response = await _dio.post(
        'absensi/lembur/$absensiId/resubmit',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      if (response.data != null) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Resubmit lembur berhasil.',
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': 'Data tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal resubmit lembur');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =========================================================================
  // SECTION NOTIFICATIONS
  // =========================================================================

  Future<int> fetchUnreadCount() async {
    try {
      final response = await _dio.get('notifications');
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['data'] is List) {
        final List notifs = response.data['data'];
        final unread = notifs.where((n) {
          final value = n['is_read'];
          return value != true && value != 1 && value?.toString() != '1';
        }).length;
        return unread;
      }
      throw const FormatException(
        'Unexpected notifications response from API.',
      );
    } on DioException catch (e) {
      final error = _handleDioError(
        e,
        'Gagal mengambil jumlah notifikasi belum dibaca',
      );
      throw AppException(
        message: error['message'] as String,
        statusCode: error['statusCode'] as int?,
        isNetworkError: error['isNetworkError'] == true,
        errors: error['errors'],
      );
    }
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final response = await _dio.get('notifications');
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const FormatException(
        'Unexpected notifications response from API.',
      );
    } on DioException catch (e) {
      final error = _handleDioError(e, 'Gagal mengambil daftar notifikasi');
      throw AppException(
        message: error['message'] as String,
        statusCode: error['statusCode'] as int?,
        isNetworkError: error['isNetworkError'] == true,
        errors: error['errors'],
      );
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(
    int notificationId,
  ) async {
    try {
      final response = await _dio.put('notifications/$notificationId/read');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ??
              'Notifikasi berhasil ditandai dibaca.',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal menandai notifikasi.',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal menandai notifikasi dibaca');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =========================================================================
  Future<List<Map<String, dynamic>>> fetchPayrollSlips() async {
    try {
      final response = await _dio.get('payroll/slips');
      final dynamic data = response.data?['data'];
      if (response.statusCode == 200 && data is List) {
        return data.whereType<Map<String, dynamic>>().toList(growable: false);
      }
      throw const FormatException('Unexpected payroll slips response.');
    } on DioException catch (e) {
      final error = _handleDioError(e, 'Gagal mengambil slip gaji');
      throw AppException(
        message: error['message'] as String,
        statusCode: error['statusCode'] as int?,
        isNetworkError: error['isNetworkError'] == true,
        errors: error['errors'],
      );
    }
  }

  Future<AttendanceGeofenceConfig> fetchAttendanceGeofence() async {
    try {
      final response = await _dio.get('attendance/geofence');
      final dynamic data = response.data?['data'];
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return AttendanceGeofenceConfig.fromJson(data);
      }
      throw const FormatException('Unexpected attendance geofence response.');
    } on DioException catch (e) {
      final error = _handleDioError(
        e,
        'Gagal mengambil konfigurasi lokasi kerja',
      );
      throw AppException(
        message: error['message'] as String,
        statusCode: error['statusCode'] as int?,
        isNetworkError: error['isNetworkError'] == true,
        errors: error['errors'],
      );
    }
  }

  Future<Map<String, dynamic>> fetchEmployeeHrRequests() async {
    try {
      final response = await _dio.get('hr-requests');
      final dynamic data = response.data?['data'];
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'message': 'Format data pengajuan HR tidak dikenali.',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal mengambil pengajuan HR');
    }
  }

  Future<Map<String, dynamic>> submitReimbursement({
    required int typeId,
    required int amount,
    required String description,
    required Uint8List receiptBytes,
    required String receiptName,
  }) async {
    try {
      final extension = receiptName.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
        'png' => MediaType('image', 'png'),
        'pdf' => MediaType('application', 'pdf'),
        _ => throw const FormatException('Format bukti tidak didukung.'),
      };
      final response = await _dio.post(
        'hr-requests/reimbursements',
        data: FormData.fromMap({
          'type_id': typeId,
          'amount': amount,
          'description': description,
          'receipt': MultipartFile.fromBytes(
            receiptBytes,
            filename: receiptName,
            contentType: contentType,
          ),
        }),
        options: Options(contentType: 'multipart/form-data'),
      );
      final dynamic data = response.data;
      if (response.statusCode == 201 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pengajuan reimbursement terkirim.',
        };
      }
      return {
        'success': false,
        'message': data is Map<String, dynamic>
            ? data['message'] ?? 'Pengajuan reimbursement gagal.'
            : 'Pengajuan reimbursement gagal.',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Pengajuan reimbursement gagal');
    } on FormatException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<Map<String, dynamic>> submitLoanRequest({
    required int principal,
    required int tenorMonths,
    required String purpose,
  }) async {
    try {
      final response = await _dio.post(
        'hr-requests/loans',
        data: {
          'principal': principal,
          'tenor_months': tenorMonths,
          'purpose': purpose,
        },
      );
      final dynamic data = response.data;
      if (response.statusCode == 201 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pengajuan pinjaman terkirim.',
        };
      }
      return {
        'success': false,
        'message': data is Map<String, dynamic>
            ? data['message'] ?? 'Pengajuan pinjaman gagal.'
            : 'Pengajuan pinjaman gagal.',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Pengajuan pinjaman gagal');
    }
  }

  Future<Uint8List> downloadPayrollSlip(int itemId) async {
    try {
      final response = await _dio.get<List<int>>(
        'payroll/slips/$itemId/download',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (response.statusCode == 200 &&
          bytes != null &&
          bytes.isNotEmpty &&
          (response.headers
                  .value(Headers.contentTypeHeader)
                  ?.contains('application/pdf') ??
              false)) {
        return Uint8List.fromList(bytes);
      }
      throw const FormatException('Unexpected payroll slip download response.');
    } on DioException catch (e) {
      final error = _handleDioError(e, 'Gagal mengunduh slip gaji');
      throw AppException(
        message: error['message'] as String,
        statusCode: error['statusCode'] as int?,
        isNetworkError: error['isNetworkError'] == true,
        errors: error['errors'],
      );
    }
  }

  // SECTION TOKEN & ERROR HANDLING
  // =========================================================================

  Future<void> _saveToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  Future<void> _deleteToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  Future<Uint8List?> getImageBytes(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Uint8List) {
          return response.data;
        } else if (response.data is List<int>) {
          return Uint8List.fromList(response.data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading image bytes: $e');
      return null;
    }
  }

  Map<String, dynamic> _handleDioError(
    DioException e,
    String defaultMessage, {
    bool logResponse = true,
  }) {
    String message = defaultMessage;
    bool isNetworkError = false;
    dynamic validationErrors;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      isNetworkError = true;
      message =
          'Tidak dapat terhubung ke server. Periksa koneksi dan alamat API.';
    }

    if (e.response != null) {
      if (e.response!.data != null &&
          e.response!.data is Map<String, dynamic>) {
        validationErrors = e.response!.data['errors'];
        if (e.response!.data.containsKey('message') &&
            e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data.containsKey('errors') &&
            e.response!.data['errors'] != null) {
          Map<String, dynamic> errors = e.response!.data['errors'];
          if (errors.values.isNotEmpty && errors.values.first.isNotEmpty) {
            message = errors.values.first[0].toString();
          } else {
            message = 'Validation error.';
          }
        }
      } else {
        message = 'Server error: ${e.response!.statusCode}';
      }
      if (validationErrors is Map) {
        final details = validationErrors.values
            .expand((value) => value is List ? value : [value])
            .where((value) => value != null)
            .map((value) => value.toString())
            .toList();
        final missingDetails = details
            .where((detail) => !message.contains(detail))
            .toList();
        if (missingDetails.isNotEmpty) {
          message = '$message ${missingDetails.join(' ')}';
        }
      }
      if (logResponse) {
        debugPrint('Dio request failed with status ${e.response!.statusCode}.');
      }
    } else if (!isNetworkError) {
      message = 'Network error: ${e.message}';
      if (logResponse) {
        debugPrint('Dio error: ${e.message}');
      }
    }

    return {
      'success': false,
      'message': message,
      'statusCode': e.response?.statusCode,
      'isNetworkError': isNetworkError,
      'data': e.response?.data,
      if (validationErrors != null) 'errors': validationErrors,
    };
  }
}
