import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';
import 'verifikasi_pengambilan_screen.dart';

class QrisPaymentScreen extends ConsumerStatefulWidget {
  final String pharmacyId;
  final String pharmacyName;
  final List<Map<String, dynamic>> items;
  final int subtotal;
  final int shippingCost;

  const QrisPaymentScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
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
    _mulaiTimer();
  }

  void _mulaiTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        _tampilExpired();
      }
    });
  }

  void _tampilExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Waktu Habis'),
        content: const Text('Waktu pembayaran sudah habis.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _konfirmasiBayar() async {
    setState(() => _paying = true);
    _timer?.cancel();

    try {
      // 1. Buat order via API
      final cartItems = widget.items
          .map((item) => {
                'medicine_id': item['medicine_id'],
                'medicine_name': item['medicine_name'],
                'quantity': item['quantity'],
                'price': item['price'],
                'subtotal': item['subtotal'],
                'unit_name': item['unit_name'] ?? 'Pcs',
                'requires_prescription':
                    item['requires_prescription'] ?? false,
              })
          .toList();

      // Convert to CartItemModel for the service
      final cartItemModels = widget.items
          .map((item) => CartItemModel(
                medicineId: item['medicine_id'] as String,
                medicineName: item['medicine_name'] as String,
                unitName: item['unit_name'] as String? ?? 'Pcs',
                requiresPrescription:
                    item['requires_prescription'] as bool? ?? false,
                quantity: item['quantity'] as int,
                price: item['price'] as int,
                subtotal: item['subtotal'] as int,
              ))
          .toList();

      final order = await _orderService.createOrder(
        pharmacyId: widget.pharmacyId,
        serviceType: 'PICK_UP',
        paymentMethod: 'TRANSFER', // QRIS = TRANSFER/E-WALLET
        items: cartItemModels,
        subtotal: widget.subtotal.toDouble(),
        shippingCost: widget.shippingCost.toDouble(),
      );

      _orderNumber = order.orderNumber;
      _verificationCode = order.verificationCode;

      // 2. Simulasi pembayaran
      await _orderService.simulatePayment(order.id);

      if (!mounted) return;

      // 3. Navigasi ke verifikasi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifikasiPengambilanScreen(
            orderId: order.id,
            orderNumber: _orderNumber,
            verificationCode: _verificationCode,
            pharmacyName: widget.pharmacyName,
            pharmacyId: widget.pharmacyId,
            items: cartItems,
            total: widget.subtotal + widget.shippingCost,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      _mulaiTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses pesanan: $e'),
          backgroundColor: Colors.red,
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

  String _bulan(int b) {
    const list = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return list[b];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Konfirmasi Pembayaran',
            style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card ringkasan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.local_pharmacy,
                        color: Color(0xFF2563EB), size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.pharmacyName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  Text(_rupiah(widget.subtotal + widget.shippingCost),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Menunggu Pembayaran',
                        style: TextStyle(
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                  Text('BATAS WAKTU BAYAR',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(_timerText,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: _secondsLeft < 60
                            ? Colors.red
                            : const Color(0xFF111827),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline,
                      color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tekan "Konfirmasi Bayar" untuk menyelesaikan pembayaran. Kamu akan mendapat QR Code untuk pengambilan obat di apotek.',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF1E3A5F)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rincian pesanan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rincian Pesanan',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NO. ORDER',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(
                              _orderNumber.isEmpty
                                  ? 'Menunggu...'
                                  : _orderNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF111827)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          height: 36,
                          width: 1,
                          color: const Color(0xFFE5E7EB)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TANGGAL',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                      letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(
                                  '${now.day} ${_bulan(now.month)} ${now.year}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF111827))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ...widget.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                  '${item['medicine_name']} x${item['quantity']}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF374151))),
                            ),
                            Text(_rupiah(item['subtotal'] as int),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF374151))),
                          ],
                        ),
                      )),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Bayar',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF111827))),
                      Text(
                          _rupiah(widget.subtotal + widget.shippingCost),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF2563EB))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol konfirmasi bayar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _paying ? null : _konfirmasiBayar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _paying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text('Konfirmasi Bayar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Setelah konfirmasi, kamu akan mendapat QR Code\nuntuk pengambilan obat di apotek',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
