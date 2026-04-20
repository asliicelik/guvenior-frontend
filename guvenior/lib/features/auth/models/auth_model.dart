class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final double monthlyIncome;
  final int salaryDay;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.monthlyIncome,
    required this.salaryDay,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'password': password,
    'monthlyIncome': monthlyIncome,
    'salaryDay': salaryDay,
  };
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class AuthResponse {
  final String token;
  final String fullName;
  final String email;
  final double monthlyIncome;
  final int salaryDay;

  AuthResponse({
    required this.token,
    required this.fullName,
    required this.email,
    required this.monthlyIncome,
    required this.salaryDay,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'] ?? '',
    fullName: (json['fullName'] ?? json['FullName'] ?? '') as String,
    email: (json['email'] ?? json['Email'] ?? '') as String,
    monthlyIncome: (json['monthlyIncome'] ?? json['MonthlyIncome'] as num?)?.toDouble() ?? 0.0,
    salaryDay: (json['salaryDay'] ?? json['SalaryDay'] as num?)?.toInt() ?? 1,
  );
}
