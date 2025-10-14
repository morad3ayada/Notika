import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/auth_models.dart';
import '../data/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  String? _token;
  UserProfile? _userProfile;
  Organization? _organization;
  
  // Getters
  String? get token => _token;
  UserProfile? get userProfile => _userProfile;
  Organization? get organization => _organization;
  bool get isAuthenticated => _token != null;
  
  // Initialize from shared preferences
  Future<void> loadUserData() async {
    try {
      debugPrint('👤 UserProvider: Loading user data...');
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ UserProvider: SharedPreferences timeout!');
          throw TimeoutException('SharedPreferences timeout');
        },
      );
      await prefs.reload().catchError((e) {
        debugPrint('⚠️ UserProvider: reload error (non-critical): $e');
        // نواصل حتى لو فشل reload
      }); // إعادة تحميل البيانات من القرص
      
      final token = prefs.getString(AuthService.tokenKey);
      final userDataString = prefs.getString(AuthService.userDataKey);
      
      debugPrint('👤 UserProvider: Token exists: ${token != null}, UserData exists: ${userDataString != null}');
      
      if (token != null && userDataString != null) {
        debugPrint('👤 UserProvider: Found saved token (${token.substring(0, 10)}...) and user data (${userDataString.length} chars)');
        _token = token;
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        debugPrint('👤 UserProvider: User data keys: ${userData.keys.toList()}');
        
        // Load nested profile from saved JSON
        final profileJson = userData['profile'] as Map<String, dynamic>?;
        if (profileJson != null) {
          _userProfile = UserProfile.fromJson(profileJson);
          debugPrint('👤 UserProvider: Loaded profile for user: ${_userProfile!.userName}');
        } else {
          debugPrint('⚠️ UserProvider: No profile data found');
          _userProfile = null;
        }
        
        // Enforce Teacher-only session restore
        final userType = _userProfile?.userType.trim().toLowerCase();
        debugPrint('👤 UserProvider: User type: $userType');
        
        if (userType != 'teacher') {
          // Clear invalid session data ONLY for non-teachers
          debugPrint('❌ UserProvider: Invalid user type "$userType", clearing session');
          await prefs.remove(AuthService.tokenKey);
          await prefs.remove(AuthService.userDataKey);
          await prefs.commit(); // إجبار حفظ التغييرات
          _token = null;
          _userProfile = null;
          _organization = null;
          notifyListeners();
          return;
        }
        
        if (userData['organization'] != null) {
          _organization = Organization.fromJson(userData['organization'] as Map<String, dynamic>);
          debugPrint('👤 UserProvider: Loaded organization: ${_organization!.name}');
        }

        // Merge saved organization URL if available but not present in saved org object
        final savedOrgUrl = prefs.getString(AuthService.orgUrlKey);
        if (_organization != null && (_organization!.url == null || _organization!.url!.isEmpty) && savedOrgUrl != null && savedOrgUrl.isNotEmpty) {
          _organization = Organization(
            id: _organization!.id,
            name: _organization!.name,
            logo: _organization!.logo,
            url: savedOrgUrl,
            startStudyDate: _organization!.startStudyDate,
            endStudyDate: _organization!.endStudyDate,
          );
          debugPrint('👤 UserProvider: Merged organization URL: $savedOrgUrl');
        }
        
        debugPrint('✅ UserProvider: User data loaded successfully for teacher ${_userProfile!.userName}');
        notifyListeners();
      } else {
        debugPrint('⚠️ UserProvider: No saved token or user data found (token: ${token != null}, userData: ${userDataString != null})');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ UserProvider: Error loading user data: $e');
      debugPrint('Stack trace: $stackTrace');
      // لا نمسح البيانات المحفوظة عند حدوث خطأ في التحميل
      // فقط نعيّن القيم على null ونستمر
      _token = null;
      _userProfile = null;
      _organization = null;
      notifyListeners();
    }
  }
  
  // Update user data
  void updateUserData(LoginResponse response) {
    _token = response.token;
    _userProfile = response.profile;
    _organization = response.organization;
    notifyListeners();
  }
  
  // Clear user data on logout
  Future<void> logout() async {
    // استخدام دالة مسح الكاش الشاملة من AuthService
    await AuthService.clearAuthData();
    
    _token = null;
    _userProfile = null;
    _organization = null;
    
    notifyListeners();
    debugPrint('✅ UserProvider: Logged out and cleared all data');
  }
}
