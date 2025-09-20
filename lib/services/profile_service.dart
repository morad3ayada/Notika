import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile_models.dart';
import '../config/api_config.dart';

class ProfileService {
  final String baseUrl = ApiConfig.baseUrl;
  final String profileEndpoint = '/api/profileAuthorized';
  final String organizationEndpoint = '/api/profile/organizationAuthorized';

  Future<TeacherProfile> getTeacherProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl$profileEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final responseData = json.decode(response.body);
        // Handle both direct profile object and nested profile object
        if (responseData['profile'] != null) {
          return TeacherProfile.fromJson(responseData['profile']);
        }
        return TeacherProfile.fromJson(responseData);
      } catch (e) {
        print('Error parsing profile data: $e');
        rethrow;
      }
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load teacher profile');
    }
  }

  Future<Organization> getOrganization(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl$organizationEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        final responseData = json.decode(response.body);
        // Handle both direct organization object and nested organization object
        if (responseData['organization'] != null) {
          return Organization.fromJson(responseData['organization']);
        }
        return Organization.fromJson(responseData);
      } catch (e) {
        print('Error parsing organization data: $e');
        rethrow;
      }
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to load organization');
    }
  }
}
