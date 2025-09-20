import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class Organization {
  final String id;
  final String name;
  final String? logo;
  final String? url;
  final DateTime? startStudyDate;
  final DateTime? endStudyDate;

  Organization({
    required this.id,
    required this.name,
    this.logo,
    this.url,
    this.startStudyDate,
    this.endStudyDate,
  });

  factory Organization.fromJson(Map<String, dynamic>? json) {
    try {
      if (json == null) {
        debugPrint('Organization JSON is null');
        return Organization(id: '', name: 'Unknown');
      }
      
      // Debug log the JSON keys
      debugPrint('Organization JSON keys: ${json.keys.join(', ')}');
      
      return Organization(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown',
        logo: json['logo']?.toString(),
        url: json['url']?.toString(),
        startStudyDate: json['startStudyDate'] != null 
            ? DateTime.tryParse(json['startStudyDate'].toString())
            : null,
        endStudyDate: json['endStudyDate'] != null 
            ? DateTime.tryParse(json['endStudyDate'].toString())
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Organization: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON data: $json');
      // Return a default organization instead of failing
      return Organization(id: 'error', name: 'Error Organization');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo': logo,
    'url': url,
    'startStudyDate': startStudyDate?.toIso8601String(),
    'endStudyDate': endStudyDate?.toIso8601String(),
  };
}

class UserProfile {
  final String userId;
  final String userName;
  final String userType;
  final String fullName;
  final String firstName;
  final String secondName;
  final String? thirdName;
  final String? fourthName;
  final String? phone;

  UserProfile({
    required this.userId,
    required this.userName,
    required this.userType,
    required this.fullName,
    required this.firstName,
    required this.secondName,
    this.thirdName,
    this.fourthName,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic>? json) {
    try {
      if (json == null) {
        throw const FormatException('UserProfile JSON is null');
      }
      
      // Debug log the JSON keys
      debugPrint('UserProfile JSON keys: ${json.keys.join(', ')}');
      
      // Handle case where profile data is nested under 'user' key
      final userData = json['user'] ?? json;
      
      // Check for required fields
      final requiredFields = ['userId', 'userName', 'userType', 'fullName', 'firstName', 'secondName'];
      for (final field in requiredFields) {
        if (userData[field] == null) {
          debugPrint('Warning: Missing required field: $field');
        }
      }
      
      return UserProfile(
        userId: userData['userId']?.toString() ?? '',
        userName: userData['userName']?.toString() ?? '',
        userType: userData['userType']?.toString() ?? '',
        fullName: userData['fullName']?.toString() ?? '',
        firstName: userData['firstName']?.toString() ?? '',
        secondName: userData['secondName']?.toString() ?? '',
        thirdName: userData['thirdName']?.toString(),
        fourthName: userData['fourthName']?.toString(),
        phone: userData['phone']?.toString(),
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing UserProfile: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userType': userType,
    'fullName': fullName,
    'firstName': firstName,
    'secondName': secondName,
    'thirdName': thirdName,
    'fourthName': fourthName,
    'phone': phone,
  };
}

class LoginResponse {
  final String token;
  final String userType;
  final UserProfile profile;
  final Organization? organization;
  final String? message;

  LoginResponse({
    required this.token,
    required this.userType,
    required this.profile,
    this.organization,
    this.message,
  });

  factory LoginResponse.fromJson(dynamic json) {
    try {
      if (json == null) {
        throw const FormatException('Response is null');
      }
      
      if (json is! Map<String, dynamic>) {
        throw FormatException('Expected a Map<String, dynamic> but got ${json.runtimeType}');
      }
      
      // Debug log the JSON keys
      debugPrint('LoginResponse JSON keys: ${json.keys.join(', ')}');
      
      // Check for required fields
      if (json['token'] == null) {
        throw const FormatException('Missing required field: token');
      }
      
      if (json['userType'] == null) {
        throw const FormatException('Missing required field: userType');
      }
      
      if (json['profile'] == null) {
        throw const FormatException('Missing required field: profile');
      }
      
      // Handle case where profile data might be in 'user' instead of 'profile'
      final profileData = json['profile'] ?? json['user'];
      if (profileData == null) {
        throw const FormatException('Missing both profile and user fields in response');
      }
      
      return LoginResponse(
        token: json['token'] as String,
        userType: json['userType'] as String,
        profile: UserProfile.fromJson(profileData as Map<String, dynamic>),
        organization: json['organization'] != null 
            ? Organization.fromJson(json['organization'] as Map<String, dynamic>)
            : null,
        message: json['message'] as String?,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing LoginResponse: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}
