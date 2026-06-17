import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/cart.dart';
import '../../data/services/order_service.dart';
import '../providers/customer_profile_provider.dart';
import 'order_confirm_screen.dart';
import 'address/address_model.dart';
import 'address/address_provider.dart';
import 'address/address_picker_sheet.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // ── State ────────────────────────────────────────────────────────
  String _deliveryMethod = 'kirim'; // 'kirim' | 'ambil'
  String _paymentMethod = 'cash';   // 'cash' | 'qris'
  String _courierCode = 'jne';
  File? _prescriptionFile;
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Address provider — diisi dari API via customerProfileProvider
  late final AddressProvider _addressProvider;
  bool _addressesLoaded = false;

  // Courier state
  List<Map<String, dynamic>> _courierRates = [];
  String? _selectedCourierCode;
  String? _selectedCourierService;
  int _selectedCourierPrice = 0;
  bool _isLoadingRates = false;
  bool _ratesError = false;
  double _distanceKm = 0;

  // Dummy item (in real app, comes from CartState)
  final List<CartItem> _cartItems = CartState().items;

  int get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  int get _shippingCost => _deliveryMethod == 'kirim' ? _selectedCourierPrice : 0;
  int get _total => _subtotal + _shippingCost;

  // ── Init ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _addressProvider = AddressProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddresses());
  }

  Future<void> _loadAddresses() async {
    final profileState = ref.read(customerProfileProvider);
    if (profileState.addresses.isEmpty && !profileState.isLoading) {
      ref.read(customerProfileProvider.notifier).loadAll();
    }
  }

  // ── Courier Rates ────────────────────────────────────────────────
  Future<void> _fetchRates() async {
    final address = _addressProvider.selectedAddress;
    if (address == null) return;

    setState(() {
      _isLoadingRates = true;
      _ratesError = false;
      _courierRates = [];
      _selectedCourierCode = null;
      _selectedCourierService = null;
      _selectedCourierPrice = 0;
    });

    try {
      final service = ref.read(orderServiceProvider);
      final items = _cartItems.map((item) => {
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'value': item.price,
        'weight': 200,
      }).toList();
      final result = await service.getShippingRates(
        pharmacyId: _cartItems.isNotEmpty ? _cartItems.first.pharmacyId : '',
        addressId: address.id,
        items: items,
      );

      final List<dynamic> pricing = result['pricing'] ?? [];
      setState(() {
        _courierRates = pricing.cast<Map<String, dynamic>>();
        _distanceKm = (result['distance_km'] as num?)?.toDouble() ?? 0;
        _isLoadingRates = false;
      });

      // Auto-pilih kurir pertama
      if (_courierRates.isNotEmpty) {
        _selectCourier(_courierRates.first);
      }
    } catch (e) {
      setState(() {
        _isLoadingRates = false;
        _ratesError = true;
      });
    }
  }

  void _selectCourier(Map<String, dynamic> rate) {
    setState(() {
      _selectedCourierCode = rate['courier_code'] as String?;
      _selectedCourierService = rate['courier_service'] as String?;
      _selectedCourierPrice = (rate['price'] as num?)?.toInt() ?? 0;
    });
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
              _sheetOption(
                Icons.camera_alt_rounded,
                'Ambil Foto',
                () async {
                  Navigator.pop(context);
                  final xfile =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (xfile != null) {
                    setState(() => _prescriptionFile = File(xfile.path));
                  }
                },
              ),
              const SizedBox(height: 12),
              _sheetOption(
                Icons.photo_library_rounded,
                'Pilih dari Galeri',
                () async {
                  Navigator.pop(context);
                  final xfile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (xfile != null) {
                    setState(() => _prescriptionFile = File(xfile.path));
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
    ref.listen(customerProfileProvider, (prev, next) {
      if (!next.isLoading && next.addresses.isNotEmpty && !_addressesLoaded) {
        _addressesLoaded = true;
        final converted =
            next.addresses.map(AddressModel.fromCustomerAddress).toList();
        _addressProvider.loadFromApi(converted);
      }
    });

    return AnimatedBuilder(
      animation: _addressProvider,
      builder: (context, _) {
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
              // ── Alamat & Kurir muncul hanya saat pilih "kirim" ────
              if (_deliveryMethod == 'kirim') ...[
                _buildDivider(),
                _buildCourierSelection(),
                _buildDivider(),
                _buildAddressSection(),
                _buildDivider(),
                _buildCourierSection(),
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
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppColors.background,
                        child: Icon(Icons.medication_rounded,
                            color: AppColors.primary.withOpacity(0.3)),
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
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.15)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Icon(
                              Icons.remove_rounded,
                              size: 16,
                              color: item.quantity > 1 ? AppColors.primary : AppColors.textLight,
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
                                  content: Text('Stok tidak mencukupi (Maks. ${item.stock})'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: item.quantity < item.stock ? AppColors.primary : AppColors.textLight,
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
      onTap: () => setState(() => _deliveryMethod = value),
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
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : AppColors.textLight,
                size: 20),
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

  // ── Section: Pilihan Kurir ───────────────────────────────────────
  Widget _buildCourierSelection() {
    const couriers = [
      {'code': 'jne', 'name': 'JNE Express'},
      {'code': 'jnt', 'name': 'J&T Express'},
      {'code': 'sicepat', 'name': 'SiCepat'},
      {'code': 'grab', 'name': 'GrabExpress'},
      {'code': 'gojek', 'name': 'GoSend'},
      {'code': 'anteraja', 'name': 'AnterAja'},
      {'code': 'tiki', 'name': 'TIKI'},
      {'code': 'pos', 'name': 'POS Indonesia'},
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PILIH KURIR'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _courierCode,
                isExpanded: true,
                items: couriers.map((c) {
                  return DropdownMenuItem(
                    value: c['code'],
                    child: Text(c['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _courierCode = v);
                },
              ),
            ),
          ),
        ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'WAJIB',
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
                            child: const Icon(Icons.location_off_rounded,
                                color: Colors.orange, size: 20),
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
                          Icon(Icons.chevron_right_rounded,
                              color: AppColors.textLight, size: 20),
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
                          child: Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 20),
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
                                    const Icon(Icons.flag_rounded,
                                        size: 11,
                                        color: AppColors.textLight),
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
                                horizontal: 12, vertical: 6),
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
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.orange.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: Colors.orange),
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

            // ── Jarak pengiriman ──────────────────────────────────
            if (selected != null && _distanceKm > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.straighten_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Jarak: ${_distanceKm.toStringAsFixed(1)} km dari apotek',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
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
      onSelected: () => setState(() {}),
      onSetPrimary: (address) {
        ref.read(customerProfileProvider.notifier).setPrimaryAddress(address.id);
        _addressProvider.updatePrimaryFlags(address.id);
      },
      onAddressSaved: (address, isEdit) async {
        final notifier = ref.read(customerProfileProvider.notifier);
        if (isEdit) {
          await notifier.updateAddress(
            id: address.id,
            label: address.name,
            addressDetail: address.fullAddress,
            latitude: address.latitude ?? -6.208800,
            longitude: address.longitude ?? 106.845600,
            isPrimary: address.isPrimary,
          );
        } else {
          final newAddr = await notifier.addAddress(
            label: address.name,
            addressDetail: address.fullAddress,
            latitude: address.latitude ?? -6.208800,
            longitude: address.longitude ?? 106.845600,
            isPrimary: address.isPrimary,
          );
          _addressProvider.updateAddressId(address.id, newAddr.id);
        }
      },
      onAddressDeleted: (id) {
        ref.read(customerProfileProvider.notifier).deleteAddress(id);
      },
    );
  }

  // ── Section: Pilih Kurir ─────────────────────────────────────────
  Widget _buildCourierSection() {
    // Fetch rates otomatis saat alamat berubah
    if (_courierRates.isEmpty && !_isLoadingRates && !_ratesError) {
      final address = _addressProvider.selectedAddress;
      if (address != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRates());
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('PILIH KURIR'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          if (_isLoadingRates)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_ratesError)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gagal memuat tarif pengiriman. Pastikan alamat sudah benar.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else if (_courierRates.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.textLight, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tidak ada kurir tersedia untuk alamat ini.',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_courierRates.asMap().entries.map((entry) {
              final index = entry.key;
              final rate = entry.value;
              final code = rate['courier_code'] as String? ?? '';
              final service = rate['courier_service'] as String? ?? '';
              final price = (rate['price'] as num?)?.toInt() ?? 0;
              final etd = rate['etd'] as String? ?? '-';
              final company = rate['company'] as String? ?? code.toUpperCase();
              final isSelected = _selectedCourierCode == code && _selectedCourierService == service;

              return Padding(
                padding: EdgeInsets.only(bottom: index < _courierRates.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => _selectCourier(rate),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: '$code|$service',
                          groupValue: isSelected ? '$code|$service' : null,
                          onChanged: (_) => _selectCourier(rate),
                          activeColor: AppColors.primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                              if (etd != '-')
                                Text(
                                  'Estimasi: $etd',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          'Rp ${_formatPrice(price)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isSelected ? AppColors.primary : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
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
                hintStyle:
                    TextStyle(color: AppColors.textLight, fontSize: 13),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  color:
                      isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
                color:
                    isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_file_rounded,
                      color: AppColors.primary.withOpacity(0.5), size: 36),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                if (_prescriptionFile != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _prescriptionFile!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _prescriptionFile!.path.split('/').last,
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
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textLight),
                    onPressed: () =>
                        setState(() => _prescriptionFile = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else ...[
                  Icon(Icons.insert_drive_file_outlined,
                      color: AppColors.textLight.withOpacity(0.5),
                      size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Belum ada file dipilih',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
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
                    _deliveryMethod == 'kirim'
                        ? (_selectedCourierCode != null
                            ? 'Biaya Pengiriman (${_selectedCourierCode!.toUpperCase()})'
                            : 'Biaya Pengiriman')
                        : 'Biaya Pengiriman',
                    _deliveryMethod == 'kirim' ? _selectedCourierPrice : 0),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child:
                      Divider(color: Colors.grey.shade100, height: 1),
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
            color: isDiscount
                ? const Color(0xFFEF4444)
                : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ── Bottom Bar ───────────────────────────────────────────────────
  Widget _buildBottomBar() {
    // Validasi: jika kirim, wajib ada alamat + kurir
    final bool hasAddress = _addressProvider.selectedAddress != null;
    final bool hasCourier = _selectedCourierCode != null;
    final bool canProceed = _deliveryMethod == 'ambil' ||
        (hasAddress && hasCourier);

    String? errorMsg;
    if (_deliveryMethod == 'kirim') {
      if (!hasAddress) errorMsg = 'Pilih alamat pengiriman terlebih dahulu';
      else if (!hasCourier) errorMsg = 'Pilih kurir pengiriman terlebih dahulu';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
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
                        courierCode: _deliveryMethod == 'kirim' ? _selectedCourierCode ?? _courierCode : null,
                        courierService: _selectedCourierService,
                        total: _total,
                        shippingCost: _shippingCost,
                        deliveryAddress:
                            _addressProvider.selectedAddress,
                        pharmacyId: _cartItems.isNotEmpty
                            ? _cartItems.first.pharmacyId
                            : '',
                        prescriptionFile: _prescriptionFile,
                      ),
                    ),
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg ?? 'Lengkapi data terlebih dahulu'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canProceed ? AppColors.primary : Colors.grey.shade300,
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
  Widget _buildDivider() =>
      Container(height: 8, color: Colors.grey.shade100);

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