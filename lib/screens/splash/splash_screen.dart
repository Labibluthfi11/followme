import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/followme_design_tokens.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glow_background.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  final String title;

  const SplashScreen({super.key, required this.title});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 34.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();

    Timer(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializationFuture;
      if (!mounted) return;

      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: FollowMeDesign.deepSpace,
      body: Stack(
        children: [
          const GlowBackground(),
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatOffset = 18 * math.sin(_floatController.value * math.pi * 2);
              return Stack(
                children: [
                  Positioned(
                    top: 110 + floatOffset,
                    left: 28,
                    child: _buildFloatingCard(
                      'Check In',
                      Icons.fingerprint_rounded,
                      const Color(0xFFB8E6FF),
                    ),
                  ),
                  Positioned(
                    top: 200 - floatOffset,
                    right: 20,
                    child: _buildFloatingCard(
                      'Lokasi sesuai',
                      Icons.location_on_rounded,
                      const Color(0xFFB5F7D0),
                    ),
                  ),
                  Positioned(
                    bottom: 220 + floatOffset,
                    left: 40,
                    child: _buildFloatingCard(
                      'Wajah terverifikasi',
                      Icons.face_rounded,
                      const Color(0xFFD9C5FF),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (_, __) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: _buildScanRing(size),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 42),
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (_, __) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Absensi wajah pintar',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Sekali scan,\nkehadiran beres.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.08,
                                    letterSpacing: -1.1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [FollowMeDesign.cyan, FollowMeDesign.successLight],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Waktu Anda terdata aman.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: 220,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: LinearProgressIndicator(
                                      minHeight: 12,
                                      value: 0.8,
                                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                                      valueColor: const AlwaysStoppedAnimation<Color>(FollowMeDesign.cyan),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Memuat…',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatBubble(String label, IconData icon, Color tint) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: BorderRadius.circular(16),
      color: Colors.white.withValues(alpha: 0.08),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard(String label, IconData icon, Color tint) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 1 + (0.04 * math.sin(_pulseController.value * math.pi * 2));
        return Transform.scale(
          scale: pulse,
          child: _buildFloatBubble(label, icon, tint),
        );
      },
    );
  }

  Widget _buildScanRing(Size size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = 1.0 + (0.18 * math.sin(_pulseController.value * math.pi * 2));
            return Transform.scale(
              scale: pulse,
              child: Container(
                width: 176,
                height: 176,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          width: 142,
          height: 142,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: FollowMeDesign.cyan.withValues(alpha: 0.25),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        Container(
          width: 98,
          height: 98,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            Icons.face_rounded,
            color: Colors.white,
            size: 46,
          ),
        ),
        Positioned(
          top: 12,
          child: Container(
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, FollowMeDesign.cyan, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
