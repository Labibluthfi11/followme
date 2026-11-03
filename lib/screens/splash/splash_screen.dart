import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/followme_design_tokens.dart';
import '../../core/widgets/glow_background.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  final String title;

  const SplashScreen({super.key, required this.title});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _mainController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.8,
              end: 1.08,
            ).chain(CurveTween(curve: Curves.easeOutBack)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.08,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeIn)),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FollowMeDesign.deepSpace,
      body: Stack(
        children: [
          const GlowBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (_, __) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: _buildBrandLogo(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 34),
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (_, __) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Column(
                              children: [
                                Text(
                                  'Absensi lebih mudah',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hadir, pantau, dan kelola absensi\nAnda dalam satu aplikasi.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: 180,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: const LinearProgressIndicator(
                                      minHeight: 4,
                                      backgroundColor: Color(0x33FFFFFF),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        FollowMeDesign.cyan,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Menyiapkan aplikasi...',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
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

  Widget _buildBrandLogo() {
    return Container(
      width: 176,
      height: 176,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: FollowMeDesign.cyan.withValues(alpha: 0.28),
            blurRadius: 38,
            spreadRadius: 2,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Image.asset('assets/images/followme.jpeg', fit: BoxFit.cover),
      ),
    );
  }
}
