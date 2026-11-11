import 'package:flutter/material.dart';

import 'absensi_lembur_screen.dart';
import 'absensi_sakit_form_screen.dart';
import 'absensi_telat_form_screen.dart';
import 'help_center_screen.dart';
import 'employee_hr_requests_screen.dart';
import 'payroll_slips_screen.dart';

class HrServicesScreen extends StatelessWidget {
  const HrServicesScreen({super.key, required this.employmentType});

  final String employmentType;

  static const _background = Color(0xFFF5F4F0);
  static const _ink = Color(0xFF172B3A);

  bool get _isOrganik => employmentType.toLowerCase() == 'organik';

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final services = <_HrService>[
      _HrService(
        title: 'Pengajuan sakit',
        subtitle: 'Kirim pengajuan dan bukti sakit',
        icon: Icons.healing_rounded,
        color: const Color(0xFFA84E48),
        available: true,
        onTap: () => _open(
          context,
          const SakitFormScreen(initialTipePengajuan: 'sakit'),
        ),
      ),
      _HrService(
        title: _isOrganik ? 'Pengajuan cuti' : 'Pengajuan izin',
        subtitle: _isOrganik
            ? 'Ajukan cuti sesuai pilihan yang tersedia'
            : 'Ajukan izin tidak masuk',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF3A7565),
        available: true,
        onTap: () => _open(
          context,
          SakitFormScreen(initialTipePengajuan: _isOrganik ? 'cuti' : 'izin'),
        ),
      ),
      _HrService(
        title: 'Pengajuan lembur',
        subtitle: 'Catat jam dan hasil kerja lembur',
        icon: Icons.nightlight_round,
        color: const Color(0xFF65518D),
        available: true,
        onTap: () => _open(context, const AbsensiLemburScreen()),
      ),
      if (!_isOrganik)
        _HrService(
          title: 'Lapor keterlambatan',
          subtitle: 'Kirim keterangan dan bukti',
          icon: Icons.more_time_rounded,
          color: const Color(0xFF986322),
          available: true,
          onTap: () => _open(context, const AbsensiTelatFormScreen()),
        ),
      _HrService(
        title: 'Slip gaji',
        subtitle: 'Lihat dan unduh slip payroll yang sudah dibayar',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF315F8C),
        available: true,
        onTap: () => _open(context, const PayrollSlipsScreen()),
      ),
      _HrService(
        title: 'Pusat bantuan',
        subtitle: 'Panduan absensi, pengajuan, dan akun',
        icon: Icons.help_outline_rounded,
        color: const Color(0xFF3B6471),
        available: true,
        onTap: () => _open(context, const HelpCenterScreen()),
      ),
      _HrService(
        title: 'Reimbursement',
        subtitle: 'Ajukan penggantian biaya dengan bukti',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF557A50),
        available: true,
        onTap: () => _open(context, const EmployeeHrRequestsScreen()),
      ),
      _HrService(
        title: 'Kasbon / pinjaman',
        subtitle: 'Ajukan pinjaman dan pantau cicilan',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF765F9D),
        available: true,
        onTap: () => _open(
          context,
          const EmployeeHrRequestsScreen(initialLoan: true),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Layanan HR',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _background,
        foregroundColor: _ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF392477), Color(0xFF124C5A)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urus kebutuhan kerja dari sini',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Pilih layanan untuk membuat pengajuan. Statusnya dapat dipantau di Riwayat dan Inbox.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Pengajuan dan layanan',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HrServiceTile(service: service),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ajukan melalui layanan yang tersedia; status proses dapat dipantau di Riwayat dan Inbox.',
            style: TextStyle(
              color: Color(0xFF66727A),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HrService {
  const _HrService({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.available,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool available;
  final VoidCallback? onTap;
}

class _HrServiceTile extends StatelessWidget {
  const _HrServiceTile({required this.service});

  final _HrService service;

  @override
  Widget build(BuildContext context) {
    final tileColor = service.available
        ? Colors.white
        : const Color(0xFFE9E9E6);

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: service.available ? service.onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(service.icon, color: service.color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        color: HrServicesScreen._ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF66727A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                service.available
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_outline_rounded,
                size: 16,
                color: const Color(0xFF76828A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
