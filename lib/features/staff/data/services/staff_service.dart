import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/audit_log.dart';
import '../models/medicine.dart';
import '../models/order.dart';
import '../repositories/staff_repository.dart';
import '../../../customer/data/models/customer_address.dart';

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

  Future<void> shipOrder(
      String orderId, String courierCode, String courierService) async {
    await _repository.shipOrder(orderId, courierCode, courierService);
  }

  Future<Order> verifyOrderByCode(String verificationCode) async {
    final response = await _repository.verifyOrderByCode(verificationCode);
    return Order.fromJson(response.data['data']);
  }

  // --- INVENTARIS (MEDICINES) ---

  Future<List<Medicine>> getMedicines(
      {Map<String, dynamic>? queryParams}) async {
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

  Future<void> updateStock(
      String medicineId, Map<String, dynamic> payload) async {
    await _repository.updateStock(medicineId, payload);
  }

  Future<void> deleteMedicine(String id) async {
    await _repository.deleteMedicine(id);
  }

  // --- POINT OF SALE (POS) ---

  Future<void> storePosOrder(Map<String, dynamic> payload) async {
    await _repository.storePosOrder(payload);
  }

  // --- AUDITS & LOGS ---

  Future<List<AuditLog>> getAudits({Map<String, dynamic>? queryParams}) async {
    final response = await _repository.getAudits(queryParams);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => AuditLog.fromJson(e)).toList();
  }

  Future<List<AuditLog>> fetchAuditLogs(
      {Map<String, dynamic>? queryParams}) async {
    final response = await _repository.getAudits(queryParams);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => AuditLog.fromJson(e)).toList();
  }

  // --- PROFIL & KEAMANAN (shared: Customer & Staff) ---

  Future<UserModel> getProfile() async {
    try {
      final response = await _repository.fetchMe();
      final data = response.data['data'] ?? response.data;
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal memuat profil',
      );
    }
  }

  Future<UserModel> updateProfile({
    required String username,
    required String email,
    String? phone,
    dynamic imageFile,
  }) async {
    final formData = FormData.fromMap({
      'username': username,
      'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });

    if (imageFile != null) {
      final path = imageFile is String ? imageFile : imageFile.path;
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(path, filename: 'profile.jpg'),
        ),
      );
    }

    try {
      final response = await _repository.updateProfile(formData);
      return UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal memperbarui profil',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      });
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal mengubah password',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
  }

  // --- ALAMAT CUSTOMER ---

  Future<List<CustomerAddress>> getAddresses() async {
    try {
      final response = await _repository.getAddresses();
      final list = response.data['data'] as List? ?? [];
      return list
          .map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal memuat alamat',
      );
    }
  }

  Future<CustomerAddress> addAddress({
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    try {
      final response = await _repository.addAddress({
        'label': label,
        'address_detail': addressDetail,
        'latitude': latitude,
        'longitude': longitude,
        'is_primary': isPrimary,
      });
      return CustomerAddress.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal menambah alamat',
      );
    }
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
      final response = await _repository.updateAddress(id, {
        'label': label,
        'address_detail': addressDetail,
        'latitude': latitude,
        'longitude': longitude,
        'is_primary': isPrimary,
      });
      return CustomerAddress.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal memperbarui alamat',
      );
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _repository.deleteAddress(id);
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal menghapus alamat',
      );
    }
  }

  String? _extractLaravelError(dynamic errorBody) {
    if (errorBody == null) return null;
    if (errorBody is Map) {
      if (errorBody['message'] != null) return errorBody['message'].toString();
      if (errorBody['errors'] is Map) {
        final errors = errorBody['errors'] as Map;
        final firstKey = errors.keys.first;
        final firstError = errors[firstKey];
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }
    return errorBody.toString();
  }
}

final staffServiceProvider = Provider<StaffService>((ref) {
  final repository = ref.watch(staffRepositoryProvider);
  return StaffService(repository);
});