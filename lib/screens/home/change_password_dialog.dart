import 'package:flutter/material.dart';

import '../../api/api.service.dart';
import '../../core/validation/password_validation.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationController = TextEditingController();
  var _isLoading = false;
  var _showCurrentPassword = false;
  var _showNewPassword = false;
  var _showConfirmation = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await widget.apiService.updatePassword(
      currentPassword: _currentPasswordController.text,
      password: _newPasswordController.text,
      passwordConfirmation: _confirmationController.text,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Gagal mengganti password.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ganti Password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Password lama',
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _showCurrentPassword = !_showCurrentPassword,
                    ),
                    icon: Icon(
                      _showCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: PasswordValidation.currentPassword,
              ),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  labelText: 'Password baru',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showNewPassword = !_showNewPassword),
                    icon: Icon(
                      _showNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: PasswordValidation.newPassword,
              ),
              TextFormField(
                controller: _confirmationController,
                obscureText: !_showConfirmation,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi password baru',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showConfirmation = !_showConfirmation),
                    icon: Icon(
                      _showConfirmation
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) => PasswordValidation.confirmation(
                  value,
                  _newPasswordController.text,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
