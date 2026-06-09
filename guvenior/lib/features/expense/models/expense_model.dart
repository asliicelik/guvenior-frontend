class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime spentAt;
  final int category;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.spentAt,
    required this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'].toString(),
    title: json['title'],
    amount: json['amount'].toDouble(),
    spentAt: DateTime.parse(json['spentAt']),
    category: json['category'],
  );
}

class CreateExpenseRequest {
  final String title;
  final double amount;
  final DateTime spentAt;
  final int category;

  CreateExpenseRequest({
    required this.title,
    required this.amount,
    required this.spentAt,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'spentAt': spentAt.toIso8601String(),
    'category': category,
  };
}
