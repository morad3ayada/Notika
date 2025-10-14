import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import '../models/daily_grades_model.dart';
import '../services/auth_service.dart';
import '../../config/api_config.dart';

/// Repository لإدارة الدرجات اليومية
class DailyGradesRepository {
  String get baseUrl => '${ApiConfig.baseUrl}/api';

  /// تحديث الدرجات اليومية بشكل جماعي
  Future<DailyGradesResponse> updateBulkDailyGrades(
      BulkDailyGradesRequest request) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('📝 تحديث الدرجات اليومية بشكل جماعي');
      print('═══════════════════════════════════════════════════════');
      print('📋 بيانات الطلب الأساسية:');
      print('   - LevelId: ${request.levelId}');
      print('   - ClassId: ${request.classId}');
      print('   - SubjectId: ${request.subjectId}');
      print('   - Date: ${request.date.toIso8601String()}');
      print('   - عدد الطلاب: ${request.studentsDailyGrades.length}');
      print('');
      
      // طباعة بيانات كل طالب
      for (int i = 0; i < request.studentsDailyGrades.length; i++) {
        final student = request.studentsDailyGrades[i];
        print('📊 طالب #$i:');
        print('   - StudentId: ${student.studentId}');
        print('   - StudentClassSubjectId: ${student.studentClassSubjectId}');
        print('   - عدد الدرجات: ${student.dailyGrades.length}');
        for (var grade in student.dailyGrades) {
          print('      * Grade: ${grade.grade}, TitleId: ${grade.dailyGradeTitleId}');
        }
      }
      print('═══════════════════════════════════════════════════════');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ لا يوجد token');
        return DailyGradesResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse('$baseUrl/dailygrade/UpdateBulk');

      final body = request.toJson();
      print('');
      print('📦 JSON الكامل المرسل:');
      print(jsonEncode(body));
      print('');
      print('🚀 إرسال الطلب إلى: $uri');

      final response = await http.put(
        uri,
        headers: {
          'accept': 'text/plain',
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('');
      print('📊 استجابة السيرفر:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Body: ${response.body}');
      print('');

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
        print('❌ خطأ 400: Bad Request');
        print('📄 Response Body الكامل:');
        print(response.body);
        
        String errorMessage = 'خطأ في البيانات الأساسية';
        try {
          final errorData = jsonDecode(response.body);
          print('📋 Error Details:');
          print(jsonEncode(errorData));
          
          // محاولة استخراج رسالة الخطأ
          if (errorData is Map) {
            errorMessage = errorData['message']?.toString() ?? 
                          errorData['title']?.toString() ??
                          errorData['detail']?.toString() ??
                          errorData.toString();
            
            // إذا كان هناك errors array
            if (errorData['errors'] != null) {
              final errors = errorData['errors'];
              print('🔍 Validation Errors:');
              print(jsonEncode(errors));
              
              if (errors is Map) {
                final errorsList = <String>[];
                errors.forEach((key, value) {
                  if (value is List) {
                    errorsList.addAll(value.map((e) => '$key: $e'));
                  } else {
                    errorsList.add('$key: $value');
                  }
                });
                if (errorsList.isNotEmpty) {
                  errorMessage = 'أخطاء في البيانات:\n${errorsList.join('\n')}';
                }
              }
            }
          }
        } catch (e) {
          print('⚠️ خطأ في تحليل رسالة الخطأ: $e');
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
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
    required String date, // بصيغة "2025-10-14"
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('📚 جلب درجات طلاب الفصل');
      print('═══════════════════════════════════════════════════════');
      print('📋 Parameters:');
      print('   - SubjectId: $subjectId');
      print('   - LevelId: $levelId');
      print('   - ClassId: $classId');
      print('   - Date: $date');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ لا يوجد token');
        return ClassStudentsGradesResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse(
          '$baseUrl/dailygrade/ClassStudents?SubjectId=$subjectId&LevelId=$levelId&ClassId=$classId&Date=$date');

      print('🌐 Full URL: $uri');
      print('🔑 Token: ${token.substring(0, 50)}...');
      print('');
      print('📨 cURL equivalent:');
      print("curl -X 'GET' \\");
      print("  '$uri' \\");
      print("  -H 'accept: text/plain' \\");
      print("  -H 'Authorization: $token'");
      print('');
      print('🚀 إرسال الطلب...');

      final response = await http.get(
        uri,
        headers: {
          'accept': 'text/plain',
          'Authorization': token,
        },
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📄 FULL RESPONSE FROM SERVER:');
      print('═══════════════════════════════════════════════════════');
      print(response.body);
      print('═══════════════════════════════════════════════════════');
      print('');

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
              print('═══════════════════════════════════════════════════════');
              print('📝 تحليل بيانات الطالب رقم $i');
              print('📦 Raw JSON: ${jsonEncode(studentsData[i])}');
              
              final studentGrade = StudentDailyGrades.fromJson(studentsData[i]);
              studentGrades.add(studentGrade);
              
              print('✅ تم تحليل درجات طالب رقم $i بنجاح:');
              print('   - studentId: ${studentGrade.studentId}');
              print('   - studentClassSubjectId: ${studentGrade.studentClassSubjectId}');
              print('   - عدد dailyGrades: ${studentGrade.dailyGrades.length}');
              print('   - عدد quizzes: ${studentGrade.quizzes.length}');
              print('   - عدد assignments: ${studentGrade.assignments.length}');
              print('   - absenceTimes: ${studentGrade.absenceTimes}');
              print('═══════════════════════════════════════════════════════');
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
