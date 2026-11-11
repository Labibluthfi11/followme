import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api/api.service.dart';
import '../../core/constants/demo_preview.dart';
import '../../core/exceptions/app_exception.dart';
import '../../models/payroll_slip_model.dart';

class PayrollSlipsScreen extends StatefulWidget {
  const PayrollSlipsScreen({super.key});

  @override
  State<PayrollSlipsScreen> createState() => _PayrollSlipsScreenState();
}

class _PayrollSlipsScreenState extends State<PayrollSlipsScreen> {
  late Future<List<PayrollSlipModel>> _slipsFuture;
  final Set<int> _downloadingIds = {};
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _slipsFuture = _loadSlips();
  }

  Future<List<PayrollSlipModel>> _loadSlips() async {
    if (DemoPreview.enabled) return const [];
    final data = await context.read<ApiService>().fetchPayrollSlips();
    return data.map(PayrollSlipModel.fromJson).toList(growable: false);
  }

  Future<void> _refresh() async {
    setState(() => _slipsFuture = _loadSlips());
    await _slipsFuture;
  }

  Future<void> _download(PayrollSlipModel slip) async {
    setState(() => _downloadingIds.add(slip.id));
    try {
      final bytes = await context.read<ApiService>().downloadPayrollSlip(
        slip.id,
      );
      final path = await FilePicker.saveFile(
        dialogTitle: 'Simpan slip gaji',
        fileName: '${slip.slipNumber}.pdf',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Penyimpanan slip dibatalkan.'
                : 'Slip gaji berhasil disimpan.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan slip gaji: $error')),
      );
    } finally {
      if (mounted) setState(() => _downloadingIds.remove(slip.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slip Gaji'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<PayrollSlipModel>>(
        future: _slipsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _MessageState(
              message: error is AppException
                  ? error.message
                  : 'Slip gaji gagal dimuat. Coba lagi.',
              actionLabel: 'Coba lagi',
              onAction: _refresh,
            );
          }

          final slips = snapshot.data ?? const [];
          if (slips.isEmpty) {
            return const _MessageState(
              message:
                  'Belum ada slip gaji yang tersedia. Slip akan muncul setelah payroll dikonfirmasi dibayar oleh HRD.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: slips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _slipCard(slips[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _slipCard(PayrollSlipModel slip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    slip.periodLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            Text('${slip.slipNumber} • ${slip.workDays} hari kerja'),
            const SizedBox(height: 12),
            Text(
              _currency.format(slip.netPay),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Dibayar ${slip.paidAt == null ? '-' : DateFormat('d MMM yyyy', 'id_ID').format(slip.paidAt!.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _downloadingIds.contains(slip.id)
                    ? null
                    : () => _download(slip),
                icon: _downloadingIds.contains(slip.id)
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: const Text('Unduh PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
