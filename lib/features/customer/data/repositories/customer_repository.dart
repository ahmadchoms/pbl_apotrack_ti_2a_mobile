import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pharmacy_repository.dart';
import 'medicine_repository.dart';
import 'order_repository.dart';
import 'address_repository.dart';
import 'profile_repository.dart';

class CustomerRepository {
  final PharmacyRepository _pharmacyRepo;
  final MedicineRepository _medicineRepo;
  final OrderRepository _orderRepo;
  final AddressRepository _addressRepo;
  final ProfileRepository _profileRepo;

  CustomerRepository({
    required PharmacyRepository pharmacyRepo,
    required MedicineRepository medicineRepo,
    required OrderRepository orderRepo,
    required AddressRepository addressRepo,
    required ProfileRepository profileRepo,
  })  : _pharmacyRepo = pharmacyRepo,
        _medicineRepo = medicineRepo,
        _orderRepo = orderRepo,
        _addressRepo = addressRepo,
        _profileRepo = profileRepo;

  // ── Order methods ────────────────────────────────────────────
  Future<Response> getCustomerOrders(Map<String, dynamic>? queryParams) =>
      _orderRepo.getCustomerOrders(queryParams);

  Future<Response> getCustomerOrderHistory(Map<String, dynamic>? queryParams) =>
      _orderRepo.getCustomerOrderHistory(queryParams);

  Future<Response> getCustomerOrderDetail(String id) =>
      _orderRepo.getCustomerOrderDetail(id);

  Future<Response> simulatePayment(String id) => _orderRepo.simulatePayment(id);

  Future<Response> requestCancellation(String id, String reason) =>
      _orderRepo.requestCancellation(id, reason);

  Future<Response> confirmReceived(String id) => _orderRepo.confirmReceived(id);

  Future<Response> createOrder(Map<String, dynamic> data) =>
      _orderRepo.createOrder(data);

  Future<Response> uploadPrescription(String orderId, FormData data) =>
      _orderRepo.uploadPrescription(orderId, data);

  Future<Response> submitReview(Map<String, dynamic> data) =>
      _orderRepo.submitReview(data);

  // ── Profile methods ──────────────────────────────────────────
  Future<Response> fetchMe() => _profileRepo.fetchMe();

  Future<Response> updateProfile(dynamic data) => _profileRepo.updateProfile(data);

  Future<Response> changePassword(Map<String, dynamic> data) =>
      _profileRepo.changePassword(data);

  Future<Response> logout() => _profileRepo.logout();

  Future<Response> joinStaffByInvitation(String invitationUrl) =>
      _profileRepo.joinStaffByInvitation(invitationUrl);

  Future<Response> joinStaffByPin(String pin) => _profileRepo.joinStaffByPin(pin);

  // ── Address methods ──────────────────────────────────────────
  Future<Response> getAddresses() => _addressRepo.getAddresses();

  Future<Response> addAddress(Map<String, dynamic> data) =>
      _addressRepo.addAddress(data);

  Future<Response> updateAddress(String id, Map<String, dynamic> data) =>
      _addressRepo.updateAddress(id, data);

  Future<Response> setPrimaryAddress(String id) =>
      _addressRepo.setPrimaryAddress(id);

  Future<Response> deleteAddress(String id) => _addressRepo.deleteAddress(id);

  // ── Pharmacy and Medicine methods ────────────────────────────
  Future<Response> getPharmacies({
    String? search,
    double? latitude,
    double? longitude,
    double? radius,
    String? categoryId,
  }) =>
      _pharmacyRepo.getPharmacies(
        search: search,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        categoryId: categoryId,
      );

  Future<Response> getPharmacyDetail(String id) =>
      _pharmacyRepo.getPharmacyDetail(id);

  Future<Response> getMedicines({
    required String pharmacyId,
    String? categoryId,
    String? search,
  }) =>
      _medicineRepo.getMedicines(
        pharmacyId: pharmacyId,
        categoryId: categoryId,
        search: search,
      );

  Future<Response> getCategories() => _medicineRepo.getCategories();

  Future<Response> getPopularCategories() => _medicineRepo.getPopularCategories();
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
    pharmacyRepo: ref.watch(pharmacyRepositoryProvider),
    medicineRepo: ref.watch(medicineRepositoryProvider),
    orderRepo: ref.watch(orderRepositoryProvider),
    addressRepo: ref.watch(addressRepositoryProvider),
    profileRepo: ref.watch(profileRepositoryProvider),
  );
});
