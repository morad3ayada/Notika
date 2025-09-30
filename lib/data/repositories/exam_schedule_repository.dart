import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exam_schedule_model.dart';
import '../services/auth_service.dart';

/// Repository لإدارة جدول الامتحانات
class ExamScheduleRepository {
  static const String baseUrl = 'https://nouraleelemorg.runasp.net/api';

  /// جلب جدول الامتحانات للمرحلة والشعبة المحددة
  Future<ExamScheduleResponse> getClassExamSchedules({
    required String levelId,
    required String classId,
  }) async {
    try {
      print('📅 جلب جدول الامتحانات للمرحلة: $levelId والشعبة: $classId');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ExamScheduleResponse.error('لم يتم العثور على رمز المصادقة');
      }

      // بناء الرابط
      final url = Uri.parse(
        '$baseUrl/examschedule/ClassExamSchedules?LevelId=$levelId&ClassId=$classId'
      );

      print('🌐 إرسال طلب إلى: $url');

      // إرسال الطلب
      final response = await http.get(
        url,
        headers: {
          'accept': 'text/plain',
          'Authorization': token, // بدون Bearer كما هو مطلوب
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال بالخادم');
        },
      );

      print('📡 رد الخادم - الكود: ${response.statusCode}');
      print('📡 رد الخادم - البيانات: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        
        // التحقق من وجود بيانات
        if (responseBody.isEmpty || responseBody.trim() == '[]') {
          print('📅 لا توجد امتحانات مجدولة');
          return ExamScheduleResponse.empty();
        }

        // محاولة تحليل JSON
        try {
          final dynamic jsonData = json.decode(responseBody);
          
          // إذا كانت البيانات عبارة عن قائمة مباشرة
          if (jsonData is List) {
            final schedules = jsonData
                .map((item) => ExamScheduleModel.fromJson(item as Map<String, dynamic>))
                .toList();
            
            return ExamScheduleResponse(
              success: true,
              message: 'تم جلب ${schedules.length} امتحان بنجاح',
              schedules: schedules,
              totalCount: schedules.length,
            );
          }
          
          // إذا كانت البيانات عبارة عن كائن يحتوي على قائمة
          if (jsonData is Map<String, dynamic>) {
            return ExamScheduleResponse.fromJson(jsonData);
          }
          
          return ExamScheduleResponse.error('تنسيق البيانات غير صحيح');
          
        } catch (e) {
          print('❌ خطأ في تحليل JSON: $e');
          return ExamScheduleResponse.error('خطأ في تحليل البيانات من الخادم');
        }
        
      } else if (response.statusCode == 401) {
        return ExamScheduleResponse.error('انتهت صلاحية جلسة المستخدم، يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 404) {
        return ExamScheduleResponse.error('لم يتم العثور على بيانات الامتحانات');
      } else if (response.statusCode == 500) {
        return ExamScheduleResponse.error('خطأ في الخادم، يرجى المحاولة لاحقاً');
      } else {
        return ExamScheduleResponse.error(
          'خطأ في الاتصال بالخادم (${response.statusCode}): ${response.body}'
        );
      }
      
    } catch (e) {
      print('❌ خطأ في جلب جدول الامتحانات: $e');
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('NetworkException')) {
        return ExamScheduleResponse.error('تحقق من اتصال الإنترنت وحاول مرة أخرى');
      } else if (e.toString().contains('TimeoutException') ||
                 e.toString().contains('انتهت مهلة الاتصال')) {
        return ExamScheduleResponse.error('انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى');
      } else {
        return ExamScheduleResponse.error('حدث خطأ غير متوقع: ${e.toString()}');
      }
    }
  }

  /// جلب جدول امتحانات مادة معينة
  Future<ExamScheduleResponse> getSubjectExamSchedules({
    required String levelId,
    required String classId,
    required String subjectId,
  }) async {
    try {
      print('📅 جلب جدول امتحانات المادة: $subjectId');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ExamScheduleResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final url = Uri.parse(
        '$baseUrl/examschedule/SubjectExamSchedules?LevelId=$levelId&ClassId=$classId&SubjectId=$subjectId'
      );

      final response = await http.get(
        url,
        headers: {
          'accept': 'text/plain',
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        
        if (responseBody.isEmpty || responseBody.trim() == '[]') {
          return ExamScheduleResponse.empty();
        }

        final dynamic jsonData = json.decode(responseBody);
        
        if (jsonData is List) {
          final schedules = jsonData
              .map((item) => ExamScheduleModel.fromJson(item as Map<String, dynamic>))
              .toList();
          
          return ExamScheduleResponse(
            success: true,
            message: 'تم جلب امتحانات المادة بنجاح',
            schedules: schedules,
            totalCount: schedules.length,
          );
        }
        
        if (jsonData is Map<String, dynamic>) {
          return ExamScheduleResponse.fromJson(jsonData);
        }
        
        return ExamScheduleResponse.error('تنسيق البيانات غير صحيح');
        
      } else {
        return ExamScheduleResponse.error('خطأ في جلب بيانات المادة (${response.statusCode})');
      }
      
    } catch (e) {
      print('❌ خطأ في جلب جدول امتحانات المادة: $e');
      return ExamScheduleResponse.error('حدث خطأ في جلب بيانات المادة');
    }
  }

  /// البحث في جدول الامتحانات
  Future<ExamScheduleResponse> searchExamSchedules({
    required String levelId,
    required String classId,
    String? subjectName,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // جلب جميع الامتحانات أولاً
      final allSchedules = await getClassExamSchedules(
        levelId: levelId,
        classId: classId,
      );

      if (!allSchedules.success) {
        return allSchedules;
      }

      // تطبيق الفلاتر
      List<ExamScheduleModel> filteredSchedules = allSchedules.schedules;

      // فلتر حسب اسم المادة
      if (subjectName != null && subjectName.isNotEmpty) {
        filteredSchedules = filteredSchedules.where((schedule) {
          return schedule.subjectName?.toLowerCase().contains(subjectName.toLowerCase()) ?? false;
        }).toList();
      }

      // فلتر حسب التاريخ
      if (fromDate != null) {
        filteredSchedules = filteredSchedules.where((schedule) {
          return schedule.examDate?.isAfter(fromDate.subtract(const Duration(days: 1))) ?? false;
        }).toList();
      }

      if (toDate != null) {
        filteredSchedules = filteredSchedules.where((schedule) {
          return schedule.examDate?.isBefore(toDate.add(const Duration(days: 1))) ?? false;
        }).toList();
      }

      return ExamScheduleResponse(
        success: true,
        message: 'تم العثور على ${filteredSchedules.length} امتحان',
        schedules: filteredSchedules,
        totalCount: filteredSchedules.length,
      );

    } catch (e) {
      print('❌ خطأ في البحث: $e');
      return ExamScheduleResponse.error('حدث خطأ أثناء البحث');
    }
  }
}
