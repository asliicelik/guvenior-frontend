import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/income_model.dart';

class IncomeService {
  static Future<List<Income>> getIncomes() async {
    final response = await ApiService.dio.get(ApiConstants.income);
    return (response.data as List).map((e) => Income.fromJson(e)).toList();
  }

  static Future<void> addIncome(CreateIncomeRequest request) async {
    await ApiService.dio.post(ApiConstants.income, data: request.toJson());
  }
  static Future<void> deleteIncome(String id) async {
    await ApiService.dio.delete('${ApiConstants.income}/$id');
  }
}
