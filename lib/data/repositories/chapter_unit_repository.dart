import '../models/chapter_unit_model.dart';
import '../../api/api_client.dart';
import '../../data/services/auth_service.dart';

class ChapterUnitRepository {
  final ApiClient _apiClient;

  ChapterUnitRepository(this._apiClient);

  Future<ChapterUnitResponse> getChapterUnits({
    required String levelSubjectId,
    required String levelId,
    required String classId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return ChapterUnitResponse(
          success: false,
          message: 'المستخدم غير مصدق عليه',
          data: [],
        );
      }

      final response = await _apiClient.get(
        '/api/fileclassification/getByLevelAndClass',
        queryParams: {
          'LevelSubjectId': levelSubjectId,
          'LevelId': levelId,
          'ClassId': classId,
        },
        headers: {
          'accept': 'text/plain',
          'Authorization': token, // ApiClient سيتعامل مع إزالة Bearer تلقائياً
        },
      );

      if (response != null) {
        // التحقق من نوع الـ response
        if (response is List<dynamic>) {
          // حالة الـ API يرجع List مباشرة
          return ChapterUnitResponse.fromList(response);
        } else if (response is Map<String, dynamic>) {
          // حالة الـ API يرجع Map مع success, message, data
          return ChapterUnitResponse.fromJson(response);
        } else {
          // حالة غير متوقعة
          return ChapterUnitResponse(
            success: false,
            message: 'نوع البيانات المستلم غير متوقع',
            data: [],
          );
        }
      } else {
        return ChapterUnitResponse(
          success: false,
          message: 'فشل في جلب البيانات',
          data: [],
        );
      }
    } catch (e) {
      return ChapterUnitResponse(
        success: false,
        message: 'حدث خطأ: $e',
        data: [],
      );
    }
  }
}