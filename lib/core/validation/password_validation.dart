abstract final class PasswordValidation {
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? otp(String? value) {
    final otp = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'OTP harus terdiri dari 6 digit angka';
    }
    return null;
  }

  static String? newPassword(String? value) {
    if ((value ?? '').length < 8) {
      return 'Password minimal 8 karakter';
    }
    return null;
  }

  static String? confirmation(String? value, String password) {
    if (value != password) return 'Konfirmasi password tidak cocok';
    return null;
  }

  static String? currentPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password lama wajib diisi';
    return null;
  }
}
