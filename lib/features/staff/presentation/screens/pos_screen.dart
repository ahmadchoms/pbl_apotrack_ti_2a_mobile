import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/staff_provider.dart';
import '../providers/pos_cart_provider.dart';
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
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedCategory = 'Semua';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(staffMedicinesProvider.notifier).fetchNextPage();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
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

  int _getCartQty(String id) {
    final cart = ref.read(posCartProvider);
    final idx = cart.indexWhere((item) => item.medicine.id == id);
    return idx >= 0 ? cart[idx].quantity : 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffMedicinesProvider);
    final cart = ref.watch(posCartProvider);
    final cartNotifier = ref.read(posCartProvider.notifier);
    final user = ref.watch(authNotifierProvider).user;

    final categories = ref.watch(medicineCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, user?.pharmacyName ?? 'Apotek ApoTrack'),
          if (state.isLoading && state.items.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null && state.items.isEmpty)
            Expanded(child: _buildErrorState(state.error!))
          else ...[
            _buildSearchAndFilter(categories),
            Expanded(child: _buildGrid(_applyFilter(state.items), state.isLoadingNextPage)),
          ],
          _buildStickyCartBar(cart, cartNotifier),
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                SizedBox(width: 6),
                Text(
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

  Widget _buildGrid(List<Medicine> filtered, bool isLoadingNextPage) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
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
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: filtered.length + (isLoadingNextPage ? 2 : 0), // +2 to keep grid even if needed, but we can just use item builder
      itemBuilder: (_, i) {
        if (i >= filtered.length) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
        }
        final med = filtered[i];
        return PosProductCard(
          medicine: med,
          cartQty: _getCartQty(med.id),
          onAdd: () {
            HapticFeedback.lightImpact();
            try {
              ref.read(posCartProvider.notifier).addItem(med);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceAll('Exception: ', '')),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildStickyCartBar(List<CartItem> cart, PosCartNotifier notifier) {
    final totalItems = cart.fold(0, (sum, item) => sum + item.quantity);
    final totalPrice = notifier.totalPrice;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: cart.isNotEmpty ? 90 : 0,
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
                        'Total ($totalItems item)',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatRupiah(totalPrice),
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
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) =>
                          _CartSheetWrapper(onCheckout: _showPaymentModal),
                    );
                  },
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
            onPressed: () => ref.read(staffMedicinesProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  Future<bool> _showPaymentModal() async {
    final method = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.divider.withOpacity(0.5)),
                ),
                leading: const Icon(
                  Icons.money_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  'Tunai (CASH)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(context, 'CASH'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.divider.withOpacity(0.5)),
                ),
                leading: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  'QRIS',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(context, 'QRIS'),
              ),
            ],
          ),
        );
      },
    );

    if (method != null) {
      return await _submitOrder(method);
    }
    return false;
  }

  Future<bool> _submitOrder(String paymentMethod) async {
    final cart = ref.read(posCartProvider);
    final notifier = ref.read(posCartProvider.notifier);
    final service = ref.read(staffServiceProvider);
    final processingNotifier = ref.read(posProcessingProvider.notifier);

    final items = cart
        .map(
          (item) => {
            'id': item.medicine.id,
            'quantity': item.quantity,
            'price': item.medicine.price,
          },
        )
        .toList();

    final orderTotal = notifier.totalPrice;

    try {
      processingNotifier.state = true;

      await service.storePosOrder({
        'items': items,
        'total': orderTotal,
        'payment_method': paymentMethod,
      });

      if (mounted) {
        notifier.clearCart();
        ref.read(staffMedicinesProvider.notifier).refresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi Berhasil disimpan!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Gagal memproses transaksi';

        if (e is DioException && e.response != null) {
          if (e.response?.statusCode == 422) {
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              errorMsg = data['message'];
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    } finally {
      processingNotifier.state = false;
    }
  }
}

class _CartSheetWrapper extends ConsumerWidget {
  final Future<bool> Function() onCheckout;
  const _CartSheetWrapper({required this.onCheckout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posCartProvider);
    final notifier = ref.read(posCartProvider.notifier);
    final isProcessing = ref.watch(posProcessingProvider);

    return _CartSheet(
      cart: cart,
      totalPrice: notifier.totalPrice,
      isProcessing: isProcessing,
      onRemove: (id) => notifier.removeItem(id),
      onUpdateQty: (id, delta) {
        try {
          notifier.updateQuantity(id, delta);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onClearCart: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kosongkan Keranjang?'),
            content: const Text('Semua item akan dihapus dari keranjang.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  notifier.clearCart();
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Kosongkan',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        );
      },
      onCheckout: () async {
        await onCheckout();
        if (context.mounted) {
          Navigator.pop(context); // Tutup sheet baik saat sukses maupun error
        }
      },
    );
  }
}

class _CartSheet extends StatelessWidget {
  final List<CartItem> cart;
  final double totalPrice;
  final bool isProcessing;
  final Function(String) onRemove;
  final Function(String, int) onUpdateQty;
  final VoidCallback onClearCart;
  final VoidCallback onCheckout;

  const _CartSheet({
    required this.cart,
    required this.totalPrice,
    required this.isProcessing,
    required this.onRemove,
    required this.onUpdateQty,
    required this.onClearCart,
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
                  ),
                ),
                Row(
                  children: [
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
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                      ),
                      onPressed: cart.isEmpty || isProcessing
                          ? null
                          : onClearCart,
                      tooltip: 'Kosongkan Keranjang',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: cart.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (_, i) => _buildCartRow(cart[i]),
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
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Tagihan',
                      style: TextStyle(color: AppColors.textMid),
                    ),
                    Text(
                      _formatRupiah(totalPrice),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: isProcessing ? 'Memproses...' : 'Proses Pembayaran',
                  icon: isProcessing ? null : Icons.payments_outlined,
                  isLoading: isProcessing,
                  onPressed: cart.isEmpty || isProcessing ? null : onCheckout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartRow(CartItem item) {
    final isObatKeras =
        item.medicine.category?.toLowerCase().contains('obat keras') == true ||
        item.medicine.requiresPrescription;

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
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
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.medicine.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatRupiah(item.medicine.price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isObatKeras) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Obat Keras',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildActionBtn(
              Icons.remove_rounded,
              item.quantity == 1
                  ? null
                  : () => onUpdateQty(item.medicine.id, -1),
              isRemove: item.quantity == 1,
            ),
            SizedBox(
              width: 32,
              child: Text(
                item.quantity.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _buildActionBtn(
              Icons.add_rounded,
              item.quantity >= item.medicine.totalActiveStock
                  ? null
                  : () => onUpdateQty(item.medicine.id, 1),
              isDisabled: item.quantity >= item.medicine.totalActiveStock,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    VoidCallback? onTap, {
    bool isRemove = false,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.divider.withOpacity(0.5)
              : (isRemove
                    ? AppColors.danger.withOpacity(0.1)
                    : AppColors.background),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDisabled
              ? AppColors.textLight
              : (isRemove ? AppColors.danger : AppColors.textDark),
        ),
      ),
    );
  }
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
