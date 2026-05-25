import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/order_service.dart';
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
  late final OrderService _orderService;
  String _orderStatus = '';
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _orderService = ref.read(orderServiceProvider);
    _cekStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _cekStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _cekStatus() async {
    if (_orderStatus == 'COMPLETED') {
      _pollTimer?.cancel();
      return;
    }
    setState(() => _loading = true);
    try {
      final order = await _orderService.getOrderById(widget.orderId);
      if (!mounted) return;
      final newStatus = order.orderStatus;
      setState(() {
        _orderStatus = newStatus;
        _loading = false;
      });
      if (newStatus == 'COMPLETED') _pollTimer?.cancel();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _rupiah(int amount) => 'Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  bool get _bisaUlas => _orderStatus == 'COMPLETED';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verifikasi Pengambilan',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner sukses
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Color(0xFF065F46), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pembayaran berhasil! Datang ke apotek dan tunjukkan QR ini.',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Tunjukkan QR Ini ke Apotek',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Datang ke apotek dan tunjukkan QR ini. Apoteker akan scan untuk memproses pengambilan obat.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),

            // Card QR
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header label
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F6FA),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: const Center(
                      child: Text(
                        'KODE VERIFIKASI PENGAMBILAN OBAT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // QR Placeholder
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 32),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF2563EB), width: 3),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        size: 200,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),

                  // Kode teks — tap untuk copy
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: widget.verificationCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode disalin!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.verificationCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF111827),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.copy,
                              size: 16, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // Info rows
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.local_pharmacy,
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
                                valueColor: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Daftar item
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Obat yang dipesan:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...widget.items.map(
                                (item) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• ${item['medicine_name']} x${item['quantity']}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF374151),
                                    ),
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
            ),
            const SizedBox(height: 20),

            // Tombol ulasan atau status
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_bisaUlas)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BeriUlasanScreen(
                        orderNumber: widget.orderNumber,
                        pharmacyId: widget.pharmacyId,
                        pharmacyName: widget.pharmacyName,
                        items: widget.items,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.star_border, size: 20),
                  label: const Text(
                    'Beri Ulasan',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD6B0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.access_time,
                        color: Color(0xFFC2410C), size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'Menunggu konfirmasi apoteker',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF7C2D12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tunjukkan QR di atas ke apoteker. Setelah dikonfirmasi, kamu bisa memberikan ulasan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cekStatus,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Cek Status',
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC2410C),
                          side: const BorderSide(
                              color: Color(0xFFFDB974)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Datang ke apotek dan tunjukkan QR Code ini kepada apoteker. Apoteker akan scan QR untuk memverifikasi dan menyerahkan pesanan kamu.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF1E3A5F)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
        Icon(icon, color: const Color(0xFF2563EB), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
