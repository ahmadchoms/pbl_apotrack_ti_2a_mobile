import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';

class OrderItemsCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String Function(num) formatRupiah;

  const OrderItemsCard({
    super.key,
    required this.order,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List;
    final grandTotal = order['grand_total'] as num;
    final shippingCost = order['shipping_cost'] as num;
    final subtotal = grandTotal - shippingCost;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ITEM PESANAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _buildItemRow(item as Map<String, dynamic>)),
          const SizedBox(height: 4),
          const Divider(height: 24),
          _PriceRow(label: 'Subtotal Produk', value: formatRupiah(subtotal)),
          const SizedBox(height: 6),
          _PriceRow(label: 'Biaya Ongkir', value: formatRupiah(shippingCost)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  formatRupiah(grandTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final med = item['medicine'] as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (med['accentColor'] as Color).withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(med['icon'] as IconData,
                color: med['accentColor'] as Color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${med['unit']}  ·  ${item['quantity']}x ${formatRupiah(item['price'] as num)}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRupiah(item['subtotal'] as num),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMid,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        Text(value,
            style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}
