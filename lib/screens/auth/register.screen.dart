import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();
  final TextEditingController _idKaryawanController = TextEditingController();
  final TextEditingController _departemenController = TextEditingController();

  String _selectedEmploymentType = 'organik';
  String _selectedWorkLocation = 'office';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
      begin: Alignment.topRight,
      end: Alignment.topLeft,
    ).animate(_bgAnimController);
    _bottomAlignment = Tween<Alignment>(
      begin: Alignment.bottomLeft,
      end: Alignment.bottomRight,
    ).animate(_bgAnimController);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _idKaryawanController.dispose();
    _departemenController.dispose();
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

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        await authProvider.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
          idKaryawan: _idKaryawanController.text,
          departemen: _departemenController.text,
          employmentType: _selectedEmploymentType,
          workLocation: _selectedWorkLocation,
        );

        if (authProvider.isAuthenticated) {
          if (!mounted) return;
          _showCustomAlert(
            'Registrasi Berhasil! Selamat datang.',
            isSuccess: true,
          );
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          if (!mounted) return;
          _showCustomAlert(
            authProvider.errorMessage ?? 'Registrasi gagal. Coba lagi.',
          );
        }
      } catch (e) {
        if (!mounted) return;
        _showCustomAlert(
          authProvider.errorMessage ?? 'Terjadi kesalahan sistem.',
        );
      }
    }
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(FollowMeTokens.radiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(FollowMeTokens.radiusMedium),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Poppins',
              ),
              prefixIcon: Icon(icon, color: theme.colorScheme.primary),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              errorStyle: TextStyle(color: theme.colorScheme.error),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(FollowMeTokens.radiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(FollowMeTokens.radiusMedium),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: theme.colorScheme.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            dropdownColor: theme.colorScheme.surface,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontFamily: 'Poppins',
              fontSize: 15,
            ),
            initialValue: value,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        // Header
                        Center(
                          child: Container(
                            height: 120,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surface,
                            ),
                            child: Image.asset(
                              "assets/images/logo.png",
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.app_registration,
                                    size: 70,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join us to manage your absensi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 30),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildGlassTextField(
                                controller: _nameController,
                                label: 'Nama Lengkap',
                                icon: Icons.person_outline,
                                validator: (val) => (val == null || val.isEmpty)
                                    ? 'Nama wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              _buildGlassTextField(
                                controller: _idKaryawanController,
                                label: 'ID Karyawan (cth: AMB071)',
                                icon: Icons.badge_outlined,
                                validator: (val) => (val == null || val.isEmpty)
                                    ? 'ID wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              _buildGlassTextField(
                                controller: _departemenController,
                                label: 'Departemen',
                                icon: Icons.work_outline,
                                validator: (val) => (val == null || val.isEmpty)
                                    ? 'Departemen wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              _buildGlassDropdown(
                                label: 'Status Karyawan',
                                icon: Icons.card_membership,
                                value: _selectedEmploymentType,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'organik',
                                    child: Text('Karyawan Organik'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'freelance',
                                    child: Text('Freelance / Kontrak'),
                                  ),
                                ],
                                onChanged: (val) => setState(
                                  () => _selectedEmploymentType = val!,
                                ),
                              ),
                              const SizedBox(height: 16),

                              _buildGlassDropdown(
                                label: 'Lokasi Kerja',
                                icon: Icons.location_on_outlined,
                                value: _selectedWorkLocation,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'office',
                                    child: Text('Office'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'produksi',
                                    child: Text('Produksi'),
                                  ),
                                ],
                                onChanged: (val) => setState(
                                  () => _selectedWorkLocation = val!,
                                ),
                              ),
                              const SizedBox(height: 16),

                              _buildGlassTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.alternate_email,
                                keyboardType: TextInputType.emailAddress,
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
                              const SizedBox(height: 16),

                              _buildGlassTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isPasswordVisible: _isPasswordVisible,
                                onVisibilityToggle: () => setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                                validator: (val) =>
                                    (val == null || val.length < 6)
                                    ? 'Min 6 karakter'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              _buildGlassTextField(
                                controller: _passwordConfirmationController,
                                label: 'Konfirmasi Password',
                                icon: Icons.lock_reset,
                                isPassword: true,
                                isPasswordVisible: _isConfirmPasswordVisible,
                                onVisibilityToggle: () => setState(
                                  () => _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible,
                                ),
                                validator: (val) =>
                                    (val != _passwordController.text)
                                    ? 'Password tidak cocok'
                                    : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 35),

                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  FollowMeTokens.radiusMedium,
                                ),
                                gradient: const LinearGradient(
                                  colors: [
                                    FollowMeTokens.ink,
                                    FollowMeTokens.primary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: FollowMeTokens.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      FollowMeTokens.radiusMedium,
                                    ),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 60,
                                        height: 24,
                                        child: Center(child: _ModernLoading()),
                                      )
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(
                                context,
                              ).pushReplacementNamed('/login'),
                              child: Text(
                                'Log In',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
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
