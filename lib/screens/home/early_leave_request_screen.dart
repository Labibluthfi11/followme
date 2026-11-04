import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';

import '../../api/api.service.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/absensi_provider.dart';

class EarlyLeaveRequestScreen extends StatefulWidget {
  const EarlyLeaveRequestScreen({super.key, required this.checkInAt});

  final DateTime checkInAt;

  @override
  State<EarlyLeaveRequestScreen> createState() =>
      _EarlyLeaveRequestScreenState();
}

class _EarlyLeaveRequestScreenState extends State<EarlyLeaveRequestScreen> {
  static const _maxFileSize = 2 * 1024 * 1024;
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  TimeOfDay? _plannedLeaveTime;
  Uint8List? _evidenceBytes;
  String? _evidenceName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _plannedLeaveTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _plannedLeaveTime = selected);
    }
  }

  Future<void> _pickEvidence() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
        withData: kIsWeb,
      );
    } on PlatformException {
      if (mounted) _showMessage('Gagal membuka pemilih file.');
      return;
    }
    if (result == null || result.files.isEmpty || !mounted) return;

    final picked = result.files.single;
    if (picked.size > _maxFileSize) {
      _showMessage('Ukuran bukti maksimal 2 MB.');
      return;
    }

    var bytes = picked.bytes;
    if (bytes == null) {
      final path = picked.path;
      if (path == null) {
        _showMessage('File tidak dapat dibaca. Silakan pilih file lain.');
        return;
      }
      try {
        bytes = await File(path).readAsBytes();
      } on FileSystemException {
        if (mounted) {
          _showMessage('File tidak dapat dibaca. Silakan pilih file lain.');
        }
        return;
      }
    }
    if (bytes.length > _maxFileSize) {
      _showMessage('Ukuran bukti maksimal 2 MB.');
      return;
    }

    setState(() {
      _evidenceBytes = bytes;
      _evidenceName = picked.name;
    });
  }

  DateTime? get _plannedLeaveDateTime {
    final time = _plannedLeaveTime;
    if (time == null) return null;
    return DateTime(
      widget.checkInAt.year,
      widget.checkInAt.month,
      widget.checkInAt.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final plannedLeave = _plannedLeaveDateTime;
    if (plannedLeave == null) {
      _showMessage('Pilih jam pulang yang direncanakan.');
      return;
    }
    if (!plannedLeave.isAfter(widget.checkInAt)) {
      _showMessage('Jam pulang harus setelah jam check-in.');
      return;
    }

    final evidenceBytes = _evidenceBytes;
    final evidenceName = _evidenceName;
    if (evidenceBytes == null || evidenceName == null) {
      _showMessage('Bukti pengajuan wajib dilampirkan.');
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await context.read<ApiService>().submitEarlyLeaveRequest(
      fileBytes: evidenceBytes,
      fileName: evidenceName,
      catatan: _reasonController.text.trim(),
      jamPulangRencana: DateFormat('HH:mm').format(plannedLeave),
    );
    if (!mounted) return;

    if (result['success'] != true) {
      setState(() => _isSubmitting = false);
      _showMessage(
        result['message']?.toString() ??
            'Pengajuan pulang lebih awal gagal. Silakan coba lagi.',
      );
      return;
    }

    unawaited(context.read<AbsensiProvider>().refreshAbsensi());
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.hourglass_top_rounded,
          color: FollowMeTokens.primary,
        ),
        title: const Text('Pengajuan terkirim'),
        content: Text(
          '${result['message'] ?? 'Pengajuan berhasil dikirim.'}\n\n'
          'Status: menunggu persetujuan HRD.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final plannedTime = _plannedLeaveTime;
    return Scaffold(
      backgroundColor: FollowMeTokens.canvas,
      appBar: AppBar(
        title: const Text('Pulang lebih awal'),
        backgroundColor: FollowMeTokens.canvas,
        foregroundColor: FollowMeTokens.ink,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Pengajuan ini untuk pulang lebih awal hari ini dan akan '
                  'menunggu persetujuan HRD.',
                  style: TextStyle(color: FollowMeTokens.ink, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Jam check-in: ${DateFormat('HH:mm').format(widget.checkInAt)}',
                style: const TextStyle(
                  color: FollowMeTokens.mutedInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  plannedTime == null
                      ? 'Pilih jam pulang'
                      : 'Jam pulang: ${plannedTime.format(context)}',
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _reasonController,
                enabled: !_isSubmitting,
                maxLength: 500,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Alasan',
                  hintText: 'Jelaskan alasan pulang lebih awal',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alasan wajib diisi.';
                  }
                  if (value.trim().length > 500) {
                    return 'Alasan maksimal 500 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickEvidence,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _evidenceName ??
                      'Pilih bukti (JPG, PNG, atau PDF; maks. 2 MB)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: FollowMeTokens.primary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim pengajuan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
