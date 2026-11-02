import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/izin_keluar_provider.dart';
import '../../api/api.service.dart';
import '../../core/constants/app_theme.dart';
import 'custom_camera_screen.dart';

class EndIzinScreen extends StatefulWidget {
  const EndIzinScreen({super.key});

  @override
  State<EndIzinScreen> createState() => _EndIzinScreenState();
}

class _EndIzinScreenState extends State<EndIzinScreen> {
  final TextEditingController _keteranganController = TextEditingController();
  File? _dokumenKembali;
  Future<void> _takePicture() async {
    final File? image = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomCameraScreen(useBackCamera: true),
      ),
    );
    if (image != null && mounted) {
      setState(() => _dokumenKembali = image);
    }
  }

  void _submitEndIzin() async {
    if (_dokumenKembali == null || _keteranganController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib mengisi keterangan & foto bukti penyelesaian!'),
        ),
      );
      return;
    }

    final provider = Provider.of<IzinKeluarProvider>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    provider.setLoading(true);

    try {
      final res = await apiService.endIzinKeluar(
        keteranganKembali: _keteranganController.text,
        dokumenKembali: _dokumenKembali!,
      );

      final isSuccess = res['statusCode'] == 200 || res['statusCode'] == 201;
      if (isSuccess) {
        provider.ubahStatusIzinBerjalan(false);
      }

      if (!mounted) return;
      if (isSuccess) {
        if (res['is_pelanggaran'] == true) {
          _tampilkanDialogPelanggaran();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin berhasil diselesaikan.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menyelesaikan izin.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      provider.setLoading(false);
    }
  }

  void _tampilkanDialogPelanggaran() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.warning_rounded,
            color: Colors.redAccent,
            size: 64,
          ),
          title: const Text(
            'Izin Diselesaikan',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Izin Keluar diselesaikan, namun lewat batas maksimal 2 jam. Ini tercatat sebagai Pelanggaran.\n\nKeputusan mengenai sanksi atau tindakan selanjutnya akan ditentukan secara manual oleh admin dan akan diinformasikan melalui notifikasi terpisah.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Mengerti',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Selesaikan Izin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<IzinKeluarProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(theme),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      FollowMeTokens.radiusMedium,
                    ),
                    border: Border.all(color: FollowMeTokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Keterangan Penyelesaian'),
                      TextFormField(
                        controller: _keteranganController,
                        maxLines: 4,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                        ),
                        decoration: _inputDecoration(
                          'Detail penyelesaian tugas/urusan...',
                          Icons.edit_note_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      FollowMeTokens.radiusMedium,
                    ),
                    border: Border.all(color: FollowMeTokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Bukti Dokumen / Lokasi (*Kamera)'),
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(
                              FollowMeTokens.radiusMedium,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.24,
                              ),
                            ),
                          ),
                          child: _dokumenKembali == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      size: 40,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap untuk mengambil foto bukti',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    FollowMeTokens.radiusMedium,
                                  ),
                                  child: Image.file(
                                    _dokumenKembali!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          FollowMeTokens.radiusSmall,
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: provider.isLoading ? null : _submitEndIzin,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Selesaikan Izin Sekarang',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FollowMeTokens.ink,
        borderRadius: BorderRadius.circular(FollowMeTokens.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FollowMeTokens.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(FollowMeTokens.radiusSmall),
            ),
            child: const Icon(
              Icons.keyboard_return_rounded,
              color: FollowMeTokens.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selesaikan izin keluar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ceritakan penyelesaian dan lampirkan bukti',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFamily: 'Poppins',
      ),
    ),
  );

  InputDecoration _inputDecoration(
    String hint,
    IconData prefixIcon,
  ) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFamily: 'Poppins',
      fontSize: 14,
    ),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    prefixIcon: Icon(prefixIcon, color: Theme.of(context).colorScheme.primary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
