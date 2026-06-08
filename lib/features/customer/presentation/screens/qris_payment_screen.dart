import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/order_service.dart';
import 'verification_screen.dart';

class QrisPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String pharmacyName;
  final List<Map<String, dynamic>> items;
  final int subtotal;
  final int shippingCost;
  final String serviceType;

  const QrisPaymentScreen({
    super.key,
    required this.orderId,
    required this.pharmacyName,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.serviceType,
  });

  @override
  ConsumerState<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends ConsumerState<QrisPaymentScreen> {
  late final OrderService _orderService;
  bool _paying = false;
  int _secondsLeft = 4 * 60 + 59;
  Timer? _timer;

  String _orderNumber = '';
  String _verificationCode = '';

  @override
  void initState() {
    super.initState();
    _orderService = ref.read(orderServiceProvider);
    _startTimer();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderService.getOrderById(widget.orderId);
      if (!mounted || order == null) return;
      setState(() {
        _orderNumber = order['order_number']?.toString() ?? '';
      });
    } catch (_) {}
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        _showExpired();
      }
    });
  }

  void _showExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Waktu Habis',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
        content: const Text('Waktu pembayaran sudah habis.',
            style: TextStyle(color: AppColors.textMid)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment() async {
    setState(() => _paying = true);
    _timer?.cancel();

    try {
      final paymentResult = await _orderService.simulatePayment(widget.orderId);
      _verificationCode = paymentResult['verification_code']?.toString() ?? '';

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationScreen(
            orderId: widget.orderId,
            orderNumber: _orderNumber,
            verificationCode: _verificationCode,
            pharmacyName: widget.pharmacyName,
            serviceType: widget.serviceType,
            items: widget.items,
            total: widget.subtotal + widget.shippingCost,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses pembayaran: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _rupiah(int amount) =>
      'Rp ${amount.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          )}';

  @override
  Widget build(BuildContext context) {
    final total = widget.subtotal + widget.shippingCost;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Pembayaran',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildPharmacyCard(total),
            const SizedBox(height: 16),
            _buildInfoBanner(),
            const SizedBox(height: 16),
            _buildOrderDetails(),
            const SizedBox(height: 28),
            _buildPayButton(),
            const SizedBox(height: 10),
            Text(
              widget.serviceType == 'PICK_UP'
                  ? 'Setelah konfirmasi, kamu akan mendapat QR Code\nuntuk pengambilan obat di apotek'
                  : 'Setelah konfirmasi, pesanan akan segera diproses',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSubtle, height: 1.5),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 12),
          Text(widget.pharmacyName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(_rupiah(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.textDark, letterSpacing: -0.5)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(20)),
            child: const Text('Menunggu Pembayaran', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(height: 20),
          const Text('BATAS WAKTU BAYAR', style: TextStyle(fontSize: 11, color: AppColors.textLight, letterSpacing: 1, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_timerText, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 4, color: _secondsLeft < 60 ? AppColors.danger : AppColors.textDark)),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.serviceType == 'PICK_UP'
                  ? 'Tekan "Konfirmasi Bayar" untuk menyelesaikan pembayaran. Kamu akan mendapat QR Code untuk pengambilan obat di apotek.'
                  : 'Tekan "Konfirmasi Bayar" untuk menyelesaikan pembayaran. Pesanan akan segera diproses dan dikirim.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A5F), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Pesanan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NO. ORDER', style: TextStyle(fontSize: 11, color: AppColors.textLight, letterSpacing: 1, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_orderNumber.isEmpty ? 'Menunggu...' : _orderNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textDark)),
                  ],
                ),
              ),
              Container(height: 36, width: 1, color: AppColors.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TANGGAL', style: TextStyle(fontSize: 11, color: AppColors.textLight, letterSpacing: 1, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${DateTime.now().day} ${_bulan(DateTime.now().month)} ${DateTime.now().year}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          ...widget.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item['medicine_name']} x${item['quantity']}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
                    ),
                    Text(_rupiah(item['subtotal'] as int), style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
                  ],
                ),
              )),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
              Text(_rupiah(widget.subtotal + widget.shippingCost),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _paying ? AppColors.primary.withOpacity(0.6) : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ElevatedButton(
          onPressed: _paying ? null : _confirmPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _paying
                ? const SizedBox(key: ValueKey('loading'), width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(
                    key: ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text('Konfirmasi Bayar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.3)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _bulan(int b) {
    const list = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return list[b];
  }
}
