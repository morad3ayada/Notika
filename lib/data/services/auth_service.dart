import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_client.dart';
import '../../config/api_config.dart';
import '../models/auth_models.dart';

class AuthService {
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String orgUrlKey = 'organization_url';

  final ApiClient _apiClient = ApiClient(baseUrl: ApiConfig.centralAuthBaseUrl);

  Future<LoginResponse> login(String username, String password) async {
    try {
      final loginResponse = await _apiClient.post(
        endpoint: ApiConfig.loginEndpoint,
        body: {
          'username': username,
          'password': password,
        },
      );

      debugPrint('Raw Login Response: $loginResponse');
      final response = LoginResponse.fromJson(loginResponse);

      // Enforce Teacher-only login
      final topLevelType = response.userType.trim();
      final profileType = response.profile.userType.trim();
      final isTeacher = topLevelType.toLowerCase() == 'teacher' || profileType.toLowerCase() == 'teacher';
      if (!isTeacher) {
        throw Exception('غير مسموح بالدخول إلا لحساب المعلم فقط');
      }

      await _saveAuthData(response);
      return response;
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _saveAuthData(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(tokenKey, response.token);

    // Save organization URL if available
    if (response.organization?.url != null) {
      await prefs.setString(orgUrlKey, response.organization!.url!);
    } else {
      await prefs.remove(orgUrlKey);
    }

    final userData = {
      'token': response.token,
      'profile': response.profile.toJson(),
      if (response.organization != null) 'organization': response.organization!.toJson(),
    };

    await prefs.setString(userDataKey, jsonEncode(userData));
    debugPrint('Auth data saved successfully');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<Map<String, dynamic>?> getSavedAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(userDataKey);
      if (userDataString == null) return null;
      return jsonDecode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting saved auth data: $e');
      return null;
    }
  }

  static Future<String?> getOrganizationUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(orgUrlKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> logout() async {
    await clearAuthData();
  }

  // Optional server logout to keep parity with legacy UI call
  // This method will call backend logout only when requireUserAction is true,
  // then always clears local auth data.
  Future<void> serverLogout({bool requireUserAction = false}) async {
    if (requireUserAction) {
      try {
        final clientWithToken = ApiClient(baseUrl: ApiConfig.centralAuthBaseUrl);
        await clientWithToken.post(endpoint: ApiConfig.logoutEndpoint);
      } catch (_) {
        // Ignore server errors, proceed to clear local data
      }
    }

    await clearAuthData();
    debugPrint('Local logout done');
  }

  // Change password for the currently authenticated user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final clientWithToken = ApiClient(baseUrl: ApiConfig.centralAuthBaseUrl);
      await clientWithToken.post(
        endpoint: ApiConfig.changePasswordEndpoint,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      throw Exception('تعذر تغيير كلمة المرور: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
