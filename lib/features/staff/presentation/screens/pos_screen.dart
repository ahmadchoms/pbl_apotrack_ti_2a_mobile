import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/staff_provider.dart';
import '../widgets/pos_product_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/staff_service.dart';
import '../../data/models/medicine.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final List<_CartItem> _cart = [];
  final _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Medicine> _applyFilter(List<Medicine> medicines) {
    final query = _searchController.text.toLowerCase().trim();
    return medicines.where((m) {
      final matchSearch = m.name.toLowerCase().contains(query);
      final catName = m.category ?? '';
      final matchCat =
          _selectedCategory == 'Semua' || catName == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  List<String> _getCategories(List<Medicine> medicines) {
    final cats = <String>{'Semua'};
    for (final m in medicines) {
      if (m.category != null && m.category!.isNotEmpty) cats.add(m.category!);
    }
    return cats.toList();
  }

  void _addToCart(Medicine med) {
    HapticFeedback.lightImpact();
    setState(() {
      final existing = _cart.indexWhere((c) => c.medicine.id == med.id);
      if (existing >= 0) {
        _cart[existing].qty++;
      } else {
        _cart.add(_CartItem(medicine: med));
      }
    });
  }

  void _removeFromCart(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_cart[index].qty > 1) {
        _cart[index].qty--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  int _getCartQty(String id) {
    final idx = _cart.indexWhere((c) => c.medicine.id == id);
    return idx >= 0 ? _cart[idx].qty : 0;
  }

  int get _totalItems => _cart.fold(0, (sum, c) => sum + c.qty);
  num get _totalPrice => _cart.fold(0, (sum, c) => sum + c.subtotal);

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(staffMedicinesProvider);
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, user?.pharmacyName ?? 'Apotek ApoTrack'),
          medicinesAsync.when(
            data: (medicines) {
              final categories = _getCategories(medicines);
              final filtered = _applyFilter(medicines);
              return Expanded(
                child: Column(
                  children: [
                    _buildSearchAndFilter(categories),
                    Expanded(child: _buildGrid(filtered)),
                  ],
                ),
              );
            },
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Expanded(child: _buildErrorState(e.toString())),
          ),
          _buildStickyCartBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String pharmacyName) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Point of Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pharmacyName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                const SizedBox(width: 6),
                const Text(
                  'Kasir Aktif',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(List<String> categories) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari SKU atau nama obat...',
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMid,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(
                          Icons.cancel_rounded,
                          color: AppColors.textLight,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _buildChip(categories[i]),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildChip(String cat) {
    final isSelected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.textDark : AppColors.divider,
          ),
        ),
        child: Text(
          cat,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMid,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<Medicine> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data tidak ditemukan',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba kata kunci atau kategori lain',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65, // Adjusted for taller, modern cards
      ),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final med = filtered[i];
        return PosProductCard(
          medicine: med,
          cartQty: _getCartQty(med.id),
          onAdd: () => _addToCart(med),
        );
      },
    );
  }

  Widget _buildStickyCartBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: _cart.isNotEmpty ? 90 : 0,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total ($_totalItems item)',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatRupiah(_totalPrice),
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showCartSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Keranjang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.danger,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Koneksi Terputus',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            width: 160,
            label: 'Muat Ulang',
            icon: Icons.refresh_rounded,
            onPressed: () => ref.refresh(staffMedicinesProvider),
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return _CartSheet(
            cart: _cart,
            totalPrice: _totalPrice,
            isProcessing: _isProcessing,
            onRemove: (idx) {
              if (_isProcessing) return;
              setState(() => _removeFromCart(idx));
              setSheetState(() {});
            },
            onAdd: (idx) {
              if (_isProcessing) return;
              setState(() => _addToCart(_cart[idx].medicine));
              setSheetState(() {});
            },
            onCheckout: () async {
              if (_isProcessing) return;
              
              setSheetState(() => _isProcessing = true);
              setState(() => _isProcessing = true);
              
              final success = await _processCheckout();
              
              if (mounted) {
                if (success) {
                  Navigator.pop(ctx);
                } else {
                  setSheetState(() => _isProcessing = false);
                  setState(() => _isProcessing = false);
                }
              }
            },
          );
        },
      ),
    );
  }

  Future<bool> _processCheckout() async {
    final service = ref.read(staffServiceProvider);
    final items = _cart
        .map(
          (c) => {
            'id': c.medicine.id,
            'quantity': c.qty,
            'price': c.price,
          },
        )
        .toList();

    try {
      await service.storePosOrder({
        'items': items,
        'total': _totalPrice,
        'payment_method': 'TUNAI',
      });
      
      setState(() {
        _cart.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Transaksi berhasil diproses',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(20),
          ),
        );
        ref.refresh(staffMedicinesProvider);
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses transaksi: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
      return false;
    }
  }
}

// ─────────────────────────────────────────────
// CART SHEET (REDESIGNED)
// ─────────────────────────────────────────────
class _CartSheet extends StatelessWidget {
  final List<_CartItem> cart;
  final num totalPrice;
  final bool isProcessing;
  final Function(int) onRemove;
  final Function(int) onAdd;
  final VoidCallback onCheckout;

  const _CartSheet({
    required this.cart,
    required this.totalPrice,
    required this.isProcessing,
    required this.onRemove,
    required this.onAdd,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Grabber
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rincian Pesanan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${cart.length} Produk',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                itemCount: cart.length,
                separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                itemBuilder: (_, i) => _buildCartRow(i),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Tagihan',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatRupiah(totalPrice),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: isProcessing ? 'Memproses...' : 'Proses Pembayaran',
                  icon: isProcessing ? null : Icons.payments_outlined,
                  isLoading: isProcessing,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          ),
          child:
              item.medicine.imageUrl != null &&
                  item.medicine.imageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.medicine.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(
                  Icons.medication_outlined,
                  color: AppColors.textLight,
                  size: 28,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.medicine.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatRupiah(item.price),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildActionBtn(
              Icons.remove_rounded,
              () => onRemove(index),
              isRemove: item.qty == 1,
            ),
            SizedBox(
              width: 40,
              child: Text(
                item.qty.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
            ),
            _buildActionBtn(Icons.add_rounded, () => onAdd(index)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    VoidCallback? onTap, {
    bool isRemove = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isRemove
                  ? AppColors.danger.withOpacity(0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isRemove ? AppColors.danger : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItem {
  final Medicine medicine;
  int qty;
  _CartItem({required this.medicine, this.qty = 1});

  num get price => medicine.price;
  num get subtotal => price * qty;
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
