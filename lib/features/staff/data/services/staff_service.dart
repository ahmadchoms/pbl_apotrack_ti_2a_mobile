import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import 'package:mobile/core/models/audit_log.dart';
import 'package:mobile/core/models/medicine.dart';
import 'package:mobile/core/models/order.dart';
import 'package:mobile/core/models/customer_address.dart';
import 'order_service.dart';
import 'medicine_service.dart';
import 'audit_service.dart';
import 'profile_service.dart';
import 'address_service.dart';

class StaffService {
  final StaffOrderService _orderService;
  final StaffMedicineService _medicineService;
  final StaffAuditService _auditService;
  final StaffProfileService _profileService;
  final StaffAddressService _addressService;

  StaffService({
    required StaffOrderService orderService,
    required StaffMedicineService medicineService,
    required StaffAuditService auditService,
    required StaffProfileService profileService,
    required StaffAddressService addressService,
  })  : _orderService = orderService,
        _medicineService = medicineService,
        _auditService = auditService,
        _profileService = profileService,
        _addressService = addressService;

  // --- PESANAN (ORDERS) ---
  Future<List<Order>> getOrders({Map<String, dynamic>? queryParams}) =>
      _orderService.getOrders(queryParams: queryParams);

  Future<Order> getOrderDetail(String orderId) =>
      _orderService.getOrderDetail(orderId);

  Future<void> updateOrderStatus(String orderId, String status) =>
      _orderService.updateOrderStatus(orderId, status);

  Future<void> shipOrder(String orderId) =>
      _orderService.shipOrder(orderId);

  Future<void> simulateTracking(String orderId, String status) =>
      _orderService.simulateTracking(orderId, status);

  Future<Order> verifyOrderByCode(String verificationCode) =>
      _orderService.verifyOrderByCode(verificationCode);

  Future<void> approveCancellation(String orderId) =>
      _orderService.approveCancellation(orderId);

  Future<void> rejectCancellation(String orderId) =>
      _orderService.rejectCancellation(orderId);

  Future<Order> storePosOrder(Map<String, dynamic> payload) =>
      _orderService.storePosOrder(payload);

  // --- INVENTARIS (MEDICINES) ---
  Future<List<Medicine>> getMedicines({Map<String, dynamic>? queryParams}) =>
      _medicineService.getMedicines(queryParams: queryParams);

  Future<Medicine> getMedicine(String id) =>
      _medicineService.getMedicine(id);

  Future<Medicine> createMedicine(dynamic payload) =>
      _medicineService.createMedicine(payload);

  Future<Medicine> updateMedicine(String id, dynamic payload) =>
      _medicineService.updateMedicine(id, payload);

  Future<void> updateStock(String medicineId, Map<String, dynamic> payload) =>
      _medicineService.updateStock(medicineId, payload);

  Future<void> deleteMedicine(String id) =>
      _medicineService.deleteMedicine(id);

  // --- AUDITS & LOGS ---
  Future<List<AuditLog>> getAudits({Map<String, dynamic>? queryParams}) =>
      _auditService.getAudits(queryParams: queryParams);

  Future<List<AuditLog>> fetchAuditLogs({Map<String, dynamic>? queryParams}) =>
      _auditService.getAudits(queryParams: queryParams);

  // --- PROFIL & KEAMANAN ---
  Future<UserModel> getProfile() => _profileService.getProfile();

  Future<UserModel> updateProfile({
    required String username,
    required String email,
    String? phone,
    dynamic imageFile,
  }) =>
      _profileService.updateProfile(
        username: username,
        email: email,
        phone: phone,
        imageFile: imageFile,
      );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _profileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  Future<void> logout() => _profileService.logout();

  // --- ALAMAT ---
  Future<List<CustomerAddress>> getAddresses() => _addressService.getAddresses();

  Future<CustomerAddress> addAddress({
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) =>
      _addressService.addAddress(
        label: label,
        addressDetail: addressDetail,
        latitude: latitude,
        longitude: longitude,
        isPrimary: isPrimary,
      );

  Future<CustomerAddress> updateAddress({
    required String id,
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) =>
      _addressService.updateAddress(
        id: id,
        label: label,
        addressDetail: addressDetail,
        latitude: latitude,
        longitude: longitude,
        isPrimary: isPrimary,
      );

  Future<void> setPrimaryAddress(String id) => _addressService.setPrimaryAddress(id);

  Future<void> deleteAddress(String id) => _addressService.deleteAddress(id);
}

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(
    orderService: ref.watch(staffOrderServiceProvider),
    medicineService: ref.watch(staffMedicineServiceProvider),
    auditService: ref.watch(staffAuditServiceProvider),
    profileService: ref.watch(staffProfileServiceProvider),
    addressService: ref.watch(staffAddressServiceProvider),
  );
});