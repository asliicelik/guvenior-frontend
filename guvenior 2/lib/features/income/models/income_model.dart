class Income {
  final String id;
  final String title;
  final double amount;
  final DateTime receivedDate;
  final int type;

  Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.receivedDate,
    required this.type,
  });

  factory Income.fromJson(Map<String, dynamic> json) => Income(
    id: json['id'].toString(),
    title: json['title'],
    amount: json['amount'].toDouble(),
    receivedDate: DateTime.parse(json['receivedDate']),
    type: json['type'],
  );
}

class CreateIncomeRequest {
  final String title;
  final double amount;
  final DateTime receivedDate;
  final int type;

  CreateIncomeRequest({
    required this.title,
    required this.amount,
    required this.receivedDate,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'receivedDate': receivedDate.toIso8601String(),
    'type': type,
  };
}
