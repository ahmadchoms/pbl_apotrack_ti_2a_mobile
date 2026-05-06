import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../widgets/pos_product_card.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _medicines = [
    {
      'id': 1,
      'name': 'Amoxicillin 500mg',
      'category': 'Tablet',
      'price': 15000.0,
      'total_active_stock': 45,
      'accentColor': const Color(0xFF6366F1),
      'icon': Icons.local_pharmacy_rounded,
    },
    {
      'id': 2,
      'name': 'Paracetamol 500mg',
      'category': 'Tablet',
      'price': 2500.0,
      'total_active_stock': 120,
      'accentColor': const Color(0xFF10B981),
      'icon': Icons.medication_rounded,
    },
    {
      'id': 3,
      'name': 'OBH Combi Sirup',
      'category': 'Sirup',
      'price': 18500.0,
      'total_active_stock': 22,
      'accentColor': const Color(0xFFF59E0B),
      'icon': Icons.water_drop_rounded,
    },
    {
      'id': 4,
      'name': 'Vitamin C 500mg',
      'category': 'Suplemen',
      'price': 5000.0,
      'total_active_stock': 200,
      'accentColor': const Color(0xFFEC4899),
      'icon': Icons.spa_rounded,
    },
  ];

  late List<Map<String, dynamic>> _filtered;
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
    ..._medicines.map((m) => m['category'] as String).toSet().toList(),
  ];

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _medicines.where((m) {
        final matchSearch = m['name'].toString().toLowerCase().contains(query);
        final matchCat =
            _selectedCategory == 'Semua' || m['category'] == _selectedCategory;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  void _addToCart(Map<String, dynamic> med) {
    HapticFeedback.lightImpact();
    setState(() {
      final existing = _cart.indexWhere((c) => c.medicine['name'] == med['name']);
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
    final idx = _cart.indexWhere((c) => c.medicine['name'] == name);
    return idx >= 0 ? _cart[idx].qty : 0;
  }

  int get _totalItems => _cart.fold(0, (sum, c) => sum + c.qty);
  num get _totalPrice => _cart.fold(0, (sum, c) => sum + c.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        color: AppColors.primary,
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
      color: AppColors.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.10),
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
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari nama obat...',
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
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
                            color: AppColors.textLight,
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
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          cat,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMid,
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
              color: AppColors.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Obat tidak ditemukan',
              style: TextStyle(
                color: AppColors.textLight,
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
      itemBuilder: (_, i) {
        final med = _filtered[i];
        return PosProductCard(
          medicine: med,
          cartQty: _getCartQty(med['name']),
          onAdd: () => _addToCart(med),
        );
      },
    );
  }

  // ── CART FAB ─────────────────────────────────
  Widget _buildCartFab() {
    return FloatingActionButton.extended(
      onPressed: _showCartSheet,
      backgroundColor: AppColors.primary,
      elevation: 8,
      label: Row(
        children: [
          const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            '$_totalItems Item · ${_formatRupiah(_totalPrice)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CartSheet(
        cart: _cart,
        totalPrice: _totalPrice,
        onRemove: _removeFromCart,
        onCheckout: () {
          Navigator.pop(ctx);
          _showSuccessCheckout();
        },
      ),
    );
  }

  void _showSuccessCheckout() {
    setState(() {
      _cart.clear();
      _fabController.reverse();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi berhasil!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CART SHEET
// ─────────────────────────────────────────────
class _CartSheet extends StatelessWidget {
  final List<_CartItem> cart;
  final num totalPrice;
  final Function(int) onRemove;
  final VoidCallback onCheckout;

  const _CartSheet({
    required this.cart,
    required this.totalPrice,
    required this.onRemove,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Text(
                  'Keranjang Belanja',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.length} Jenis',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: cart.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (_, i) => _buildCartRow(i),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatRupiah(totalPrice),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Proses Transaksi',
                  icon: Icons.check_circle_rounded,
                  onPressed: onCheckout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartRow(int index) {
    final item = cart[index];
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: (item.medicine['accentColor'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.medicine['icon'] as IconData,
              color: item.medicine['accentColor'] as Color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.medicine['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatRupiah(item.medicine['price'] as num),
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildQtyBtn(Icons.remove_rounded, () => onRemove(index)),
            const SizedBox(width: 12),
            Text(
              item.qty.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            _buildQtyBtn(Icons.add_rounded, null), // simplified for now
          ],
        ),
      ],
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.textMid),
      ),
    );
  }
}

// Model & Helper
class _CartItem {
  final Map<String, dynamic> medicine;
  int qty;
  _CartItem({required this.medicine, this.qty = 1});
  num get subtotal => (medicine['price'] as num) * qty;
}

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
