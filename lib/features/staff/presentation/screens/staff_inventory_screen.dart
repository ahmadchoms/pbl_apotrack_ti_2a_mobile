import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../providers/staff_provider.dart';
import '../widgets/medicine_inventory_card.dart';
import '../../data/models/medicine.dart';
import 'medicine_detail_screen.dart';
import 'medicine_form_screen.dart';

class StaffInventoryScreen extends ConsumerStatefulWidget {
  const StaffInventoryScreen({super.key});

  @override
  ConsumerState<StaffInventoryScreen> createState() =>
      _StaffInventoryScreenState();
}

class _StaffInventoryScreenState extends ConsumerState<StaffInventoryScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(staffMedicinesProvider.notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Medicine> _applySearch(List<Medicine> medicines) {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return medicines;
    return medicines.where((m) {
      final name = m.name.toLowerCase();
      final catName = (m.category ?? '').toLowerCase();
      return name.contains(q) || catName.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = ref.watch(filteredMedicinesProvider);
    final state = ref.watch(staffMedicinesProvider);
    final filterState = ref.watch(inventoryFilterProvider);
    final displayList = _applySearch(filteredList);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildFixedHeader(state.items.length),
          _buildInsightSection(state.items),
          _buildSearchSection(filterState),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.read(staffMedicinesProvider.notifier).refresh(),
              color: AppColors.primary,
              child: _buildScrollableList(displayList, state),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildModernFab(),
    );
  }

  Widget _buildFixedHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MANAJEMEN STOK',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inventori Produk',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildHeaderAction(Icons.sort_rounded, () => _showSortSheet(context)),
          const SizedBox(width: 8),
          _buildHeaderAction(
            Icons.tune_rounded,
            () => _showFilterSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInsightSection(List<Medicine> medicines) {
    final critical = medicines.where((m) => m.totalActiveStock <= 10).length;

    final low = medicines
        .where((m) => m.totalActiveStock <= 20 && m.totalActiveStock > 10)
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildInsightCard(
              'Total Produk',
              medicines.length.toString(),
              Icons.analytics_outlined,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInsightCard(
              'Stok Kritis',
              critical.toString(),
              Icons.bolt_rounded,
              AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInsightCard(
              'Stok Rendah',
              low.toString(),
              Icons.low_priority_rounded,
              AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              Icon(icon, color: color.withOpacity(0.3), size: 20),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(InventoryFilterState filterState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Cari nama atau kategori obat...',
            hintStyle: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.textSubtle,
                      size: 20,
                    ),
                    onPressed: () => _searchCtrl.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableList(List<Medicine> medicines, dynamic state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (medicines.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: AppColors.divider,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Data tidak ditemukan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: medicines.length + (state.isLoadingNextPage ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == medicines.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final med = medicines[i];
        return MedicineInventoryCard(
          medicine: med,
          onTap: () => context.push(AppRouter.staffMedicineDetail, extra: med),
          onEdit: () => context.push(AppRouter.staffMedicineForm, extra: med),
          formatRupiah: (val) {
            final str = val.toStringAsFixed(0);
            final buf = StringBuffer();
            for (int i = 0; i < str.length; i++) {
              if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
              buf.write(str[i]);
            }
            return 'Rp ${buf.toString()}';
          },
        );
      },
    );
  }

  Widget _buildModernFab() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 10),
      child: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.staffMedicineForm),
        backgroundColor: AppColors.primary,
        elevation: 6,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          'TAMBAH PRODUK',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final categories = ref.read(medicineCategoriesProvider);
    final filterState = ref.read(inventoryFilterProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Filter Inventori',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'STATUS KETERSEDIAAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textLight,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Semua', 'Stok Kritis', 'Stok Rendah', 'Normal']
                    .map(
                      (s) => _buildChoiceChip(
                        s,
                        filterState.stockFilter == s,
                        onSelected: (val) {
                          ref
                              .read(inventoryFilterProvider.notifier)
                              .setStockFilter(s);
                          setSheetState(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'KATEGORI PRODUK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textLight,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                // maxHeight: 200,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories
                        .map(
                          (c) => _buildChoiceChip(
                            c,
                            filterState.categoryFilter == c,
                            onSelected: (val) {
                              ref
                                  .read(inventoryFilterProvider.notifier)
                                  .setCategoryFilter(c);
                              setSheetState(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        ref.read(inventoryFilterProvider.notifier).reset();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

  void _showSortSheet(BuildContext context) {
    final filterState = ref.watch(inventoryFilterProvider);
    final options = [
      (MedicineSortBy.nameAsc, 'Nama (A-Z)', Icons.sort_by_alpha_rounded),
      (MedicineSortBy.nameDesc, 'Nama (Z-A)', Icons.sort_by_alpha_rounded),
      (
        MedicineSortBy.stockAsc,
        'Stok Terendah',
        Icons.keyboard_double_arrow_up_rounded,
      ),
      (
        MedicineSortBy.stockDesc,
        'Stok Tertinggi',
        Icons.keyboard_double_arrow_down_rounded,
      ),
      (MedicineSortBy.priceAsc, 'Harga Termurah', Icons.payments_outlined),
      (MedicineSortBy.priceDesc, 'Harga Termahal', Icons.payments_outlined),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Urutkan Inventori',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            ...options.map((opt) {
              final isSelected = filterState.sortBy == opt.$1;
              return ListTile(
                onTap: () {
                  ref.read(inventoryFilterProvider.notifier).setSortBy(opt.$1);
                  Navigator.pop(ctx);
                },
                leading: Icon(
                  opt.$3,
                  color: isSelected ? AppColors.primary : AppColors.textLight,
                ),
                title: Text(
                  opt.$2,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textDark,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: isSelected
                    ? AppColors.primary.withOpacity(0.05)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    bool selected, {
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textMid,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.divider,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }
}
