import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import '../models/term_grades_model.dart';
import '../services/auth_service.dart';
import '../../config/api_config.dart';

/// Repository لإدارة الدرجات الفصلية
class TermGradesRepository {
  String get baseUrl => '${ApiConfig.baseUrl}/api';

  /// جلب درجات طلاب الفصل الفصلية
  Future<TermGradesResponse> getClassStudentsTermGrades({
    required String subjectId,
    required String levelId,
    required String classId,
  }) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('📚 جلب الدرجات الفصلية لطلاب الفصل');
      print('═══════════════════════════════════════════════════════');
      print('📋 Parameters:');
      print('   - SubjectId: $subjectId');
      print('   - LevelId: $levelId');
      print('   - ClassId: $classId');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ لا يوجد token');
        return TermGradesResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse(
          '$baseUrl/grade/ClassStudents?SubjectId=$subjectId&LevelId=$levelId&ClassId=$classId');

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

          final List<StudentTermGrades> studentGrades = [];
          for (int i = 0; i < studentsData.length; i++) {
            try {
              print('═══════════════════════════════════════════════════════');
              print('📝 تحليل بيانات الطالب رقم $i');
              print('📦 Raw JSON: ${jsonEncode(studentsData[i])}');
              
              // طباعة جميع المفاتيح المتاحة في البيانات
              print('🔑 المفاتيح المتاحة في البيانات:');
              (studentsData[i] as Map<String, dynamic>).forEach((key, value) {
                print('   - $key: $value (${value.runtimeType})');
              });
              
              final studentGrade = StudentTermGrades.fromJson(studentsData[i]);
              studentGrades.add(studentGrade);
              
              print('✅ تم تحليل درجات طالب رقم $i بنجاح:');
              print('   - studentId: ${studentGrade.studentId}');
              print('   - studentName: "${studentGrade.studentName}"');
              print('   - firstTermAverage: ${studentGrade.firstTermAverage}');
              print('   - midtermExam: ${studentGrade.midtermExam}');
              print('   - secondTermAverage: ${studentGrade.secondTermAverage}');
              print('   - annualAverage: ${studentGrade.annualAverage}');
              print('═══════════════════════════════════════════════════════');
            } catch (e, stackTrace) {
              print('⚠️ خطأ في تحليل درجات طالب رقم $i: $e');
              print('Stack trace: $stackTrace');
            }
          }

          print('✅ تم جلب درجات ${studentGrades.length} طالب بنجاح');

          return TermGradesResponse.success(studentGrades);
        } catch (e) {
          print('❌ خطأ في تحليل JSON: $e');
          return TermGradesResponse.error('خطأ في تحليل البيانات من السيرفر');
        }
      } else if (response.statusCode == 401) {
        return TermGradesResponse.error(
            'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 404) {
        // لا توجد درجات - نرجع قائمة فارغة
        return TermGradesResponse.success([]);
      } else {
        return TermGradesResponse.error(
            'فشل جلب الدرجات. كود الخطأ: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في جلب الدرجات: $e');
      return TermGradesResponse.error(
          'خطأ في الاتصال بالسيرفر: ${e.toString()}');
    }
  }
}

/// استجابة API للدرجات الفصلية
class TermGradesResponse extends Equatable {
  final bool success;
  final String? message;
  final List<StudentTermGrades> studentGrades;

  const TermGradesResponse({
    required this.success,
    this.message,
    required this.studentGrades,
  });

  factory TermGradesResponse.success(List<StudentTermGrades> grades) {
    return TermGradesResponse(
      success: true,
      studentGrades: grades,
    );
  }

  factory TermGradesResponse.error(String message) {
    return TermGradesResponse(
      success: false,
      message: message,
      studentGrades: const [],
    );
  }

  @override
  List<Object?> get props => [success, message, studentGrades];
}
