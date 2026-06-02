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
// PAGINATION STATE
// ─────────────────────────────────────────────

class PaginationState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingNextPage;
  final String? error;
  final int page;
  final bool hasMore;

  const PaginationState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingNextPage = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingNextPage,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class StaffMedicinesNotifier extends StateNotifier<PaginationState<Medicine>> {
  final Ref ref;
  static const int _perPage = 15;

  StaffMedicinesNotifier(this.ref) : super(const PaginationState()) {
    fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(staffServiceProvider);
      final newItems = await service.getMedicines(queryParams: {
        'page': 1,
        'per_page': _perPage,
      });
      
      state = state.copyWith(
        items: newItems,
        isLoading: false,
        page: 1,
        hasMore: newItems.length >= _perPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoadingNextPage || state.isLoading) return;

    state = state.copyWith(isLoadingNextPage: true, error: null);
    try {
      final nextPage = state.page + 1;
      final service = ref.read(staffServiceProvider);
      final newItems = await service.getMedicines(queryParams: {
        'page': nextPage,
        'per_page': _perPage,
      });

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoadingNextPage: false,
        page: nextPage,
        hasMore: newItems.length >= _perPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingNextPage: false, error: e.toString());
    }
  }
  
  void refresh() {
    fetchFirstPage();
  }
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

/// Provider untuk mengambil daftar pesanan staf secara asinkron.
final staffOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final service = ref.watch(staffServiceProvider);
  return service.getOrders();
});

/// Provider untuk mengambil daftar obat staf dengan Paginasi.
final staffMedicinesProvider = StateNotifierProvider<StaffMedicinesNotifier, PaginationState<Medicine>>((ref) {
  return StaffMedicinesNotifier(ref);
});

/// Provider untuk mengambil daftar obat + menerapkan filter & sorting secara lokal.
final filteredMedicinesProvider = Provider<List<Medicine>>((ref) {
  final medicinesState = ref.watch(staffMedicinesProvider);
  final filter = ref.watch(inventoryFilterProvider);

  var result = List<Medicine>.from(medicinesState.items);

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
      MedicineSortBy.stockAsc => a.totalActiveStock.compareTo(b.totalActiveStock),
      MedicineSortBy.stockDesc => b.totalActiveStock.compareTo(a.totalActiveStock),
      MedicineSortBy.priceAsc => a.price.compareTo(b.price),
      MedicineSortBy.priceDesc => b.price.compareTo(a.price),
    };
  });

  return result;
});

/// Ekstrak daftar kategori unik dari data obat untuk digunakan di filter sheet.
final medicineCategoriesProvider = Provider<List<String>>((ref) {
  final medicinesState = ref.watch(staffMedicinesProvider);
  final cats = <String>{'Semua'};
  for (final m in medicinesState.items) {
    if (m.category != null && m.category!.isNotEmpty) {
      cats.add(m.category!);
    }
  }
  return cats.toList();
});

class StaffAuditsNotifier extends StateNotifier<PaginationState<AuditLog>> {
  final Ref ref;
  static const int _perPage = 20;

  StaffAuditsNotifier(this.ref) : super(const PaginationState()) {
    fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(staffServiceProvider);
      final newItems = await service.fetchAuditLogs(queryParams: {
        'page': 1,
        'per_page': _perPage,
      });

      state = state.copyWith(
        items: newItems,
        isLoading: false,
        page: 1,
        hasMore: newItems.length >= _perPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoadingNextPage || state.isLoading) return;

    state = state.copyWith(isLoadingNextPage: true, error: null);
    try {
      final nextPage = state.page + 1;
      final service = ref.read(staffServiceProvider);
      final newItems = await service.fetchAuditLogs(queryParams: {
        'page': nextPage,
        'per_page': _perPage,
      });

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoadingNextPage: false,
        page: nextPage,
        hasMore: newItems.length >= _perPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingNextPage: false, error: e.toString());
    }
  }

  void refresh() {
    fetchFirstPage();
  }
}

/// Provider untuk mengelola state riwayat aktivitas staf dengan Paginasi.
final staffAuditsProvider = StateNotifierProvider<StaffAuditsNotifier, PaginationState<AuditLog>>((ref) {
  return StaffAuditsNotifier(ref);
});
