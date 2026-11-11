import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api/api.service.dart';

class EmployeeHrRequestsScreen extends StatefulWidget {
  const EmployeeHrRequestsScreen({super.key, this.initialLoan = false});

  final bool initialLoan;

  @override
  State<EmployeeHrRequestsScreen> createState() =>
      _EmployeeHrRequestsScreenState();
}

class _EmployeeHrRequestsScreenState extends State<EmployeeHrRequestsScreen> {
  static const _maximumReceiptBytes = 5 * 1024 * 1024;
  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _principalController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isLoan = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _selectedTypeId;
  int _tenorMonths = 1;
  Uint8List? _receiptBytes;
  String? _receiptName;
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _reimbursements = [];
  List<Map<String, dynamic>> _loans = [];
  int _maxPrincipal = 5000000;
  int _maxTenorMonths = 12;

  @override
  void initState() {
    super.initState();
    _isLoan = widget.initialLoan;
    _loadRequests();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _principalController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _loadRequests() async {
    if (mounted) setState(() => _isLoading = true);
    final result = await context.read<ApiService>().fetchEmployeeHrRequests();
    if (!mounted) return;
    final data = result['data'];
    if (result['success'] != true || data is! Map<String, dynamic>) {
      setState(() => _isLoading = false);
      _showMessage(
        result['message']?.toString() ?? 'Gagal memuat riwayat pengajuan.',
      );
      return;
    }

    final policy = data['loan_policy'];
    final types = _mapList(data['reimbursement_types']);
    setState(() {
      _types = types;
      _reimbursements = _mapList(data['reimbursements']);
      _loans = _mapList(data['loans']);
      if (_selectedTypeId == null && types.isNotEmpty) {
        _selectedTypeId = int.tryParse(types.first['id'].toString());
      }
      if (policy is Map) {
        _maxPrincipal =
            int.tryParse(policy['max_principal'].toString()) ?? _maxPrincipal;
        _maxTenorMonths =
            int.tryParse(policy['max_tenor_months'].toString()) ??
            _maxTenorMonths;
        if (_tenorMonths > _maxTenorMonths) {
          _tenorMonths = _maxTenorMonths;
        }
      }
      _isLoading = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickReceipt() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
    } on PlatformException {
      _showMessage('Gagal membuka pemilih file.');
      return;
    }
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (file.size > _maximumReceiptBytes ||
        bytes == null ||
        bytes.length > _maximumReceiptBytes) {
      _showMessage('Bukti wajib dapat dibaca dan maksimal berukuran 5 MB.');
      return;
    }
    final extension = file.extension?.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png', 'pdf'}.contains(extension)) {
      _showMessage('Format bukti harus JPG, PNG, atau PDF.');
      return;
    }
    setState(() {
      _receiptBytes = bytes;
      _receiptName = file.name;
    });
  }

  Map<String, dynamic>? get _selectedType {
    for (final type in _types) {
      if (int.tryParse(type['id'].toString()) == _selectedTypeId) return type;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final api = context.read<ApiService>();
    final Map<String, dynamic> result;
    if (_isLoan) {
      result = await api.submitLoanRequest(
        principal: int.parse(_principalController.text.replaceAll('.', '')),
        tenorMonths: _tenorMonths,
        purpose: _purposeController.text.trim(),
      );
    } else {
      final receiptBytes = _receiptBytes;
      final receiptName = _receiptName;
      if (_selectedTypeId == null ||
          receiptBytes == null ||
          receiptName == null) {
        setState(() => _isSubmitting = false);
        _showMessage('Pilih kategori dan lampirkan bukti pengeluaran.');
        return;
      }
      result = await api.submitReimbursement(
        typeId: _selectedTypeId!,
        amount: int.parse(_amountController.text.replaceAll('.', '')),
        description: _descriptionController.text.trim(),
        receiptBytes: receiptBytes,
        receiptName: receiptName,
      );
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showMessage(
      result['message']?.toString() ??
          (result['success'] == true
              ? 'Pengajuan berhasil dikirim.'
              : 'Pengajuan gagal dikirim.'),
    );
    if (result['success'] == true) {
      _amountController.clear();
      _descriptionController.clear();
      _principalController.clear();
      _purposeController.clear();
      setState(() {
        _receiptBytes = null;
        _receiptName = null;
      });
      await _loadRequests();
    }
  }

  String _statusLabel(dynamic status) => switch (status?.toString()) {
    'pending' => 'Menunggu HRD',
    'approved' => 'Disetujui',
    'rejected' => 'Ditolak',
    'paid' => 'Dibayarkan',
    _ => status?.toString() ?? 'Status tidak diketahui',
  };

  int get _monthlyInstallmentEstimate {
    final principal = int.tryParse(_principalController.text) ?? 0;
    return principal == 0 ? 0 : (principal + _tenorMonths - 1) ~/ _tenorMonths;
  }

  Widget _buildRequestForm() {
    final selectedType = _selectedType;
    final selectedLimit = int.tryParse(
      selectedType?['monthly_limit']?.toString() ?? '',
    );
    final usedThisMonth = int.tryParse(
      selectedType?['used_this_month']?.toString() ?? '',
    );
    final remaining = selectedLimit == null || _selectedTypeId == null
        ? null
        : (selectedLimit - (usedThisMonth ?? 0)).clamp(0, selectedLimit);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Reimbursement'),
                    icon: Icon(Icons.receipt_long_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Kasbon'),
                    icon: Icon(Icons.account_balance_wallet_rounded),
                  ),
                ],
                selected: {_isLoan},
                onSelectionChanged: _isSubmitting
                    ? null
                    : (selection) => setState(() => _isLoan = selection.first),
              ),
              const SizedBox(height: 18),
              if (_isLoan) ...[
                TextFormField(
                  controller: _principalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Nominal pinjaman',
                    prefixText: 'Rp ',
                    helperText:
                        'Maksimal ${_currency.format(_maxPrincipal)} tanpa bunga',
                  ),
                  validator: (value) {
                    final amount = int.tryParse(value ?? '');
                    if (amount == null || amount < 1) {
                      return 'Masukkan nominal pinjaman.';
                    }
                    if (amount > _maxPrincipal) {
                      return 'Nominal melebihi batas kebijakan HRD.';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _tenorMonths,
                  decoration: InputDecoration(
                    labelText: 'Tenor cicilan',
                    helperText: _monthlyInstallmentEstimate == 0
                        ? null
                        : 'Perkiraan cicilan ${_currency.format(_monthlyInstallmentEstimate)} per bulan',
                  ),
                  items: List.generate(
                    _maxTenorMonths,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1} bulan'),
                    ),
                  ),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _tenorMonths = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _purposeController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Tujuan pinjaman',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 5
                      ? 'Jelaskan tujuan minimal 5 karakter.'
                      : null,
                ),
              ] else ...[
                if (_types.isEmpty)
                  const Text(
                    'Belum ada kategori reimbursement dengan limit aktif. Hubungi HRD.',
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTypeId,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      helperText: remaining == null
                          ? null
                          : 'Sisa limit bulan ini: ${_currency.format(remaining)}',
                    ),
                    items: _types
                        .map(
                          (type) => DropdownMenuItem(
                            value: int.tryParse(type['id'].toString()),
                            child: Text(type['name'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) => setState(() => _selectedTypeId = value),
                    validator: (value) =>
                        value == null ? 'Pilih kategori.' : null,
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah pengeluaran',
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    final amount = int.tryParse(value ?? '');
                    if (amount == null || amount < 1) {
                      return 'Masukkan jumlah pengeluaran.';
                    }
                    if (remaining != null && amount > remaining) {
                      return 'Jumlah melebihi sisa limit bulan ini.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan pengeluaran',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 5
                      ? 'Keterangan minimal 5 karakter.'
                      : null,
                ),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickReceipt,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(
                    _receiptName ?? 'Lampirkan bukti (JPG, PNG, PDF)',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Bukti wajib dilampirkan, maksimal 5 MB.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSubmitting || (!_isLoan && _types.isEmpty)
                    ? null
                    : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kirim pengajuan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistory() {
    final entries =
        <Map<String, dynamic>>[
          ..._reimbursements.map(
            (entry) => {...entry, '_kind': 'Reimbursement'},
          ),
          ..._loans.map((entry) => {...entry, '_kind': 'Kasbon'}),
        ]..sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '');
          final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '');
          return (dateB ?? DateTime(1970)).compareTo(dateA ?? DateTime(1970));
        });

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Text('Belum ada pengajuan.'),
      );
    }
    return Column(
      children: entries.map((entry) {
        final isLoan = entry['_kind'] == 'Kasbon';
        final amount = int.tryParse(
          (isLoan ? entry['principal'] : entry['amount'])?.toString() ?? '',
        );
        final date = DateTime.tryParse(entry['created_at']?.toString() ?? '');
        final details = isLoan
            ? '${entry['tenor_months']} bulan • ${entry['purpose'] ?? 'Tanpa keterangan'}'
            : '${entry['type'] ?? 'Kategori'} • ${entry['description'] ?? ''}';
        final rejection = entry['rejection_reason']?.toString();
        final installments = entry['installments'];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isLoan
                  ? Icons.account_balance_wallet_rounded
                  : Icons.receipt_long_rounded,
            ),
            title: Text(
              '${entry['_kind']}: ${amount == null ? '-' : _currency.format(amount)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(details),
                if (isLoan && installments is List)
                  for (final installment in installments.whereType<Map>().take(
                    3,
                  ))
                    Text(
                      'Cicilan ${installment['number']}: ${_currency.format(int.tryParse(installment['amount'].toString()) ?? 0)} • ${_statusLabel(installment['status'])}${installment['payment_reference'] == null ? '' : ' • Ref ${installment['payment_reference']}'}',
                    ),
                if (date != null)
                  Text(DateFormat('d MMM yyyy', 'id_ID').format(date)),
                if (rejection != null && rejection.isNotEmpty)
                  Text('Catatan HRD: $rejection'),
              ],
            ),
            trailing: Text(
              _statusLabel(entry['status']),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: entry['status'] == 'rejected'
                    ? Colors.red.shade700
                    : entry['status'] == 'paid'
                    ? Colors.green.shade700
                    : null,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            isThreeLine: rejection != null && rejection.isNotEmpty,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan HR'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _isLoading ? null : _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildRequestForm(),
                  const SizedBox(height: 24),
                  Text(
                    'Riwayat pengajuan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildHistory(),
                ],
              ),
            ),
    );
  }
}
