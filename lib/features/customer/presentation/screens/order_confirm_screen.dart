import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/cart.dart';
import '../../data/models/order_model.dart';
import '../../data/services/order_service.dart';
import 'address/address_model.dart';
import 'qris_payment_screen.dart';
import 'verifikasi_pengambilan_screen.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;
  final String deliveryMethod;  // 'kirim' | 'ambil'
  final String paymentMethod;   // 'cash' | 'qris'
  final String? courierCode;
  final int total;
  final int shippingCost;
  final AddressModel? deliveryAddress;
  final String pharmacyId;
  final File? prescriptionFile;
  final String? courierService;

  const OrderConfirmationScreen({
    super.key,
    required this.cartItems,
    required this.deliveryMethod,
    required this.paymentMethod,
    this.courierCode,
    required this.total,
    required this.shippingCost,
    this.deliveryAddress,
    required this.pharmacyId,
    this.prescriptionFile,
    this.courierService,
  });

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  bool _isSubmitting = false;

  // ── Helpers ──────────────────────────────────────────────────────
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String get _paymentLabel => widget.paymentMethod == 'cash'
      ? 'Bayar di Tempat (Cash)'
      : 'QRIS (Scan Pembayaran)';

  String get _deliveryLabel =>
      widget.deliveryMethod == 'kirim' ? 'Dikirim ke Alamat' : 'Ambil ke Apotek';

  String get _deliveryAddress {
    if (widget.deliveryMethod == 'kirim' && widget.deliveryAddress != null) {
      return widget.deliveryAddress!.fullAddress;
    }
    return '';
  }

  String get _deliveryAddressName {
    if (widget.deliveryMethod == 'kirim' && widget.deliveryAddress != null) {
      return widget.deliveryAddress!.name;
    }
    return '';
  }

  Future<void> _confirmOrder() async {
    setState(() => _isSubmitting = true);
    try {
      final isQris = widget.paymentMethod == 'qris';
      final isDelivery = widget.deliveryMethod == 'kirim';

      if (isQris) {
        // QRIS: order dibuat + bayar di QrisPaymentScreen
        // copy items BEFORE clearing cart (CartState is a singleton, same reference)
        final pharmacyName = widget.cartItems.isNotEmpty
            ? widget.cartItems.first.pharmacyName
            : 'Apotek';
        final items = widget.cartItems
            .map((item) => {
                  'medicine_id': item.id,
                  'medicine_name': item.name,
                  'unit_name': item.unit,
                  'requires_prescription': item.requiresPrescription,
                  'quantity': item.quantity,
                  'price': item.price,
                  'subtotal': item.price * item.quantity,
                })
            .toList();
        CartState().clear();
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QrisPaymentScreen(
              pharmacyId: widget.pharmacyId,
              pharmacyName: pharmacyName,
              deliveryMethod: widget.deliveryMethod,
              addressId: widget.deliveryAddress?.id,
              notes: null,
              courierCode: widget.courierCode,
              courierService: widget.courierService,
              items: items,
              subtotal: widget.total - widget.shippingCost,
              shippingCost: widget.shippingCost,
              prescriptionFile: widget.prescriptionFile,
            ),
          ),
        );
        return;
      }

      // Cash: buat order langsung
      final service = ref.read(orderServiceProvider);
      final cartItemModels = widget.cartItems
          .map((item) => CartItemModel(
                medicineId: item.id,
                medicineName: item.name,
                unitName: item.unit,
                requiresPrescription: false,
                quantity: item.quantity,
                price: item.price,
                subtotal: item.price * item.quantity,
              ))
          .toList();

      final order = await service.createOrder(
        pharmacyId: widget.pharmacyId,
        items: cartItemModels,
        subtotal: (widget.total - widget.shippingCost).toDouble(),
        serviceType: isDelivery ? 'DELIVERY' : 'PICK_UP',
        paymentMethod: 'CASH',
        addressId: widget.deliveryAddress?.id,
        notes: null,
        shippingCost: widget.shippingCost.toDouble(),
        courierCode: widget.courierCode,
        courierService: widget.courierService,
      );

      if (widget.prescriptionFile != null) {
        await service.uploadPrescription(order.id, widget.prescriptionFile!);
      }

      if (!mounted) return;

      final itemsForNext = order.items.map((item) => {
        'medicine_name': item.medicineName,
        'medicine_id': item.medicineId,
        'quantity': item.quantity,
        'price': item.price.toInt(),
        'subtotal': item.subtotal.toInt(),
      }).toList();

      if (isDelivery) {
        // Cash + Delivery: go home with success
        CartState().clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pesanan berhasil dibuat!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Cash + Pickup: show QR langsung
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifikasiPengambilanScreen(
              orderId: order.id,
              orderNumber: order.orderNumber,
              verificationCode: order.verificationCode,
              pharmacyName: widget.cartItems.isNotEmpty
                  ? widget.cartItems.first.pharmacyName
                  : 'Apotek',
              pharmacyId: widget.pharmacyId,
              items: itemsForNext,
              total: widget.total,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat pesanan: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Konfirmasi Pesanan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          _buildEstimationBanner(),
          _buildPaymentMethodSection(),
          _buildNotice(),
          if (widget.prescriptionFile != null) _buildPrescriptionSection(),
          _buildOrderSummary(),
          _buildTotalTagihan(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── Estimation Banner ────────────────────────────────────────────
  Widget _buildEstimationBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              widget.deliveryMethod == 'kirim'
                  ? '⏱  Estimasi pengiriman: 30–45 menit'
                  : '⏱  Estimasi siap ambil: 15–20 menit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Payment Method ───────────────────────────────────────────────
  Widget _buildPaymentMethodSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('METODE PEMBAYARAN'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.paymentMethod == 'cash'
                        ? Icons.payments_rounded
                        : Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _paymentLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.paymentMethod == 'cash'
                            ? 'Bayar saat pesanan diterima'
                            : 'Scan QR Code untuk membayar',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Notice ───────────────────────────────────────────────────────
  Widget _buildNotice() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 16, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.paymentMethod == 'cash'
                    ? 'Pembayaran dilakukan saat pesanan diterima oleh kurir atau saat pengambilan.'
                    : 'QR Code pembayaran akan dikirim setelah pesanan dikonfirmasi oleh apotek.',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Order Summary ────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('RINGKASAN PESANAN'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Delivery info
                _summaryBlock(
                  icon: Icons.local_shipping_rounded,
                  label: 'METODE LAYANAN',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _deliveryLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_deliveryAddressName.isNotEmpty) ...[
                        Text(
                          _deliveryAddressName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        _deliveryAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),

                // Items
                _summaryBlock(
                  icon: Icons.receipt_long_rounded,
                  label: 'DAFTAR ITEM',
                  child: Column(
                    children: [
                      ...widget.cartItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} ${item.unit}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${_formatPrice(item.price * item.quantity)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.shippingCost > 0) ...[
                        Divider(height: 16, color: Colors.grey.shade100),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Biaya Pengiriman',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textLight),
                            ),
                            Text(
                              'Rp ${_formatPrice(widget.shippingCost)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Instant Delivery',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Rp ${_formatPrice(widget.total)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                    indent: 16,
                    endIndent: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBlock({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ── Prescription Section ─────────────────────────────────────────
  Widget _buildPrescriptionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('RESEP DOKTER'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.image_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      widget.prescriptionFile != null
                          ? widget.prescriptionFile!.path.endsWith('.pdf')
                              ? 'File PDF Resep'
                              : 'Gambar Resep'
                          : 'Tidak ada resep',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Menunggu Verifikasi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.prescriptionFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.prescriptionFile!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        color: AppColors.background,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, size: 32, color: AppColors.textLight),
                              SizedBox(height: 4),
                              Text('File Resep (PDF)', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


 
  // ── Total Tagihan ────────────────────────────────────────────────
  Widget _buildTotalTagihan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Tagihan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
          Text(
            'Rp ${_formatPrice(widget.total)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ───────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _confirmOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Konfirmasi Pesanan',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ],
                  ),
          ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textLight,
          letterSpacing: 0.8,
        ),
      );
}
