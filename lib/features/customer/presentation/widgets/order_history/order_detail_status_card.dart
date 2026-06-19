import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class OrderDetailStatusCard extends StatelessWidget {
  final String orderStatus;

  const OrderDetailStatusCard({super.key, required this.orderStatus});

  @override
  Widget build(BuildContext context) {
    final statusTheme = _getStatusTheme(orderStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: orderStatus == 'PENDING'
            ? Border.all(color: AppColors.divider, width: 1)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Pesanan',
                  style: TextStyle(
                    color: statusTheme.textColor.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusLabel(orderStatus),
                  style: TextStyle(
                    color: statusTheme.textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusTheme.iconContainerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(orderStatus),
              color: statusTheme.textColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  _StatusThemeData _getStatusTheme(String status) {
    switch (status) {
      case 'PENDING':
        return _StatusThemeData(
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warning,
          iconContainerColor: AppColors.warning.withOpacity(0.15),
        );

      case 'PROCESSING':
        return const _StatusThemeData(
          backgroundColor: AppColors.info,
          textColor: AppColors.white,
          iconContainerColor: Colors.white24,
        );

      case 'READY_FOR_PICKUP':
        return const _StatusThemeData(
          backgroundColor: AppColors.accentPurple,
          textColor: AppColors.white,
          iconContainerColor: Colors.white24,
        );

      case 'SHIPPED':
        return const _StatusThemeData(
          backgroundColor: AppColors.accentOrange,
          textColor: AppColors.white,
          iconContainerColor: Colors.white24,
        );

      case 'DELIVERED':
        return const _StatusThemeData(
          backgroundColor: AppColors.successLight,
          textColor: AppColors.mapGrid,
          iconContainerColor: Colors.white24,
        );

      case 'COMPLETED':
      case 'REVIEWED':
        return const _StatusThemeData(
          backgroundColor: AppColors.success,
          textColor: AppColors.white,
          iconContainerColor: Colors.white24,
        );

      case 'CANCELLED':
        return const _StatusThemeData(
          backgroundColor: AppColors.danger,
          textColor: AppColors.white,
          iconContainerColor: Colors.white24,
        );

      default:
        return const _StatusThemeData(
          backgroundColor: AppColors.textSlate,
          textColor: AppColors.white,
          iconContainerColor: Colors.white24,
        );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Menunggu';

      case 'PROCESSING':
        return 'Diproses';

      case 'READY_FOR_PICKUP':
        return 'Siap Diambil';

      case 'SHIPPED':
        return 'Dikirim';

      case 'COMPLETED':
      case 'REVIEWED':
        return 'Selesai';

      case 'CANCELLED':
        return 'Dibatalkan';

      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_top_rounded;

      case 'PROCESSING':
        return Icons.hourglass_bottom_rounded;

      case 'READY_FOR_PICKUP':
        return Icons.storefront_outlined;

      case 'SHIPPED':
        return Icons.local_shipping_outlined;

      case 'COMPLETED':
      case 'REVIEWED':
        return Icons.check_circle_outline_rounded;

      case 'CANCELLED':
        return Icons.cancel_outlined;

      default:
        return Icons.info_outline_rounded;
    }
  }
}

class _StatusThemeData {
  final Color backgroundColor;
  final Color textColor;
  final Color iconContainerColor;

  const _StatusThemeData({
    required this.backgroundColor,
    required this.textColor,
    required this.iconContainerColor,
  });
}
