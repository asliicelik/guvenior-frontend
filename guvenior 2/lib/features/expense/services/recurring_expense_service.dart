import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/recurring_expense_model.dart';
import 'package:dio/dio.dart';

class CreateRecurringExpenseRequest {
  final String title;
  final double amount;
  final int category;
  final int dayOfMonth;

  CreateRecurringExpenseRequest({
    required this.title,
    required this.amount,
    required this.category,
    required this.dayOfMonth,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'category': category,
        'dayOfMonth': dayOfMonth,
      };
}

class RecurringExpenseService {
  static Future<List<RecurringExpense>> getRecurringExpenses() async {
    try {
      final response = await ApiService.dio.get('/api/RecurringExpense');
      final list = response.data as List;
      return list.map((e) => RecurringExpense.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<RecurringExpense?> addRecurringExpense(
      CreateRecurringExpenseRequest request) async {
    try {
      final response = await ApiService.dio.post(
        '/api/RecurringExpense',
        data: request.toJson(),
      );
      return RecurringExpense.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteRecurringExpense(int id) async {
    try {
      await ApiService.dio.delete('/api/RecurringExpense/$id');
    } catch (e) {}
  }
}
