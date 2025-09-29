import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chapter_unit_model.dart';
import '../../config/api_config.dart';
import '../../api/api_client.dart';

class ChapterUnitService {
  final ApiClient _apiClient;

  ChapterUnitService(this._apiClient);

  Future<ChapterUnitResponse> getChapterUnits({
    required int levelSubjectId,
    required int levelId,
    required int classId,
    required String token,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/fileclassification/getByLevelAndClass',
        queryParams: {
          'LevelSubjectId': levelSubjectId.toString(),
          'LevelId': levelId.toString(),
          'ClassId': classId.toString(),
        },
        headers: {
          'accept': 'text/plain',
          'Authorization': token, // ApiClient سيتعامل مع إزالة Bearer تلقائياً
        },
      );

      if (response != null) {
        return ChapterUnitResponse.fromJson(response);
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