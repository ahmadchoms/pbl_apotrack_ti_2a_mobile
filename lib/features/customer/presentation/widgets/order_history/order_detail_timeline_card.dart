import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../staff/data/models/order.dart';

class OrderDetailTimelineCard extends StatelessWidget {
  final List<OrderStatusLog> statusLogs;

  const OrderDetailTimelineCard({
    super.key,
    required this.statusLogs,
  });

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pesanan Dibuat';
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'READY_FOR_PICKUP':
        return 'Siap Diambil';
      case 'SHIPPED':
        return 'Dikirim';
      case 'DELIVERED':
        return 'Terkirim';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (statusLogs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...statusLogs.asMap().entries.map((entry) {
            final i = entry.key;
            final log = entry.value;
            return _buildTimelineItem(
              label: _statusLabel(log.status),
              time: log.createdAt,
              description: log.description,
              isLast: i == statusLogs.length - 1,
              isCancelled: log.status == 'CANCELLED',
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String label,
    required String time,
    String? description,
    bool isLast = false,
    bool isCancelled = false,
  }) {
    final color =
        isCancelled ? AppColors.danger : AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCancelled
                    ? Icons.close_rounded
                    : Icons.check_rounded,
                color: AppColors.white,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                  width: 2,
                  height: description != null ? 44 : 36,
                  color: AppColors.divider),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCancelled
                      ? AppColors.danger
                      : AppColors.textPrimary,
                ),
              ),
              if (description != null && description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSlate,
                    ),
                  ),
                ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              if (!isLast) const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}