import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthService.tokenKey);
    final userDataString = prefs.getString(AuthService.userDataKey);
    
    if (token != null && userDataString != null) {
      _token = token;
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      
      _userProfile = UserProfile.fromJson(userData);
      
      if (userData['organization'] != null) {
        _organization = Organization.fromJson(userData['organization']);
      }
      
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AuthService.tokenKey);
    await prefs.remove(AuthService.userDataKey);
    
    _token = null;
    _userProfile = null;
    _organization = null;
    
    notifyListeners();
  }
}
