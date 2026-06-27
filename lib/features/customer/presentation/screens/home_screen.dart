import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/notification.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/utils/location_helper.dart';
import 'package:mobile/core/models/cart.dart';
import 'package:mobile/features/customer/data/services/notification_service.dart';
import 'package:mobile/features/customer/presentation/providers/customer_profile_provider.dart';
import 'package:mobile/routes/app_router.dart';
import 'cart_screen.dart';
import 'notification_screen.dart';
import 'package:mobile/core/models/address.dart';
import 'package:mobile/features/customer/presentation/providers/address_provider.dart';
import 'address/address_picker_sheet.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _cartCount = 0;
  int _notifCount = 0;
  List<Map<String, dynamic>> _popularCategories = [];
  bool _isLoading = true;
  late final AddressProvider _addressProvider;

  @override
  void initState() {
    super.initState();
    _addressProvider = AddressProvider();
    _loadData();
    _loadNotifCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCurrentLocation();
    });
  }

  Future<void> _loadNotifCount() async {
    try {
      final dio = ref.read(dioProvider);
      final data = await NotificationService(dio).getNotifications();
      if (mounted) {
        final models = data.map((e) => NotificationModel.fromJson(e)).toList();
        setState(() => _notifCount = models.where((n) => !n.isRead).length);
      }
    } catch (_) {}
  }

  Future<void> _initCurrentLocation() async {
    try {
      final position = await LocationHelper.determinePosition(context);
      if (position == null) return;

      final addressText = await LocationHelper.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        ref
            .read(customerProfileProvider.notifier)
            .updateCurrentGpsLocation(
              latitude: position.latitude,
              longitude: position.longitude,
              addressDetail: addressText,
            );
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan lokasi GPS: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/categories/popular');
      final list = response.data['data'] as List<dynamic>;
      if (mounted) {
        setState(() {
          _popularCategories = list.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    final pharmacyData =
        (product['pharmacy'] ?? product['pharmacies']) as Map<String, dynamic>?;
    final price = product['price'] is int
        ? product['price'] as int
        : (product['price'] as num).toInt();
    final imageUrl = product['image_url'] as String? ?? '';
    final unit = product['dosage_info'] as String? ?? '';

    CartState().addItem(
      CartItem(
        id: product['id']?.toString() ?? '',
        name: product['name'] as String,
        price: price,
        unit: unit,
        imageUrl: imageUrl,
        pharmacyName: pharmacyData?['name'] as String? ?? 'Apotek',
        pharmacyId: pharmacyData?['id']?.toString() ?? '',
        stock: (product['total_active_stock'] as num?)?.toInt() ?? 99,
      ),
    );
    setState(() {
      _cartCount = CartState().totalCount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ditambahkan ke keranjang'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openAddressPicker() {
    showAddressPickerSheet(
      context,
      _addressProvider,
      onSelected: () => setState(() {}),
      onSetPrimary: (address) {
        ref
            .read(customerProfileProvider.notifier)
            .setPrimaryAddress(address.id);
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

  @override
  Widget build(BuildContext context) {
    ref.listen(customerProfileProvider, (prev, next) {
      if (!next.isLoading) {
        final converted = next.addresses
            .map(AddressModel.fromCustomerAddress)
            .toList();
        _addressProvider.loadFromApi(converted);
      }
    });

    final state = ref.watch(customerProfileProvider);
    final profile = state.profile;
    final userName = profile?.username ?? 'Pengguna';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGreetingSection(userName),
                            _buildFindPharmacySection(context),
                            _buildSectionHeader(
                              'Jenis Obat Terpopuler',
                              () => context.push(
                                AppRouter.customerPharmacySearch,
                              ),
                            ),
                            _buildCategoryGrid(),
                            const SizedBox(height: 100),
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

  Widget _buildHeader() {
    final state = ref.watch(customerProfileProvider);
    final activeAddr =
        state.tempGpsAddress ??
        state.addresses.where((a) => a.isPrimary).firstOrNull;
    final locationName = activeAddr?.displayAddress ?? 'Atur Alamat';
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: _openAddressPicker,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi Anda',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                locationName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    ).then((_) => _loadNotifCount());
                  },
                  child: Stack(
                    children: [
                      _buildHeaderIcon(Icons.notifications_none_rounded),
                      if (_notifCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '$_notifCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ).then(
                      (_) =>
                          setState(() => _cartCount = CartState().totalCount),
                    );
                  },
                  child: Stack(
                    children: [
                      _buildHeaderIcon(Icons.shopping_cart_outlined),
                      if (_cartCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '$_cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
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
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildGreetingSection(String userName) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Cari obat, vitamin, atau alat kesehatan...',
                  hintStyle: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindPharmacySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: GestureDetector(
        onTap: () => context.go(AppRouter.customerPharmacySearch),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D70F5), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D70F5).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  Icons.local_pharmacy_rounded,
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.near_me_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cari Apotek Terdekat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Temukan apotek di sekitarmu & pesan obat sekarang',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────
  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Grid ─────────────────────────────────────────────────
  Widget _buildCategoryGrid() {
    final categories = _popularCategories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (_, i) => _buildCategoryCard(categories[i]),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final name = category['name']?.toString() ?? 'Kategori';
    final id = category['id']?.toString() ?? '';

    // Icon mapping
    IconData iconData = Icons.medication_rounded;
    List<Color> gradientColors = [AppColors.primary, AppColors.primaryDark];

    if (name.contains('Antibiotik')) {
      iconData = Icons.biotech_rounded;
      gradientColors = [const Color(0xFF0EA5E9), const Color(0xFF0284C7)];
    } else if (name.contains('Analgesik')) {
      iconData = Icons.healing_rounded;
      gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
    } else if (name.contains('Antipiretik')) {
      iconData = Icons.thermostat_rounded;
      gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    } else if (name.contains('Antihipertensi')) {
      iconData = Icons.favorite_rounded;
      gradientColors = [const Color(0xFFEC4899), const Color(0xFFDB2777)];
    } else if (name.contains('Antidiabetes')) {
      iconData = Icons.water_drop_rounded;
      gradientColors = [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
    } else if (name.contains('Vitamin')) {
      iconData = Icons.spa_rounded;
      gradientColors = [const Color(0xFF84CC16), const Color(0xFF65A30D)];
    } else if (name.contains('Antihistamin')) {
      iconData = Icons.masks_rounded;
      gradientColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    } else if (name.contains('Antasida')) {
      iconData = Icons.sick_rounded;
      gradientColors = [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
    } else if (name.contains('Batuk')) {
      iconData = Icons.coronavirus_rounded;
      gradientColors = [const Color(0xFF14B8A6), const Color(0xFF0D9488)];
    } else if (name.contains('P3K') || name.contains('Antiseptik')) {
      iconData = Icons.medical_services_rounded;
      gradientColors = [const Color(0xFFF43F5E), const Color(0xFFB91C1C)];
    } else if (name.contains('Mata')) {
      iconData = Icons.visibility_rounded;
      gradientColors = [const Color(0xFF06B6D4), const Color(0xFF0891B2)];
    } else if (name.contains('Ibu') || name.contains('Bayi')) {
      iconData = Icons.child_care_rounded;
      gradientColors = [const Color(0xFFEC4899), const Color(0xFFDB2777)];
    }

    return GestureDetector(
      onTap: () {
        context.push(
          AppRouter.customerPharmacySearch,
          extra: {'categoryId': id, 'categoryName': name},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                iconData,
                size: 72,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: Colors.white, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pesan Sekarang',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
