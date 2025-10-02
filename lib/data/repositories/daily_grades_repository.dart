import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_grades_model.dart';
import '../services/auth_service.dart';

/// Repository لإدارة الدرجات اليومية
class DailyGradesRepository {
  static const String baseUrl = 'https://nouraleelemorg.runasp.net/api';

  /// تحديث الدرجات اليومية بشكل جماعي
  Future<DailyGradesResponse> updateBulkDailyGrades(
      BulkDailyGradesRequest request) async {
    try {
      print('📝 تحديث الدرجات اليومية بشكل جماعي...');
      print('🎓 levelId: ${request.levelId}');
      print('🏫 classId: ${request.classId}');
      print('📚 subjectId: ${request.subjectId}');
      print('📅 date: ${request.date}');
      print('👥 عدد الطلاب: ${request.studentsDailyGrades.length}');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ لا يوجد token');
        return DailyGradesResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse('$baseUrl/dailygrade/UpdateBulk');

      final body = request.toJson();
      print('📦 البيانات المرسلة: ${jsonEncode(body)}');

      final response = await http.put(
        uri,
        headers: {
          'accept': 'text/plain',
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('📄 نص الاستجابة: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ تم تحديث الدرجات بنجاح');
        
        // محاولة تحليل الاستجابة
        try {
          if (response.body.isNotEmpty) {
            final responseData = jsonDecode(response.body);
            return DailyGradesResponse.success(
              message: responseData['message']?.toString() ?? 'تم حفظ الدرجات بنجاح',
              data: responseData,
            );
          }
        } catch (e) {
          print('⚠️ لم يتم تحليل الاستجابة: $e');
        }
        
        return DailyGradesResponse.success(
          message: 'تم حفظ الدرجات بنجاح',
        );
      } else if (response.statusCode == 400) {
        String errorMessage = 'خطأ في البيانات المُرسلة';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        return DailyGradesResponse.error(errorMessage);
      } else if (response.statusCode == 401) {
        return DailyGradesResponse.error(
            'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 403) {
        return DailyGradesResponse.error(
            'ليس لديك صلاحية لتحديث الدرجات');
      } else if (response.statusCode == 404) {
        return DailyGradesResponse.error('لم يتم العثور على البيانات المطلوبة');
      } else if (response.statusCode >= 500) {
        return DailyGradesResponse.error(
            'خطأ في الخادم، يرجى المحاولة لاحقاً');
      } else {
        return DailyGradesResponse.error(
            'حدث خطأ غير متوقع (${response.statusCode})');
      }
    } catch (e) {
      print('❌ خطأ في تحديث الدرجات: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        return DailyGradesResponse.error('لا يوجد اتصال بالإنترنت');
      } else if (e.toString().contains('TimeoutException')) {
        return DailyGradesResponse.error(
            'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى');
      } else if (e.toString().contains('FormatException')) {
        return DailyGradesResponse.error('خطأ في تنسيق البيانات');
      } else {
        return DailyGradesResponse.error(
            'حدث خطأ أثناء حفظ الدرجات: ${e.toString()}');
      }
    }
  }
}
