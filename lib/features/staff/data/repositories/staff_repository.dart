import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_repository.dart';
import 'medicine_repository.dart';
import 'audit_repository.dart';
import 'profile_repository.dart';
import 'address_repository.dart';

class StaffRepository {
  final StaffOrderRepository _orderRepo;
  final StaffMedicineRepository _medicineRepo;
  final StaffAuditRepository _auditRepo;
  final StaffProfileRepository _profileRepo;
  final StaffAddressRepository _addressRepo;

  StaffRepository({
    required StaffOrderRepository orderRepo,
    required StaffMedicineRepository medicineRepo,
    required StaffAuditRepository auditRepo,
    required StaffProfileRepository profileRepo,
    required StaffAddressRepository addressRepo,
  })  : _orderRepo = orderRepo,
        _medicineRepo = medicineRepo,
        _auditRepo = auditRepo,
        _profileRepo = profileRepo,
        _addressRepo = addressRepo;

  // --- PESANAN (ORDERS) ---
  Future<Response> getOrders(Map<String, dynamic>? queryParams) =>
      _orderRepo.getOrders(queryParams);

  Future<Response> getOrderDetail(String id) =>
      _orderRepo.getOrderDetail(id);

  Future<Response> updateOrderStatus(String id, String status) =>
      _orderRepo.updateOrderStatus(id, status);

  Future<Response> shipOrder(String id) =>
      _orderRepo.shipOrder(id);

  Future<Response> simulateTracking(String id, String status) =>
      _orderRepo.simulateTracking(id, status);

  Future<Response> verifyOrderByCode(String verificationCode) =>
      _orderRepo.verifyOrderByCode(verificationCode);

  Future<Response> approveCancellation(String id) =>
      _orderRepo.approveCancellation(id);

  Future<Response> rejectCancellation(String id) =>
      _orderRepo.rejectCancellation(id);

  Future<Response> storePosOrder(Map<String, dynamic> data) =>
      _orderRepo.storePosOrder(data);

  // --- INVENTARIS (MEDICINES) ---
  Future<Response> getMedicines(Map<String, dynamic>? queryParams) =>
      _medicineRepo.getMedicines(queryParams);

  Future<Response> getMedicineDetail(String id) =>
      _medicineRepo.getMedicineDetail(id);

  Future<Response> createMedicine(dynamic data) =>
      _medicineRepo.createMedicine(data);

  Future<Response> updateMedicine(String id, dynamic data) =>
      _medicineRepo.updateMedicine(id, data);

  Future<Response> updateStock(String id, Map<String, dynamic> data) =>
      _medicineRepo.updateStock(id, data);

  Future<Response> deleteMedicine(String id) =>
      _medicineRepo.deleteMedicine(id);

  // --- AUDITS & LOGS ---
  Future<Response> getAudits(Map<String, dynamic>? queryParams) =>
      _auditRepo.getAudits(queryParams);

  // --- PROFIL & KEAMANAN ---
  Future<Response> fetchMe() => _profileRepo.fetchMe();

  Future<Response> updateProfile(dynamic data) => _profileRepo.updateProfile(data);

  Future<Response> changePassword(Map<String, dynamic> data) =>
      _profileRepo.changePassword(data);

  Future<Response> logout() => _profileRepo.logout();

  // --- ALAMAT ---
  Future<Response> getAddresses() => _addressRepo.getAddresses();

  Future<Response> addAddress(Map<String, dynamic> data) =>
      _addressRepo.addAddress(data);

  Future<Response> updateAddress(String id, Map<String, dynamic> data) =>
      _addressRepo.updateAddress(id, data);

  Future<Response> setPrimaryAddress(String id) =>
      _addressRepo.setPrimaryAddress(id);

  Future<Response> deleteAddress(String id) => _addressRepo.deleteAddress(id);
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(
    orderRepo: ref.watch(staffOrderRepositoryProvider),
    medicineRepo: ref.watch(staffMedicineRepositoryProvider),
    auditRepo: ref.watch(staffAuditRepositoryProvider),
    profileRepo: ref.watch(staffProfileRepositoryProvider),
    addressRepo: ref.watch(staffAddressRepositoryProvider),
  );
});