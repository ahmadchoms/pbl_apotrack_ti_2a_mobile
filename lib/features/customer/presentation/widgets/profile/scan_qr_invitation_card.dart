import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../customer/data/repositories/customer_repository.dart';
import '../../screens/scanner_screen.dart';

class ScanQrInvitationCard extends ConsumerWidget {
  const ScanQrInvitationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,

        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.success,
            size: 20,
          ),
        ),

        title: const Text(
          'Scan QR Undangan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),

        subtitle: const Text(
          'Masuk sebagai Staff Apotek',
          style: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),

        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textLight,
        ),

        onTap: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );

          if (result != null && context.mounted) {
            _showConfirmDialog(context, ref, result);
          }
        },
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String invitationUrl,
  ) {
    // Parse pharmacy name dari URL jika ada, fallback ke "apotek ini"
    String pharmacyHint = 'apotek ini';
    try {
      final uri = Uri.parse(invitationUrl);
      final pharmacyId = uri.queryParameters['pharmacy_id'];
      if (pharmacyId != null) {
        pharmacyHint = 'apotek (ID: ${pharmacyId.substring(0, 8)}...)';
      }
    } catch (_) {}

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _InvitationConfirmDialog(
        invitationUrl: invitationUrl,
        pharmacyHint: pharmacyHint,
        onConfirm: () async {
          Navigator.pop(ctx); // tutup dialog konfirmasi
          await _processJoin(context, ref, invitationUrl);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _processJoin(
    BuildContext context,
    WidgetRef ref,
    String invitationUrl,
  ) async {
    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repo = ref.read(customerRepositoryProvider);
      final response = await repo.joinStaffByInvitation(invitationUrl);

      if (context.mounted) Navigator.pop(context); // tutup loading

      final pharmacyName = response.data['pharmacy']?['name'] ?? 'apotek';

      if (context.mounted) {
        _showResultDialog(
          context,
          isSuccess: true,
          message:
              'Kamu berhasil bergabung sebagai Staff di $pharmacyName!\n\nSilakan login ulang untuk mengakses fitur staff.',
        );
      }
    } on DioException catch (e) {
      if (context.mounted) Navigator.pop(context); // tutup loading

      final msg =
          e.response?.data?['message'] ?? 'Terjadi kesalahan. Coba lagi.';

      if (context.mounted) {
        _showResultDialog(context, isSuccess: false, message: msg);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        _showResultDialog(
          context,
          isSuccess: false,
          message: 'Terjadi kesalahan tidak terduga.',
        );
      }
    }
  }

  void _showResultDialog(
    BuildContext context, {
    required bool isSuccess,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppColors.successLight
                    : AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: isSuccess ? AppColors.success : AppColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess ? 'Berhasil!' : 'Gagal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSuccess ? AppColors.success : AppColors.danger,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMid,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess
                    ? AppColors.success
                    : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog Widget ────────────────────────────────────────────────────────────

class _InvitationConfirmDialog extends StatelessWidget {
  final String invitationUrl;
  final String pharmacyHint;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _InvitationConfirmDialog({
    required this.invitationUrl,
    required this.pharmacyHint,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_rounded,
              color: AppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bergabung sebagai Staff?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamu akan bergabung sebagai Staff di $pharmacyHint. Role akunmu akan berubah dari Customer menjadi Staff.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMid,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: AppColors.textMid,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ya, Bergabung',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
