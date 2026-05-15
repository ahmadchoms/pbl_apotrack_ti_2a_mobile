import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/staff/presentation/providers/staff_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/services/staff_service.dart';
import '../widgets/order_status_timeline.dart';
import '../widgets/delivery_info_card.dart';
import '../widgets/order_items_card.dart';
import '../../data/models/order.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isUpdating = false;
  late Order _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    // Ambil detail terbaru segera setelah layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOrderDetail();
    });
  }

  Future<void> _refreshOrderDetail() async {
    try {
      final service = ref.read(staffServiceProvider);
      final updatedOrder = await service.getOrderDetail(_order.id);
      if (mounted) {
        setState(() => _order = updatedOrder);
      }
    } catch (e) {
      debugPrint('Gagal refresh detail: $e');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final service = ref.read(staffServiceProvider);
      await service.updateOrderStatus(_order.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan berhasil diperbarui ke: $newStatus'),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshOrderDetail(); // Refresh data setelah update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui pesanan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _shipOrder() async {
    setState(() => _isUpdating = true);
    try {
      final service = ref.read(staffServiceProvider);
      // Untuk sementara kita gunakan JNE REG sebagai default
      // Di masa depan bisa ditambahkan pemilihan kurir
      await service.shipOrder(_order.id, 'jne', 'reg');

      final updatedOrder = await service.getOrderDetail(_order.id);

      if (mounted) {
        setState(() => _order = updatedOrder);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kurir Biteship berhasil dipanggil!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(staffOrdersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal panggil kurir: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _order.orderStatus;
    final isDelivery = _order.serviceType == 'DELIVERY';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverHeader(context, _order, isDelivery),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    OrderStatusTimeline(currentStatus: status),
                    const SizedBox(height: 16),
                    if (isDelivery) ...[
                      DeliveryInfoCard(order: _order),
                      const SizedBox(height: 16),
                    ],
                    if (!isDelivery && _order.verificationCode != null) ...[
                      _buildVerificationCard(_order),
                      const SizedBox(height: 16),
                    ],
                    OrderItemsCard(order: _order, formatRupiah: _formatRupiah),
                    const SizedBox(height: 16),
                    _buildPaymentCard(_order),
                    const SizedBox(height: 16),
                    if (_order.hasPrescription ||
                        (_order.notes ?? '').isNotEmpty)
                      _buildNotesCard(context, _order),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildActionPanel(context),
          ),
        ],
      ),
    );
  }

  // ── SLIVER HEADER ────────────────────────────
  Widget _buildSliverHeader(
    BuildContext context,
    Order order,
    bool isDelivery,
  ) {
    final status = order.orderStatus;
    final cfg = _statusMap[status] ?? _statusMap['PENDING']!;
    final customerName =
        order.customer['username']?.toString() ?? 'Pembeli Umum';
    final customerPhone = order.customer['phone']?.toString();

    return SliverAppBar(
      expandedHeight: 210,
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
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(color: AppColors.primary),
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
                        '#${order.orderNumber}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
                    customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (customerPhone != null)
                    Text(
                      customerPhone,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                            order.serviceType == 'DELIVERY'
                                ? 'Pengiriman'
                                : 'Ambil Sendiri',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatDateTime(order.createdAt),
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
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        'Detail Pesanan',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }

  // ── VERIFICATION CARD ───────────────────────
  Widget _buildVerificationCard(Order order) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KODE VERIFIKASI AMBIL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentOrange.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  order.verificationCode ?? '-',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentOrange,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tunjukkan kode ini saat pengambilan',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PAYMENT CARD ─────────────────────────────
  Widget _buildPaymentCard(Order order) {
    final isPaid = order.paymentStatus.toUpperCase() == 'PAID';
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
                  color: isPaid
                      ? AppColors.successLight
                      : AppColors.dangerLight,
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
                      'Metode Pembayaran',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: order.paymentStatus,
                color: isPaid ? AppColors.success : AppColors.danger,
                backgroundColor: isPaid
                    ? AppColors.successLight
                    : AppColors.dangerLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── NOTES CARD ───────────────────────────────
  Widget _buildNotesCard(BuildContext context, Order order) {
    final notes = order.notes ?? '';
    final hasPresc = order.hasPrescription;

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
              onPressed: () {},
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
  Widget _buildActionPanel(BuildContext context) {
    final status = _order.orderStatus;
    final type = _order.serviceType;

    // Sembunyikan tombol untuk status akhir
    if (['SHIPPED', 'DELIVERED', 'COMPLETED', 'CANCELLED'].contains(status)) {
      return const SizedBox.shrink();
    }

    String label = '';
    IconData icon = Icons.check_circle_rounded;
    VoidCallback? onPressed;
    Color bgColor = AppColors.primary;

    if (status == 'PENDING') {
      label = 'Terima & Proses Pesanan';
      onPressed = () => _updateStatus('PROCESSING');
    } else if (status == 'PROCESSING') {
      label = 'Obat Siap / Selesai Dibungkus';
      onPressed = () => _updateStatus('READY_FOR_PICKUP');
    } else if (status == 'READY_FOR_PICKUP') {
      if (type == 'DELIVERY') {
        label = 'Panggil Kurir (Request Pickup)';
        icon = Icons.local_shipping_rounded;
        bgColor = AppColors.accentIndigo;
        onPressed = _shipOrder;
      } else {
        label = 'Selesaikan Pesanan (Diserahkan)';
        onPressed = () => _updateStatus('COMPLETED');
      }
    }

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
              label: _isUpdating ? 'Memproses...' : label,
              icon: icon,
              backgroundColor: bgColor,
              onPressed: _isUpdating ? null : onPressed,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.danger,
                      ),
                    )
                  : const Icon(Icons.close_rounded, color: AppColors.danger),
              onPressed: _isUpdating ? null : () => _updateStatus('CANCELLED'),
            ),
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

final _statusMap = {
  'PENDING': _StatusCfg(
    'Menunggu',
    AppColors.warning,
    AppColors.warningLight,
    Icons.hourglass_top_rounded,
  ),
  'PROCESSING': _StatusCfg(
    'Diproses',
    AppColors.primary,
    AppColors.primaryLight,
    Icons.autorenew_rounded,
  ),
  'READY_FOR_PICKUP': _StatusCfg(
    'Siap',
    AppColors.success,
    AppColors.successLight,
    Icons.check_circle_rounded,
  ),
  'SHIPPED': _StatusCfg(
    'Dikirim',
    AppColors.accentIndigo,
    AppColors.primaryLight,
    Icons.local_shipping_rounded,
  ),
  'DELIVERED': _StatusCfg(
    'Diterima',
    AppColors.success,
    AppColors.successLight,
    Icons.inventory_2_rounded,
  ),
  'COMPLETED': _StatusCfg(
    'Selesai',
    AppColors.textMid,
    AppColors.background,
    Icons.done_all_rounded,
  ),
  'CANCELLED': _StatusCfg(
    'Dibatalkan',
    AppColors.danger,
    AppColors.dangerLight,
    Icons.cancel_rounded,
  ),
};

String _formatDateTime(String raw) {
  try {
    final dt = DateTime.parse(raw);

    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final month = months[dt.month - 1];

    return '$hour:$minute · $day $month ${dt.year}';
  } catch (e) {
    return raw;
  }
}

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
