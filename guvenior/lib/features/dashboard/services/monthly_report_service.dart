import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/monthly_report_model.dart';

class MonthlyReportService {
  static Future<MonthlyReport> getMonthlyReport({int? month, int? year}) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;

    final response = await ApiService.dio.get(
      ApiConstants.monthlyReport,
      queryParameters: queryParams,
    );
    return MonthlyReport.fromJson(response.data);
  }
}
