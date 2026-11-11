import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

import '../../api/api.service.dart';
import '../../core/theme/followme_design_tokens.dart';
import '../../pages/notifications_page.dart';
import '../../providers/auth_provider.dart';
import 'attendance_history_screen.dart';
import 'home_dashboard_content.dart';
import 'hr_services_screen.dart';
import 'profile_screen.dart';

const Color kPrimaryColor = Color(0xFF172B3A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isRedirectingToLogin = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final apiService = context.read<ApiService>();

    if (!authProvider.isAuthenticated) {
      if (!_isRedirectingToLogin) {
        _isRedirectingToLogin = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (context.read<AuthProvider>().isAuthenticated) {
            _isRedirectingToLogin = false;
            return;
          }
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        });
      }

      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeDashboardContent(isActive: _selectedIndex == 0),
          const AttendanceHistoryScreen(),
          HrServicesScreen(
            employmentType:
                authProvider.user?.employmentType.toLowerCase() ?? 'freelance',
          ),
          NotificationsPage(
            apiService: apiService,
            isActive: _selectedIndex == 3,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: GNav(
                    gap: 6,
                    activeColor: FollowMeDesign.primary,
                    iconSize: 21,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 12,
                    ),
                    duration: const Duration(milliseconds: 420),
                    tabBackgroundColor: FollowMeDesign.primary.withValues(
                      alpha: 0.14,
                    ),
                    color: FollowMeDesign.textSecondary,
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: FollowMeDesign.primary,
                      fontSize: 12,
                    ),
                    tabs: const [
                      GButton(icon: Icons.home_rounded, text: 'Beranda'),
                      GButton(
                        icon: Icons.receipt_long_rounded,
                        text: 'Riwayat',
                      ),
                      GButton(icon: Icons.sick_rounded, text: 'Pengajuan'),
                      GButton(icon: Icons.notifications_rounded, text: 'Inbox'),
                      GButton(icon: Icons.person_rounded, text: 'Profil'),
                    ],
                    selectedIndex: _selectedIndex,
                    onTabChange: _onItemTapped,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
