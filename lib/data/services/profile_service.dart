import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../api/api_client.dart';
import '../models/profile_models.dart';

class ProfileService {
  // إنشاء ApiClient ديناميكياً ليستخدم ApiConfig.baseUrl الحالي
  ApiClient get _client => ApiClient(baseUrl: ApiConfig.baseUrl);

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
    final allClasses = classesJson
        .whereType<Map<String, dynamic>>()
        .map((e) => TeacherClass.fromJson(e))
        .toList();
    
    // إزالة التكرار: كل فصل يظهر مرة واحدة فقط بناءً على levelId و classId
    final classes = _removeDuplicateClasses(allClasses);

    Organization? organization;
    if (responseData['organization'] is Map<String, dynamic>) {
      organization = Organization.fromJson(responseData['organization'] as Map<String, dynamic>);
    }

    return ProfileResult(profile: profile, classes: classes, organization: organization);
  }

  // New: fetch profile with an explicit token and return the aggregated result
  Future<ProfileResult> getProfile(String token) async {
    final clientWithToken = ApiClient(baseUrl: ApiConfig.baseUrl, token: token);
    final responseData = await clientWithToken.get(ApiConfig.profileEndpoint);
    if (responseData is! Map<String, dynamic>) {
      throw Exception('استجابة غير متوقعة');
    }

    final profileJson = (responseData['profile'] as Map<String, dynamic>?) ?? responseData;
    final profile = TeacherProfile.fromJson(profileJson);

    final classesJson = (responseData['classes'] as List?) ?? (profileJson['classes'] as List?) ?? const [];
    final allClasses = classesJson
        .whereType<Map<String, dynamic>>()
        .map((e) => TeacherClass.fromJson(e))
        .toList();
    
    // إزالة التكرار: كل فصل يظهر مرة واحدة فقط بناءً على levelId و classId
    final classes = _removeDuplicateClasses(allClasses);

    Organization? organization;
    if (responseData['organization'] is Map<String, dynamic>) {
      organization = Organization.fromJson(responseData['organization'] as Map<String, dynamic>);
    }

    return ProfileResult(profile: profile, classes: classes, organization: organization);
  }

  /// إزالة الفصول المكررة بناءً على levelId و classId
  /// يحتفظ بأول فصل ويتجاهل التكرارات
  List<TeacherClass> _removeDuplicateClasses(List<TeacherClass> classes) {
    if (classes.isEmpty) {
      debugPrint('📚 No classes to process');
      return classes;
    }

    debugPrint('📚 Processing ${classes.length} classes from server...');
    
    final seen = <String>{};
    final uniqueClasses = <TeacherClass>[];
    int duplicatesRemoved = 0;

    for (final cls in classes) {
      // استخدام levelId و classId كمفتاح فريد
      final key = '${cls.levelId}_${cls.classId}';
      
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueClasses.add(cls);
        debugPrint('✅ Added: ${cls.levelName} ${cls.className}');
      } else {
        duplicatesRemoved++;
        debugPrint('⏭️  Skipped duplicate: ${cls.levelName} ${cls.className} (Subject: ${cls.subjectName})');
      }
    }

    debugPrint('📊 Result: ${uniqueClasses.length} unique classes (removed $duplicatesRemoved duplicates)');
    return uniqueClasses;
  }
}
