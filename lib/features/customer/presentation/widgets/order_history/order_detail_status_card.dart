import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class OrderDetailStatusCard extends StatelessWidget {
  final String orderStatus;

  const OrderDetailStatusCard({super.key, required this.orderStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Pesanan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusLabel(orderStatus),
                  style: const TextStyle(
                    color: Colors.white,
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
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(orderStatus),
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':    return 'Diproses';
      case 'SHIPPED':    return 'Dikirim';
      case 'COMPLETED':  return 'Selesai';
      case 'REVIEWED':   return 'Selesai';
      case 'CANCELLED':  return 'Dibatalkan';
      default:           return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING':    return Icons.hourglass_top_rounded;
      case 'SHIPPED':    return Icons.local_shipping_outlined;
      case 'COMPLETED':  return Icons.check_circle_outline_rounded;
      case 'REVIEWED':   return Icons.check_circle_outline_rounded;
      case 'CANCELLED':  return Icons.cancel_outlined;
      default:           return Icons.info_outline_rounded;
    }
  }
}