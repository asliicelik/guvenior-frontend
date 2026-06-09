enum FinancialGoalType {
  home,
  car,
  rent,
  education,
  emergencyFund,
  other,
}

extension FinancialGoalTypeExtension on FinancialGoalType {
  int get value {
    switch (this) {
      case FinancialGoalType.home:
        return 1;
      case FinancialGoalType.car:
        return 2;
      case FinancialGoalType.rent:
        return 3;
      case FinancialGoalType.education:
        return 4;
      case FinancialGoalType.emergencyFund:
        return 5;
      case FinancialGoalType.other:
        return 6;
    }
  }

  static FinancialGoalType fromValue(int val) {
    switch (val) {
      case 1:
        return FinancialGoalType.home;
      case 2:
        return FinancialGoalType.car;
      case 3:
        return FinancialGoalType.rent;
      case 4:
        return FinancialGoalType.education;
      case 5:
        return FinancialGoalType.emergencyFund;
      default:
        return FinancialGoalType.other;
    }
  }

  String get label {
    switch (this) {
      case FinancialGoalType.home:
        return 'Ev Al';
      case FinancialGoalType.car:
        return 'Araba Al';
      case FinancialGoalType.rent:
        return 'Kira Öde';
      case FinancialGoalType.education:
        return 'Eğitim';
      case FinancialGoalType.emergencyFund:
        return 'Acil Durum Fonu';
      case FinancialGoalType.other:
        return 'Diğer';
    }
  }

  String get emoji {
    switch (this) {
      case FinancialGoalType.home:
        return '🏠';
      case FinancialGoalType.car:
        return '🚗';
      case FinancialGoalType.rent:
        return '🔑';
      case FinancialGoalType.education:
        return '🎓';
      case FinancialGoalType.emergencyFund:
        return '🛡️';
      case FinancialGoalType.other:
        return '🎯';
    }
  }
}

class FinancialGoal {
  final int id;
  final String title;
  final FinancialGoalType type;
  final double currentPrice;
  final double currentSavings;
  final double monthlyContribution;
  final double annualInflationRate;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime createdAt;

  FinancialGoal({
    required this.id,
    required this.title,
    required this.type,
    required this.currentPrice,
    required this.currentSavings,
    required this.monthlyContribution,
    required this.annualInflationRate,
    required this.targetDate,
    required this.isCompleted,
    required this.createdAt,
  });

  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      type: FinancialGoalTypeExtension.fromValue(json['type'] ?? 6),
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      currentSavings: (json['currentSavings'] as num?)?.toDouble() ?? 0.0,
      monthlyContribution: (json['monthlyContribution'] as num?)?.toDouble() ?? 0.0,
      annualInflationRate: (json['annualInflationRate'] as num?)?.toDouble() ?? 0.0,
      targetDate: DateTime.parse(json['targetDate'] ?? DateTime.now().toIso8601String()),
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.value,
      'currentPrice': currentPrice,
      'currentSavings': currentSavings,
      'monthlyContribution': monthlyContribution,
      'annualInflationRate': annualInflationRate,
      'targetDate': targetDate.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class FinancialGoalSimulationAnalysis {
  final int monthsRemaining;
  final double currentPrice;
  final double projectedTargetPrice;
  final double currentSavings;
  final double plannedTotalSavings;
  final double fundingGap;
  final double requiredMonthlyContribution;
  final double monthlyContributionDifference;
  final bool isReachableWithCurrentPlan;
  final String riskLevel;
  final double currentMonthIncome;
  final double currentMonthExpense;
  final double currentMonthSavingsCapacity;
  final String? suggestedCutCategory;
  final double suggestedMonthlyExpenseReduction;
  final double adjustedFundingGap;

  double get monthlyContribution => requiredMonthlyContribution - monthlyContributionDifference;

  FinancialGoalSimulationAnalysis({
    required this.monthsRemaining,
    required this.currentPrice,
    required this.projectedTargetPrice,
    required this.currentSavings,
    required this.plannedTotalSavings,
    required this.fundingGap,
    required this.requiredMonthlyContribution,
    required this.monthlyContributionDifference,
    required this.isReachableWithCurrentPlan,
    required this.riskLevel,
    required this.currentMonthIncome,
    required this.currentMonthExpense,
    required this.currentMonthSavingsCapacity,
    this.suggestedCutCategory,
    required this.suggestedMonthlyExpenseReduction,
    required this.adjustedFundingGap,
  });

  factory FinancialGoalSimulationAnalysis.fromJson(Map<String, dynamic> json) {
    return FinancialGoalSimulationAnalysis(
      monthsRemaining: json['monthsRemaining'] ?? 0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      projectedTargetPrice: (json['projectedTargetPrice'] as num?)?.toDouble() ?? 0.0,
      currentSavings: (json['currentSavings'] as num?)?.toDouble() ?? 0.0,
      plannedTotalSavings: (json['plannedTotalSavings'] as num?)?.toDouble() ?? 0.0,
      fundingGap: (json['fundingGap'] as num?)?.toDouble() ?? 0.0,
      requiredMonthlyContribution: (json['requiredMonthlyContribution'] as num?)?.toDouble() ?? 0.0,
      monthlyContributionDifference: (json['monthlyContributionDifference'] as num?)?.toDouble() ?? 0.0,
      isReachableWithCurrentPlan: json['isReachableWithCurrentPlan'] ?? false,
      riskLevel: json['riskLevel'] ?? '',
      currentMonthIncome: (json['currentMonthIncome'] as num?)?.toDouble() ?? 0.0,
      currentMonthExpense: (json['currentMonthExpense'] as num?)?.toDouble() ?? 0.0,
      currentMonthSavingsCapacity: (json['currentMonthSavingsCapacity'] as num?)?.toDouble() ?? 0.0,
      suggestedCutCategory: json['suggestedCutCategory'],
      suggestedMonthlyExpenseReduction: (json['suggestedMonthlyExpenseReduction'] as num?)?.toDouble() ?? 0.0,
      adjustedFundingGap: (json['adjustedFundingGap'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FinancialGoalSimulation {
  final int goalId;
  final String title;
  final FinancialGoalSimulationAnalysis analysis;
  final String ruleBasedRecommendation;
  final String aiMessage;

  FinancialGoalSimulation({
    required this.goalId,
    required this.title,
    required this.analysis,
    required this.ruleBasedRecommendation,
    required this.aiMessage,
  });

  factory FinancialGoalSimulation.fromJson(Map<String, dynamic> json) {
    return FinancialGoalSimulation(
      goalId: json['goalId'] ?? 0,
      title: json['title'] ?? '',
      analysis: FinancialGoalSimulationAnalysis.fromJson(json['analysis'] ?? {}),
      ruleBasedRecommendation: json['ruleBasedRecommendation'] ?? '',
      aiMessage: json['aiMessage'] ?? '',
    );
  }
}

class SpendingImpactAnalysis {
  final int goalId;
  final String goalTitle;
  final String expenseTitle;
  final int expenseCategory;
  final String expenseCategoryName;
  final double expenseAmount;
  final double originalFundingGap;
  final double newFundingGap;
  final double impactAmount;
  final int estimatedDelayMonths;
  final double suggestedMonthlyOffset;
  final String impactLevel;

  SpendingImpactAnalysis({
    required this.goalId,
    required this.goalTitle,
    required this.expenseTitle,
    required this.expenseCategory,
    required this.expenseCategoryName,
    required this.expenseAmount,
    required this.originalFundingGap,
    required this.newFundingGap,
    required this.impactAmount,
    required this.estimatedDelayMonths,
    required this.suggestedMonthlyOffset,
    required this.impactLevel,
  });

  factory SpendingImpactAnalysis.fromJson(Map<String, dynamic> json) {
    return SpendingImpactAnalysis(
      goalId: json['goalId'] ?? 0,
      goalTitle: json['goalTitle'] ?? '',
      expenseTitle: json['expenseTitle'] ?? '',
      expenseCategory: json['expenseCategory'] ?? 8,
      expenseCategoryName: json['expenseCategoryName'] ?? '',
      expenseAmount: (json['expenseAmount'] as num?)?.toDouble() ?? 0.0,
      originalFundingGap: (json['originalFundingGap'] as num?)?.toDouble() ?? 0.0,
      newFundingGap: (json['newFundingGap'] as num?)?.toDouble() ?? 0.0,
      impactAmount: (json['impactAmount'] as num?)?.toDouble() ?? 0.0,
      estimatedDelayMonths: json['estimatedDelayMonths'] ?? 0,
      suggestedMonthlyOffset: (json['suggestedMonthlyOffset'] as num?)?.toDouble() ?? 0.0,
      impactLevel: json['impactLevel'] ?? '',
    );
  }
}

class SpendingImpactResponse {
  final SpendingImpactAnalysis analysis;
  final String ruleBasedRecommendation;
  final String aiMessage;

  SpendingImpactResponse({
    required this.analysis,
    required this.ruleBasedRecommendation,
    required this.aiMessage,
  });

  factory SpendingImpactResponse.fromJson(Map<String, dynamic> json) {
    return SpendingImpactResponse(
      analysis: SpendingImpactAnalysis.fromJson(json['analysis'] ?? {}),
      ruleBasedRecommendation: json['ruleBasedRecommendation'] ?? '',
      aiMessage: json['aiMessage'] ?? '',
    );
  }
}
