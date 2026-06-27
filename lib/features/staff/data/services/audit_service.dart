import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/audit_log.dart';
import '../repositories/audit_repository.dart';

class StaffAuditService {
  final StaffAuditRepository _repository;
  StaffAuditService(this._repository);

  Future<List<AuditLog>> getAudits({Map<String, dynamic>? queryParams}) async {
    final response = await _repository.getAudits(queryParams);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => AuditLog.fromJson(e)).toList();
  }
}

final staffAuditServiceProvider = Provider<StaffAuditService>((ref) {
  final repository = ref.watch(staffAuditRepositoryProvider);
  return StaffAuditService(repository);
});
