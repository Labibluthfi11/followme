import 'dart:convert';
import 'dart:typed_data';

import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/screens/home/change_password_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'successful password change closes the dialog without widget exceptions',
    (tester) async {
      final apiService = ApiService.withDio(
        Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1/'))
          ..httpClientAdapter = _SuccessAdapter(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => ChangePasswordDialog(apiService: apiService),
                ),
                child: const Text('Open password dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open password dialog'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'oldpassword');
      await tester.enterText(find.byType(TextFormField).at(1), 'newpassword');
      await tester.enterText(find.byType(TextFormField).at(2), 'newpassword');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Ganti Password'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _SuccessAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'message': 'Password berhasil diperbarui.'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
