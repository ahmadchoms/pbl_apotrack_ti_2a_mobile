import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log.dart';
import '../models/medicine.dart';
import '../models/order.dart';
import '../repositories/staff_repository.dart';

/// Service untuk menangani logika bisnis fitur Staf.
/// Menggunakan StaffRepository untuk komunikasi data mentah dengan API.
class StaffService {
  final StaffRepository _repository;

  StaffService(this._repository);

  // --- PESANAN (ORDERS) ---

  Future<List<Order>> getOrders({Map<String, dynamic>? queryParams}) async {
    final response = await _repository.getOrders(queryParams);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> getOrderDetail(String orderId) async {
    final response = await _repository.getOrderDetail(orderId);
    return Order.fromJson(response.data['data']);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _repository.updateOrderStatus(orderId, status);
  }

  Future<void> shipOrder(String orderId, String courierCode, String courierService) async {
    await _repository.shipOrder(orderId, courierCode, courierService);
  }

  Future<Order> verifyOrderByCode(String verificationCode) async {
    final response = await _repository.verifyOrderByCode(verificationCode);
    return Order.fromJson(response.data['data']);
  }

  // --- INVENTARIS (MEDICINES) ---

  Future<List<Medicine>> getMedicines({Map<String, dynamic>? queryParams}) async {
    final response = await _repository.getMedicines(queryParams);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => Medicine.fromJson(e)).toList();
  }

  Future<Medicine> getMedicine(String id) async {
    final response = await _repository.getMedicineDetail(id);
    return Medicine.fromJson(response.data['data']);
  }

  Future<Medicine> createMedicine(dynamic payload) async {
    final response = await _repository.createMedicine(payload);
    return Medicine.fromJson(response.data['data']);
  }

  Future<Medicine> updateMedicine(String id, dynamic payload) async {
    final response = await _repository.updateMedicine(id, payload);
    return Medicine.fromJson(response.data['data']);
  }

  Future<void> updateStock(String medicineId, Map<String, dynamic> payload) async {
    await _repository.updateStock(medicineId, payload);
  }

  Future<void> deleteMedicine(String id) async {
    await _repository.deleteMedicine(id);
  }

  // --- POINT OF SALE (POS) ---

  Future<void> storePosOrder(Map<String, dynamic> payload) async {
    await _repository.storePosOrder(payload);
  }

  // --- PROFIL & KEAMANAN ---

  Future<Map<String, dynamic>> updateProfile(dynamic payload) async {
    final response = await _repository.updateProfile(payload);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> changePassword(Map<String, dynamic> payload) async {
    await _repository.changePassword(payload);
  }

  // --- AUDITS & LOGS ---

  Future<List<AuditLog>> getAudits({Map<String, dynamic>? queryParams}) async {
    final response = await _repository.getAudits(queryParams);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => AuditLog.fromJson(e)).toList();
  }

  Future<List<AuditLog>> fetchAuditLogs({Map<String, dynamic>? queryParams}) async {
    final response = await _repository.getAudits(queryParams);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => AuditLog.fromJson(e)).toList();
  }
}

final staffServiceProvider = Provider<StaffService>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return StaffService(repository);
});
