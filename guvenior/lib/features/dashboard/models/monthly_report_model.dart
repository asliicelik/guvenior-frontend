class MonthlyReportAnalysis {
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double savingsAmount;
  final double savingsRate;
  final String? topExpenseCategory;
  final double topExpenseCategoryAmount;
  final double nightSpendingRate;
  final double salaryFirst48HourSpendingRate;
  final double flexibleExpenseTotal;
  final int activeGoalCount;
  final int highRiskGoalCount;
  final String behaviorProfile;

  MonthlyReportAnalysis({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.savingsAmount,
    required this.savingsRate,
    this.topExpenseCategory,
    required this.topExpenseCategoryAmount,
    required this.nightSpendingRate,
    required this.salaryFirst48HourSpendingRate,
    required this.flexibleExpenseTotal,
    required this.activeGoalCount,
    required this.highRiskGoalCount,
    required this.behaviorProfile,
  });

  factory MonthlyReportAnalysis.fromJson(Map<String, dynamic> json) {
    return MonthlyReportAnalysis(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      savingsAmount: (json['savingsAmount'] as num?)?.toDouble() ?? 0.0,
      savingsRate: (json['savingsRate'] as num?)?.toDouble() ?? 0.0,
      topExpenseCategory: json['topExpenseCategory'],
      topExpenseCategoryAmount: (json['topExpenseCategoryAmount'] as num?)?.toDouble() ?? 0.0,
      nightSpendingRate: (json['nightSpendingRate'] as num?)?.toDouble() ?? 0.0,
      salaryFirst48HourSpendingRate: (json['salaryFirst48HourSpendingRate'] as num?)?.toDouble() ?? 0.0,
      flexibleExpenseTotal: (json['flexibleExpenseTotal'] as num?)?.toDouble() ?? 0.0,
      activeGoalCount: json['activeGoalCount'] ?? 0,
      highRiskGoalCount: json['highRiskGoalCount'] ?? 0,
      behaviorProfile: json['behaviorProfile'] ?? '',
    );
  }
}

class MonthlyReport {
  final MonthlyReportAnalysis analysis;
  final String ruleBasedSummary;
  final String aiSummary;

  MonthlyReport({
    required this.analysis,
    required this.ruleBasedSummary,
    required this.aiSummary,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      analysis: MonthlyReportAnalysis.fromJson(json['analysis'] ?? {}),
      ruleBasedSummary: json['ruleBasedSummary'] ?? '',
      aiSummary: json['aiSummary'] ?? '',
    );
  }
}
