import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/api.service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/validation/password_validation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  late AnimationController _bgAnimController;
  late Animation<Alignment> _topAlignment;
  late Animation<Alignment> _bottomAlignment;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _topAlignment = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(_bgAnimController);
    _bottomAlignment = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(_bgAnimController);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showCustomAlert(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 8,
      ),
    );
  }

  void _showFunnyNetworkErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.signal_wifi_connected_no_internet_4_rounded,
                    color: Color(0xFFFB7185),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Koneksi terputus',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Periksa koneksi internet Anda, lalu coba masuk kembali.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFB7185),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoading) return;

    // Premium Haptic Feedback
    HapticFeedback.mediumImpact();

    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      try {
        await authProvider.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (authProvider.isAuthenticated) {
          if (!mounted || !context.mounted) return;
          _showCustomAlert('Login Berhasil! Selamat Datang.', isSuccess: true);
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          if (!mounted || !context.mounted) return;
          _showCustomAlert(
            'Email atau kata sandi tidak cocok. Periksa kembali lalu coba lagi.',
          );
        }
      } catch (e) {
        if (!mounted || !context.mounted) return;
        debugPrint('Login error: $e');
        if (e is AppException) {
          if (e.isNetworkError) {
            _showFunnyNetworkErrorDialog();
          } else if (e.statusCode != null && e.statusCode! >= 500) {
            _showCustomAlert(
              'Aduh, server lagi bermasalah nih. Coba lagi nanti ya!',
            );
          } else if (e.statusCode == 401) {
            _showCustomAlert(
              'Email atau kata sandi tidak cocok. Periksa kembali lalu coba lagi.',
            );
          } else {
            _showCustomAlert(e.message);
          }
        } else {
          _showCustomAlert(
            'Terjadi kesalahan yang tidak terduga. Coba lagi ya!',
          );
        }
      }
    }
  }

  Widget _buildLoginTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontFamily: 'Poppins',
        ),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        suffixIcon: isPassword
            ? IconButton(
                tooltip: isPasswordVisible
                    ? 'Sembunyikan password'
                    : 'Lihat password',
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF8A939B),
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FollowMeTokens.radiusSmall),
          borderSide: const BorderSide(color: FollowMeTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FollowMeTokens.radiusSmall),
          borderSide: const BorderSide(color: FollowMeTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FollowMeTokens.radiusSmall),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FollowMeTokens.radiusSmall),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FollowMeTokens.radiusSmall),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(fontFamily: 'Poppins'),
      ),
      validator: validator,
    );
  }

  Future<void> _showForgotPasswordPopup() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    int step = 1;
    bool isLoading = false;

    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool showNewPassword = false;
    bool showConfirmPassword = false;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Forgot Password',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFEFD),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE9EDF2)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7C3A2D,
                              ).withValues(alpha: 0.12),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                step == 1
                                    ? 'Reset Password'
                                    : step == 2
                                    ? 'Verifikasi OTP'
                                    : 'Password Baru',
                                style: const TextStyle(
                                  color: Color(0xFF263238),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step == 1
                                    ? 'Masukkan email akun Anda.'
                                    : step == 2
                                    ? 'Masukkan 6 digit kode OTP.'
                                    : 'Buat sandi baru yang aman.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF8A939B),
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 24),

                              if (step == 1)
                                TextFormField(
                                  controller: emailController,
                                  style: const TextStyle(
                                    color: Color(0xFF263238),
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    hintText: 'Email',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF8A939B),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE9EDF2),
                                      ),
                                    ),
                                  ),
                                  validator: PasswordValidation.email,
                                ),

                              if (step == 2)
                                TextFormField(
                                  controller: otpController,
                                  style: const TextStyle(
                                    color: Color(0xFF263238),
                                    letterSpacing: 4,
                                  ),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    hintText: '000000',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF8A939B),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE9EDF2),
                                      ),
                                    ),
                                    counterText: "",
                                  ),
                                  validator: PasswordValidation.otp,
                                ),

                              if (step == 3) ...[
                                TextFormField(
                                  controller: newPasswordController,
                                  obscureText: !showNewPassword,
                                  style: const TextStyle(
                                    color: Color(0xFF263238),
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    hintText: 'Password Baru',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF8A939B),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE9EDF2),
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showNewPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: const Color(0xFF8A939B),
                                      ),
                                      onPressed: () => setDialogState(
                                        () =>
                                            showNewPassword = !showNewPassword,
                                      ),
                                    ),
                                  ),
                                  validator: PasswordValidation.newPassword,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: !showConfirmPassword,
                                  style: const TextStyle(
                                    color: Color(0xFF263238),
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    hintText: 'Konfirmasi Password',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF8A939B),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE9EDF2),
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: const Color(0xFF8A939B),
                                      ),
                                      onPressed: () => setDialogState(
                                        () => showConfirmPassword =
                                            !showConfirmPassword,
                                      ),
                                    ),
                                  ),
                                  validator: (v) =>
                                      PasswordValidation.confirmation(
                                        v,
                                        newPasswordController.text,
                                      ),
                                ),
                              ],

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF172B3A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          if (!formKey.currentState!
                                              .validate()) {
                                            return;
                                          }
                                          setDialogState(
                                            () => isLoading = true,
                                          );
                                          Map<String, dynamic> result = {};

                                          if (step == 1) {
                                            result = await apiService.sendOtp(
                                              email: emailController.text
                                                  .trim(),
                                            );
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            if (result['success'] == true) {
                                              setDialogState(() {
                                                step = 2;
                                                isLoading = false;
                                              });
                                              return;
                                            }
                                          } else if (step == 2) {
                                            result = await apiService.verifyOtp(
                                              email: emailController.text
                                                  .trim(),
                                              otp: otpController.text.trim(),
                                            );
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            if (result['success'] == true) {
                                              setDialogState(() {
                                                step = 3;
                                                isLoading = false;
                                              });
                                              return;
                                            }
                                          } else {
                                            result = await apiService
                                                .resetPassword(
                                                  email: emailController.text
                                                      .trim(),
                                                  otp: otpController.text
                                                      .trim(),
                                                  password:
                                                      newPasswordController
                                                          .text,
                                                  passwordConfirmation:
                                                      confirmPasswordController
                                                          .text,
                                                );
                                            if (!mounted || !context.mounted) {
                                              return;
                                            }
                                            if (result['success'] == true) {
                                              await Provider.of<AuthProvider>(
                                                context,
                                                listen: false,
                                              ).clearSessionLocally();
                                              if (!mounted ||
                                                  !context.mounted) {
                                                return;
                                              }
                                              Navigator.of(context).pop();
                                              _showCustomAlert(
                                                result['message'] ??
                                                    'Password berhasil direset. Silakan login kembali.',
                                                isSuccess: true,
                                              );
                                              return;
                                            }
                                          }
                                          setDialogState(
                                            () => isLoading = false,
                                          );
                                          _showCustomAlert(
                                            result['message'] ??
                                                'Terjadi kesalahan.',
                                          );
                                        },
                                  child: isLoading
                                      ? const _ModernLoading()
                                      : const Text(
                                          'Lanjutkan',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.scaffoldBackgroundColor,
                  theme.colorScheme.surfaceContainerHighest,
                  theme.scaffoldBackgroundColor,
                ],
                begin: _topAlignment.value,
                end: _bottomAlignment.value,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: FollowMeTokens.primary.withValues(
                                  alpha: 0.13,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: 188,
                                child: _LoginHeroIllustration(),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  0,
                                  22,
                                  18,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Selamat Datang Kembali!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Silakan masuk ke akun Anda',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          _buildLoginTextField(
                                            controller: _emailController,
                                            label: 'Email',
                                            icon: Icons.email_outlined,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: (val) {
                                              if (val == null || val.isEmpty) {
                                                return 'Email wajib diisi';
                                              }
                                              if (!val.contains('@')) {
                                                return 'Format email tidak valid';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          _buildLoginTextField(
                                            controller: _passwordController,
                                            label: 'Password',
                                            icon: Icons.lock_outline,
                                            isPassword: true,
                                            isPasswordVisible:
                                                _isPasswordVisible,
                                            onVisibilityToggle: () {
                                              setState(() {
                                                _isPasswordVisible =
                                                    !_isPasswordVisible;
                                              });
                                            },
                                            validator: (val) {
                                              if (val == null || val.isEmpty) {
                                                return 'Password wajib diisi';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _showForgotPasswordPopup,
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              theme.colorScheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Lupa Password?',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, child) {
                                        return SizedBox(
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed: authProvider.isLoading
                                                ? null
                                                : _login,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  theme.colorScheme.primary,
                                              disabledBackgroundColor: theme
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.6),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: authProvider.isLoading
                                                ? const SizedBox(
                                                    width: 60,
                                                    height: 24,
                                                    child: Center(
                                                      child: _ModernLoading(),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Masuk',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 15,
                                          color: Color(0xFF8A939B),
                                        ),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Belum punya akun? Hubungi HRD.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color(0xFF8A939B),
                                              fontSize: 11,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginHeroIllustration extends StatelessWidget {
  const _LoginHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LoginHeroPainter(),
      child: Center(
        child: Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: FollowMeTokens.primary.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              'assets/images/followme.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = FollowMeTokens.primary.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.18), 92, paint);
    paint.color = FollowMeTokens.accent.withValues(alpha: 0.34);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.86), 76, paint);
    paint.color = FollowMeTokens.primary.withValues(alpha: 0.24);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.22), 5, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.78), 4, paint);
  }

  @override
  bool shouldRepaint(covariant _LoginHeroPainter oldDelegate) => false;
}

class _ModernLoading extends StatefulWidget {
  final Color color;
  const _ModernLoading() : color = Colors.white;
  @override
  State<_ModernLoading> createState() => _ModernLoadingState();
}

class _ModernLoadingState extends State<_ModernLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = (_ctrl.value * 2 * math.pi) + (i * math.pi / 2);
            final offset = math.sin(t) * 4;
            final alpha = (math.sin(t) + 1) / 2 * 0.6 + 0.4;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Opacity(
                  opacity: alpha,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
