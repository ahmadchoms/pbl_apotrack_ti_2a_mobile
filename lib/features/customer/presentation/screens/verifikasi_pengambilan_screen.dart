import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../staff/data/models/order.dart';
import '../../data/services/customer_order_service.dart';
import '../widgets/order_history/order_detail_status_card.dart';
import '../widgets/order_history/order_detail_timeline_card.dart';
import 'beri_ulasan_screen.dart';

class VerifikasiPengambilanScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String orderNumber;
  final String verificationCode;
  final String pharmacyName;
  final String pharmacyId;
  final List<Map<String, dynamic>> items;
  final int total;

  const VerifikasiPengambilanScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.verificationCode,
    required this.pharmacyName,
    required this.pharmacyId,
    required this.items,
    required this.total,
  });

  @override
  ConsumerState<VerifikasiPengambilanScreen> createState() =>
      _VerifikasiPengambilanScreenState();
}

class _VerifikasiPengambilanScreenState
    extends ConsumerState<VerifikasiPengambilanScreen> {
  late final CustomerOrderService _orderService;
  Order? _order;
  String _verificationCode = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _orderService = ref.read(customerOrderServiceProvider);
    _verificationCode = widget.verificationCode;
    _cekStatus();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _cekStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _cekStatus() async {
    if (_order?.orderStatus == 'COMPLETED') {
      _pollTimer?.cancel();
      return;
    }
    try {
      final order = await _orderService.getOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        if (_verificationCode.isEmpty) {
          _verificationCode = order.verificationCode ?? '';
        }
      });
      if (order.orderStatus == 'COMPLETED') _pollTimer?.cancel();
    } catch (_) {
      if (!mounted) return;
    }
  }

  String _rupiah(int amount) =>
      'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  bool get _bisaUlas => _order?.orderStatus == 'COMPLETED';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Verifikasi Pengambilan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuccessBanner(),
            const SizedBox(height: 20),
            _buildSectionTitle(
              'Tunjukkan QR Ini ke Apotek',
              'Datang ke apotek dan tunjukkan QR ini. Apoteker akan scan untuk memproses pengambilan obat.',
            ),
            const SizedBox(height: 20),
            _buildQrCard(),
            const SizedBox(height: 24),
            if (_order != null) ...[
              const SizedBox(height: 16),
              OrderDetailStatusCard(orderStatus: _order!.orderStatus),
              const SizedBox(height: 12),
              OrderDetailTimelineCard(statusLogs: _order!.statusLogs),
              const SizedBox(height: 16),
            ],
            _buildReviewButton(enabled: _bisaUlas),
            if (!_bisaUlas) _buildWaitingCard(),
            const SizedBox(height: 16),
            _buildInfoBanner(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pembayaran berhasil! Datang ke apotek dan tunjukkan QR ini.',
              style: TextStyle(
                color: Color(0xFF065F46),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textLight,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQrCard() {
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
                data: _verificationCode.isEmpty ? ' ' : _verificationCode,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _verificationCode));
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
                    _verificationCode.isEmpty ? 'Memuat...' : _verificationCode,
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
                  value: widget.pharmacyName,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.receipt_outlined,
                        label: 'No. Pesanan',
                        value: widget.orderNumber,
                      ),
                    ),
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Total',
                        value: _rupiah(widget.total),
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
                      ...widget.items.map(
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
                                  '${item['medicine_name']} x${item['quantity']}',
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

  Widget _buildReviewButton({required bool enabled}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton.icon(
          onPressed: enabled
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BeriUlasanScreen(
                      orderNumber: widget.orderNumber,
                      pharmacyId: widget.pharmacyId,
                      pharmacyName: widget.pharmacyName,
                      items: widget.items,
                    ),
                  ),
                )
              : null,
          icon: Icon(
            Icons.star_rounded,
            size: 20,
            color: enabled ? Colors.white : Colors.grey.shade400,
          ),
          label: Text(
            enabled ? 'Beri Ulasan' : 'Tunggu verifikasi apoteker...',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.3,
              color: enabled ? Colors.white : Colors.grey.shade400,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD6B0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: Color(0xFFC2410C),
            size: 32,
          ),
          const SizedBox(height: 10),
          const Text(
            'Menunggu konfirmasi apoteker',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF7C2D12),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tunjukkan QR di atas ke apoteker. Setelah dikonfirmasi, kamu bisa memberikan ulasan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF92400E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _cekStatus,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Cek Status',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC2410C),
                side: const BorderSide(color: Color(0xFFFDB974)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Datang ke apotek dan tunjukkan QR Code ini kepada apoteker. Apoteker akan scan QR untuk memverifikasi dan menyerahkan pesanan kamu.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E3A5F),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
