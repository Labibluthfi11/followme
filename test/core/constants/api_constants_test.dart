import 'package:absensi_app/core/constants/api_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to the production API over HTTPS', () {
    expect(ApiConstants.baseUrl, 'https://sistemabsensi.followme.id/api/v1/');
  });
}
