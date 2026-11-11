import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _entries = <(String, String)>[
    (
      'Absensi tidak bisa dikirim',
      'Pastikan GPS aktif, izinkan akses lokasi presisi, ambil foto terbaru, dan pastikan berada di area kerja. Server tetap memeriksa lokasi saat absensi dikirim.',
    ),
    (
      'Akurasi GPS rendah',
      'Coba pindah ke area terbuka, matikan lalu nyalakan lokasi, dan tunggu sampai akurasi membaik sebelum mengirim absensi.',
    ),
    (
      'Status pengajuan',
      'Pengajuan yang masih diproses akan berstatus Menunggu. Jika ditolak, buka Riwayat untuk membaca catatan HRD dan kirim ulang bila tombol pengiriman ulang tersedia.',
    ),
    (
      'Slip gaji',
      'Slip hanya muncul setelah payroll dikonfirmasi dibayar oleh HRD. Buka Layanan HR > Slip gaji untuk melihat dan mengunduh PDF.',
    ),
    (
      'Masalah akun atau data karyawan',
      'Hubungi HRD perusahaan dan sertakan nama, ID karyawan, waktu kejadian, serta tangkapan layar. Jangan mengirim kata sandi atau kode OTP.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Panduan singkat',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ..._entries.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: Text(
                  entry.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(entry.$2, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
