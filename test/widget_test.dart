// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:absensi_app/core/constants/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'FollowMe defines light and dark themes with attendance status colors',
    () {
      expect(buildAppTheme().brightness, Brightness.light);
      expect(buildAppDarkTheme().brightness, Brightness.dark);
      expect(FollowMeTokens.present, isNot(FollowMeTokens.absent));
      expect(FollowMeTokens.leave, isNot(FollowMeTokens.overtime));
    },
  );
}
