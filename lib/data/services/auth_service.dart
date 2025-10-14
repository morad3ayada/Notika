import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../api/api_client.dart';
import '../../config/api_config.dart';
import '../models/auth_models.dart';

class AuthService {
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String orgUrlKey = 'organization_url';

  final ApiClient _centralApiClient = ApiClient(baseUrl: ApiConfig.centralAuthBaseUrl);

  /// الخطوة 1: الحصول على URL المنظمة من Central Authentication Server
  Future<OrganizationUrlResponse> fetchOrganizationUrl(String username) async {
    try {
      debugPrint('🔍 Getting organization URL for username: $username');
      
      final response = await _centralApiClient.get(
        '${ApiConfig.getOrganizationUrlEndpoint}?username=$username',
      );

      debugPrint('✅ Organization URL Response: $response');
      final orgUrlResponse = OrganizationUrlResponse.fromJson(response);
      
      // حفظ URL المنظمة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(orgUrlKey, orgUrlResponse.organizationUrl);
      
      // تحديث baseUrl في ApiConfig
      ApiConfig.setOrganizationBaseUrl(orgUrlResponse.organizationUrl);
      debugPrint('✅ Organization URL set to: ${orgUrlResponse.organizationUrl}');
      
      return orgUrlResponse;
    } catch (e) {
      debugPrint('❌ Failed to get organization URL: $e');
      throw Exception('فشل الحصول على معلومات المنظمة: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// الخطوة 2: تسجيل الدخول باستخدام URL المنظمة
  Future<LoginResponse> login(String username, String password) async {
    try {
      // مسح جميع البيانات القديمة بالكامل قبل البدء
      debugPrint('🧹 Clearing old auth data before login...');
      await clearAuthData();
      debugPrint('✅ Old auth data cleared');
      
      // الخطوة 1: الحصول على URL المنظمة
      debugPrint('🔐 Step 1: Getting organization URL...');
      final orgUrlResponse = await fetchOrganizationUrl(username);
      
      // الخطوة 2: تسجيل الدخول باستخدام URL المنظمة
      debugPrint('🔐 Step 2: Logging in to organization at ${orgUrlResponse.organizationUrl}...');
      final orgApiClient = ApiClient(baseUrl: orgUrlResponse.organizationUrl);
      
      final loginResponse = await orgApiClient.post(
        endpoint: ApiConfig.loginEndpoint,
        body: {
          'username': username,
          'password': password,
        },
      );

      debugPrint('✅ Login Response: $loginResponse');
      final response = LoginResponse.fromJson(loginResponse);

      // Enforce Teacher-only login
      final topLevelType = response.userType.trim();
      final profileType = response.profile.userType.trim();
      final isTeacher = topLevelType.toLowerCase() == 'teacher' || profileType.toLowerCase() == 'teacher';
      if (!isTeacher) {
        throw Exception('غير مسموح بالدخول إلا لحساب المعلم فقط');
      }

      await _saveAuthData(response, orgUrlResponse.organizationUrl);
      debugPrint('✅ Login successful for ${response.profile.fullName}');
      return response;
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      // إعادة تعيين baseUrl عند الفشل
      ApiConfig.resetBaseUrl();
      throw Exception('فشل تسجيل الدخول: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _saveAuthData(LoginResponse response, String organizationUrl) async {
    debugPrint('💾 Starting to save auth data...');
    
    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        debugPrint('💾 Save attempt $attempt/5');
        final prefs = await SharedPreferences.getInstance();

        // حفظ كل قيمة بشكل منفصل مع commit بعد كل واحدة
        
        // 1. حفظ التوكن
        await prefs.setString(tokenKey, response.token);
        bool tokenCommitted = await prefs.commit();
        debugPrint('🔑 Token ${tokenCommitted ? "committed ✓" : "commit failed ✗"}');
        
        if (!tokenCommitted) {
          await Future.delayed(Duration(milliseconds: 100 * attempt));
          continue;
        }

        // 2. حفظ organization URL
        await prefs.setString(orgUrlKey, organizationUrl);
        bool orgCommitted = await prefs.commit();
        debugPrint('🌐 OrgUrl ${orgCommitted ? "committed ✓" : "commit failed ✗"}');
        
        if (!orgCommitted) {
          await Future.delayed(Duration(milliseconds: 100 * attempt));
          continue;
        }

        // 3. حفظ بيانات المستخدم
        final userData = {
          'token': response.token,
          'userType': response.userType,
          'profile': response.profile.toJson(),
          'organizationUrl': organizationUrl,
          if (response.organization != null) 'organization': response.organization!.toJson(),
        };

        await prefs.setString(userDataKey, jsonEncode(userData));
        bool userDataCommitted = await prefs.commit();
        debugPrint('👤 UserData ${userDataCommitted ? "committed ✓" : "commit failed ✗"}');
        
        if (!userDataCommitted) {
          await Future.delayed(Duration(milliseconds: 100 * attempt));
          continue;
        }
        
        // انتظار إضافي للتأكد من الكتابة
        await Future.delayed(const Duration(milliseconds: 500));
        
        // التحقق النهائي من حفظ جميع البيانات
        await prefs.reload();
        final savedToken = prefs.getString(tokenKey);
        final savedOrgUrl = prefs.getString(orgUrlKey);
        final savedUserData = prefs.getString(userDataKey);
        
        if (savedToken != null && savedOrgUrl != null && savedUserData != null) {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('✅ AUTH DATA SAVED SUCCESSFULLY ON ATTEMPT $attempt');
          debugPrint('   - Token: ${savedToken.substring(0, 10)}...');
          debugPrint('   - OrgUrl: $savedOrgUrl');
          debugPrint('   - UserData: ${savedUserData.length} chars');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return; // Success!
        } else {
          debugPrint('⚠️ Verification failed on attempt $attempt:');
          debugPrint('   - Token: ${savedToken != null ? "✓" : "✗"}');
          debugPrint('   - OrgUrl: ${savedOrgUrl != null ? "✓" : "✗"}');
          debugPrint('   - UserData: ${savedUserData != null ? "✓" : "✗"}');
          await Future.delayed(Duration(milliseconds: 200 * attempt));
        }
      } catch (e) {
        debugPrint('❌ Error on attempt $attempt: $e');
        if (attempt < 5) {
          await Future.delayed(Duration(milliseconds: 200 * attempt));
        }
      }
    }
    
    // إذا فشلت كل المحاولات
    throw Exception('Failed to save auth data after 5 attempts - please try logging in again');
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // إعادة تحميل البيانات من القرص
      final token = prefs.getString(tokenKey);
      debugPrint('🔍 getToken: ${token != null ? "Found (${token.substring(0, 10)}...)" : "Not found"}');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSavedAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // إعادة تحميل البيانات من القرص
      final userDataString = prefs.getString(userDataKey);
      debugPrint('🔍 getSavedAuthData: ${userDataString != null ? "Found (${userDataString.length} chars)" : "Not found"}');
      if (userDataString == null) return null;
      return jsonDecode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error getting saved auth data: $e');
      return null;
    }
  }

  static Future<String?> getOrganizationUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // إعادة تحميل البيانات من القرص
      final orgUrl = prefs.getString(orgUrlKey);
      debugPrint('🔍 getOrganizationUrl: ${orgUrl ?? "Not found"}');
      return orgUrl;
    } catch (e) {
      debugPrint('❌ Error getting organization URL: $e');
      return null;
    }
  }

  static Future<String?> getUserId() async {
    try {
      final authData = await getSavedAuthData();
      if (authData == null) return null;
      
      final profile = authData['profile'] as Map<String, dynamic>?;
      if (profile == null) return null;
      
      // محاولة الحصول على userId من عدة حقول محتملة
      return profile['userId']?.toString() ?? 
             profile['UserId']?.toString() ?? 
             profile['id']?.toString() ?? 
             profile['Id']?.toString();
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      final isLogged = token != null && token.isNotEmpty;
      debugPrint('🔐 isLoggedIn check: $isLogged');
      return isLogged;
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');
      return false;
    }
  }
  
  /// التحقق الشامل من صحة البيانات المحفوظة
  static Future<bool> validateSavedAuth() async {
    try {
      debugPrint('🔍 Validating saved auth data...');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      
      final token = prefs.getString(tokenKey);
      final orgUrl = prefs.getString(orgUrlKey);
      final userDataString = prefs.getString(userDataKey);
      
      debugPrint('   - Token: ${token != null ? "✓" : "✗"}');
      debugPrint('   - OrgUrl: ${orgUrl != null ? "✓" : "✗"}');
      debugPrint('   - UserData: ${userDataString != null ? "✓" : "✗"}');
      
      if (token == null || token.isEmpty) {
        debugPrint('❌ Validation failed: No token');
        return false;
      }
      
      if (orgUrl == null || orgUrl.isEmpty) {
        debugPrint('❌ Validation failed: No organization URL');
        return false;
      }
      
      if (userDataString == null || userDataString.isEmpty) {
        debugPrint('❌ Validation failed: No user data');
        return false;
      }
      
      // التحقق من صحة JSON
      try {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        if (!userData.containsKey('token') || !userData.containsKey('userType') || !userData.containsKey('profile')) {
          debugPrint('❌ Validation failed: Invalid user data structure');
          return false;
        }
      } catch (e) {
        debugPrint('❌ Validation failed: Corrupted JSON data - $e');
        return false;
      }
      
      debugPrint('✅ Validation successful: All auth data is valid');
      return true;
    } catch (e) {
      debugPrint('❌ Validation error: $e');
      return false;
    }
  }

  /// تحميل organization URL المحفوظ عند بدء التطبيق
  static Future<void> loadSavedOrganizationUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // إعادة تحميل البيانات من القرص
      final orgUrl = prefs.getString(orgUrlKey);
      
      if (orgUrl != null && orgUrl.isNotEmpty) {
        ApiConfig.setOrganizationBaseUrl(orgUrl);
        debugPrint('✅ Loaded saved organization URL: $orgUrl');
      } else {
        ApiConfig.resetBaseUrl();
        debugPrint('⚠️ No saved organization URL found');
      }
    } catch (e) {
      debugPrint('❌ Error loading organization URL: $e');
      ApiConfig.resetBaseUrl();
    }
  }

  /// مسح جميع بيانات المصادقة والكاش
  static Future<void> clearAuthData() async {
    try {
      // 1. إعادة تعيين baseUrl أولاً (قبل مسح أي حاجة)
      ApiConfig.resetBaseUrl();
      debugPrint('✅ Reset organization URL');
      
      // 2. مسح جميع SharedPreferences (كل الكاش)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ Cleared all SharedPreferences');
      
      // 3. مسح cache الملفات المؤقتة
      await _clearAppCache();
      
      debugPrint('✅ All cache and auth data cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing auth data: $e');
      // حتى لو فشل مسح الكاش، نكمل بإعادة تعيين baseUrl
      ApiConfig.resetBaseUrl();
    }
  }

  /// مسح cache الملفات المؤقتة للتطبيق
  static Future<void> _clearAppCache() async {
    try {
      // مسح temporary directory
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await _deleteDirectory(tempDir);
        debugPrint('✅ Cleared temporary directory');
      }

      // مسح application cache directory (Android/iOS)
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final cacheDir = await getApplicationCacheDirectory();
          if (cacheDir.existsSync()) {
            await _deleteDirectory(cacheDir);
            debugPrint('✅ Cleared application cache directory');
          }
        } catch (e) {
          debugPrint('⚠️ Could not clear application cache: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error clearing app cache: $e');
      // لا نرمي exception لأن مسح الكاش ليس ضرورياً للـ logout
    }
  }

  /// حذف محتويات مجلد بشكل كامل
  static Future<void> _deleteDirectory(Directory directory) async {
    try {
      if (directory.existsSync()) {
        final List<FileSystemEntity> entities = directory.listSync();
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (e) {
            debugPrint('⚠️ Could not delete ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error deleting directory: $e');
    }
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
        // استخدام baseUrl الحالي (organization URL)
        final clientWithToken = ApiClient(baseUrl: ApiConfig.baseUrl);
        await clientWithToken.post(endpoint: ApiConfig.logoutEndpoint);
      } catch (_) {
        // Ignore server errors, proceed to clear local data
      }
    }

    await clearAuthData();
    debugPrint('✅ Logout done');
  }

  // Change password for the currently authenticated user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // استخدام baseUrl الحالي (organization URL)
      final clientWithToken = ApiClient(baseUrl: ApiConfig.baseUrl);
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
