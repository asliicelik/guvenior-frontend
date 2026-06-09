import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/insight_model.dart';

class InsightService {
  static Future<List<Insight>> getInsights() async {
    final response = await ApiService.dio.get(ApiConstants.insight);
    final list = response.data as List;
    return list.map((json) => Insight.fromJson(json)).toList();
  }

  static Future<GenerateInsightsResponse> generateInsights() async {
    final response = await ApiService.dio.post('${ApiConstants.insight}/generate');
    return GenerateInsightsResponse.fromJson(response.data);
  }

  static Future<void> markAsRead(int id) async {
    await ApiService.dio.patch('${ApiConstants.insight}/$id/read');
  }
}
