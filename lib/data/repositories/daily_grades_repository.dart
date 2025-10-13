import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
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

  /// جلب درجات طلاب الفصل
  Future<ClassStudentsGradesResponse> getClassStudentsGrades({
    required String subjectId,
    required String levelId,
    required String classId,
    required String date, // بصيغة "2-10-2025"
  }) async {
    try {
      print('📚 جلب درجات طلاب الفصل...');
      print('📚 subjectId: $subjectId');
      print('🎓 levelId: $levelId');
      print('🏫 classId: $classId');
      print('📅 date: $date');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ لا يوجد token');
        return ClassStudentsGradesResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse(
          '$baseUrl/dailygrade/ClassStudents?SubjectId=$subjectId&LevelId=$levelId&ClassId=$classId&Date=$date');

      print('🌐 إرسال طلب إلى: $uri');

      final response = await http.get(
        uri,
        headers: {
          'accept': 'text/plain',
          'Authorization': token,
        },
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('📄 نص الاستجابة: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        try {
          final dynamic responseData = jsonDecode(response.body);

          // التحقق من شكل الاستجابة
          List<dynamic> studentsData;
          
          if (responseData is List) {
            studentsData = responseData;
          } else if (responseData is Map) {
            studentsData = responseData['data'] as List? ??
                responseData['students'] as List? ??
                responseData['items'] as List? ??
                [];
          } else {
            studentsData = [];
          }

          print('📋 عدد الطلاب من السيرفر: ${studentsData.length}');

          final List<StudentDailyGrades> studentGrades = [];
          for (int i = 0; i < studentsData.length; i++) {
            try {
              print('📝 تحليل بيانات الطالب رقم $i: ${studentsData[i]}');
              final studentGrade = StudentDailyGrades.fromJson(studentsData[i]);
              studentGrades.add(studentGrade);
              print('✅ تم تحليل درجات طالب رقم $i: ${studentGrade.studentId}');
              print('   - عدد dailyGrades: ${studentGrade.dailyGrades.length}');
              print('   - عدد quizzes: ${studentGrade.quizzes.length}');
              print('   - عدد assignments: ${studentGrade.assignments.length}');
              print('   - absenceTimes: ${studentGrade.absenceTimes}');
            } catch (e, stackTrace) {
              print('⚠️ خطأ في تحليل درجات طالب رقم $i: $e');
              print('Stack trace: $stackTrace');
            }
          }

          print('✅ تم جلب درجات ${studentGrades.length} طالب بنجاح');

          return ClassStudentsGradesResponse.success(studentGrades);
        } catch (e) {
          print('❌ خطأ في تحليل JSON: $e');
          return ClassStudentsGradesResponse.error('خطأ في تحليل البيانات من السيرفر');
        }
      } else if (response.statusCode == 401) {
        return ClassStudentsGradesResponse.error(
            'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 404) {
        // لا توجد درجات - نرجع قائمة فارغة
        return ClassStudentsGradesResponse.success([]);
      } else {
        return ClassStudentsGradesResponse.error(
            'فشل جلب الدرجات. كود الخطأ: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في جلب الدرجات: $e');
      return ClassStudentsGradesResponse.error(
          'خطأ في الاتصال بالسيرفر: ${e.toString()}');
    }
  }
}

/// استجابة API لدرجات طلاب الفصل
class ClassStudentsGradesResponse extends Equatable {
  final bool success;
  final String? message;
  final List<StudentDailyGrades> studentGrades;

  const ClassStudentsGradesResponse({
    required this.success,
    this.message,
    required this.studentGrades,
  });

  factory ClassStudentsGradesResponse.success(List<StudentDailyGrades> grades) {
    return ClassStudentsGradesResponse(
      success: true,
      studentGrades: grades,
    );
  }

  factory ClassStudentsGradesResponse.error(String message) {
    return ClassStudentsGradesResponse(
      success: false,
      message: message,
      studentGrades: const [],
    );
  }

  @override
  List<Object?> get props => [success, message, studentGrades];
}
