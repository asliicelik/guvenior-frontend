class RecurringExpense {
  final int id;
  final String title;
  final double amount;
  final int category;
  final int dayOfMonth; // 1–31
  final bool isActive;

  RecurringExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.dayOfMonth,
    this.isActive = true,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) =>
      RecurringExpense(
        id: json['id'] as int,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as int,
        dayOfMonth: json['dayOfMonth'] as int,
        isActive: (json['isActive'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'dayOfMonth': dayOfMonth,
        'isActive': isActive,
      };

  RecurringExpense copyWith({
    int? id,
    String? title,
    double? amount,
    int? category,
    int? dayOfMonth,
    bool? isActive,
  }) =>
      RecurringExpense(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        isActive: isActive ?? this.isActive,
      );
}
