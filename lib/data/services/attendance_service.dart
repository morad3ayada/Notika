import '../../api/api_client.dart';
import '../../config/api_config.dart';

class AttendanceService {
  // إنشاء ApiClient ديناميكياً ليستخدم ApiConfig.baseUrl الحالي
  ApiClient get _client => ApiClient(baseUrl: ApiConfig.baseUrl);

  Future<List<Map<String, dynamic>>> getClassStudents({
    required String levelId,
    required String classId,
  }) async {
    final response = await _client.get(
      ApiConfig.classStudentsEndpoint,
      queryParams: {
        'LevelID': levelId,
        'ClassID': classId,
      },
    );

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    throw Exception('استجابة غير متوقعة لقائمة الطلاب');
  }
}
