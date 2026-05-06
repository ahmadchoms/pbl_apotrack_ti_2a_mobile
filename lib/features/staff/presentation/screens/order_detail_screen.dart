import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../widgets/order_status_timeline.dart';
import '../widgets/delivery_info_card.dart';
import '../widgets/order_items_card.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy order data
    final order = {
      'id': 1,
      'order_number': 'ORD-0921',
      'created_at': '05 Mei 2026, 10:30',
      'buyer': {
        'id': 1,
        'username': 'Andi Setiawan',
        'email': 'andi@example.com',
        'phone': '081234567890',
      },
      'order_status': 'PROCESSING',
      'service_type': 'DELIVERY',
      'payment_status': 'PAID',
      'payment_method': 'Bank Transfer (BCA)',
      'tracking': {
        'tracking_number': 'AFT-9821039812',
        'courier_name': 'Biteship (Sicepat Reg)',
        'status': 'PICKUP',
      },
      'address': {
        'address_line': 'Jl. Merdeka No. 123, Kel. Sukamaju, Kec. Cilodong, Kota Depok, 16415',
        'distance': 4.2,
      },
      'items': [
        {
          'medicine': {
            'name': 'Amoxicillin 500mg',
            'unit': 'Strip',
            'accentColor': const Color(0xFF6366F1),
            'icon': Icons.local_pharmacy_rounded,
          },
          'quantity': 2,
          'price': 15000.0,
          'subtotal': 30000.0,
        },
        {
          'medicine': {
            'name': 'Paracetamol 500mg',
            'unit': 'Tablet',
            'accentColor': const Color(0xFF10B981),
            'icon': Icons.medication_rounded,
          },
          'quantity': 5,
          'price': 2500.0,
          'subtotal': 12500.0,
        },
      ],
      'grand_total': 52500.0,
      'shipping_cost': 10000.0,
      'notes': 'Mohon obat jangan dibanting, teras depan rumah ada pagar hitam.',
      'has_prescription': true,
    };

    final status = order['order_status'] as String;
    final isFinished = status == 'COMPLETED' || status == 'CANCELLED';
    final isDelivery = order['service_type'] == 'DELIVERY';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverHeader(context, order, isDelivery),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    OrderStatusTimeline(currentStatus: status),
                    const SizedBox(height: 16),
                    if (isDelivery) ...[
                      DeliveryInfoCard(order: order),
                      const SizedBox(height: 16),
                    ],
                    OrderItemsCard(order: order, formatRupiah: _formatRupiah),
                    const SizedBox(height: 16),
                    _buildPaymentCard(order),
                    const SizedBox(height: 16),
                    if ((order['has_prescription'] as bool) || (order['notes'] as String).isNotEmpty)
                      _buildNotesCard(context, order),
                  ]),
                ),
              ),
            ],
          ),
          if (!isFinished)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildActionPanel(context, status),
            ),
        ],
      ),
    );
  }

  // ── SLIVER HEADER ────────────────────────────
  Widget _buildSliverHeader(
    BuildContext context,
    Map<String, dynamic> order,
    bool isDelivery,
  ) {
    final status = order['order_status'] as String;
    final cfg = _statusMap[status]!;

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
            onPressed: () => _showMoreOptions(context),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${order['order_number']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: cfg.label,
                        color: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        icon: cfg.icon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (order['buyer'] as Map<String, dynamic>)['username'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isDelivery
                            ? Icons.delivery_dining_rounded
                            : Icons.store_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isDelivery ? 'Delivery' : 'Pickup',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded,
                          color: Colors.white.withOpacity(0.7), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        order['created_at'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text('Detail Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }

  // ── PAYMENT CARD ─────────────────────────────
  Widget _buildPaymentCard(Map<String, dynamic> order) {
    final isPaid = order['payment_status'] == 'PAID';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PEMBAYARAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.successLight : AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isPaid ? Icons.verified_rounded : Icons.warning_amber_rounded,
                  color: isPaid ? AppColors.success : AppColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPaid ? 'Sudah Dibayar' : 'Belum Dibayar',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isPaid ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order['payment_method'] as String,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: order['payment_status'] as String,
                color: isPaid ? AppColors.success : AppColors.danger,
                backgroundColor: isPaid ? AppColors.successLight : AppColors.dangerLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── NOTES CARD ───────────────────────────────
  Widget _buildNotesCard(BuildContext context, Map<String, dynamic> order) {
    final notes = order['notes'] as String;
    final hasPresc = order['has_prescription'] as bool;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATATAN / RESEP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          if (hasPresc) ...[
            AppButton(
              label: 'Lihat Resep Dokter',
              icon: Icons.assignment_rounded,
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              onPressed: () => _showPrescriptionDialog(context),
            ),
            const SizedBox(height: 16),
          ],
          if (notes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                notes,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMid,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── ACTION PANEL ─────────────────────────────
  Widget _buildActionPanel(BuildContext context, String status) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppButton(
              label: status == 'PENDING' ? 'Konfirmasi Pesanan' : 'Selesaikan Pesanan',
              icon: status == 'PENDING' ? Icons.check_circle_rounded : Icons.task_alt_rounded,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.danger),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(Icons.phone_rounded, 'Hubungi Customer', () {}),
            _buildOptionTile(Icons.print_rounded, 'Cetak Struk', () {}),
            _buildOptionTile(Icons.share_rounded, 'Bagikan Status', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMid),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showPrescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Resep Dokter', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.image_rounded, size: 48, color: AppColors.textSubtle),
            ),
            const SizedBox(height: 16),
            const Text('Foto resep yang diunggah oleh pembeli.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// Helper models and data
class _StatusCfg {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusCfg(this.label, this.color, this.bg, this.icon);
}

const Map<String, _StatusCfg> _statusMap = {
  'PENDING': _StatusCfg('Menunggu', AppColors.warning, AppColors.warningLight, Icons.hourglass_top_rounded),
  'PROCESSING': _StatusCfg('Diproses', AppColors.primary, AppColors.primaryLight, Icons.autorenew_rounded),
  'READY': _StatusCfg('Siap', AppColors.success, AppColors.successLight, Icons.check_circle_rounded),
  'COMPLETED': _StatusCfg('Selesai', AppColors.textMid, AppColors.background, Icons.done_all_rounded),
  'CANCELLED': _StatusCfg('Dibatalkan', AppColors.danger, AppColors.dangerLight, Icons.cancel_rounded),
};

String _formatRupiah(num value) {
  final str = value.toStringAsFixed(0);
  final buf = StringBuffer();
  final len = str.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return 'Rp ${buf.toString()}';
}