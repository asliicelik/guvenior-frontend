import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../models/financial_goal_model.dart';

class FinancialGoalService {
  static Future<List<FinancialGoal>> getGoals() async {
    final response = await ApiService.dio.get(ApiConstants.financialGoal);
    final list = response.data as List;
    return list.map((json) => FinancialGoal.fromJson(json)).toList();
  }

  static Future<FinancialGoal> addGoal({
    required String title,
    required int type,
    required double currentPrice,
    required double currentSavings,
    required double monthlyContribution,
    double? annualInflationRate,
    required DateTime targetDate,
  }) async {
    final response = await ApiService.dio.post(
      ApiConstants.financialGoal,
      data: {
        'title': title,
        'type': type,
        'currentPrice': currentPrice,
        'currentSavings': currentSavings,
        'monthlyContribution': monthlyContribution,
        'annualInflationRate': annualInflationRate,
        'targetDate': targetDate.toUtc().toIso8601String(),
      },
    );
    return FinancialGoal.fromJson(response.data);
  }

  static Future<FinancialGoal> updateGoal(
    int id, {
    String? title,
    int? type,
    double? currentPrice,
    double? currentSavings,
    double? monthlyContribution,
    double? annualInflationRate,
    DateTime? targetDate,
    bool? isCompleted,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (type != null) data['type'] = type;
    if (currentPrice != null) data['currentPrice'] = currentPrice;
    if (currentSavings != null) data['currentSavings'] = currentSavings;
    if (monthlyContribution != null) data['monthlyContribution'] = monthlyContribution;
    if (annualInflationRate != null) data['annualInflationRate'] = annualInflationRate;
    if (targetDate != null) data['targetDate'] = targetDate.toUtc().toIso8601String();
    if (isCompleted != null) data['isCompleted'] = isCompleted;

    final response = await ApiService.dio.patch(
      '${ApiConstants.financialGoal}/$id',
      data: data,
    );
    return FinancialGoal.fromJson(response.data);
  }

  static Future<void> deleteGoal(int id) async {
    await ApiService.dio.delete('${ApiConstants.financialGoal}/$id');
  }

  static Future<FinancialGoalSimulation> getSimulation(int id) async {
    final response = await ApiService.dio.get('${ApiConstants.financialGoal}/$id/simulation');
    return FinancialGoalSimulation.fromJson(response.data);
  }

  static Future<List<FinancialGoalSimulation>> getSimulations() async {
    final response = await ApiService.dio.get('${ApiConstants.financialGoal}/simulations');
    final list = response.data as List;
    return list.map((json) => FinancialGoalSimulation.fromJson(json)).toList();
  }

  static Future<SpendingImpactResponse> simulateSpendingImpact({
    required int goalId,
    required String title,
    required int category,
    required double amount,
  }) async {
    final response = await ApiService.dio.post(
      '${ApiConstants.financialGoal}/spending-impact',
      data: {
        'goalId': goalId,
        'title': title,
        'category': category,
        'amount': amount,
      },
    );
    return SpendingImpactResponse.fromJson(response.data);
  }
}
