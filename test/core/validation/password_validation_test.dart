import 'package:absensi_app/core/validation/password_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordValidation', () {
    test('validates a non-empty email address', () {
      expect(PasswordValidation.email('person@example.com'), isNull);
      expect(PasswordValidation.email('invalid-email'), isNotNull);
      expect(PasswordValidation.email(' '), isNotNull);
    });

    test('accepts only six numeric OTP digits', () {
      expect(PasswordValidation.otp('123456'), isNull);
      expect(PasswordValidation.otp('12345'), isNotNull);
      expect(PasswordValidation.otp('12a456'), isNotNull);
    });

    test('requires new passwords to have at least eight characters', () {
      expect(PasswordValidation.newPassword('12345678'), isNull);
      expect(PasswordValidation.newPassword('1234567'), isNotNull);
    });

    test('validates confirmation and current password', () {
      expect(
        PasswordValidation.confirmation('newpassword', 'newpassword'),
        isNull,
      );
      expect(
        PasswordValidation.confirmation('different', 'newpassword'),
        isNotNull,
      );
      expect(PasswordValidation.currentPassword('oldpassword'), isNull);
      expect(PasswordValidation.currentPassword(''), isNotNull);
    });
  });
}
