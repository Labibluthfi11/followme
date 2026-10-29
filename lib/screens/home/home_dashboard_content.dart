import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api.service.dart';
import '../../models/absensi_model.dart';
import '../../models/user_model.dart';
import '../../pages/notifications_page.dart';
import '../../providers/absensi_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/izin_keluar_provider.dart';
import '../../services/update_service.dart';
import 'absensi_lembur_screen.dart';
import 'absensi_masuk_screen.dart';
import 'absensi_pulang_screen.dart';
import 'absensi_sakit_form_screen.dart';
import 'absensi_telat_form_screen.dart';
import 'attendance_history_screen.dart';
import 'end_izin_screen.dart';
import 'jadwal_lembur_screen.dart';
import 'start_izin_screen.dart';

const _ink = Color(0xFF172B3A);
const _mutedInk = Color(0xFF70808C);
const _canvas = Color(0xFFF5F4F0);
const _accent = Color(0xFFB7F36B);

class HomeDashboardContent extends StatefulWidget {
  const HomeDashboardContent({super.key});

  @override
  State<HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<HomeDashboardContent> {
  late String _timeString;
  late final Timer _timer;
  late Future<int> _unreadCountFuture;

  @override
  void initState() {
    super.initState();
    _timeString = _formatTime(DateTime.now());
    _unreadCountFuture = context.read<ApiService>().fetchUnreadCount();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _timeString = _formatTime(DateTime.now()));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshProfile();
        UpdateService.checkForUpdate(context);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _refreshProfile(),
      context.read<AbsensiProvider>().refreshAbsensi(),
    ]);
  }

  Future<void> _refreshProfile() async {
    await context.read<AuthProvider>().refreshProfile();
    if (mounted) {
      setState(() {
        _unreadCountFuture = context.read<ApiService>().fetchUnreadCount();
      });
    }
  }

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

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

  Future<void> _openNotifications(ApiService apiService) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsPage(apiService: apiService),
      ),
    );
    if (mounted) {
      setState(() {
        _unreadCountFuture = apiService.fetchUnreadCount();
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final apiService = context.read<ApiService>();
    final attendance = context.watch<AbsensiProvider>().currentDayAbsensi;
    final izinProvider = context.watch<IzinKeluarProvider>();
    final isCheckedIn = attendance?.checkInAt != null;
    final isCheckedOut = attendance?.checkOutAt != null;
    final canLeave =
        isCheckedIn &&
        !isCheckedOut &&
        ['hadir', 'terlambat'].contains(attendance?.status.toLowerCase());

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
              const SizedBox(height: 22),
              _buildAttendanceCard(attendance, isCheckedIn, isCheckedOut),
              if (canLeave) ...[
                const SizedBox(height: 12),
                _buildLeaveAction(izinProvider.isIzinBerjalan),
              ],
              if (user?.employmentType.toLowerCase() == 'organik') ...[
                const SizedBox(height: 20),
                _buildLeaveBalance(user!),
              ],
              const SizedBox(height: 28),
              _buildSectionTitle(
                'Butuh sesuatu?',
                'Pilih layanan yang ingin kamu buka',
                trailing: 'LAYANAN',
              ),
              const SizedBox(height: 14),
              _buildServiceGrid(user),
              const SizedBox(height: 24),
              _buildNotice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(User? user, ApiService apiService) {
    final name = user?.name ?? 'Pengguna';
    final photoUrl = user?.profilePhotoUrl;
    final department = user?.departemen;

    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE5EAD9),
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Text(
                  name.isEmpty ? 'U' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RUANG KERJA',
                style: TextStyle(
                  color: _mutedInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (department != null && department.isNotEmpty)
                Text(
                  department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _mutedInk, fontSize: 12),
                ),
            ],
          ),
        ),
        FutureBuilder<int>(
          future: _unreadCountFuture,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return IconButton(
              tooltip: 'Notifikasi',
              onPressed: () => _openNotifications(apiService),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ink,
                fixedSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text(count > 9 ? '9+' : '$count'),
                child: const Icon(Icons.notifications_none_rounded, size: 23),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(
    Absensi? attendance,
    bool isCheckedIn,
    bool isCheckedOut,
  ) {
    final status = attendance?.status.toLowerCase() ?? '';
    final statusLabel = !isCheckedIn
        ? 'BELUM ABSEN'
        : isCheckedOut
        ? 'SELESAI'
        : status == 'terlambat'
        ? 'TERLAMBAT'
        : 'SEDANG BEKERJA';
    final buttonLabel = !isCheckedIn
        ? 'Mulai absensi'
        : isCheckedOut
        ? 'Lihat riwayat'
        : 'Absen pulang';
    final buttonIcon = !isCheckedIn
        ? Icons.fingerprint_rounded
        : isCheckedOut
        ? Icons.arrow_forward_rounded
        : Icons.logout_rounded;
    final now = DateTime.now();

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -52,
            top: -72,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .07),
                  width: 28,
                ),
              ),
            ),
          ),
          Positioned(
            right: 22,
            top: 38,
            child: Icon(
              Icons.near_me_rounded,
              size: 24,
              color: _accent.withValues(alpha: .8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'STATUS HARI INI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCheckedIn
                            ? _accent.withValues(alpha: .14)
                            : Colors.white.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isCheckedIn ? _accent : Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: isCheckedIn ? _accent : Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _timeString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(now),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .09),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTimePoint(
                          label: 'MASUK',
                          time: _clockTime(attendance?.checkInAt),
                          icon: Icons.login_rounded,
                          active: isCheckedIn,
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 1,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: _buildTimePoint(
                          label: 'PULANG',
                          time: _clockTime(attendance?.checkOutAt),
                          icon: Icons.logout_rounded,
                          active: isCheckedOut,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openMainAttendance(attendance),
                    icon: Icon(buttonIcon, size: 19),
                    label: Text(buttonLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _ink,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePoint({
    required String label,
    required String time,
    required IconData icon,
    required bool active,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!alignEnd) ...[
              Icon(icon, size: 13, color: active ? _accent : Colors.white38),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            if (alignEnd) ...[
              const SizedBox(width: 5),
              Icon(icon, size: 13, color: active ? _accent : Colors.white38),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Text(
          time,
          style: TextStyle(
            color: active ? Colors.white : Colors.white38,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveAction(bool isLeaveOngoing) {
    return Material(
      color: isLeaveOngoing ? const Color(0xFFFFE7E1) : const Color(0xFFE7F2DF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isLeaveOngoing
                ? const EndIzinScreen()
                : const StartIzinScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isLeaveOngoing
                    ? Icons.keyboard_return_rounded
                    : Icons.exit_to_app_rounded,
                color: isLeaveOngoing
                    ? const Color(0xFFB84C36)
                    : const Color(0xFF456C36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isLeaveOngoing
                      ? 'Selesaikan izin keluar'
                      : 'Ajukan izin keluar',
                  style: TextStyle(
                    color: isLeaveOngoing
                        ? const Color(0xFF8F3928)
                        : const Color(0xFF385A2B),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 19,
                color: isLeaveOngoing
                    ? const Color(0xFFB84C36)
                    : const Color(0xFF456C36),
              ),
            ],
          ),
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: _mutedInk, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: _mutedInk,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
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
      _DashboardService(
        title: 'Jadwal lembur',
        subtitle: 'Lihat lembur terjadwal',
        icon: Icons.calendar_month_rounded,
        background: const Color(0xFFF5E3D8),
        foreground: const Color(0xFF9A5A35),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JadwalLemburScreen()),
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
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: _ink, size: 20),
          SizedBox(width: 10),
          Expanded(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
