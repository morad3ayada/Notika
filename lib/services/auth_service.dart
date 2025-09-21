import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import '../models/auth_models.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiConfig.centralAuthBaseUrl);
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String orgUrlKey = 'organization_url';


  Future<LoginResponse> login(String username, String password) async {
    try {
      // Perform login directly to the main API
      final loginResponse = await _apiClient.post(
        endpoint: ApiConfig.loginEndpoint,
        body: {
          'username': username,
          'password': password,
        },
      );

      debugPrint('Raw Login Response: $loginResponse');
      if (loginResponse is Map) {
        debugPrint('Response keys: ${loginResponse.keys.join(', ')}');
      }
      
      // Parse the response
      final response = LoginResponse.fromJson(loginResponse);
      
      // Save the authentication data
      await _saveAuthData(response);
      
      return response;
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _saveAuthData(LoginResponse response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save token
      await prefs.setString(tokenKey, response.token);
      
      // Save organization URL if available
      if (response.organization?.url != null) {
        await prefs.setString(orgUrlKey, response.organization!.url!);
      } else {
        await prefs.remove(orgUrlKey);
      }
      
      // Save user data as JSON string
      final userData = {
        'token': response.token,
        'user': response.profile.toJson(),
        if (response.organization != null) 'organization': response.organization!.toJson(),
      };
      
      await prefs.setString(userDataKey, jsonEncode(userData));
      
      debugPrint('Auth data saved successfully');
    } catch (e) {
      debugPrint('Error saving auth data: $e');
      rethrow;
    }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear all app preferences as requested
      await prefs.clear();
    } catch (e) {
      print('Error clearing auth data: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    await clearAuthData();
  }

  // Calls the backend logout endpoint with the saved token
  // The call will be blocked unless explicitly invoked from a confirmed user action.
  Future<void> serverLogout({bool requireUserAction = false}) async {
    if (!requireUserAction) {
      return;
    }

    try {
      final token = await AuthService.getToken();
      if (token != null) {
        final clientWithToken = ApiClient(
          baseUrl: ApiConfig.centralAuthBaseUrl,
          token: token,
        );
        await clientWithToken.post(
          endpoint: ApiConfig.logoutEndpoint,
        );
      }
    } catch (_) {
      // Intentionally ignore any server error (including 401)
    }

    // Always clear local auth data and confirm with a single log line
    await clearAuthData();
    debugPrint('Local logout done');
  }
}
