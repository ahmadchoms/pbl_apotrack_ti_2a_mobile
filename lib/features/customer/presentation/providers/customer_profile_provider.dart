import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/secure_storage_service.dart';
import '../../data/models/cart.dart';
import '../../data/models/customer_profile.dart';
import '../../data/models/customer_address.dart';
import '../../data/services/customer_service.dart';

class CustomerProfileState {
  const CustomerProfileState({
    this.profile,
    this.addresses = const [],
    this.isLoading = false,
    this.error,
  });

  final CustomerProfile? profile;
  final List<CustomerAddress> addresses;
  final bool isLoading;
  final String? error;

  CustomerProfileState copyWith({
    CustomerProfile? profile,
    List<CustomerAddress>? addresses,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CustomerProfileState(
      profile: profile ?? this.profile,
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CustomerProfileNotifier extends StateNotifier<CustomerProfileState> {
  CustomerProfileNotifier(this._service, this._storage)
    : super(const CustomerProfileState());

  final CustomerService _service;
  final SecureStorageService _storage;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _service.getProfile();
      final addresses = await _service.getAddresses();
      state = state.copyWith(
        profile: profile,
        addresses: addresses,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      print('[Provider] loadAll error: $e');
      print('Stack: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat data: ${e.toString()}',
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
      username: username,
      email: email,
      phone: phone,
      imageFile: imageFile,
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
      label: label,
      addressDetail: addressDetail,
      latitude: latitude,
      longitude: longitude,
      isPrimary: isPrimary,
    );

    final updated = isPrimary
        ? state.addresses
              .map(
                (a) => CustomerAddress(
                  id: a.id,
                  label: a.label,
                  addressDetail: a.addressDetail,
                  completeAddress: a.completeAddress,
                  latitude: a.latitude,
                  longitude: a.longitude,
                  isPrimary: false,
                ),
              )
              .toList()
        : List<CustomerAddress>.from(state.addresses);

    updated.add(newAddr);
    state = state.copyWith(addresses: updated);
    return newAddr;
  }

  Future<CustomerAddress> updateAddress({
    required String id,
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    try {
      final updated = await _service.updateAddress(
        id: id,
        label: label,
        addressDetail: addressDetail,
        latitude: latitude,
        longitude: longitude,
        isPrimary: isPrimary,
      );

      state = state.copyWith(
        addresses: state.addresses.map((a) {
          if (a.id == id) return updated;
          if (isPrimary && a.isPrimary) {
            return CustomerAddress(
              id: a.id,
              label: a.label,
              addressDetail: a.addressDetail,
              completeAddress: a.completeAddress,
              latitude: a.latitude,
              longitude: a.longitude,
              isPrimary: false,
            );
          }
          return a;
        }).toList(),
      );
      return updated;
    } catch (e, stackTrace) {
      print('[Provider] updateAddress error: $e');
      print('Stack: $stackTrace');
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
      print('[Provider] Alamat ID $id berhasil dijadikan utama');
    } catch (e, stackTrace) {
      print('[Provider] setPrimaryAddress error: $e');
      print('Stack: $stackTrace');
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
      print('[Provider] Alamat ID $id berhasil dihapus');
    } catch (e, stackTrace) {
      print('[Provider] deleteAddress error: $e');
      print('Stack: $stackTrace');
      state = state.copyWith(
        error: 'Gagal menghapus alamat: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _service.logout();
    } catch (e) {
      print('[Provider] logout API error: $e');
    } finally {
      try {
        await _storage.clearAll();
      } catch (e) {
        print('[Provider] clearAll error: $e');
      }
      CartState().items.clear();
      state = const CustomerProfileState();
    }
  }
}

final customerProfileProvider =
    StateNotifierProvider<CustomerProfileNotifier, CustomerProfileState>((ref) {
      final service = ref.watch(customerServiceProvider);
      final storage = ref.watch(secureStorageServiceProvider);
      return CustomerProfileNotifier(service, storage);
    });