import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
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
  final _notesController = TextEditingController();
  String _selectedCategory = 'Semua';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
    _notesController.dispose();
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
            Expanded(
              child: _buildGrid(
                _applyFilter(state.items),
                state.isLoadingNextPage,
              ),
            ),
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
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  pharmacyName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: AppColors.success, size: 8),
          SizedBox(width: 8),
          Text(
            'Kasir Aktif',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(List<String> categories) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama obat atau SKU...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildCategoryChip(categories[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String cat) {
    final isSelected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = cat);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          cat,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMid,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<Medicine> filtered, bool isLoadingNextPage) {
    if (filtered.isEmpty) return _buildEmptyState();

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: filtered.length + (isLoadingNextPage ? 2 : 0),
      itemBuilder: (_, i) {
        if (i >= filtered.length) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final med = filtered[i];
        return PosProductCard(
          medicine: med,
          cartQty: _getCartQty(med.id),
          onAdd: () => ref.read(posCartProvider.notifier).addItem(med),
          onRemove: () =>
              ref.read(posCartProvider.notifier).subtractItem(med.id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSubtle.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Produk tidak ditemukan',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const Text(
            'Coba gunakan kata kunci lain',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCartBar(List<CartItem> cart, PosCartNotifier notifier) {
    if (cart.isEmpty) return const SizedBox.shrink();

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
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Tagihan',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatRupiah(notifier.totalPrice),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openCartSheet(),
            icon: const Icon(
              Icons.shopping_cart_checkout_rounded,
              color: Colors.white,
            ),
            label: const Text(
              'KERANJANG',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CartSheetWrapper(
        onCheckout: _showPaymentModal,
        notesController: _notesController,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          TextButton(
            onPressed: () =>
                ref.read(staffMedicinesProvider.notifier).refresh(),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showPaymentModal() async {
    final method = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            _buildPaymentOption(
              context,
              'CASH',
              'Tunai / Cash',
              Icons.payments_rounded,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              context,
              'QRIS',
              'QRIS Dinamis',
              Icons.qr_code_scanner_rounded,
            ),
          ],
        ),
      ),
    );

    if (method != null) return await _submitOrder(method);
    return false;
  }

  Widget _buildPaymentOption(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return ListTile(
      onTap: () => Navigator.pop(context, value),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textLight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
    );
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

    try {
      processingNotifier.state = true;
      await service.storePosOrder({
        'items': items,
        'total': notifier.totalPrice,
        'payment_method': paymentMethod,
        'notes': _notesController.text.trim(),
      });

      if (mounted) {
        notifier.clearCart();
        _notesController.clear();
        ref.read(staffMedicinesProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi Berhasil disimpan!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      processingNotifier.state = false;
    }
  }
}

class _CartSheetWrapper extends ConsumerWidget {
  final Future<bool> Function() onCheckout;
  final TextEditingController notesController;

  const _CartSheetWrapper({
    required this.onCheckout,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posCartProvider);
    final notifier = ref.read(posCartProvider.notifier);
    final isProcessing = ref.watch(posProcessingProvider);

    return _CartSheet(
      cart: cart,
      totalPrice: notifier.totalPrice,
      isProcessing: isProcessing,
      notesController: notesController,
      onRemove: (id) => notifier.removeItem(id),
      onUpdateQty: (id, delta) => notifier.updateQuantity(id, delta),
      onClearCart: () {
        notifier.clearCart();
        Navigator.pop(context);
      },
      onCheckout: () async {
        final success = await onCheckout();
        if (success && context.mounted) Navigator.pop(context);
      },
    );
  }
}

class _CartSheet extends StatelessWidget {
  final List<CartItem> cart;
  final double totalPrice;
  final bool isProcessing;
  final TextEditingController notesController;
  final Function(String) onRemove;
  final Function(String, int) onUpdateQty;
  final VoidCallback onClearCart;
  final VoidCallback onCheckout;

  const _CartSheet({
    required this.cart,
    required this.totalPrice,
    required this.isProcessing,
    required this.notesController,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rincian Pesanan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                IconButton(
                  onPressed: onClearCart,
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.danger,
                  ),
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
                separatorBuilder: (_, _) => const Divider(height: 32),
                itemBuilder: (_, i) => _buildCartRow(cart[i]),
              ),
            ),
          ),
          _buildNotesSection(),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Catatan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tulis instruksi penggunaan...',
                hintStyle: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid,
                ),
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
          const SizedBox(height: 20),
          AppButton(
            label: isProcessing ? 'Memproses...' : 'Proses Pembayaran',
            onPressed: cart.isEmpty || isProcessing ? null : onCheckout,
            isLoading: isProcessing,
          ),
        ],
      ),
    );
  }

  Widget _buildCartRow(CartItem item) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: item.medicine.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.medicine.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.medication),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.medicine.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatRupiah(item.medicine.price),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildQtyBtn(Icons.remove, () => onUpdateQty(item.medicine.id, -1)),
            SizedBox(
              width: 30,
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            _buildQtyBtn(Icons.add, () => onUpdateQty(item.medicine.id, 1)),
          ],
        ),
      ],
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textDark),
      ),
    );
  }
}

String _formatRupiah(num value) {
  final str = value.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }
  return 'Rp ${buffer.toString()}';
}
