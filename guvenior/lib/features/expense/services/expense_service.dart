import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/expense_model.dart';

class ExpenseService {
  static Future<List<Expense>> getExpenses() async {
    final response = await ApiService.dio.get(ApiConstants.expense);
    return (response.data as List).map((e) => Expense.fromJson(e)).toList();
  }

  static Future<void> addExpense(CreateExpenseRequest request) async {
    await ApiService.dio.post(ApiConstants.expense, data: request.toJson());
  }
}
