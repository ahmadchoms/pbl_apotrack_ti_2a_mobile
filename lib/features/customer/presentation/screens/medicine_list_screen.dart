import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/customer/data/models/medicine_model.dart';
import 'package:mobile/features/customer/data/models/medicine_category_model.dart';
import 'package:mobile/features/customer/data/services/medicine_service.dart';
import 'package:mobile/shared/widgets/status_badge.dart';
import '../../data/models/cart.dart';
import 'checkout_order.dart';

class MedicineListScreen extends ConsumerStatefulWidget {
  final String pharmacyId;
  final String pharmacyName;
  final double pharmacyRating;
  final String pharmacyDistance;
  final String pharmacyArea;
  final bool isOpen;
  final String? categoryId;

  const MedicineListScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
    this.pharmacyRating = 4.9,
    this.pharmacyDistance = '-',
    this.pharmacyArea = '-',
    this.isOpen = true,
    this.categoryId,
  });

  @override
  ConsumerState<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends ConsumerState<MedicineListScreen> {
  String _selectedCategoryId = '';
  String _search = '';
  final Map<String, int> _cart = {};
  final FocusNode _searchFocus = FocusNode();

  String _rupiah(double amount) {
    final str = amount.toStringAsFixed(0);
    return 'Rp ${str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  List<MedicineModel> _filterMedicines(List<MedicineModel> all) {
    return all.where((m) {
      final matchCat =
          _selectedCategoryId.isEmpty || m.categoryId == _selectedCategoryId;
      final matchSearch =
          _search.isEmpty ||
          m.name.toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  double get _cartTotal {
    double total = 0;
    final allMeds =
        ref.read(medicinesProvider(widget.pharmacyId)).valueOrNull ?? [];
    for (final m in allMeds) {
      total += (_cart[m.id] ?? 0) * m.price;
    }
    return total;
  }

  int get _cartItemCount => _cart.values.fold(0, (a, b) => a + b);

  void _goToCheckout() {
    final cartState = CartState();
    cartState.items.clear();

    final allMeds =
        ref.read(medicinesProvider(widget.pharmacyId)).valueOrNull ?? [];
    for (final entry in _cart.entries) {
      final med = allMeds.firstWhere((m) => m.id == entry.key);
      cartState.items.add(
        CartItem(
          id: med.id,
          name: med.name,
          price: med.price.toInt(),
          unit: med.unitName ?? 'Pcs',
          imageUrl: med.imageUrl ?? '',
          pharmacyName: widget.pharmacyName,
          pharmacyId: widget.pharmacyId,
          quantity: entry.value,
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen()),
    );
  }

  Map<String, Color> _typeColor(String? typeName) {
    switch (typeName) {
      case 'Obat Keras':
        return {'fg': AppColors.accentPurple, 'bg': const Color(0xFFF3F0FF)};
      case 'Obat Bebas Terbatas':
        return {'fg': AppColors.warning, 'bg': AppColors.warningLight};
      case 'Herbal':
        return {'fg': AppColors.success, 'bg': AppColors.successLight};
      case 'Alat Kesehatan':
        return {'fg': AppColors.info, 'bg': AppColors.infoLight};
      default:
        return {'fg': AppColors.success, 'bg': AppColors.successLight};
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId ?? '';
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider(widget.pharmacyId));
    final categoriesAsync = ref.watch(medicineCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!widget.isOpen) _buildClosedBanner(),
          Expanded(
            child: medicinesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 56,
                        color: AppColors.textSubtle,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal memuat data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSubtle,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => ref.refresh(
                              medicinesProvider(widget.pharmacyId),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Coba Lagi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (medicines) {
                final sortedMeds = List<MedicineModel>.from(medicines);
                sortedMeds.sort((a, b) {
                  final aAvail = a.isActive && a.totalActiveStock > 0 ? 1 : 0;
                  final bAvail = b.isActive && b.totalActiveStock > 0 ? 1 : 0;
                  return bAvail.compareTo(aAvail);
                });

                final filtered = _filterMedicines(sortedMeds);
                final popular = sortedMeds.take(3).toList();

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    categoriesAsync.when(
                      loading: () => const SizedBox(height: 52),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (cats) => _buildPopularSection(popular, cats),
                    ),
                    const SizedBox(height: 12),
                    _buildAllProductsSection(filtered, sortedMeds),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: (_cartTotal > 0 && widget.isOpen)
          ? _buildCheckoutBar()
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.pharmacyName,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ' ${widget.pharmacyRating}  •  ${widget.pharmacyDistance}  •  ${widget.pharmacyArea}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.primary,
              ),
              onPressed: (!widget.isOpen || _cartItemCount == 0)
                  ? null
                  : _goToCheckout,
            ),
            if (_cartItemCount > 0 && widget.isOpen)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildClosedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warningLight,
      child: const Row(
        children: [
          Icon(Icons.access_time_rounded, color: AppColors.warning, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Apotek sedang tutup. Kamu masih bisa lihat-lihat, tapi tidak bisa memesan sekarang.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isFocused = _searchFocus.hasFocus;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFocused ? AppColors.primary : AppColors.divider,
            width: isFocused ? 2 : 1.5,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: TextField(
          focusNode: _searchFocus,
          onChanged: (v) => setState(() => _search = v),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Cari obat, vitamin, atau alat kesehatan...',
            hintStyle: const TextStyle(
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularSection(
    List<MedicineModel> popular,
    List<MedicineCategoryModel> cats,
  ) {
    if (_search.isNotEmpty) return const SizedBox.shrink();

    final items = _selectedCategoryId.isEmpty
        ? popular
        : popular.where((m) => m.categoryId == _selectedCategoryId).toList();

    final allCategories = [
      MedicineCategoryModel(id: '', name: 'Semua'),
      ...cats,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produk Populer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = ''),
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24, right: 8),
              itemCount: allCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = allCategories[i];
                final selected = _selectedCategoryId == cat.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textMid,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Tidak ada produk di kategori ini.',
                  style: TextStyle(fontSize: 13, color: AppColors.textLight),
                ),
              ),
            )
          else
            ...items.map((m) => _buildMedicineRow(m)),
        ],
      ),
    );
  }

  Widget _buildAllProductsSection(
    List<MedicineModel> filtered,
    List<MedicineModel> allMeds,
  ) {
    final popularIds = allMeds.take(3).map((m) => m.id).toSet();
    final items = _search.isNotEmpty
        ? filtered
        : filtered.where((m) => !popularIds.contains(m.id)).toList();

    if (items.isEmpty) {
      return _search.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Obat tidak ditemukan.',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ),
            )
          : const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: Text(
              'Semua Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
          ),
          ...items.map((m) => _buildMedicineRow(m)),
        ],
      ),
    );
  }

  Widget _buildMedicineRow(MedicineModel m) {
    final qty = _cart[m.id] ?? 0;
    final stock = m.totalActiveStock;
    final isMedicineAvailable = m.isActive && m.totalActiveStock > 0;
    final isUnavailable = !widget.isOpen || !isMedicineAvailable;

    final String? stockLabel;
    final Color? stockColor;
    final Color? stockBg;
    final IconData? stockIcon;

    if (!widget.isOpen) {
      stockLabel = 'Tutup';
      stockColor = AppColors.danger;
      stockBg = AppColors.dangerLight;
      stockIcon = Icons.store_outlined;
    } else if (m.requiresPrescription) {
      stockLabel = 'Butuh Resep';
      stockColor = AppColors.accentPurple;
      stockBg = const Color(0xFFF3F0FF);
      stockIcon = Icons.description_outlined;
    } else if (isMedicineAvailable) {
      stockLabel = null;
      stockColor = AppColors.success;
      stockBg = AppColors.successLight;
      stockIcon = Icons.check_circle_outline;
    } else {
      stockLabel = null;
      stockColor = null;
      stockBg = null;
      stockIcon = null;
    }

    final typeColors = _typeColor(m.typeName);
    final typeColor = isUnavailable ? AppColors.textLight : typeColors['fg']!;
    final typeBg = isUnavailable ? AppColors.divider : typeColors['bg']!;

    Widget card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: isUnavailable
                        ? AppColors.textLight
                        : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                StatusBadge(
                  label: m.typeName ?? 'Obat Bebas',
                  color: typeColor,
                  backgroundColor: typeBg,
                ),
                const SizedBox(height: 6),
                Text(
                  m.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  _rupiah(m.price),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isUnavailable
                        ? AppColors.textLight
                        : AppColors.textDark,
                  ),
                ),
                if (stockLabel != null) ...[
                  const SizedBox(height: 6),
                  StatusBadge(
                    label: stockLabel,
                    color: stockColor ?? AppColors.success,
                    backgroundColor: stockBg ?? AppColors.successLight,
                    icon: stockIcon,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildMedicineImage(m.imageUrl),
                ),
              ),
              const SizedBox(height: 10),
              if (isUnavailable)
                _buildDisabledButton(widget.isOpen ? 'Habis' : 'Tutup')
              else if (qty == 0)
                _buildTambahButton(m.id)
              else
                _buildQtyControl(m.id, qty, stock),
            ],
          ),
        ],
      ),
    );

    if (isUnavailable) {
      card = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Opacity(opacity: 0.6, child: card),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        card,
        const Divider(
          height: 1,
          indent: 24,
          endIndent: 24,
          color: AppColors.divider,
        ),
      ],
    );
  }

  Widget _buildMedicineImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return _placeholderIcon();
    return Image.network(
      imageUrl,
      width: 88,
      height: 88,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, progress) =>
          progress == null ? child : _loadingIndicator(),
      errorBuilder: (ctx, _, _) => _placeholderIcon(),
    );
  }

  Widget _placeholderIcon() {
    return const SizedBox(
      width: 88,
      height: 88,
      child: Icon(Icons.medication, color: AppColors.textSubtle, size: 40),
    );
  }

  Widget _loadingIndicator() {
    return const SizedBox(
      width: 88,
      height: 88,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDisabledButton(String label) {
    return SizedBox(
      width: 88,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildTambahButton(String id) {
    return SizedBox(
      width: 88,
      child: OutlinedButton(
        onPressed: () => setState(() => _cart[id] = 1),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: const Text(
          'Tambah',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildQtyControl(String id, int qty, int stock) {
    return Container(
      width: 88,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (_cart[id]! > 1) {
                _cart[id] = _cart[id]! - 1;
              } else {
                _cart.remove(id);
              }
            }),
            child: const Icon(
              Icons.remove_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          Text(
            '$qty',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              if ((_cart[id] ?? 0) < stock) {
                _cart[id] = (_cart[id] ?? 0) + 1;
              }
            }),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _goToCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        if (_cartItemCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_cartItemCount',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _rupiah(_cartTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'CHECKOUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
