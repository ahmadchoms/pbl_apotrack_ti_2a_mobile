import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:mobile/core/models/order.dart';
import '../widgets/order_history/order_detail_status_card.dart';
import '../widgets/order_history/order_detail_items_card.dart';
import '../widgets/order_history/order_detail_summary_card.dart';
import '../widgets/order_history/order_detail_timeline_card.dart';
import 'package:mobile/core/models/prescription.dart';
import '../providers/customer_order_provider.dart';

class CustomerOrderDetailScreen extends ConsumerStatefulWidget {
  final Order? order;
  final String? orderId;

  const CustomerOrderDetailScreen({super.key, this.order, this.orderId})
    : assert(
        order != null || orderId != null,
        'Either order or orderId must be provided',
      );

  @override
  ConsumerState<CustomerOrderDetailScreen> createState() =>
      _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState
    extends ConsumerState<CustomerOrderDetailScreen> {
  Order? _order;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _silentRefresh();
    });
  }

  Future<void> _silentRefresh() async {
    final id = _order?.id ?? widget.orderId ?? widget.order?.id;
    if (id == null) return;
    try {
      final fresh = await ref.refresh(orderDetailProvider(id).future);
      if (!mounted) return;
      setState(() => _order = fresh);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    final id = _order?.id ?? widget.orderId ?? widget.order?.id;
    if (id == null) return;
    try {
      final fresh = await ref.refresh(orderDetailProvider(id).future);
      if (!mounted) return;
      setState(() => _order = fresh);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan diperbarui'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId ?? widget.order?.id;
    if (orderId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark,
              size: 20,
            ),
            onPressed: () => context.go('/customer?tab=2'),
          ),
          title: const Text(
            'Detail Pesanan',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: Text('ID Pesanan tidak valid')),
      );
    }

    final orderFuture = ref.watch(orderDetailProvider(orderId));

    return orderFuture.when(
      loading: () => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.go('/customer?tab=2');
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textDark,
                size: 20,
              ),
              onPressed: () => context.go('/customer?tab=2'),
            ),
            title: const Text(
              'Detail Pesanan',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            centerTitle: true,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.go('/customer?tab=2');
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textDark,
                size: 20,
              ),
              onPressed: () => context.go('/customer?tab=2'),
            ),
            title: const Text(
              'Detail Pesanan',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            centerTitle: true,
          ),
          body: const Center(child: Text('Pesanan tidak ditemukan')),
        ),
      ),
      data: (order) {
        _order = order;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            context.go('/customer?tab=2');
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark,
                  size: 20,
                ),
                onPressed: () => context.go('/customer?tab=2'),
              ),
              title: const Text(
                'Detail Pesanan',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textDark,
                  ),
                  onPressed: _refresh,
                ),
              ],
            ),
            body: _buildContent(context),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final order = _order!;
    final pData = order.prescription;
    final parsedPrescription = pData != null
        ? CustomerPrescription(
            id: pData.id,
            imageUrl: pData.imageUrl ?? '',
            status: pData.status,
          )
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OrderDetailStatusCard(orderStatus: order.orderStatus),
        const SizedBox(height: 12),
        _buildPharmacyCard(order),
        const SizedBox(height: 12),
        if (order.verificationCode != null &&
            order.verificationCode!.isNotEmpty &&
            order.orderStatus != 'COMPLETED' &&
            order.orderStatus != 'CANCELLED') ...[
          _buildQrCard(context, order),
          const SizedBox(height: 12),
        ],
        _buildTransactionTimeCard(order),
        const SizedBox(height: 12),
        _buildPaymentMethodCard(order),
        const SizedBox(height: 12),
        if (parsedPrescription != null) ...[
          _buildPrescriptionCard(parsedPrescription),
          const SizedBox(height: 12),
        ],
        OrderDetailItemsCard(
          items: order.items,
          totalItems: order.items.length,
        ),
        const SizedBox(height: 12),
        OrderDetailSummaryCard(
          subtotal: order.subtotalAmount,
          grandTotal: order.grandTotal,
        ),
        const SizedBox(height: 12),
        OrderDetailTimelineCard(statusLogs: order.statusLogs),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPharmacyCard(Order detail) {
    final pharmacyName = detail.pharmacy['name']?.toString() ?? '—';
    final pharmacyAddress = detail.pharmacy['address']?.toString() ?? '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.store_rounded, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'INFORMASI TOKO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pharmacyName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pharmacyAddress,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSlate,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(BuildContext context, Order detail) {
    final verificationCode = detail.verificationCode ?? '';
    final pharmacyName = detail.pharmacy['name']?.toString() ?? '—';
    final total = detail.grandTotal;

    String rupiah(num amount) =>
        'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: const Center(
              child: Text(
                'KODE VERIFIKASI PENGAMBILAN OBAT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMid,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: QrImageView(
                data: verificationCode.isEmpty ? ' ' : verificationCode,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: verificationCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kode disalin!'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    verificationCode.isEmpty ? 'Memuat...' : verificationCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textDark,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.local_pharmacy_rounded,
                  label: 'Nama Apotek',
                  value: pharmacyName,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.receipt_outlined,
                        label: 'No. Pesanan',
                        value: detail.orderNumber,
                      ),
                    ),
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Total',
                        value: rupiah(total),
                        valueColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Obat yang dipesan:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...detail.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.textMid,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.medicineName} x${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMid,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTimeCard(Order detail) {
    final isPickup = detail.serviceType == 'PICK_UP' || detail.serviceType == 'PICKUP';
    final isPos = detail.serviceType == 'POS' || detail.serviceType == 'WALK_IN';
    final serviceLabel = isPickup
        ? 'Ambil di Tempat'
        : (isPos ? 'Pembelian Langsung' : 'Ambil di Tempat');
    final serviceIcon = isPickup
        ? Icons.storefront_rounded
        : (isPos ? Icons.receipt_long_rounded : Icons.storefront_rounded);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TIPE LAYANAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          serviceIcon,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          serviceLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WAKTU TRANSAKSI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail.createdAt,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Order detail) {
    final isPaid = detail.paymentStatus == 'PAID';
    final isCash = detail.paymentMethod == 'CASH';
    final isQris = detail.paymentMethod == 'E-WALLET';

    final paymentIcon = isCash
        ? Icons.payments_outlined
        : isQris
        ? Icons.qr_code_rounded
        : Icons.account_balance_rounded;
    final paymentLabel = isCash
        ? 'Tunai'
        : isQris
        ? 'QRIS'
        : 'Transfer';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(paymentIcon, color: AppColors.textPrimary, size: 20),
                const SizedBox(width: 10),
                Text(
                  paymentLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? 'Lunas' : 'Belum Dibayar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isPaid ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isQris ? Icons.verified_outlined : Icons.info_outline_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                isCash
                    ? 'PEMBAYARAN DILAKUKAN DI APOTEK'
                    : isQris
                    ? 'PEMBAYARAN TERVERIFIKASI OTOMATIS'
                    : 'PEMBAYARAN VIA TRANSFER BANK',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(CustomerPrescription prescription) {
    final statusColor = switch (prescription.status) {
      'VERIFIED' => AppColors.success,
      'REJECTED' => AppColors.danger,
      _ => AppColors.warning,
    };
    final statusBg = switch (prescription.status) {
      'VERIFIED' => AppColors.successLight,
      'REJECTED' => AppColors.dangerLight,
      _ => AppColors.warningLight,
    };
    final statusLabel = switch (prescription.status) {
      'VERIFIED' => 'Terverifikasi',
      'REJECTED' => 'Ditolak',
      _ => 'Menunggu Verifikasi',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Resep Dokter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              prescription.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 160,
                color: AppColors.background,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: AppColors.textLight,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          if (prescription.doctorName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Dr. ${prescription.doctorName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSlate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (prescription.status == 'REJECTED' &&
              prescription.rejectionNote != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.danger,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prescription.rejectionNote!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({Color? color}) => BoxDecoration(
    color: color ?? AppColors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
