import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
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
  bool _refreshError = false;
  late Order _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOrderDetail());
  }

  Future<void> _refreshOrderDetail() async {
    try {
      final service = ref.read(staffServiceProvider);
      final updatedOrder = await service.getOrderDetail(_order.id);
      if (mounted) {
        setState(() {
          _order = updatedOrder;
          _refreshError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _refreshError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat detail: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ulang',
              textColor: Colors.white,
              onPressed: _refreshOrderDetail,
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(staffServiceProvider)
          .updateOrderStatus(_order.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status diperbarui: $newStatus'),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshOrderDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _shipOrder() async {
    String selectedCourierCode = 'grab';
    String selectedCourierType = 'instant';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Pilih Kurir',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih layanan kurir untuk pengiriman pesanan ini.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCourierCode,
                decoration: InputDecoration(
                  labelText: 'Kurir',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'grab', child: Text('GrabExpress')),
                  DropdownMenuItem(value: 'gojek', child: Text('GoSend')),
                  DropdownMenuItem(value: 'jne', child: Text('JNE')),
                  DropdownMenuItem(value: 'jnt', child: Text('J&T Express')),
                  DropdownMenuItem(
                      value: 'sicepat', child: Text('SiCepat')),
                ],
                onChanged: (val) =>
                    setStateDialog(() => selectedCourierCode = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCourierType,
                decoration: InputDecoration(
                  labelText: 'Tipe Layanan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'instant', child: Text('Instant')),
                  DropdownMenuItem(
                      value: 'same_day', child: Text('Same Day')),
                  DropdownMenuItem(
                      value: 'regular', child: Text('Regular')),
                ],
                onChanged: (val) =>
                    setStateDialog(() => selectedCourierType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentIndigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Panggil Kurir',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);
    try {
      await ref.read(staffServiceProvider).shipOrder(
            _order.id,
            selectedCourierCode,
            selectedCourierType,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kurir berhasil dipanggil!'),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshOrderDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memanggil kurir: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivery = _order.serviceType == 'DELIVERY';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildModernHeader(context),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_refreshError)
                        _buildRefreshErrorBanner(),
                      const _SectionTitle(
                        title: 'Informasi Utama',
                        icon: Icons.analytics_outlined,
                      ),
                      _buildOrderInfoCard(_order),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Progres Operasional',
                        icon: Icons.timeline_rounded,
                      ),
                      OrderStatusTimeline(currentStatus: _order.orderStatus),
                      const SizedBox(height: 24),
                      if (isDelivery) ...[
                        const _SectionTitle(
                          title: 'Logistik & Lokasi',
                          icon: Icons.local_shipping_outlined,
                        ),
                        DeliveryInfoCard(order: _order),
                        const SizedBox(height: 24),
                      ] else if (_order.verificationCode != null) ...[
                        _VerificationCodeCard(order: _order),
                        const SizedBox(height: 24),
                      ],
                      const _SectionTitle(
                        title: 'Rincian Pesanan',
                        icon: Icons.receipt_long_outlined,
                      ),
                      OrderItemsCard(
                        order: _order,
                        formatRupiah: _formatRupiah,
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentSummaryCard(_order),
                      const SizedBox(height: 16),
                      if (_order.hasPrescription ||
                          (_order.notes ?? '').isNotEmpty)
                        _MetadataCard(order: _order),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyActionPanel(context),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderAction(
            Icons.arrow_back_ios_new_rounded,
            () => context.pop(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'OPERASIONAL TOKO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Detail Pesanan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderAction(Icons.notifications_none_rounded, () {}),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildRefreshErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gagal memuat data dari server. Menampilkan data tersimpan.',
              style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _refreshOrderDetail,
            child: const Text('Ulangi', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(Order order) {
    final cfg = _statusMap[order.orderStatus] ?? _statusMap['PENDING']!;
    final serviceConfig = {
      'DELIVERY': {'label': 'Antar ke Rumah'},
      'PICK_UP': {'label': 'Ambil di Apotek'},
      'WALK_IN': {'label': 'Pembelian Langsung'},
    };
    final config =
        serviceConfig[order.serviceType] ?? serviceConfig['WALK_IN']!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleInfo(
                'NO. PESANAN',
                '#${order.orderNumber}',
                isHighlight: true,
              ),
              StatusBadge(
                label: cfg.label,
                color: cfg.color,
                backgroundColor: cfg.bg,
                icon: cfg.icon,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildSimpleInfo(
                    'TIPE LAYANAN',
                    config['label']!,
                    icon: order.serviceType == 'DELIVERY'
                        ? Icons.local_shipping
                        : Icons.store,
                  ),
                ),
                const VerticalDivider(width: 32),
                Expanded(
                  child: _buildSimpleInfo(
                    'WAKTU ORDER',
                    order.createdAt,
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCustomerTile(order),
        ],
      ),
    );
  }

  Widget _buildSimpleInfo(
    String label,
    String value, {
    bool isHighlight = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: AppColors.textLight,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isHighlight ? AppColors.primary : AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerTile(Order order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 18,
            child: Text(
              order.customer['username']?[0]?.toUpperCase() ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customer['username'] ?? 'Pembeli Umum',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  order.customer['phone'] ?? '-',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.phone_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(Order order) {
    final isPaid = order.paymentStatus.toUpperCase() == 'PAID';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPaid ? AppColors.successLight : AppColors.dangerLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: isPaid ? AppColors.success : AppColors.danger,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'Pembayaran Lunas' : 'Belum Dibayar',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  isPaid ? 'Metode: Online Payment' : 'Menunggu Transfer',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _formatPriceBadge(order.grandTotal),
        ],
      ),
    );
  }

  Widget _formatPriceBadge(num price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _formatRupiah(price),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStickyActionPanel(BuildContext context) {
    final status = _order.orderStatus;
    if (['SHIPPED', 'DELIVERED', 'COMPLETED', 'CANCELLED'].contains(status)) {
      return const SizedBox.shrink();
    }

    String label = '';
    Color color = AppColors.primary;

    if (status == 'PENDING') {
      label = 'Terima & Proses';
    } else if (status == 'PROCESSING') {
      label = 'Siap Diambil/Kirim';
    } else if (status == 'READY_FOR_PICKUP') {
      label = _order.serviceType == 'DELIVERY'
          ? 'Panggil Kurir'
          : 'Selesaikan Pesanan';
      if (_order.serviceType == 'DELIVERY') color = AppColors.accentIndigo;
    } else if (status == 'CANCEL_REQUESTED') {
      label = 'Setujui Pembatalan';
      color = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: AppButton(
              label: _isUpdating ? 'Memproses...' : label,
              backgroundColor: color,
              onPressed: _isUpdating
                  ? null
                  : () {
                      if (status == 'PENDING') {
                        _updateStatus('PROCESSING');
                      } else if (status == 'PROCESSING') {
                        _updateStatus('READY_FOR_PICKUP');
                      } else if (status == 'READY_FOR_PICKUP') {
                        if (_order.serviceType == 'DELIVERY') {
                          _shipOrder();
                        } else {
                      else if (status == 'READY_FOR_PICKUP') {
                        if (_order.serviceType == 'PICK_UP')
                          _updateStatus('COMPLETED');
                        }
                      } else if (status == 'CANCEL_REQUESTED') {
                        _updateStatus('CANCELLED');
                      }
                    },
            ),
          ),
          const SizedBox(width: 12),
          if (status != 'CANCEL_REQUESTED')
            Container(
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.close_rounded, color: AppColors.danger),
                onPressed:
                    _isUpdating ? null : () => _updateStatus('CANCELLED'),
              ),
            ),
        ],
      ),
    );
  }
}

// ── SECTION TITLE ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textMid,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── METADATA CARD ─────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  final Order order;
  const _MetadataCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.hasPrescription) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    order.prescription?.isVerified == true
                        ? Icons.check_circle_rounded
                        : order.prescription?.isRejected == true
                            ? Icons.cancel_rounded
                            : Icons.verified_user_rounded,
                    color: order.prescription?.isVerified == true
                        ? AppColors.success
                        : order.prescription?.isRejected == true
                            ? AppColors.danger
                            : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.prescription?.isVerified == true
                          ? 'Resep sudah diverifikasi.'
                          : order.prescription?.isRejected == true
                              ? 'Resep ditolak.'
                              : 'Pesanan ini memerlukan verifikasi resep dokter.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: order.prescription?.isVerified == true
                            ? const Color(0xFF166534)
                            : order.prescription?.isRejected == true
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (order.prescription?.imageUrl != null) ...[
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                order.prescription!.imageUrl ?? '',
                                fit: BoxFit.contain,
                                loadingBuilder: (c, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  );
                                },
                                errorBuilder: (c, error, stackTrace) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_rounded,
                                          color: Colors.white54,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text('Gagal memuat gambar',
                                            style: TextStyle(
                                                color: Colors.white54)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      order.prescription!.imageUrl ?? '',
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_rounded,
                                  color: AppColors.textLight, size: 32),
                              SizedBox(height: 4),
                              Text('Gagal memuat gambar',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textLight)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
          if ((order.notes ?? '').isNotEmpty) ...[
            const Text(
              'CATATAN PELANGGAN',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order.notes!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMid,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── VERIFICATION CODE CARD ────────────────────────────────────

class _VerificationCodeCard extends StatelessWidget {
  final Order order;
  const _VerificationCodeCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.success.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'KODE PENGAMBILAN (PICKUP)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.success,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            order.verificationCode ?? '-',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.success,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Berikan kode ini saat mengambil pesanan',
            style: TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ── HELPERS ───────────────────────────────────────────────────

class _StatusCfg {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusCfg(this.label, this.color, this.bg, this.icon);
}

final _statusMap = {
  'PENDING': _StatusCfg(
    'Baru',
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
    'Siap Ambil',
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
    'Terkirim',
    AppColors.success,
    AppColors.successLight,
    Icons.check_circle_rounded,
  ),
  'COMPLETED': _StatusCfg(
    'Selesai',
    AppColors.textMid,
    AppColors.background,
    Icons.done_all_rounded,
  ),
  'CANCELLED': _StatusCfg(
    'Batal',
    AppColors.danger,
    AppColors.dangerLight,
    Icons.cancel_rounded,
  ),
  'CANCEL_REQUESTED': _StatusCfg(
    'Minta Batal',
    AppColors.danger,
    AppColors.dangerLight,
    Icons.cancel_outlined,
  ),
};

String _formatRupiah(num value) {
  final str = value.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return 'Rp ${buf.toString()}';
}