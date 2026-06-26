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
    final isPos = order.serviceType == 'POS' || order.serviceType == 'WALK_IN';
    final customerName =
        order.customer['username']?.toString() ?? 'Pembeli Umum';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTimeIndicator(),
                    const Spacer(),
                    StatusBadge(
                      label: statusConfig['label'],
                      color: statusConfig['color'],
                      backgroundColor: statusConfig['bgColor'],
                      icon: statusConfig['icon'],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCustomerAvatar(customerName),
                    const SizedBox(width: 14),
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
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildOrderMeta(isPos),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMid,
                        ),
                      ),
                      Text(
                        formatRupiah(order.grandTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSubtle,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _buildActionButton(context, status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatFullDateTime(order.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderMeta(bool isPos) {
    return Row(
      children: [
        _buildMetaItem(
          Icons.inventory_2_outlined,
          '${order.items.length} Produk',
        ),
        const SizedBox(width: 12),
        _buildMetaItem(
          isPos ? Icons.receipt_long_rounded : Icons.storefront_rounded,
          isPos ? "Pembelian Langsung" : "Ambil di Apotek",
        ),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerAvatar(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String status) {
    final Map<String, String> actions = {
      'PENDING': 'Mulai Proses',
      'PROCESSING': 'Siapkan Order',
      'READY_FOR_PICKUP': 'Selesaikan',
    };

    final isCompleted =
        status == 'COMPLETED' || status == 'CANCELLED' || status == 'DELIVERED';

    void goToDetail() {
      HapticFeedback.selectionClick();
      context.push('/staff/order-detail', extra: order);
    }

    if (isCompleted) {
      return InkWell(
        onTap: goToDetail,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            'Lihat Detail',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: goToDetail,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            actions[status] ?? 'Kelola Order',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  String _formatFullDateTime(dynamic dateStr) {
    if (dateStr == null) return '--.--, -- --- ----';
    try {
      final str = dateStr.toString();
      final parts = str.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');

        if (dateParts.length == 3 && timeParts.length >= 2) {
          final year = dateParts[0];
          final month = _getMonthName(dateParts[1]);
          final day = dateParts[2];
          final hour = timeParts[0];
          final minute = timeParts[1];

          return '$hour.$minute, $day $month $year';
        }
      }
      return str;
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _getMonthName(String monthNum) {
    const months = {
      '01': 'Jan',
      '02': 'Feb',
      '03': 'Mar',
      '04': 'Apr',
      '05': 'Mei',
      '06': 'Jun',
      '07': 'Jul',
      '08': 'Agt',
      '09': 'Sep',
      '10': 'Okt',
      '11': 'Nov',
      '12': 'Des',
    };
    return months[monthNum] ?? monthNum;
  }
}
