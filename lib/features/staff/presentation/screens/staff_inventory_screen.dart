import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/staff_provider.dart';
import '../widgets/medicine_inventory_card.dart';
import '../../data/models/medicine.dart';

class StaffInventoryScreen extends ConsumerStatefulWidget {
  const StaffInventoryScreen({super.key});

  @override
  ConsumerState<StaffInventoryScreen> createState() => _StaffInventoryScreenState();
}

class _StaffInventoryScreenState extends ConsumerState<StaffInventoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Terapkan pencarian teks lokal di atas data yang sudah difilter/sort oleh provider
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
    final filteredAsync = ref.watch(filteredMedicinesProvider);
    final rawAsync = ref.watch(staffMedicinesProvider);
    final filterState = ref.watch(inventoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: rawAsync.when(
        data: (allMedicines) {
          final criticalCount = allMedicines.where((m) => m.totalActiveStock <= 10).length;
          final lowStockCount = allMedicines.where((m) {
            final s = m.totalActiveStock;
            return s <= 20 && s > 10;
          }).length;

          final displayList = filteredAsync.whenOrNull(data: (d) => _applySearch(d)) ?? [];

          return Column(
            children: [
              _buildHeader(allMedicines.length),
              if (criticalCount > 0 || lowStockCount > 0)
                _buildAlertBanner(criticalCount, lowStockCount),
              _buildSearchAndFilter(filterState),
              _buildStatRow(displayList.length, filterState),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(staffMedicinesProvider.future),
                  child: _buildList(displayList),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(err.toString()),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 64),
            const SizedBox(height: 16),
            const Text('Gagal Memuat Inventori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(staffMedicinesProvider),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    final filterState = ref.watch(inventoryFilterProvider);
    return Container(
      decoration: const BoxDecoration(color: AppColors.primary),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stok Obat', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  Text('$count produk terdaftar', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
              const Spacer(),
              _buildHeaderIcon(Icons.filter_list_rounded, () => _showFilterSheet(context)),
              const SizedBox(width: 8),
              _buildHeaderIcon(Icons.sort_rounded, () => _showSortSheet(context, filterState.sortBy)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 18), onPressed: onTap, padding: EdgeInsets.zero),
    );
  }

  Widget _buildAlertBanner(int criticalCount, int lowStockCount) {
    final isCritical = criticalCount > 0;
    return GestureDetector(
      onTap: () => ref.read(inventoryFilterProvider.notifier).setStockFilter(isCritical ? 'Stok Kritis' : 'Stok Rendah'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCritical ? AppColors.dangerLight : AppColors.warningLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCritical ? AppColors.danger.withOpacity(0.3) : AppColors.warning.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(isCritical ? Icons.error_outline_rounded : Icons.warning_amber_rounded, color: isCritical ? AppColors.danger : AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isCritical ? '$criticalCount produk hampir habis!' : '$lowStockCount produk stok rendah.',
                style: TextStyle(color: isCritical ? AppColors.danger : AppColors.warning, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isCritical ? AppColors.danger : AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(InventoryFilterState filterState) {
    final stockFilters = ['Semua', 'Stok Kritis', 'Stok Rendah', 'Normal'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 3))],
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kategori obat...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stockFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _buildFilterChip(stockFilters[i], filterState.stockFilter,
                  onTap: () => ref.read(inventoryFilterProvider.notifier).setStockFilter(stockFilters[i])),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selected, {required VoidCallback onTap}) {
    final isSelected = selected == label;
    Color chipColor = AppColors.primary;
    if (label == 'Stok Kritis') chipColor = AppColors.danger;
    else if (label == 'Stok Rendah') chipColor = AppColors.warning;
    else if (label == 'Normal') chipColor = AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor : AppColors.divider, width: 1.5),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textMid, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  Widget _buildStatRow(int count, InventoryFilterState filterState) {
    final sortLabel = _getSortLabel(filterState.sortBy);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Text('$count produk ditemukan', style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.sort_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(sortLabel, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _getSortLabel(MedicineSortBy sort) {
    return switch (sort) {
      MedicineSortBy.nameAsc   => 'A–Z',
      MedicineSortBy.nameDesc  => 'Z–A',
      MedicineSortBy.stockAsc  => 'Stok ↑',
      MedicineSortBy.stockDesc => 'Stok ↓',
      MedicineSortBy.priceAsc  => 'Harga ↑',
      MedicineSortBy.priceDesc => 'Harga ↓',
    };
  }

  Widget _buildList(List<Medicine> medicines) {
    if (medicines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSubtle),
            SizedBox(height: 12),
            Text('Tidak ada obat ditemukan', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: medicines.length,
      itemBuilder: (_, i) {
        final med = medicines[i];
        return MedicineInventoryCard(
          medicine: med,
          onTap: () => context.push(AppRouter.staffMedicineDetail, extra: med),
          onEdit: () => context.push(AppRouter.staffMedicineForm, extra: med),
          formatRupiah: _formatRupiah,
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    final categoriesAsync = ref.read(medicineCategoriesProvider);
    final categories = categoriesAsync.whenOrNull(data: (d) => d) ?? ['Semua'];
    final filterState = ref.read(inventoryFilterProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              const SizedBox(height: 20),

              // Filter Stok
              const Text('STATUS STOK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textLight, letterSpacing: 1)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ['Semua', 'Stok Kritis', 'Stok Rendah', 'Normal'].map((f) => _buildFilterChip(f, filterState.stockFilter,
                  onTap: () { ref.read(inventoryFilterProvider.notifier).setStockFilter(f); setSheetState(() {}); },
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Filter Kategori
              const Text('KATEGORI OBAT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textLight, letterSpacing: 1)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: categories.map((c) => _buildFilterChip(c, filterState.categoryFilter,
                  onTap: () { ref.read(inventoryFilterProvider.notifier).setCategoryFilter(c); setSheetState(() {}); },
                )).toList(),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () { ref.read(inventoryFilterProvider.notifier).reset(); Navigator.pop(ctx); },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(label: 'Terapkan', onPressed: () => Navigator.pop(ctx)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context, MedicineSortBy current) {
    final options = [
      (MedicineSortBy.nameAsc,   'Nama A–Z',       Icons.sort_by_alpha_rounded),
      (MedicineSortBy.nameDesc,  'Nama Z–A',       Icons.sort_by_alpha_rounded),
      (MedicineSortBy.stockAsc,  'Stok Terkecil',  Icons.arrow_upward_rounded),
      (MedicineSortBy.stockDesc, 'Stok Terbesar',  Icons.arrow_downward_rounded),
      (MedicineSortBy.priceAsc,  'Harga Termurah', Icons.arrow_upward_rounded),
      (MedicineSortBy.priceDesc, 'Harga Termahal', Icons.arrow_downward_rounded),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Urutkan Berdasarkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ...options.map((o) {
              final isActive = current == o.$1;
              return ListTile(
                leading: Icon(o.$3, color: isActive ? AppColors.primary : AppColors.textLight, size: 20),
                title: Text(o.$2, style: TextStyle(fontWeight: isActive ? FontWeight.w900 : FontWeight.w600, color: isActive ? AppColors.primary : AppColors.textDark)),
                trailing: isActive ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isActive ? AppColors.primaryLight : Colors.transparent,
                onTap: () {
                  ref.read(inventoryFilterProvider.notifier).setSortBy(o.$1);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => context.push(AppRouter.staffMedicineForm),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('Tambah Produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}

String _formatRupiah(num value) {
  final str = value.toStringAsFixed(0);
  final buf = StringBuffer();
  final len = str.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return 'Rp ${buf.toString()}';
}
