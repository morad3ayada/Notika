import '../../config/api_config.dart';
import '../../api/api_client.dart';
import '../models/profile_models.dart';

class ProfileService {
  final ApiClient _client = ApiClient(baseUrl: ApiConfig.baseUrl);

  Future<TeacherProfile> getTeacherProfile() async {
    final responseData = await _client.get(ApiConfig.profileEndpoint);
    if (responseData is Map<String, dynamic>) {
      if (responseData['profile'] != null) {
        return TeacherProfile.fromJson(responseData['profile']);
      }
      return TeacherProfile.fromJson(responseData);
    }
    throw Exception('استجابة غير متوقعة لملف المعلم');
  }

  Future<Organization> getOrganization() async {
    final responseData = await _client.get(ApiConfig.organizationEndpoint);
    if (responseData is Map<String, dynamic>) {
      if (responseData['organization'] != null) {
        return Organization.fromJson(responseData['organization']);
      }
      return Organization.fromJson(responseData);
    }
    throw Exception('استجابة غير متوقعة لبيانات المؤسسة');
  }

  Future<ProfileResult> getProfileResult() async {
    final responseData = await _client.get(ApiConfig.profileEndpoint);
    if (responseData is! Map<String, dynamic>) {
      throw Exception('استجابة غير متوقعة');
    }

    final profileJson = (responseData['profile'] as Map<String, dynamic>?) ?? responseData;
    final profile = TeacherProfile.fromJson(profileJson);

    // classes may come under top-level 'classes' or inside 'profile.classes'
    final classesJson = (responseData['classes'] as List?) ?? (profileJson['classes'] as List?) ?? const [];
    final classes = classesJson
        .whereType<Map<String, dynamic>>()
        .map((e) => TeacherClass.fromJson(e))
        .toList();

    Organization? organization;
    if (responseData['organization'] is Map<String, dynamic>) {
      organization = Organization.fromJson(responseData['organization'] as Map<String, dynamic>);
    }

    return ProfileResult(profile: profile, classes: classes, organization: organization);
  }
}
