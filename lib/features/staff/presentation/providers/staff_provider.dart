import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/secure_storage_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/audit_log.dart';
import '../../data/models/medicine.dart';
import '../../data/models/order.dart';
import '../../data/services/staff_service.dart';
import '../../../customer/data/models/customer_address.dart';

// ─────────────────────────────────────────────
// Inventory Filter
// ─────────────────────────────────────────────

enum MedicineSortBy {
  nameAsc, nameDesc, stockAsc, stockDesc, priceAsc, priceDesc,
}

class InventoryFilterState {
  final String stockFilter;
  final String categoryFilter;
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
// Pagination
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
      final newItems = await service.getMedicines(
          queryParams: {'page': 1, 'per_page': _perPage});
      state = state.copyWith(
        items: newItems, isLoading: false,
        page: 1, hasMore: newItems.length >= _perPage,
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
      final newItems = await service.getMedicines(
          queryParams: {'page': nextPage, 'per_page': _perPage});
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

  void refresh() => fetchFirstPage();
}

final staffOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final service = ref.watch(staffServiceProvider);
  return service.getOrders();
});

final staffMedicinesProvider =
    StateNotifierProvider<StaffMedicinesNotifier, PaginationState<Medicine>>(
        (ref) => StaffMedicinesNotifier(ref));

final filteredMedicinesProvider = Provider<List<Medicine>>((ref) {
  final medicinesState = ref.watch(staffMedicinesProvider);
  final filter = ref.watch(inventoryFilterProvider);
  var result = List<Medicine>.from(medicinesState.items);

  if (filter.categoryFilter != 'Semua') {
    result = result.where((m) => m.category == filter.categoryFilter).toList();
  }

  result = result.where((m) {
    final stock = m.totalActiveStock;
    return switch (filter.stockFilter) {
      'Stok Kritis' => stock <= 10,
      'Stok Rendah' => stock <= 20 && stock > 10,
      'Normal' => stock > 20,
      _ => true,
    };
  }).toList();

  result.sort((a, b) => switch (filter.sortBy) {
    MedicineSortBy.nameAsc  => a.name.compareTo(b.name),
    MedicineSortBy.nameDesc => b.name.compareTo(a.name),
    MedicineSortBy.stockAsc  => a.totalActiveStock.compareTo(b.totalActiveStock),
    MedicineSortBy.stockDesc => b.totalActiveStock.compareTo(a.totalActiveStock),
    MedicineSortBy.priceAsc  => a.price.compareTo(b.price),
    MedicineSortBy.priceDesc => b.price.compareTo(a.price),
  });

  return result;
});

final medicineCategoriesProvider = Provider<List<String>>((ref) {
  final medicinesState = ref.watch(staffMedicinesProvider);
  final cats = <String>{'Semua'};
  for (final m in medicinesState.items) {
    if (m.category != null && m.category!.isNotEmpty) cats.add(m.category!);
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
      final newItems = await service.fetchAuditLogs(
          queryParams: {'page': 1, 'per_page': _perPage});
      state = state.copyWith(
        items: newItems, isLoading: false,
        page: 1, hasMore: newItems.length >= _perPage,
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
      final newItems = await service.fetchAuditLogs(
          queryParams: {'page': nextPage, 'per_page': _perPage});
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

  void refresh() => fetchFirstPage();
}

final staffAuditsProvider =
    StateNotifierProvider<StaffAuditsNotifier, PaginationState<AuditLog>>(
        (ref) => StaffAuditsNotifier(ref));

// ─────────────────────────────────────────────
// PROFILE STATE — bersama Customer & Staff
// ─────────────────────────────────────────────

class ProfileState {
  const ProfileState({
    this.profile,
    this.addresses = const [],
    this.tempGpsAddress,
    this.isLoading = false,
    this.error,
  });

  final UserModel? profile;
  final List<CustomerAddress> addresses;
  final CustomerAddress? tempGpsAddress;
  final bool isLoading;
  final String? error;

  ProfileState copyWith({
    UserModel? profile,
    List<CustomerAddress>? addresses,
    CustomerAddress? tempGpsAddress,
    bool clearTempGpsAddress = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      addresses: addresses ?? this.addresses,
      tempGpsAddress: clearTempGpsAddress ? null : tempGpsAddress ?? this.tempGpsAddress,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._service, this._storage) : super(const ProfileState());

  final StaffService _service;
  final SecureStorageService _storage;

  void clearTempGpsLocation() {
    state = state.copyWith(clearTempGpsAddress: true);
  }

  void updateCurrentGpsLocation({
    required double latitude,
    required double longitude,
    required String addressDetail,
  }) {
    final gpsAddress = CustomerAddress(
      id: 'gps_session',
      label: 'Lokasi Sekarang',
      addressDetail: addressDetail,
      completeAddress: addressDetail,
      latitude: latitude,
      longitude: longitude,
      isPrimary: false,
    );
    state = state.copyWith(tempGpsAddress: gpsAddress, clearTempGpsAddress: false);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _service.getProfile();
      final addresses = profile.isCustomer
          ? await _service.getAddresses()
          : <CustomerAddress>[];
      state = state.copyWith(
        profile: profile, addresses: addresses, isLoading: false,
      );
    } catch (e, s) {
      debugPrint('[ProfileNotifier] loadAll error: $e\n$s');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data: ${e.toString()}',
      );
    }
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _service.getProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e, s) {
      debugPrint('[ProfileNotifier] fetchProfile error: $e\n$s');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat profil: ${e.toString()}',
      );
    }
  }

  Future<void> updateProfile({
    required String username,
    required String email,
    String? phone,
    dynamic imageFile,
  }) async {
    final updated = await _service.updateProfile(
      username: username, email: email,
      phone: phone, imageFile: imageFile,
    );
    state = state.copyWith(profile: updated);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _service.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<CustomerAddress> addAddress({
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    final newAddr = await _service.addAddress(
      label: label, addressDetail: addressDetail,
      latitude: latitude, longitude: longitude, isPrimary: isPrimary,
    );
    final updated = isPrimary
        ? state.addresses.map((a) => CustomerAddress(
              id: a.id, label: a.label, addressDetail: a.addressDetail,
              completeAddress: a.completeAddress, latitude: a.latitude,
              longitude: a.longitude, isPrimary: false,
            )).toList()
        : List<CustomerAddress>.from(state.addresses);
    updated.add(newAddr);
    state = state.copyWith(addresses: updated);
    return newAddr;
  }

  Future<void> updateAddress({
    required String id,
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    try {
      final updated = await _service.updateAddress(
        id: id, label: label, addressDetail: addressDetail,
        latitude: latitude, longitude: longitude, isPrimary: isPrimary,
      );
      state = state.copyWith(
        addresses: state.addresses.map((a) {
          if (a.id == id) return updated;
          if (isPrimary && a.isPrimary) {
            return CustomerAddress(
              id: a.id, label: a.label, addressDetail: a.addressDetail,
              completeAddress: a.completeAddress, latitude: a.latitude,
              longitude: a.longitude, isPrimary: false,
            );
          }
          return a;
        }).toList(),
      );
    } catch (e, s) {
      debugPrint('[ProfileNotifier] updateAddress error: $e\n$s');
      state = state.copyWith(error: 'Gagal mengubah alamat: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> setPrimaryAddress(String id) async {
    try {
      await _service.setPrimaryAddress(id);
      state = state.copyWith(
        addresses: state.addresses.map((a) => CustomerAddress(
          id: a.id,
          label: a.label,
          addressDetail: a.addressDetail,
          completeAddress: a.completeAddress,
          latitude: a.latitude,
          longitude: a.longitude,
          isPrimary: a.id == id,
        )).toList(),
      );
    } catch (e, s) {
      debugPrint('[ProfileNotifier] setPrimaryAddress error: $e\n$s');
      state = state.copyWith(
        error: 'Gagal mengatur alamat utama: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _service.deleteAddress(id);
      state = state.copyWith(
        addresses: state.addresses.where((a) => a.id != id).toList(),
      );
    } catch (e, s) {
      debugPrint('[ProfileNotifier] deleteAddress error: $e\n$s');
      state = state.copyWith(error: 'Gagal menghapus alamat: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _service.logout();
    } catch (e) {
      debugPrint('[ProfileNotifier] logout error: $e');
    } finally {
      try {
        await _storage.clearAll();
      } catch (e) {
        debugPrint('[ProfileNotifier] clearAll error: $e');
      }
      state = const ProfileState();
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final service = ref.watch(staffServiceProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return ProfileNotifier(service, storage);
});