class Insight {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  Insight({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class BehaviorAnalysis {
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double savingsAmount;
  final double savingsRate;
  final double salaryFirst48HourSpendingRate;
  final double nightSpendingRate;
  final double monthlyExpenseIncreaseRate;
  final int? highestBudgetUsageCategory;
  final double highestBudgetUsageRate;

  BehaviorAnalysis({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.savingsAmount,
    required this.savingsRate,
    required this.salaryFirst48HourSpendingRate,
    required this.nightSpendingRate,
    required this.monthlyExpenseIncreaseRate,
    this.highestBudgetUsageCategory,
    required this.highestBudgetUsageRate,
  });

  factory BehaviorAnalysis.fromJson(Map<String, dynamic> json) {
    return BehaviorAnalysis(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      savingsAmount: (json['savingsAmount'] as num?)?.toDouble() ?? 0.0,
      savingsRate: (json['savingsRate'] as num?)?.toDouble() ?? 0.0,
      salaryFirst48HourSpendingRate: (json['salaryFirst48HourSpendingRate'] as num?)?.toDouble() ?? 0.0,
      nightSpendingRate: (json['nightSpendingRate'] as num?)?.toDouble() ?? 0.0,
      monthlyExpenseIncreaseRate: (json['monthlyExpenseIncreaseRate'] as num?)?.toDouble() ?? 0.0,
      highestBudgetUsageCategory: json['highestBudgetUsageCategory'],
      highestBudgetUsageRate: (json['highestBudgetUsageRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GenerateInsightsResponse {
  final BehaviorAnalysis analysis;
  final List<Insight> insights;

  GenerateInsightsResponse({
    required this.analysis,
    required this.insights,
  });

  factory GenerateInsightsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['insights'] as List? ?? [];
    return GenerateInsightsResponse(
      analysis: BehaviorAnalysis.fromJson(json['analysis'] ?? {}),
      insights: list.map((i) => Insight.fromJson(i)).toList(),
    );
  }
}
