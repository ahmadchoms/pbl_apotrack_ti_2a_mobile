import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/staff/data/models/audit_log.dart';
import '../../data/services/staff_service.dart';
import '../../data/models/medicine.dart';
import '../../data/models/order.dart';

// ─────────────────────────────────────────────
// STATE: Sort & Filter untuk Inventory
// ─────────────────────────────────────────────

enum MedicineSortBy {
  nameAsc,
  nameDesc,
  stockAsc,
  stockDesc,
  priceAsc,
  priceDesc,
}

class InventoryFilterState {
  final String stockFilter; // 'Semua', 'Stok Kritis', 'Stok Rendah', 'Normal'
  final String categoryFilter; // 'Semua' atau nama kategori
  final MedicineSortBy sortBy;

  const InventoryFilterState({
    this.stockFilter = 'Semua',
    this.categoryFilter = 'Semua',
    this.sortBy = MedicineSortBy.nameAsc,
  });

  InventoryFilterState copyWith({
    String? stockFilter,
    String? categoryFilter,
    MedicineSortBy? sortBy,
  }) {
    return InventoryFilterState(
      stockFilter: stockFilter ?? this.stockFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class InventoryFilterNotifier extends StateNotifier<InventoryFilterState> {
  InventoryFilterNotifier() : super(const InventoryFilterState());

  void setStockFilter(String f) => state = state.copyWith(stockFilter: f);
  void setCategoryFilter(String f) => state = state.copyWith(categoryFilter: f);
  void setSortBy(MedicineSortBy s) => state = state.copyWith(sortBy: s);
  void reset() => state = const InventoryFilterState();
}

final inventoryFilterProvider =
    StateNotifierProvider<InventoryFilterNotifier, InventoryFilterState>(
      (ref) => InventoryFilterNotifier(),
    );

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

/// Provider untuk mengambil daftar pesanan staf secara asinkron.
final staffOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final service = ref.watch(staffServiceProvider);
  return service.getOrders();
});

/// Provider untuk mengambil daftar obat staf secara asinkron.
final staffMedicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  final service = ref.watch(staffServiceProvider);
  return service.getMedicines();
});

/// Provider untuk mengambil daftar obat + menerapkan filter & sorting secara lokal.
final filteredMedicinesProvider = Provider<AsyncValue<List<Medicine>>>((ref) {
  final medicinesAsync = ref.watch(staffMedicinesProvider);
  final filter = ref.watch(inventoryFilterProvider);

  return medicinesAsync.whenData((medicines) {
    var result = List<Medicine>.from(medicines);

    // Filter kategori
    if (filter.categoryFilter != 'Semua') {
      result = result
          .where((m) => m.category == filter.categoryFilter)
          .toList();
    }

    // Filter stok
    result = result.where((m) {
      final stock = m.totalActiveStock;
      return switch (filter.stockFilter) {
        'Stok Kritis' => stock <= 10,
        'Stok Rendah' => stock <= 20 && stock > 10,
        'Normal' => stock > 20,
        _ => true,
      };
    }).toList();

    // Sorting
    result.sort((a, b) {
      return switch (filter.sortBy) {
        MedicineSortBy.nameAsc => a.name.compareTo(b.name),
        MedicineSortBy.nameDesc => b.name.compareTo(a.name),
        MedicineSortBy.stockAsc => a.totalActiveStock.compareTo(
          b.totalActiveStock,
        ),
        MedicineSortBy.stockDesc => b.totalActiveStock.compareTo(
          a.totalActiveStock,
        ),
        MedicineSortBy.priceAsc => a.price.compareTo(b.price),
        MedicineSortBy.priceDesc => b.price.compareTo(a.price),
      };
    });

    return result;
  });
});

/// Ekstrak daftar kategori unik dari data obat untuk digunakan di filter sheet.
final medicineCategoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(staffMedicinesProvider).whenData((medicines) {
    final cats = <String>{'Semua'};
    for (final m in medicines) {
      if (m.category != null && m.category!.isNotEmpty) {
        cats.add(m.category!);
      }
    }
    return cats.toList();
  });
});

/// Provider untuk mengambil riwayat aktivitas staf secara asinkron.
final staffAuditsProvider = FutureProvider<List<AuditLog>>((ref) async {
  final service = ref.watch(staffServiceProvider);
  return service.getAudits();
});
