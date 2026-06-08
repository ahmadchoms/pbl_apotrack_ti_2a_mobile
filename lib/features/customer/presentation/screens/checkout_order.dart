import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';

import '../../data/models/cart.dart';
import '../../data/models/customer_address.dart';
import '../providers/customer_profile_provider.dart';
import 'order_confirm_screen.dart';
import 'address/address_model.dart';
import 'address/address_provider.dart';
import 'address/address_picker_sheet.dart';
import '../../data/services/order_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // ── State ────────────────────────────────────────────────────────
  String _deliveryMethod = 'kirim'; // 'kirim' | 'ambil'
  String _paymentMethod = 'cash'; // 'cash' | 'qris'
  Uint8List? _prescriptionBytes;
  String? _prescriptionFileName;
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Address provider — diisi dari API via customerProfileProvider
  late final AddressProvider _addressProvider;
  bool _addressesLoaded = false;

  // Courier rates from Biteship
  List<Map<String, dynamic>> _courierRates = [];
  Map<String, dynamic>? _selectedCourier;
  bool _loadingRates = false;
  String? _shippingRateError;

  // Dummy item (in real app, comes from CartState)
  final List<CartItem> _cartItems = CartState().items;

  int get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  int get _shippingCost =>
      _selectedCourier != null ? _selectedCourier!['price'] as int : 0;
  int get _total => _subtotal + _shippingCost;

  // ── Init ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _addressProvider = AddressProvider();
    ref.read(customerProfileProvider.notifier).loadAll();
  }

  void _populateAddresses(List<CustomerAddress> addresses) {
    debugPrint('=== _populateAddresses ===');
    debugPrint('addresses count: ${addresses.length}');
    debugPrint('isPrimary values: ${addresses.map((a) => a.isPrimary).toList()}');
    final converted = addresses
        .map(AddressModel.fromCustomerAddress)
        .toList();
    _addressProvider.loadFromApi(converted);
    debugPrint('selectedAddress after loadFromApi: ${_addressProvider.selectedAddress?.id} / ${_addressProvider.selectedAddress?.name}');
    if (_deliveryMethod == 'kirim') {
      _fetchShippingRates();
    }
  }

  Future<void> _fetchShippingRates() async {
    final address = _addressProvider.selectedAddress;
    final pharmacyId = _cartItems.isNotEmpty ? _cartItems.first.pharmacyId : '';

    debugPrint('=== _fetchShippingRates ===');
    debugPrint('selectedAddress id:   ${address?.id ?? 'null'}');
    debugPrint('selectedAddress name: ${address?.name ?? 'null'}');
    debugPrint('deliveryMethod: $_deliveryMethod');
    debugPrint('cartItems count: ${_cartItems.length}');
    debugPrint('pharmacyId: "$pharmacyId"');

    if (address == null) {
      debugPrint('SKIP: address null');
      return;
    }
    if (_deliveryMethod != 'kirim') {
      debugPrint('SKIP: bukan kirim');
      return;
    }
    if (pharmacyId.isEmpty) {
      debugPrint('SKIP: pharmacyId kosong');
      return;
    }

    setState(() {
      _loadingRates = true;
      _selectedCourier = null;
      _courierRates = [];
      _shippingRateError = null;
    });
    try {
      final service = ref.read(orderServiceProvider);
      final items = _cartItems
          .map((item) => {
                'name': item.name,
                'value': item.price * item.quantity,
                'weight': 200,
                'quantity': item.quantity,
              })
          .toList();
      final rates = await service.getShippingRates(
        pharmacyId: pharmacyId,
        addressId: address.id,
        items: items,
      );
      if (!mounted) return;
      setState(() {
        _courierRates = rates;
        _loadingRates = false;
        if (rates.isNotEmpty) {
          _selectedCourier = rates.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRates = false;
        _shippingRateError = e is DioException ? e.message ?? e.toString() : e.toString();
      });
      debugPrint('Gagal ambil ongkir: $e');
    }
  }

  // ── Pick Image ───────────────────────────────────────────────────
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

              // 1. OPSI KAMERA
              _sheetOption(Icons.camera_alt_rounded, 'Ambil Foto', () async {
                Navigator.pop(context);
                try {
                  final xfile = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (xfile != null) {
                    final bytes = await xfile.readAsBytes();
                    final name = xfile.name;
                    setState(() {
                      _prescriptionBytes = bytes;
                      _prescriptionFileName = name;
                    });
                  }
                } catch (e) {
                  debugPrint('Error ambil kamera: $e');
                }
              }),
              const SizedBox(height: 12),

              // 2. OPSI FILE MANAGER
              _sheetOption(
                Icons.folder_open_rounded,
                'Pilih File (foto/PDF)',
                () async {
                  Navigator.pop(context);
                  try {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.any,
                      withData: true,
                    );

                    if (result == null || result.files.isEmpty) return;

                    final picked = result.files.single;

                    if (picked.bytes != null) {
                      setState(() {
                        _prescriptionBytes = picked.bytes;
                        _prescriptionFileName = picked.name;
                      });
                      return;
                    }

                    String? path;
                    try {
                      path = picked.path;
                    } catch (_) {}

                    if (path != null) {
                      final file = File(path!);
                      final bytes = await file.readAsBytes();
                      if (!mounted) return;
                      setState(() {
                        _prescriptionBytes = bytes;
                        _prescriptionFileName = picked.name;
                      });
                    }
                  } catch (e) {
                    debugPrint('Error pilih file: $e');
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

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(customerProfileProvider);

    ref.listen<CustomerProfileState>(customerProfileProvider, (prev, next) {
      debugPrint('=== ref.listen fired ===');
      debugPrint('prev?.isLoading: ${prev?.isLoading}  next.isLoading: ${next.isLoading}');
      debugPrint('next.addresses.length: ${next.addresses.length}');
      debugPrint('_addressesLoaded: $_addressesLoaded');
      // Ketika loadAll selesai (isLoading true→false) — pake data fresh
      if (prev != null &&
          prev.isLoading &&
          !next.isLoading &&
          next.addresses.isNotEmpty) {
        debugPrint('ref.listen: loadAll completed, calling _populateAddresses');
        _addressesLoaded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _populateAddresses(next.addresses);
        });
      }
    });

    // Build check — pake data yg sudah ada (abaikan isLoading)
    debugPrint('=== build check ===');
    debugPrint('_addressesLoaded: $_addressesLoaded');
    debugPrint('profileState.addresses.length: ${profileState.addresses.length}');
    if (!_addressesLoaded && profileState.addresses.isNotEmpty) {
      debugPrint('build check: condition satisfied, calling _populateAddresses');
      _addressesLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateAddresses(profileState.addresses);
      });
    }

    return AnimatedBuilder(
      animation: _addressProvider,
      builder: (context, _) {
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
              // ── Alamat muncul hanya saat pilih "kirim" ────────────
              if (_deliveryMethod == 'kirim') ...[
                _buildDivider(),
                _buildAddressSection(),
                _buildDivider(),
                _buildCourierSelection(),
              ],
              _buildDivider(),
              _buildNoteField(),
              _buildDivider(),
              _buildPaymentMethod(),
              _buildDivider(),
              _buildPrescriptionUpload(),
              _buildDivider(),
              _buildPaymentDetails(),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  // ── Section: Order Summary ───────────────────────────────────────
  Widget _buildOrderSummary() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('ORDER SUMMARY'),
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
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppColors.background,
                        child: Icon(
                          Icons.medication_rounded,
                          color: AppColors.primary.withOpacity(0.3),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
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

  // ── Section: Delivery Method ─────────────────────────────────────
  Widget _buildDeliveryMethod() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('METODE LAYANAN'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _deliveryOption(
                  icon: Icons.delivery_dining_rounded,
                  label: 'Kirim',
                  value: 'kirim',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _deliveryOption(
                  icon: Icons.store_rounded,
                  label: 'Ambil',
                  value: 'ambil',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deliveryOption({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSelected = _deliveryMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _deliveryMethod = value;
          if (value == 'ambil') {
            _selectedCourier = null;
            _courierRates = [];
          }
        });
        if (value == 'kirim') {
          _fetchShippingRates();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section: Alamat Pengiriman ───────────────────────────────────
  Widget _buildAddressSection() {
    final selected = _addressProvider.selectedAddress;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sectionLabel('ALAMAT PENGIRIMAN'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected == null
                      ? Colors.orange.withOpacity(0.4)
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: selected == null
                  // ── Belum pilih alamat ─────────────────────────
                  ? GestureDetector(
                      onTap: _openAddressPicker,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_off_rounded,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Belum ada alamat dipilih',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Ketuk untuk memilih alamat pengiriman',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textLight,
                            size: 20,
                          ),
                        ],
                      ),
                    )
                  // ── Alamat sudah dipilih ───────────────────────
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
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
                                selected.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selected.fullAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (selected.landmark != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.flag_rounded,
                                      size: 11,
                                      color: AppColors.textLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        selected.landmark!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _openAddressPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Ganti',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // ── Warning jika belum pilih alamat ───────────────────
            if (selected == null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Isi detail alamat biar kurir gampang cari lokasimu.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
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
      ),
    );
  }

  void _openAddressPicker() {
    showAddressPickerSheet(
      context,
      _addressProvider,
      onSelected: () {
        setState(() {});
        _fetchShippingRates();
      },
      onSetPrimary: (address) async {
        try {
          await ref
              .read(customerProfileProvider.notifier)
              .setPrimaryAddress(address.id);
          _addressProvider.updatePrimaryFlags(address.id);
        } catch (e) {
          debugPrint('set-primary non-fatal: $e');
        }
      },
      onAddressSaved: (address, isEdit) {
        // Provider udah dipanggil dari AddressFormScreen._save(),
        // di sini cuma update local state & fetch ulang kurir
        if (!isEdit) {
          _addressProvider.addFavorite(address);
          _addressProvider.selectAddress(address);
        }
        _fetchShippingRates();
      },
      onAddressDeleted: (id) {
        ref.read(customerProfileProvider.notifier).deleteAddress(id);
      },
    );
  }

  // ── Section: Courier Selection ────────────────────────────────────
  Widget _buildCourierSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PILIH KURIR'),
          const SizedBox(height: 12),
          if (_loadingRates)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_courierRates.isEmpty && _shippingRateError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    _shippingRateError!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_courierRates.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Pilih alamat untuk melihat tarif pengiriman',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...(_courierRates.map((rate) {
              final isSelected =
                  _selectedCourier == rate;
              final code =
                  rate['courier_code'] as String? ?? '';
              final service =
                  rate['courier_service'] as String? ?? '';
              final price = rate['price'] as int? ?? 0;
              final duration =
                  rate['duration'] as String? ?? '';
              return GestureDetector(
                onTap: () => setState(() => _selectedCourier = rate),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            code.toUpperCase().substring(0, 2),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textLight,
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
                              '${code.toUpperCase()} - $service',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (duration.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Estimasi: $duration',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${_formatPrice(price)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })),
        ],
      ),
    );
  }

  // ── Section: Note ────────────────────────────────────────────────
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
                hintText: 'Contoh: Titipkan di satpam, jangan diketuk...',
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

  // ── Section: Payment Method ──────────────────────────────────────
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
            subtitle: 'Bayar saat pesanan diterima',
            value: 'cash',
          ),
          const SizedBox(height: 10),
          _paymentOption(
            icon: Icons.qr_code_2_rounded,
            title: 'QRIS (Scan Pembayaran)',
            subtitle: 'QR Code akan muncul setelah konfirmasi',
            value: 'qris',
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
              color: Colors.black.withOpacity(0.04),
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
                color: AppColors.primary.withOpacity(0.1),
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

  // ── Section: Prescription Upload ────────────────────────────────
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
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'OPTIONAL',
                  style: TextStyle(
                    color: AppColors.textLight,
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
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary.withOpacity(0.5),
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
                    'Upload foto resep dokter',
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
                    child: (_prescriptionFileName ?? '').endsWith('.pdf')
                        ? Container(
                            width: 44,
                            height: 44,
                            color: Colors.red.withOpacity(0.1),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.red,
                              size: 24,
                            ),
                          )
                        : Image.memory(
                            _prescriptionBytes!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _prescriptionFileName ?? 'file',
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
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else ...[
                  Icon(
                    Icons.insert_drive_file_outlined,
                    color: AppColors.textLight.withOpacity(0.5),
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

  // ── Section: Payment Details ─────────────────────────────────────
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
                const SizedBox(height: 10),
                _priceRow(
                  'Biaya Pengiriman',
                  _shippingCost,
                ),
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

  Widget _priceRow(String label, int amount) {
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
          'Rp ${_formatPrice(amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ── Bottom Bar ───────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final bool canProceed = _deliveryMethod == 'ambil'
        ? true
        : (_addressProvider.selectedAddress != null &&
            _selectedCourier != null);

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
            color: Colors.black.withOpacity(0.08),
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
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderConfirmationScreen(
                        cartItems: _cartItems,
                        deliveryMethod: _deliveryMethod,
                        paymentMethod: _paymentMethod,
                        total: _total,
                        shippingCost: _shippingCost,
                        deliveryAddress: _addressProvider.selectedAddress,
                        pharmacyId: _cartItems.isNotEmpty
                            ? _cartItems.first.pharmacyId
                            : '',
                        prescriptionBytes: _prescriptionBytes,
                        prescriptionFileName: _prescriptionFileName,
                        courierCode: _selectedCourier?['courier_code'] as String?,
                        courierService: _selectedCourier?['courier_service'] as String?,
                      ),
                    ),
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih alamat pengiriman terlebih dahulu'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
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
          child: const Text(
            'Lanjutkan Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
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

  @override
  void dispose() {
    _noteController.dispose();
    _addressProvider.dispose();
    super.dispose();
  }
}
