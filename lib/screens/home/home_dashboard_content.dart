import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api.service.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/demo_preview.dart';
import '../../core/theme/followme_design_tokens.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/absensi_model.dart';
import '../../models/user_model.dart';
import '../../providers/absensi_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/update_service.dart';
import 'absensi_lembur_screen.dart';
import 'absensi_masuk_screen.dart';
import 'absensi_pulang_screen.dart';
import 'absensi_sakit_form_screen.dart';
import 'absensi_telat_form_screen.dart';
import 'early_leave_request_screen.dart';
import 'attendance_history_screen.dart';

const _ink = FollowMeTokens.ink;
const _mutedInk = FollowMeTokens.mutedInk;
const _canvas = FollowMeTokens.canvas;
const _accent = FollowMeTokens.accent;

class HomeDashboardContent extends StatefulWidget {
  const HomeDashboardContent({super.key});

  @override
  State<HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<HomeDashboardContent> {
  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  late String _timeString;
  late final Timer _timer;
  late Future<int> _unreadCountFuture;
  int _selectedStatsMonth = DateTime.now().month;
  final int _selectedStatsYear = DateTime.now().year;
  List<Absensi> _monthlyAttendanceRecords = [];
  bool _isLoadingMonthlyStats = false;
  String? _monthlyStatsError;

  @override
  void initState() {
    super.initState();
    _timeString = _formatTime(DateTime.now());
    _unreadCountFuture = DemoPreview.enabled
        ? Future<int>.value(0)
        : context.read<ApiService>().fetchUnreadCount();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _timeString = _formatTime(DateTime.now()));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!DemoPreview.enabled) {
          _refreshProfile();
          _refreshMonthlyStats();
          UpdateService.checkForUpdate(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (DemoPreview.enabled) return;
    final provider = context.read<AbsensiProvider>();
    await Future.wait([
      _refreshProfile(),
      provider.refreshAbsensi(),
      _refreshMonthlyStats(),
    ]);
  }

  Future<void> _refreshMonthlyStats() async {
    if (DemoPreview.enabled) return;
    final month = _selectedStatsMonth;
    setState(() {
      _isLoadingMonthlyStats = true;
      _monthlyStatsError = null;
    });

    try {
      final records = await context.read<ApiService>().getHistoryAbsensi(
        month: month,
        year: _selectedStatsYear,
      );
      if (!mounted || month != _selectedStatsMonth) return;
      setState(() => _monthlyAttendanceRecords = records);
    } catch (error) {
      debugPrint('Gagal memuat rekap absensi bulanan: $error');
      if (mounted && month == _selectedStatsMonth) {
        setState(() => _monthlyStatsError = 'Gagal memuat rekap absensi.');
      }
    } finally {
      if (mounted && month == _selectedStatsMonth) {
        setState(() => _isLoadingMonthlyStats = false);
      }
    }
  }

  Future<void> _refreshProfile() async {
    if (DemoPreview.enabled) return;
    await context.read<AuthProvider>().refreshProfile();
    if (mounted) {
      setState(() {
        _unreadCountFuture = context.read<ApiService>().fetchUnreadCount();
      });
    }
  }

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _clockTime(String? value) {
    if (value == null) return '--:--';
    final date = DateTime.tryParse(value);
    if (date == null) return '--:--';
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Map<String, int> _monthlyStats(List<Absensi> records) {
    final stats = {
      'hadir': 0,
      'terlambat': 0,
      'izin': 0,
      'alfa': 0,
      'sakit': 0,
    };
    for (final record in records) {
      final rawDate = record.checkInAt ?? record.createdAt;
      final date = rawDate == null
          ? null
          : DateTime.tryParse(rawDate)?.toLocal();
      if (date == null ||
          date.year != _selectedStatsYear ||
          date.month != _selectedStatsMonth) {
        continue;
      }
      final status = record.status.trim().toLowerCase();
      if (status == 'hadir') {
        stats['hadir'] = stats['hadir']! + 1;
      }
      if (status == 'telat' || status == 'terlambat' || record.isLate == true) {
        stats['terlambat'] = stats['terlambat']! + 1;
      }
      if (status == 'sakit') {
        stats['sakit'] = stats['sakit']! + 1;
      } else if (status.contains('izin') || status.contains('cuti')) {
        stats['izin'] = stats['izin']! + 1;
      } else if (status == 'alfa' ||
          status == 'alpa' ||
          status == 'alpha' ||
          status == 'tanpa keterangan') {
        stats['alfa'] = stats['alfa']! + 1;
      }
    }
    return stats;
  }

  Widget _buildMonthlyStats(Map<String, int> stats) {
    const items = [
      ('Hadir', 'hadir', FollowMeTokens.present),
      ('Terlambat', 'terlambat', FollowMeTokens.late),
      ('Izin', 'izin', FollowMeTokens.leave),
      ('Alfa', 'alfa', FollowMeTokens.absent),
      ('Sakit', 'sakit', Color(0xFF3B82F6)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Rekap Bulanan',
                style: TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FollowMeTokens.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedStatsMonth,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _mutedInk,
                  ),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  items: List.generate(
                    _monthNames.length,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${_monthNames[index]} $_selectedStatsYear'),
                    ),
                  ),
                  onChanged: (month) {
                    if (month == null || month == _selectedStatsMonth) return;
                    setState(() => _selectedStatsMonth = month);
                    _refreshMonthlyStats();
                  },
                ),
              ),
            ),
            if (_isLoadingMonthlyStats) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        if (_monthlyStatsError != null) ...[
          const SizedBox(height: 8),
          Text(
            _monthlyStatsError!,
            style: const TextStyle(
              color: FollowMeTokens.absent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  SizedBox(
                    width: tileWidth,
                    child: _MonthlyStatTile(
                      label: item.$1,
                      value: stats[item.$2] ?? 0,
                      color: item.$3,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeeklyAttendance(List<Absensi> records) {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDay = today.subtract(Duration(days: today.weekday - 1));
    final week = List.generate(
      7,
      (index) => firstDay.add(Duration(days: index)),
    );
    final recordsByDay = <DateTime, Absensi>{};

    for (final record in records) {
      final rawDate = record.checkInAt ?? record.createdAt;
      final date = rawDate == null
          ? null
          : DateTime.tryParse(rawDate)?.toLocal();
      if (date == null) continue;

      final day = DateUtils.dateOnly(date);
      if (!day.isBefore(firstDay) && !day.isAfter(today)) {
        recordsByDay.putIfAbsent(day, () => record);
      }
    }

    final presentCount = recordsByDay.values
        .where((record) => record.status.toLowerCase() == 'hadir')
        .length;
    final lateCount = recordsByDay.values
        .where((record) => record.isLate)
        .length;
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: FollowMeTokens.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FollowMeTokens.border),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Minggu ini',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$presentCount hadir · $lateCount terlambat',
                style: const TextStyle(
                  color: _mutedInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 78,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < week.length; index++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 54,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              width: 18,
                              height: recordsByDay[week[index]] == null
                                  ? 9
                                  : 48,
                              decoration: BoxDecoration(
                                color: recordsByDay[week[index]] == null
                                    ? FollowMeTokens.border
                                    : recordsByDay[week[index]]!.isLate
                                    ? FollowMeTokens.late
                                    : FollowMeTokens.present,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          labels[index],
                          style: TextStyle(
                            color: week[index] == today
                                ? FollowMeTokens.primary
                                : _mutedInk,
                            fontSize: 10,
                            fontWeight: week[index] == today
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openMainAttendance(Absensi? attendance) {
    if (attendance?.checkInAt == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AbsensiMasukScreen()),
      );
    } else if (attendance?.checkOutAt == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AbsensiPulangScreen(lembur: false),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
      );
    }
  }

  Future<void> _openEarlyLeaveRequest(DateTime checkInAt) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EarlyLeaveRequestScreen(checkInAt: checkInAt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final apiService = context.read<ApiService>();
    final absensiProvider = context.watch<AbsensiProvider>();
    final attendance = absensiProvider.currentDayAbsensi;
    final monthlyStats = _monthlyStats(_monthlyAttendanceRecords);
    final isCheckedIn = attendance?.checkInAt != null;
    final isCheckedOut = attendance?.checkOutAt != null;

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: _ink,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              _buildTopBar(user, apiService),
              if (DemoPreview.enabled) ...[
                const SizedBox(height: 14),
                _buildPreviewNotice(),
              ],
              const SizedBox(height: 8),
              _buildAttendanceCard(attendance, isCheckedIn, isCheckedOut),
              const SizedBox(height: 22),
              _buildSectionTitle(
                'Akses cepat',
                'Pilih layanan yang ingin kamu buka',
                trailing: 'LAYANAN',
              ),
              const SizedBox(height: 14),
              _buildServiceGrid(user),
              const SizedBox(height: 22),
              _buildWeeklyAttendance(absensiProvider.myAbsensiList),
              const SizedBox(height: 22),
              _buildMonthlyStats(monthlyStats),
              if (user?.employmentType.toLowerCase() == 'organik') ...[
                const SizedBox(height: 20),
                _buildLeaveBalance(user!),
              ],
              const SizedBox(height: 22),
              _buildNotice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2D8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.7)),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: _ink),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Mode preview — akun dan data tidak disimpan.',
              style: TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(User? user, ApiService apiService) {
    final name = user?.name ?? 'Pengguna';
    final department = user?.departemen ?? 'Karyawan';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF392477), Color(0xFF124C5A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            left: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FollowMeDesign.violet.withValues(alpha: 0.28),
              ),
            ),
          ),
          Positioned(
            right: -40,
            bottom: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FollowMeDesign.cyan.withValues(alpha: 0.22),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileAvatar(user),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat pagi',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          department,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<int>(
                    future: _unreadCountFuture,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return GlassContainer(
                        padding: const EdgeInsets.all(10),
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.08),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            if (count > 0)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFEF4444),
                                    border: Border.all(
                                      color: FollowMeDesign.deepSpace,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hari ini',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _timeString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(User? user) {
    final photoUrl = user?.profilePhotoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: 52,
        height: 52,
        child: hasPhoto
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _profileAvatarFallback(),
              )
            : _profileAvatarFallback(),
      ),
    );
  }

  Widget _profileAvatarFallback() {
    return Container(
      color: const Color(0xFFE8F5FD),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: _mutedInk, size: 30),
    );
  }

  Widget _buildAttendanceCard(
    Absensi? attendance,
    bool isCheckedIn,
    bool isCheckedOut,
  ) {
    final status = attendance?.status.toLowerCase() ?? '';
    final statusLabel = !isCheckedIn
        ? 'Belum absen'
        : isCheckedOut
        ? 'Selesai'
        : status == 'terlambat'
        ? 'Terlambat'
        : 'Sedang bekerja';
    final buttonLabel = !isCheckedIn
        ? 'Check-in sekarang'
        : isCheckedOut
        ? 'Lihat riwayat'
        : 'Check-out sekarang';
    final buttonIcon = !isCheckedIn
        ? Icons.fingerprint_rounded
        : isCheckedOut
        ? Icons.arrow_forward_rounded
        : Icons.logout_rounded;
    final checkIn = attendance?.checkInAt == null
        ? null
        : DateTime.tryParse(attendance!.checkInAt!)?.toLocal();
    final checkOut = attendance?.checkOutAt == null
        ? null
        : DateTime.tryParse(attendance!.checkOutAt!)?.toLocal();
    final end = checkOut ?? (isCheckedIn ? DateTime.now() : null);
    final worked = checkIn != null && end != null
        ? end.difference(checkIn)
        : Duration.zero;
    final durationText = '${worked.inHours}j ${(worked.inMinutes % 60)}m';
    final progress = (worked.inMinutes / (8 * 60)).clamp(0.0, 1.0);
    final statusColor = !isCheckedIn
        ? _mutedInk
        : status == 'terlambat'
        ? FollowMeTokens.late
        : FollowMeTokens.present;
    final hasPendingEarlyLeave =
        attendance?.catatanAdmin?.trim() == 'izin_pulang_cepat' &&
        attendance?.statusApproval?.toLowerCase() == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FollowMeTokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FollowMeTokens.border),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Absensi hari ini',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTimePoint(
                  label: 'Masuk',
                  time: _clockTime(attendance?.checkInAt),
                  icon: Icons.login_rounded,
                  active: isCheckedIn,
                  background: const Color(0xFFEAFBF1),
                  foreground: FollowMeTokens.present,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimePoint(
                  label: 'Pulang',
                  time: _clockTime(attendance?.checkOutAt),
                  icon: Icons.logout_rounded,
                  active: isCheckedOut,
                  background: const Color(0xFFF1F4F8),
                  foreground: _mutedInk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimePoint(
                  label: 'Durasi',
                  time: durationText,
                  icon: Icons.schedule_rounded,
                  active: isCheckedIn,
                  background: const Color(0xFFEDF2FF),
                  foreground: FollowMeTokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: FollowMeTokens.border,
                    color: FollowMeTokens.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Target 8 jam',
                style: TextStyle(
                  color: _mutedInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openMainAttendance(attendance),
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                backgroundColor: FollowMeTokens.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (isCheckedIn && !isCheckedOut) ...[
            const SizedBox(height: 10),
            if (hasPendingEarlyLeave)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 18,
                      color: Color(0xFF946200),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pengajuan pulang lebih awal menunggu persetujuan HRD.',
                        style: TextStyle(
                          color: Color(0xFF755000),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (checkIn != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openEarlyLeaveRequest(checkIn),
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: const Text('Ajukan pulang lebih awal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FollowMeTokens.primary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePoint({
    required String label,
    required String time,
    required IconData icon,
    required bool active,
    required Color background,
    required Color foreground,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 13, color: active ? foreground : _mutedInk),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _mutedInk,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  time,
                  maxLines: 1,
                  style: TextStyle(
                    color: active ? foreground : _mutedInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveBalance(User user) {
    final remaining = user.sisaCuti ?? 12;
    final used = user.totalCutiDiambil ?? 0;
    final total = remaining + used;
    final progress = total == 0 ? 0.0 : (used / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EAD9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ink.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.beach_access_rounded,
              color: _ink,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sisa cuti tahunan',
                  style: TextStyle(
                    color: _mutedInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$remaining',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 27,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 5, bottom: 4),
                      child: Text(
                        'hari tersisa',
                        style: TextStyle(
                          color: _mutedInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: .8),
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$used',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'terpakai',
                style: TextStyle(
                  color: _mutedInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    String subtitle, {
    required String trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _mutedInk,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _ink.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            trailing,
            style: const TextStyle(
              color: _mutedInk,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceGrid(User? user) {
    final services = <_DashboardService>[
      _DashboardService(
        title: 'Lembur',
        subtitle: 'Catat jam lembur',
        icon: Icons.nightlight_round,
        background: const Color(0xFFEAE3F6),
        foreground: const Color(0xFF65518D),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AbsensiLemburScreen()),
        ),
      ),
      if (user?.employmentType.toLowerCase() != 'organik')
        _DashboardService(
          title: 'Lapor telat',
          subtitle: 'Isi keterangan',
          icon: Icons.more_time_rounded,
          background: const Color(0xFFF7E9D1),
          foreground: const Color(0xFF986322),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AbsensiTelatFormScreen()),
          ),
        ),
      _DashboardService(
        title: 'Pengajuan sakit',
        subtitle: 'Kirim bukti sakit',
        icon: Icons.healing_rounded,
        background: const Color(0xFFF7E1DE),
        foreground: const Color(0xFFA84E48),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const SakitFormScreen(initialTipePengajuan: 'sakit'),
          ),
        ),
      ),
      _DashboardService(
        title: 'Pengajuan izin',
        subtitle: 'Ajukan izin tidak masuk',
        icon: Icons.event_note_rounded,
        background: const Color(0xFFDCEDE8),
        foreground: const Color(0xFF3A7565),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SakitFormScreen(initialTipePengajuan: 'izin'),
          ),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: services
              .map(
                (service) => SizedBox(
                  width: itemWidth,
                  child: _ServiceTile(service: service),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBE4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ink.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _ink.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded, color: _ink, size: 16),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pastikan lokasi perangkat aktif dan kamu berada di area yang sesuai saat melakukan absensi.',
              style: TextStyle(
                color: _mutedInk,
                fontSize: 11,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardService {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _DashboardService({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });
}

class _MonthlyStatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MonthlyStatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FollowMeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _mutedInk,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final _DashboardService service;

  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: service.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: service.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(service.icon, color: service.foreground, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.subtitle,
                      style: const TextStyle(
                        color: _mutedInk,
                        fontSize: 9,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: _mutedInk,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
