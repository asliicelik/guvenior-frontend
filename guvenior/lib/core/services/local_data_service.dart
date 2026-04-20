import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/expense/models/recurring_expense_model.dart';

class LocalDataService {
  static const _keySalary = 'salary';
  static const _keySalaryDay = 'salaryDay';
  static const _keyRecurring = 'recurringExpenses';
  static const _keyStreak = 'streak';
  static const _keyLastOpen = 'lastOpen';

  // ─── Maaş ─────────────────────────────────────────────────────────────────

  static Future<double> getSalary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keySalary) ?? 0.0;
  }

  static Future<void> setSalary(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySalary, value);
  }

  static Future<int> getSalaryDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySalaryDay) ?? 1;
  }

  static Future<void> setSalaryDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySalaryDay, day);
  }

  // ─── Tekrarlayan Giderler ──────────────────────────────────────────────────

  static Future<List<RecurringExpense>> getRecurringExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyRecurring);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => RecurringExpense.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveRecurringExpenses(
      List<RecurringExpense> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_keyRecurring, jsonStr);
  }

  static Future<void> addRecurringExpense(RecurringExpense expense) async {
    final list = await getRecurringExpenses();
    list.add(expense);
    await saveRecurringExpenses(list);
  }

  static Future<void> deleteRecurringExpense(int id) async {
    final list = await getRecurringExpenses();
    list.removeWhere((e) => e.id == id);
    await saveRecurringExpenses(list);
  }

  static Future<void> updateRecurringExpense(
      RecurringExpense updated) async {
    final list = await getRecurringExpenses();
    final idx = list.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
      await saveRecurringExpenses(list);
    }
  }

  // ─── Streak ───────────────────────────────────────────────────────────────

  static Future<int> checkAndUpdateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastOpenStr = prefs.getString(_keyLastOpen);

    if (lastOpenStr == todayStr) {
      return prefs.getInt(_keyStreak) ?? 1;
    }

    int streak = prefs.getInt(_keyStreak) ?? 0;

    if (lastOpenStr != null) {
      final parts = lastOpenStr.split('-');
      final lastOpen = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final diff = today.difference(lastOpen).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    await prefs.setInt(_keyStreak, streak);
    await prefs.setString(_keyLastOpen, todayStr);
    return streak;
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 0;
  }
}
