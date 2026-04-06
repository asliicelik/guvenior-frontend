import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/auth_model.dart';

class AuthService {
  static Future<AuthResponse> register(RegisterRequest request) async {
    final response = await ApiService.dio.post(
      ApiConstants.register,
      data: request.toJson(),
    );
    final authResponse = AuthResponse.fromJson(response.data);
    await ApiService.setToken(authResponse.token);
    await _saveUser(authResponse);
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
    return authResponse;
  }

  static Future<void> _saveUser(AuthResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', response.fullName);
    await prefs.setString('email', response.email);
  }
}
