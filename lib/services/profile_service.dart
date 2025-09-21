import '../models/profile_models.dart';
import '../config/api_config.dart';
import '../api/api_client.dart';

class ProfileService {
  final String baseUrl = ApiConfig.baseUrl;
  final String profileEndpoint = '/api/profileAuthorized';
  final String organizationEndpoint = '/api/profile/organizationAuthorized';
  final ApiClient _client = ApiClient(baseUrl: ApiConfig.baseUrl);

  Future<TeacherProfile> getTeacherProfile(String token) async {
    // Ignore incoming token param and use centralized ApiClient which reads token from SharedPreferences
    final responseData = await _client.get(profileEndpoint);
    try {
      // Handle both direct profile object and nested profile object
      if (responseData['profile'] != null) {
        return TeacherProfile.fromJson(responseData['profile']);
      }
      return TeacherProfile.fromJson(responseData);
    } catch (e) {
      print('Error parsing profile data: $e');
      rethrow;
    }
  }

  Future<Organization> getOrganization(String token) async {
    // Ignore incoming token param and use centralized ApiClient which reads token from SharedPreferences
    final responseData = await _client.get(organizationEndpoint);
    try {
      // Handle both direct organization object and nested organization object
      if (responseData['organization'] != null) {
        return Organization.fromJson(responseData['organization']);
      }
      return Organization.fromJson(responseData);
    } catch (e) {
      print('Error parsing organization data: $e');
      rethrow;
    }
  }
}
