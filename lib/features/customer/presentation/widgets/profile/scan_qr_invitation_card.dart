import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../screens/scanner_screen.dart';

class ScanQrInvitationCard extends StatelessWidget {
  const ScanQrInvitationCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),

        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textLight,
        ),

        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScannerScreen(),
            ),
          );

          if (result != null) {
            debugPrint('QR Invitation Result: $result');

            // TODO:
            // validasi invitation
            // join staff apotek
            // call API backend
          }
        },
      ),
    );
  }
}