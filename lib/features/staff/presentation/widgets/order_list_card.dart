import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/order.dart';

class OrderListCard extends StatelessWidget {
  final Order order;
  final Map<String, dynamic> statusConfig;
  final String Function(num) formatRupiah;

  const OrderListCard({
    super.key,
    required this.order,
    required this.statusConfig,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;
    final isCompleted = status == 'COMPLETED' || status == 'CANCELLED';
    final isDelivery = order.serviceType == 'DELIVERY';

    final Map<String, String> nextAction = {
      'PENDING': 'Mulai Proses',
      'PROCESSING': 'Tandai Siap',
      'READY': 'Selesaikan',
    };

    final customerName = order.customer['username']?.toString() ?? 'Pembeli Umum';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            context.push('/staff/order-detail', extra: order);
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppColors.textMid,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textLight),
                    const SizedBox(width: 3),
                    Text(
                      _formatTime(order.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(
                      label: statusConfig['label'],
                      color: statusConfig['color'],
                      backgroundColor: statusConfig['bgColor'],
                      icon: statusConfig['icon'],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.items.length} item pesanan',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(order.grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatusBadge(
                      label: isDelivery ? 'Delivery' : 'Pickup',
                      color: isDelivery ? AppColors.primary : AppColors.success,
                      backgroundColor: isDelivery ? AppColors.primaryLight : AppColors.successLight,
                      icon: isDelivery ? Icons.delivery_dining_rounded : Icons.store_rounded,
                    ),
                    const Spacer(),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Pesanan Selesai',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push('/staff/order-detail', extra: order);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            nextAction[status] ?? 'Lihat Detail',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null) return '--:--';
    final str = dateStr.toString();
    final parts = str.split(' ');
    if (parts.length >= 2) {
      final timeParts = parts[1].split(':');
      if (timeParts.length >= 2) return '${timeParts[0]}:${timeParts[1]}';
    }
    return str.length > 5 ? str.substring(0, 5) : str;
  }
}