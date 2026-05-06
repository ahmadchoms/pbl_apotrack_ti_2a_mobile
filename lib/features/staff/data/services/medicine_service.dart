import '../../../../core/network/api_client.dart';
import '../models/medicine.dart';

class MedicineService {
  final ApiClient _apiClient;

  MedicineService(this._apiClient);

  Future<List<Medicine>> getMedicines() async {
    try {
      final response = await _apiClient.get('/medicines');
      if (response.data['status'] == 'success') {
        final List data = response.data['data'];
        return data.map((json) => Medicine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Medicine> getMedicineDetail(int id) async {
    try {
      final response = await _apiClient.get('/medicines/$id');
      return Medicine.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
