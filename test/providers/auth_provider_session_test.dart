import 'dart:convert';

import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/models/user_model.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/services/notification_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'clears local credentials and user data after password change',
    () async {
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'person@example.com',
        idKaryawan: 'EMP-1',
        departemen: 'IT',
        employmentType: 'freelance',
      );
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'revoked-token',
      });
      SharedPreferences.setMockInitialValues({
        'user_data': jsonEncode(user.toJson()),
      });

      final provider = AuthProvider(
        apiService: ApiService.withDio(Dio()),
        pushTokenProvider: _FakePushTokenProvider(),
      );
      await provider.initializationFuture;
      await provider.clearSessionLocally();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.user, isNull);
      expect(
        await const FlutterSecureStorage().read(key: 'auth_token'),
        isNull,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('user_data'), isFalse);
    },
  );
}

class _FakePushTokenProvider implements PushTokenProvider {
  @override
  Future<String?> requestPermissionAndGetToken() async => null;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  void setTokenRefreshHandler(Future<void> Function(String token)? handler) {}
}
