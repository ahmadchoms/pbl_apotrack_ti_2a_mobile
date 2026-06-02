import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../../../staff/data/models/order.dart';
import '../providers/customer_order_provider.dart';
import '../widgets/order_history/cancel_order_dialog.dart';
import '../widgets/order_history/cancellation_detail_sheet.dart';
import '../widgets/order_history/order_history_card.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  String _selectedFilter = 'Semua';
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  static const _filters = [
    'Semua',
    'Menunggu',
    'Diproses',
    'Siap Diambil',
    'Dikirim',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Order> _applyFilter(List<Order> all) {
    List<Order> result;
    switch (_selectedFilter) {
      case 'Menunggu':
        result = all.where((o) => o.orderStatus == 'PENDING').toList();
        break;
      case 'Diproses':
        result = all.where((o) => o.orderStatus == 'PROCESSING').toList();
        break;
      case 'Siap Diambil':
        result = all.where((o) => o.orderStatus == 'READY_FOR_PICKUP').toList();
        break;
      case 'Dikirim':
        result = all.where((o) => o.orderStatus == 'SHIPPED').toList();
        break;
      case 'Selesai':
        result = all
            .where(
              (o) =>
                  o.orderStatus == 'COMPLETED' || o.orderStatus == 'REVIEWED',
            )
            .toList();
        break;
      case 'Dibatalkan':
        result = all.where((o) => o.orderStatus == 'CANCELLED').toList();
        break;
      default:
        result = all;
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((o) {
        final pharmacyName = (o.pharmacy['name'] ?? '')
            .toString()
            .toLowerCase();
        final orderNumber = o.orderNumber.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return pharmacyName.contains(query) || orderNumber.contains(query);
      }).toList();
    }
    return result;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchFocus.requestFocus();
      } else {
        _searchFocus.unfocus();
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => CancelOrderDialog(
        order: order,
        onConfirm: (reason) => ref
            .read(customerOrderProvider.notifier)
            .requestCancellation(order.id, reason),
      ),
    );
  }

  VoidCallback? _getPrimaryAction(BuildContext context, Order order) {
    switch (order.orderStatus) {
      case 'PENDING':
        return () => _showCancelDialog(order);
      case 'SHIPPED':
        return () => context.push(AppRouter.customerTrackOrder, extra: order);
      case 'COMPLETED':
      case 'REVIEWED':
        return () {
          // TODO: beli lagi
        };
      case 'CANCELLED':
        return () {
          // TODO: pesan lagi
        };
      default:
        return null;
    }
  }

  VoidCallback? _getSecondaryAction(BuildContext context, Order order) {
    switch (order.orderStatus) {
      case 'COMPLETED':
        return () {
          // TODO: navigate ke review screen
        };
      case 'CANCELLED':
        return () => CancellationDetailSheet.show(context, order);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerOrderProvider);
    final allOrders = [...state.activeOrders, ...state.historyOrders];
    final filtered = _applyFilter(allOrders);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_isSearching) _buildSearchBar(),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(state, filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CustomerOrderState state, List<Order> filtered) {
    // Masih loading keduanya dan belum ada data sama sekali
    if (state.isLoading && filtered.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Keduanya gagal dan tidak ada data
    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    // Ada partial error (salah satu gagal) tapi ada data → tampilkan data
    // dengan banner peringatan di atas
    return RefreshIndicator(
      onRefresh: () => ref.read(customerOrderProvider.notifier).loadAll(),
      child: filtered.isEmpty
          ? _buildEmptyState()
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 200 + (index * 60)),
                      child: OrderHistoryCard(
                        order: order,
                        onDetailTap: () => context.push(
                          AppRouter.customerOrderDetail,
                          extra: order,
                        ),
                        onPrimaryActionTap: _getPrimaryAction(context, order),
                        onSecondaryActionTap: _getSecondaryAction(
                          context,
                          order,
                        ),
                      ),
                    );
                  },
                ),
                // Banner partial error (history gagal tapi active berhasil)
                if (state.historyError != null && state.activeOrders.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Riwayat pesanan selesai/batal belum dapat dimuat',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Riwayat Pesanan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: _toggleSearch,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                key: ValueKey(_isSearching),
                color: AppColors.textPrimary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Cari nama apotek atau nomor pesanan...',
              hintStyle: TextStyle(
                color: AppColors.textSubtle,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: _filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.white : AppColors.textSlate,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSlate, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(customerOrderProvider.notifier).loadAll(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 72,
              color: AppColors.divider,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Pesanan tidak ditemukan'
                  : 'Belum ada pesanan',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba kata kunci lain'
                  : 'Pesananmu akan muncul di sini',
              style: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
