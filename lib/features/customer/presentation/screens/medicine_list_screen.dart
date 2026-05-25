import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/customer/data/models/medicine_model.dart';
import 'package:mobile/features/customer/data/models/medicine_category_model.dart';
import 'package:mobile/features/customer/data/services/medicine_service.dart';
import 'package:mobile/shared/widgets/app_card.dart';
import 'package:mobile/shared/widgets/status_badge.dart';
import 'qris_payment_screen.dart';

class MedicineListScreen extends ConsumerStatefulWidget {
  final String pharmacyId;
  final String pharmacyName;
  final double pharmacyRating;
  final String pharmacyDistance;
  final String pharmacyArea;
  final bool isOpen;

  const MedicineListScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
    this.pharmacyRating = 4.9,
    this.pharmacyDistance = '1.2 km',
    this.pharmacyArea = 'Menteng',
    this.isOpen = true,
  });

  @override
  ConsumerState<MedicineListScreen> createState() =>
      _MedicineListScreenState();
}

class _MedicineListScreenState extends ConsumerState<MedicineListScreen> {
  String _selectedCategoryId = '';
  String _search = '';
  final Map<String, int> _cart = {};

  String _rupiah(double amount) {
    final str = amount.toStringAsFixed(0);
    return 'Rp ${str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  List<MedicineModel> _filterMedicines(List<MedicineModel> all) {
    return all.where((m) {
      final matchCat = _selectedCategoryId.isEmpty ||
          m.categoryId == _selectedCategoryId;
      final matchSearch = _search.isEmpty ||
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

  List<Map<String, dynamic>> get _cartItems {
    final allMeds =
        ref.read(medicinesProvider(widget.pharmacyId)).valueOrNull ?? [];
    return allMeds.where((m) => (_cart[m.id] ?? 0) > 0).map((m) {
      final qty = _cart[m.id]!;
      final subtotal = (qty * m.price).toInt();
      return {
        'medicine_id': m.id,
        'medicine_name': m.name,
        'unit_name': m.unitName ?? 'Pcs',
        'quantity': qty,
        'price': m.price.toInt(),
        'subtotal': subtotal,
        'requires_prescription': m.requiresPrescription,
      };
    }).toList();
  }

  void _goToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrisPaymentScreen(
          pharmacyId: widget.pharmacyId,
          pharmacyName: widget.pharmacyName,
          items: _cartItems,
          subtotal: _cartTotal.toInt(),
          shippingCost: 0,
        ),
      ),
    );
  }

  Map<String, Color> _typeColor(String? typeName) {
    switch (typeName) {
      case 'Obat Keras':
        return {'fg': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF3F0FF)};
      case 'Obat Bebas Terbatas':
        return {'fg': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)};
      case 'Herbal':
        return {'fg': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)};
      case 'Alat Kesehatan':
        return {'fg': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)};
      default:
        return {'fg': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider(widget.pharmacyId));
    final categoriesAsync = ref.watch(medicineCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!widget.isOpen) _buildClosedBanner(),
          Expanded(
            child: medicinesAsync.when(
              loading: () => const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 48, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat data:\n$e',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .refresh(medicinesProvider(widget.pharmacyId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Coba Lagi',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              data: (medicines) {
                final filtered = _filterMedicines(medicines);
                final popular = medicines.take(3).toList();

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 8),
                    categoriesAsync.when(
                      loading: () => const SizedBox(height: 52),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (cats) =>
                          _buildPopularSection(popular, cats),
                    ),
                    const SizedBox(height: 8),
                    _buildAllProductsSection(filtered, medicines),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          (_cartTotal > 0 && widget.isOpen) ? _buildCheckoutBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.pharmacyName,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 13),
              Text(
                ' ${widget.pharmacyRating}  •  ${widget.pharmacyDistance}  •  ${widget.pharmacyArea}',
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: Color(0xFF2563EB)),
              onPressed: (!widget.isOpen || _cartItemCount == 0)
                  ? null
                  : _goToCheckout,
            ),
            if (_cartItemCount > 0 && widget.isOpen)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
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
        IconButton(
          icon: const Icon(Icons.info_outline, color: Color(0xFF6B7280)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildClosedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFF3CD),
      child: const Row(
        children: [
          Icon(Icons.access_time, color: Color(0xFF92400E), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Apotek sedang tutup. Kamu masih bisa lihat-lihat, tapi tidak bisa memesan sekarang.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Cari obat, vitamin, atau alat kesehatan...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon:
              Icon(Icons.search, color: Colors.grey[400], size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F6FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide:
                const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 16),
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
        : popular
            .where((m) => m.categoryId == _selectedCategoryId)
            .toList();

    final allCategories = [
      MedicineCategoryModel(id: '', name: 'SEMUA'),
      ...cats,
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      borderRadius: 0,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produk Populer',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategoryId = ''),
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
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
              padding: const EdgeInsets.only(left: 16, right: 8),
              itemCount: allCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = allCategories[i];
                final selected = _selectedCategoryId == cat.id;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategoryId = cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF374151),
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
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF9CA3AF)),
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
                child: Text('Obat tidak ditemukan.',
                    style: TextStyle(color: Colors.grey[400])),
              ),
            )
          : const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      borderRadius: 0,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Semua Produk',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
          ...List.generate(items.length, (i) {
            return Column(
              children: [
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF3F4F6),
                  ),
                _buildMedicineRow(items[i]),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMedicineRow(MedicineModel m) {
    final qty = _cart[m.id] ?? 0;
    const stock = 99;
    final isUnavailable = !widget.isOpen;

    final String stockLabel;
    final Color stockColor;
    final Color stockBg;
    final IconData? stockIcon;

    if (!widget.isOpen) {
      stockLabel = 'Tutup';
      stockColor = const Color(0xFFB91C1C);
      stockBg = const Color(0xFFFFEBEE);
      stockIcon = Icons.store_outlined;
    } else if (m.requiresPrescription) {
      stockLabel = 'Butuh Resep';
      stockColor = const Color(0xFF7C3AED);
      stockBg = const Color(0xFFF3F0FF);
      stockIcon = Icons.description_outlined;
    } else {
      stockLabel = 'Tersedia';
      stockColor = const Color(0xFF059669);
      stockBg = const Color(0xFFECFDF5);
      stockIcon = Icons.check_circle_outline;
    }

    final typeColors = _typeColor(m.typeName);
    final typeColor =
        isUnavailable ? const Color(0xFF9CA3AF) : typeColors['fg']!;
    final typeBg =
        isUnavailable ? const Color(0xFFF3F4F6) : typeColors['bg']!;

    return Opacity(
      opacity: isUnavailable ? 0.45 : 1.0,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: isUnavailable
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 5),
                  StatusBadge(
                    label: m.typeName ?? 'Obat Bebas',
                    color: typeColor,
                    backgroundColor: typeBg,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m.description,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rupiah(m.price),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isUnavailable
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(
                    label: stockLabel,
                    color: stockColor,
                    backgroundColor: stockBg,
                    icon: stockIcon,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                ColorFiltered(
                  colorFilter: isUnavailable
                      ? const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 1, 0,
                        ])
                      : const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    width: 88,
                    borderRadius: 12,
                    color: const Color(0xFFF3F4F6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMedicineImage(m.imageUrl),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (isUnavailable)
                  _buildDisabledButton('Tutup')
                else if (qty == 0)
                  _buildTambahButton(m.id)
                else
                  _buildQtyControl(m.id, qty, stock),
              ],
            ),
          ],
        ),
      ),
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
      errorBuilder: (ctx, _, __) => _placeholderIcon(),
    );
  }

  Widget _placeholderIcon() {
    return const SizedBox(
      width: 88,
      height: 88,
      child:
          Icon(Icons.medication, color: Color(0xFF9CA3AF), size: 40),
    );
  }

  Widget _loadingIndicator() {
    return const SizedBox(
      width: 88,
      height: 88,
      child: Center(
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Color(0xFF2563EB)),
      ),
    );
  }

  Widget _buildDisabledButton(String label) {
    return SizedBox(
      width: 88,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ),
    );
  }

  Widget _buildTambahButton(String id) {
    return SizedBox(
      width: 88,
      child: OutlinedButton(
        onPressed: () => setState(() => _cart[id] = 1),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2563EB)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: const Text(
          'Tambah',
          style: TextStyle(
            color: Color(0xFF2563EB),
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
        color: const Color(0xFF2563EB),
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
            child:
                const Icon(Icons.remove, color: Colors.white, size: 16),
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
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return AppCard(
      borderRadius: 0,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ElevatedButton(
        onPressed: _goToCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 20),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white, size: 22),
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
                                color: Color(0xFF2563EB),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}