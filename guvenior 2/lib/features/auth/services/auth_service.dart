import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/local_data_service.dart';
import '../models/auth_model.dart';

class AuthService {
  static Future<AuthResponse> register(
    RegisterRequest request, {
    double? monthlyIncome,
    int? salaryDay,
  }) async {
    final response = await ApiService.dio.post(
      ApiConstants.register,
      data: request.toJson(),
    );
    final authResponse = AuthResponse.fromJson(response.data);
    await ApiService.setToken(authResponse.token);
    await _saveUser(authResponse);
    // Maaş bilgisini yerel depolamaya kaydet
    if (monthlyIncome != null && monthlyIncome > 0) {
      await LocalDataService.setSalary(monthlyIncome);
    }
    if (salaryDay != null) {
      await LocalDataService.setSalaryDay(salaryDay);
    }
    return authResponse;
  }

  static Future<AuthResponse> login(LoginRequest request) async {
    final response = await ApiService.dio.post(
      ApiConstants.login,
      data: request.toJson(),
    );
    final authResponse = AuthResponse.fromJson(response.data);
    await ApiService.setToken(authResponse.token);
    await _saveUser(authResponse);
    // Backend'den gelen maaş bilgilerini lokale al:
    await LocalDataService.setSalary(authResponse.monthlyIncome);
    await LocalDataService.setSalaryDay(authResponse.salaryDay);
    return authResponse;
  }

  static Future<void> updateSalary(double monthlyIncome, int salaryDay) async {
    try {
      await ApiService.dio.put(
        ApiConstants.updateSalary,
        data: {
          'monthlyIncome': monthlyIncome,
          'salaryDay': salaryDay,
        },
      );
      // Lokali de güncelle:
      await LocalDataService.setSalary(monthlyIncome);
      await LocalDataService.setSalaryDay(salaryDay);
    } catch (e) {
      // Ignored for now
    }
  }

  static Future<AuthResponse?> getProfile() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.profile);
      final profile = AuthResponse.fromJson(response.data);
      // Lokali veritabanından gelen verilerle tazele:
      await LocalDataService.setSalary(profile.monthlyIncome);
      await LocalDataService.setSalaryDay(profile.salaryDay);
      return profile;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _saveUser(AuthResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', response.fullName);
    await prefs.setString('email', response.email);
  }
}
