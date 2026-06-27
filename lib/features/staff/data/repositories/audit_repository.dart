import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class StaffAuditRepository {
  final Dio _dio;
  StaffAuditRepository(this._dio);

  Future<Response> getAudits(Map<String, dynamic>? queryParams) =>
      _dio.get('/staff/audits', queryParameters: queryParams);
}

final staffAuditRepositoryProvider = Provider<StaffAuditRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffAuditRepository(dio);
});
