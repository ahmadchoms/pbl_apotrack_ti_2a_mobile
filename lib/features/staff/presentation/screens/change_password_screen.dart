import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/staff_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
  final _oldPassController     = TextEditingController();
  final _newPassController     = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureOld     = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

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
    } else if (_newPassController.text.trim() ==
        _oldPassController.text.trim()) {
      _newPassError = 'Kata Sandi baru tidak boleh sama dengan kata sandi lama';
      valid = false;
    } else {
      _newPassError = null;
    }

    if (_confirmPassController.text.trim() !=
        _newPassController.text.trim()) {
      _confirmPassError = 'Kata Sandi tidak cocok';
      valid = false;
    } else {
      _confirmPassError = null;
    }

    setState(() {});
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(profileProvider.notifier).changePassword(
            currentPassword: _oldPassController.text.trim(),
            newPassword: _newPassController.text.trim(),
          );
      if (mounted) {
        _showSnack('Kata Sandi berhasil diperbarui!');
        context.pop();
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('current_password')) {
        errorMessage = 'Kata Sandi lama yang Anda masukkan salah';
      }
      if (mounted) _showSnack(errorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Ubah Kata Sandi',
          style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Info Box (UI staff)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.shield_outlined,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Keamanan Akun',
                            style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        SizedBox(height: 4),
                        Text(
                          'Gunakan minimal 8 karakter dengan kombinasi '
                          'huruf dan angka untuk keamanan maksimal.',
                          style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Field dengan error inline (dari customer)
            _buildPasswordField(
              label: 'Kata Sandi Saat Ini',
              controller: _oldPassController,
              obscure: _obscureOld,
              toggle: (v) => setState(() => _obscureOld = v),
              errorText: _oldPassError,
              onChanged: (_) {
                if (_oldPassError != null) {
                  setState(() => _oldPassError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              label: 'Kata Sandi Baru',
              controller: _newPassController,
              obscure: _obscureNew,
              toggle: (v) => setState(() => _obscureNew = v),
              errorText: _newPassError,
              onChanged: (_) {
                if (_newPassError != null) {
                  setState(() => _newPassError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              label: 'Konfirmasi Kata Sandi Baru',
              controller: _confirmPassController,
              obscure: _obscureConfirm,
              toggle: (v) => setState(() => _obscureConfirm = v),
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
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Perbarui Kata Sandi',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required Function(bool) toggle,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: errorText != null
                  ? AppColors.danger
                  : AppColors.textLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null
                  ? AppColors.danger
                  : AppColors.divider,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.textMid, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMid,
                  size: 20,
                ),
                onPressed: () => toggle(!obscure),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
        ),
        // Error text inline (dari customer)
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 13, color: AppColors.danger),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}