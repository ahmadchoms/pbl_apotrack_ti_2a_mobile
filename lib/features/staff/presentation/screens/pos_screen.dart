import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────
class _AppColors {
  static const primary = Color(0xFF1D70F5);
  static const primaryLight = Color(0xFFEEF4FF);
  static const background = Color(0xFFF4F7FE);
  static const textDark = Color(0xFF0F1828);
  static const textMid = Color(0xFF4B5563);
  static const textLight = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5EAF2);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────
String _formatRupiah(num value) {
  final str = value.toStringAsFixed(0);
  final buffer = StringBuffer();
  final len = str.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }
  return 'Rp ${buffer.toString()}';
}

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
class _Medicine {
  final String name;
  final String category;
  final int price;
  final int stock;
  final Color accentColor;
  final IconData icon;

  const _Medicine({
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.accentColor,
    required this.icon,
  });
}

class _CartItem {
  final _Medicine medicine;
  int qty;

  _CartItem({required this.medicine, this.qty = 1});

  int get subtotal => medicine.price * qty;
}

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with TickerProviderStateMixin {
  final List<_Medicine> _medicines = const [
    _Medicine(
      name: 'Amoxicillin 500mg',
      category: 'Tablet',
      price: 15000,
      stock: 45,
      accentColor: Color(0xFF6366F1),
      icon: Icons.local_pharmacy_rounded,
    ),
    _Medicine(
      name: 'Paracetamol 500mg',
      category: 'Tablet',
      price: 2500,
      stock: 120,
      accentColor: Color(0xFF10B981),
      icon: Icons.medication_rounded,
    ),
    _Medicine(
      name: 'OBH Combi Sirup',
      category: 'Sirup',
      price: 18500,
      stock: 22,
      accentColor: Color(0xFFF59E0B),
      icon: Icons.water_drop_rounded,
    ),
    _Medicine(
      name: 'Panadol Flu & Batuk',
      category: 'Tablet',
      price: 12000,
      stock: 50,
      accentColor: Color(0xFFEF4444),
      icon: Icons.healing_rounded,
    ),
    _Medicine(
      name: 'Sanmol Sirup',
      category: 'Sirup',
      price: 21000,
      stock: 15,
      accentColor: Color(0xFF8B5CF6),
      icon: Icons.opacity_rounded,
    ),
    _Medicine(
      name: 'Vitamin C 500mg',
      category: 'Suplemen',
      price: 5000,
      stock: 200,
      accentColor: Color(0xFFEC4899),
      icon: Icons.spa_rounded,
    ),
  ];

  late List<_Medicine> _filtered;
  final List<_CartItem> _cart = [];
  final _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _filtered = _medicines;
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  List<String> get _categories => [
    'Semua',
    ..._medicines.map((m) => m.category).toSet().toList(),
  ];

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _medicines.where((m) {
        final matchSearch = m.name.toLowerCase().contains(query);
        final matchCat =
            _selectedCategory == 'Semua' || m.category == _selectedCategory;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  void _addToCart(_Medicine med) {
    HapticFeedback.lightImpact();
    setState(() {
      final existing = _cart.indexWhere((c) => c.medicine.name == med.name);
      if (existing >= 0) {
        _cart[existing].qty++;
      } else {
        _cart.add(_CartItem(medicine: med));
      }
      if (_cart.length == 1) _fabController.forward();
    });
  }

  void _removeFromCart(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_cart[index].qty > 1) {
        _cart[index].qty--;
      } else {
        _cart.removeAt(index);
        if (_cart.isEmpty) _fabController.reverse();
      }
    });
  }

  int _getCartQty(String name) {
    final idx = _cart.indexWhere((c) => c.medicine.name == name);
    return idx >= 0 ? _cart[idx].qty : 0;
  }

  int get _totalItems => _cart.fold(0, (sum, c) => sum + c.qty);
  int get _totalPrice => _cart.fold(0, (sum, c) => sum + c.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchAndFilter(),
          Expanded(child: _buildGrid()),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        ),
        child: _cart.isNotEmpty ? _buildCartFab() : const SizedBox.shrink(),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.primary,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kasir POS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Apotek Sehat Sejahtera',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Color(0xFF4ADE80), size: 7),
                    const SizedBox(width: 5),
                    Text(
                      'Buka',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SEARCH + FILTER ──────────────────────────
  Widget _buildSearchAndFilter() {
    return Container(
      color: _AppColors.background,
      child: Column(
        children: [
          // Search bar pulled up, overlapping header
          Transform.translate(
            offset: const Offset(0, 0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.primary.withOpacity(0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _filter(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: _AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari nama obat...',
                    hintStyle: const TextStyle(
                      color: _AppColors.textLight,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _AppColors.primary,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _filter();
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: _AppColors.textLight,
                              size: 18,
                            ),
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _buildChip(_categories[i]),
            ),
          ),
          const SizedBox(height: 16),
          // Subtle stat bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} produk ditemukan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChip(String cat) {
    final isSelected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = cat);
        _filter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _AppColors.primary : _AppColors.divider,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          cat,
          style: TextStyle(
            color: isSelected ? Colors.white : _AppColors.textMid,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ── GRID ─────────────────────────────────────
  Widget _buildGrid() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: _AppColors.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Obat tidak ditemukan',
              style: TextStyle(
                color: _AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildProductCard(_filtered[i]),
    );
  }

  Widget _buildProductCard(_Medicine med) {
    final qty = _getCartQty(med.name);
    final isInCart = qty > 0;
    final isLowStock = med.stock <= 20;

    return GestureDetector(
      onTap: () => _addToCart(med),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isInCart
                ? _AppColors.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isInCart
                  ? _AppColors.primary.withOpacity(0.12)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon area
                  Container(
                    height: 72,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: med.accentColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(med.icon, color: med.accentColor, size: 34),
                  ),
                  const SizedBox(height: 10),

                  // Category pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: med.accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      med.category,
                      style: TextStyle(
                        color: med.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Name
                  Text(
                    med.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: _AppColors.textDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),

                  // Stock indicator
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? _AppColors.warning
                              : _AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stok ${med.stock}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isLowStock
                              ? _AppColors.warning
                              : _AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price + Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _formatRupiah(med.price),
                          style: const TextStyle(
                            color: _AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isInCart
                              ? _AppColors.primary
                              : _AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: isInCart ? Colors.white : _AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cart qty badge
            if (isInCart)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: _AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    qty.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── CART FAB ─────────────────────────────────
  Widget _buildCartFab() {
    return GestureDetector(
      onTap: _showCartSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              '$_totalItems item  •  ${_formatRupiah(_totalPrice)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Bayar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CART SHEET ───────────────────────────────
  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => _CartSheet(
          cart: _cart,
          totalPrice: _totalPrice,
          onRemove: (i) {
            _removeFromCart(i);
            setSheet(() {});
            setState(() {});
          },
          onAdd: (i) {
            setState(() => _cart[i].qty++);
            setSheet(() {});
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CART SHEET WIDGET
// ─────────────────────────────────────────────
class _CartSheet extends StatelessWidget {
  const _CartSheet({
    required this.cart,
    required this.totalPrice,
    required this.onRemove,
    required this.onAdd,
  });

  final List<_CartItem> cart;
  final int totalPrice;
  final void Function(int) onRemove;
  final void Function(int) onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 14),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: _AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Keranjang Belanja',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cart.fold(0, (s, c) => s + c.qty)} item',
                    style: const TextStyle(
                      color: _AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: _AppColors.divider, height: 1),

          // Item list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: cart.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: _AppColors.divider, height: 24),
              itemBuilder: (_, i) => _buildCartRow(i),
            ),
          ),

          // Checkout area
          _buildCheckoutBar(),
        ],
      ),
    );
  }

  Widget _buildCartRow(int i) {
    final item = cart[i];
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: item.medicine.accentColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.medicine.icon,
            color: item.medicine.accentColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.medicine.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                _formatRupiah(item.medicine.price),
                style: const TextStyle(
                  color: _AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Qty control
        Container(
          decoration: BoxDecoration(
            color: _AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _QtyButton(icon: Icons.remove_rounded, onTap: () => onRemove(i)),
              SizedBox(
                width: 28,
                child: Text(
                  item.qty.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: _AppColors.textDark,
                  ),
                ),
              ),
              _QtyButton(icon: Icons.add_rounded, onTap: () => onAdd(i)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            _formatRupiah(item.subtotal),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              color: _AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              // Summary rows
              _SummaryRow(label: 'Subtotal', value: _formatRupiah(totalPrice)),
              const SizedBox(height: 6),
              _SummaryRow(
                label: 'Biaya Layanan',
                value: _formatRupiah(0),
                isLight: true,
              ),
              const SizedBox(height: 10),
              const Divider(color: _AppColors.divider, height: 1),
              const SizedBox(height: 10),
              _SummaryRow(
                label: 'Total Bayar',
                value: _formatRupiah(totalPrice),
                isTotal: true,
              ),
              const SizedBox(height: 16),

              // Pay button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Proses Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SMALL WIDGETS
// ─────────────────────────────────────────────
class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: _AppColors.primary),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLight = false,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isLight;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            fontSize: isTotal ? 15 : 13,
            color: isLight
                ? _AppColors.textLight
                : isTotal
                ? _AppColors.textDark
                : _AppColors.textMid,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            fontSize: isTotal ? 18 : 13,
            color: isTotal ? _AppColors.primary : _AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
