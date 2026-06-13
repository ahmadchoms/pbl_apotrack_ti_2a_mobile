import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_profile_provider.dart';
import '../widgets/profile/password_field.dart';

class CustomerChangePasswordScreen extends ConsumerStatefulWidget {
  const CustomerChangePasswordScreen({super.key});

  @override
  ConsumerState<CustomerChangePasswordScreen> createState() =>
      _CustomerChangePasswordScreenState();
}

class _CustomerChangePasswordScreenState
    extends ConsumerState<CustomerChangePasswordScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  String? _oldPassError;
  String? _newPassError;
  String? _confirmPassError;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    if (_oldPassController.text.trim().isEmpty) {
      _oldPassError = 'Kata Sandi lama tidak boleh kosong';
      valid = false;
    } else {
      _oldPassError = null;
    }
    if (_newPassController.text.trim().length < 8) {
      _newPassError = 'Kata Sandi minimal 8 karakter';
      valid = false;
    } else {
      _newPassError = null;
    }
    if (_confirmPassController.text.trim() != _newPassController.text.trim()) {
      _confirmPassError = 'Kata Sandi tidak cocok';
      valid = false;
    } else {
      _confirmPassError = null;
    }
    setState(() {});
    return valid;
  }

  Future<void> _onSave() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(customerProfileProvider.notifier)
          .changePassword(
            currentPassword: _oldPassController.text.trim(),
            newPassword: _newPassController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata Sandi berhasil diperbarui'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1D70F5);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ubah Kata Sandi',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pastikan kata sandi baru Anda minimal 8 karakter '
                      'dengan kombinasi huruf dan angka.',
                      style: TextStyle(
                        color: Color(0xFF0055a5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PasswordField(
              label: 'Kata Sandi Lama',
              controller: _oldPassController,
              obscure: _obscureOld,
              onToggle: (v) => setState(() => _obscureOld = v),
              errorText: _oldPassError,
              onChanged: (_) {
                if (_oldPassError != null) {
                  setState(() => _oldPassError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Kata Sandi Baru',
              controller: _newPassController,
              obscure: _obscureNew,
              onToggle: (v) => setState(() => _obscureNew = v),
              errorText: _newPassError,
              onChanged: (_) {
                if (_newPassError != null) {
                  setState(() => _newPassError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Konfirmasi Kata Sandi Baru',
              controller: _confirmPassController,
              obscure: _obscureConfirm,
              onToggle: (v) => setState(() => _obscureConfirm = v),
              errorText: _confirmPassError,
              onChanged: (_) {
                if (_confirmPassError != null) {
                  setState(() => _confirmPassError = null);
                }
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Perbarui Kata Sandi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
