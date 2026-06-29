import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:mobile/core/models/cart.dart';
import '../../data/services/order_service.dart';
import 'qris_payment_screen.dart';
import 'order_detail_screen.dart';
import 'package:mobile/core/models/order.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _paymentMethod = 'cash';
  Uint8List? _prescriptionBytes;
  String? _prescriptionFileName;
  String? _prescriptionFilePath;
  bool _isSubmitting = false;
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<CartItem> _cartItems = CartState().items;

  static const _doctorNames = [
    'dr. Andi Pratama, Sp.F.',
    'dr. Budi Santoso, M.Kes.',
    'dr. Cipto Mangunkusumo, Sp.PD.',
    'dr. Dewi Sartika, Sp.A.',
    'dr. Eko Wahyudi, Sp.B.',
    'dr. Fitriani Nur, Sp.OG.',
    'dr. Gunawan Wijaya, Sp.JP.',
    'dr. Hapsari Dewi, M.Sc.',
    'dr. Indra Lesmana, Sp.M.',
    'dr. Joko Susilo, Sp.KK.',
    'dr. Kartika Sari, Sp.THT.',
    'dr. Lukman Hakim, Sp.S.',
    'dr. Maya Anggraini, Sp.KJ.',
    'dr. Nanda Pratiwi, Sp.Rad.',
    'dr. Oscar Rinaldi, Sp.U.',
  ];

  String get _randomDoctorName =>
      _doctorNames[DateTime.now().millisecondsSinceEpoch % _doctorNames.length];

  int get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  int get _total => _subtotal;
  bool get _requiresPrescription =>
      _cartItems.any((item) => item.requiresPrescription);

  Future<void> _confirmOrder() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final isQris = _paymentMethod == 'qris';
      final pharmacyId = _cartItems.isNotEmpty
          ? _cartItems.first.pharmacyId
          : '';
      final pharmacyName = _cartItems.isNotEmpty
          ? _cartItems.first.pharmacyName
          : 'Apotek';
      final notes = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      if (isQris) {
        final items = _cartItems
            .map(
              (item) => {
                'medicine_id': item.id,
                'medicine_name': item.name,
                'unit_name': item.unit,
                'requires_prescription': item.requiresPrescription,
                'quantity': item.quantity,
                'price': item.price,
                'subtotal': item.price * item.quantity,
              },
            )
            .toList();

        final subtotalVal = _subtotal;
        CartState().clear();
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QrisPaymentScreen(
              pharmacyId: pharmacyId,
              pharmacyName: pharmacyName,
              notes: notes,
              items: items,
              subtotal: subtotalVal,
              prescriptionBytes: _prescriptionBytes,
              prescriptionFileName: _prescriptionFileName,
            ),
          ),
        );
        return;
      }

      // Cash: buat order langsung
      final service = ref.read(orderServiceProvider);
      final cartItemModels = _cartItems
          .map(
            (item) => CartItemModel(
              medicineId: item.id,
              medicineName: item.name,
              unitName: item.unit,
              requiresPrescription: item.requiresPrescription,
              quantity: item.quantity,
              price: item.price,
              subtotal: item.price * item.quantity,
            ),
          )
          .toList();

      final order = await service.createOrder(
        pharmacyId: pharmacyId,
        items: cartItemModels,
        subtotal: _subtotal.toDouble(),
        serviceType: 'PICK_UP',
        paymentMethod: 'CASH',
        notes: notes,
      );

      if (_prescriptionBytes != null) {
        try {
          final user = ref.read(currentUserProvider);
          await service.uploadPrescription(
            order.id,
            _prescriptionBytes!,
            fileName: _prescriptionFileName ?? 'resep.jpg',
            doctorName: _randomDoctorName,
            patientName: user?.username,
            issuedDate: DateTime.now().toIso8601String().split('T').first,
          );
        } catch (e) {
          debugPrint('Prescription upload gagal: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Gagal mengunggah resep. Kamu bisa upload ulang di halaman detail pesanan.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }

      if (!mounted) return;

      CartState().clear();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerOrderDetailScreen(orderId: order.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat pesanan: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickPrescription() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Resep Dokter',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _sheetOption(Icons.camera_alt_rounded, 'Ambil Foto', () async {
                Navigator.pop(context);
                try {
                  final xfile = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                    maxWidth: 1024,
                  );
                  if (xfile != null) {
                    final bytes = await xfile.readAsBytes();
                    if (mounted) {
                      setState(() {
                        _prescriptionBytes = bytes;
                        _prescriptionFileName = xfile.name;
                        _prescriptionFilePath = xfile.path;
                      });
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Gagal mengakses kamera. Periksa izin kamera.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              }),
              const SizedBox(height: 12),
              _sheetOption(
                Icons.photo_library_rounded,
                'Pilih dari Galeri',
                () async {
                  Navigator.pop(context);
                  try {
                    final xfile = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 1024,
                    );
                    if (xfile != null) {
                      final bytes = await xfile.readAsBytes();
                      if (mounted) {
                        setState(() {
                          _prescriptionBytes = bytes;
                          _prescriptionFileName = xfile.name;
                          _prescriptionFilePath = xfile.path;
                        });
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Gagal mengakses galeri. Periksa izin penyimpanan.'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
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
          _buildOrderSummary(),
          _buildDivider(),
          _buildDeliveryMethod(),
          _buildDivider(),
          _buildNoteField(),
          _buildDivider(),
          _buildPaymentMethod(),
          if (_requiresPrescription) ...[
            _buildDivider(),
            _buildPrescriptionUpload(),
            _buildDivider(),
          ],
          _buildPaymentDetails(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildOrderSummary() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('RINGKASAN PESANAN'),
          const SizedBox(height: 12),
          ..._cartItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 56,
                        height: 56,
                        color: AppColors.background,
                        child: Icon(
                          Icons.medication_rounded,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.unit,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${_formatPrice(item.price)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (item.quantity > 1) {
                              setState(() {
                                item.quantity--;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Icon(
                              Icons.remove_rounded,
                              size: 16,
                              color: item.quantity > 1
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                          ),
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (item.quantity < item.stock) {
                              setState(() {
                                item.quantity++;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Stok tidak mencukupi (Maks. ${item.stock})',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: item.quantity < item.stock
                                  ? AppColors.primary
                                  : AppColors.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMethod() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('METODE LAYANAN'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambil di Tempat (Pick Up)',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Estimasi siap ambil: 15–20 menit setelah dikonfirmasi',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
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

  Widget _buildNoteField() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CATATAN PEMBELI'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              decoration: const InputDecoration(
                hintText: 'Contoh: Siapkan resep asli saat pengambilan...',
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
                contentPadding: EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('METODE PEMBAYARAN'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'REQUIRED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _paymentOption(
            icon: Icons.payments_rounded,
            title: 'Bayar di Tempat (Cash)',
            subtitle: 'Bayar langsung di kasir apotek saat mengambil',
            value: 'cash',
          ),
          const SizedBox(height: 10),
          _paymentOption(
            icon: Icons.qr_code_2_rounded,
            title: 'QRIS (Scan Pembayaran)',
            subtitle: 'QR Code akan muncul setelah konfirmasi apotek',
            value: 'qris',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _paymentMethod == 'cash'
                        ? 'Kamu bisa bayar langsung di kasir apotek saat mengambil pesananmu nanti, ya!'
                        : 'QR Code pembayaran bakal dikirim ke HP-mu setelah pesanan selesai dikonfirmasi oleh apotek.',
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
        ],
      ),
    );
  }

  Widget _paymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionUpload() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('UPLOAD RESEP DOKTER'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'WAJIB',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickPrescription,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unggah foto resep Anda',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Format JPG, PNG, atau PDF (Maks. 5MB)',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                if (_prescriptionBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _prescriptionBytes!,
                      key: ValueKey(_prescriptionBytes!.hashCode),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _imageErrorWidget(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _prescriptionFileName ?? 'resep.jpg',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textLight,
                    ),
                    onPressed: () => setState(() {
                      _prescriptionBytes = null;
                      _prescriptionFileName = null;
                      _prescriptionFilePath = null;
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else ...[
                  Icon(
                    Icons.insert_drive_file_outlined,
                    color: AppColors.textLight.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Belum ada file dipilih',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('RINCIAN PEMBAYARAN'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _priceRow('Subtotal Produk', _subtotal),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.grey.shade100, height: 1),
                ),
                Row(
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
                      'Rp ${_formatPrice(_total)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, int amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          isDiscount
              ? '-Rp ${_formatPrice(amount.abs())}'
              : 'Rp ${_formatPrice(amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? const Color(0xFFEF4444) : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final bool hasPrescription =
        !_requiresPrescription || _prescriptionBytes != null;
    final bool canProceed = hasPrescription && !_isSubmitting;

    String? errorMsg;
    if (_requiresPrescription && !hasPrescription) {
      errorMsg = 'Upload resep dokter terlebih dahulu';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
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
          onPressed: canProceed
              ? _confirmOrder
              : (_isSubmitting
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              errorMsg ?? 'Lengkapi data terlebih dahulu',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }),
          style: ElevatedButton.styleFrom(
            backgroundColor: canProceed
                ? AppColors.primary
                : Colors.grey.shade300,
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
              : Text(
                  _paymentMethod == 'qris'
                      ? 'Lanjutkan ke Pembayaran'
                      : 'Konfirmasi & Buat Pesanan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(height: 8, color: Colors.grey.shade100);

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: AppColors.textLight,
      letterSpacing: 0.8,
    ),
  );

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Widget _imageErrorWidget() => Container(
    width: 44,
    height: 44,
    color: Colors.grey.shade100,
    child: const Icon(
      Icons.broken_image_rounded,
      color: AppColors.textLight,
      size: 20,
    ),
  );

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
