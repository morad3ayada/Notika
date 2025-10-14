import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/class_students_model.dart';
import '../services/auth_service.dart';
import '../../config/api_config.dart';

/// Repository لجلب بيانات طلاب الفصل من السيرفر
class ClassStudentsRepository {
  String get baseUrl => '${ApiConfig.baseUrl}/api';

  /// جلب طلاب الفصل من السيرفر
  Future<ClassStudentsResponse> getClassStudents({
    required String levelId,
    required String classId,
  }) async {
    try {
      print('📚 جلب طلاب الفصل...');
      print('🔍 LevelId: $levelId');
      print('🔍 ClassId: $classId');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ClassStudentsResponse.error('لم يتم العثور على رمز المصادقة');
      }

      // بناء الرابط مع query parameters
      final queryParams = {
        'LevelId': levelId,
        'ClassId': classId,
      };
      
      final uri = Uri.parse('$baseUrl/school/ClassStudents').replace(
        queryParameters: queryParams,
      );
      
      print('🌐 إرسال طلب إلى: $uri');

      // إرسال الطلب
      final response = await http.get(
        uri,
        headers: {
          'accept': 'text/plain',
          'Authorization': token, // بدون Bearer حسب النمط المُتبع في المشروع
        },
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('📄 نص الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        // نجح الطلب
        try {
          // محاولة تحليل الاستجابة كـ JSON array مباشرة
          final List<dynamic> studentsData = jsonDecode(response.body);
          
          // طباعة البيانات الخام للتشخيص
          print('📋 البيانات الخام من السيرفر:');
          for (int i = 0; i < studentsData.length && i < 3; i++) {
            print('طالب $i: ${studentsData[i]}');
          }
          
          final students = studentsData.map((studentJson) => Student.fromJson(studentJson)).toList();
          
          print('✅ تم جلب ${students.length} طالب بنجاح');
          print('📝 أول طالب محول: ${students.isNotEmpty ? students.first.toJson() : 'لا يوجد'}');
          
          return ClassStudentsResponse.success(
            students: students,
            message: 'تم جلب ${students.length} طالب بنجاح',
          );
        } catch (e) {
          print('❌ خطأ في تحليل البيانات: $e');
          
          // محاولة تحليل كـ object يحتوي على array
          try {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            return ClassStudentsResponse.fromJson(responseData);
          } catch (e2) {
            return ClassStudentsResponse.error('خطأ في تحليل بيانات الطلاب');
          }
        }
      } else if (response.statusCode == 400) {
        // خطأ في المعاملات المُرسلة
        String errorMessage = 'خطأ في معاملات الطلب';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
        }
        return ClassStudentsResponse.error(errorMessage);
      } else if (response.statusCode == 401) {
        return ClassStudentsResponse.error('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 403) {
        return ClassStudentsResponse.error('ليس لديك صلاحية للوصول لبيانات هذا الفصل');
      } else if (response.statusCode == 404) {
        return ClassStudentsResponse.error('لم يتم العثور على الفصل المحدد');
      } else if (response.statusCode >= 500) {
        return ClassStudentsResponse.error('خطأ في الخادم، يرجى المحاولة لاحقاً');
      } else {
        return ClassStudentsResponse.error('حدث خطأ غير متوقع (${response.statusCode})');
      }
    } catch (e) {
      print('❌ خطأ في جلب طلاب الفصل: $e');
      
      if (e.toString().contains('SocketException') || e.toString().contains('NetworkException')) {
        return ClassStudentsResponse.error('لا يوجد اتصال بالإنترنت');
      } else if (e.toString().contains('TimeoutException')) {
        return ClassStudentsResponse.error('انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى');
      } else if (e.toString().contains('FormatException')) {
        return ClassStudentsResponse.error('خطأ في تنسيق البيانات المُستلمة');
      } else {
        return ClassStudentsResponse.error('حدث خطأ أثناء جلب البيانات: ${e.toString()}');
      }
    }
  }

  /// البحث عن طالب معين في الفصل (اختياري للمستقبل)
  Future<ClassStudentsResponse> searchStudents({
    required String levelId,
    required String classId,
    required String searchQuery,
  }) async {
    try {
      // جلب جميع الطلاب أولاً
      final allStudentsResponse = await getClassStudents(
        levelId: levelId,
        classId: classId,
      );

      if (!allStudentsResponse.success) {
        return allStudentsResponse;
      }

      // تصفية الطلاب حسب البحث
      final filteredStudents = allStudentsResponse.students.where((student) {
        final query = searchQuery.toLowerCase();
        return (student.fullName?.toLowerCase().contains(query) ?? false) ||
               (student.userName?.toLowerCase().contains(query) ?? false) ||
               (student.phone?.contains(query) ?? false);
      }).toList();

      return ClassStudentsResponse.success(
        students: filteredStudents,
        message: 'تم العثور على ${filteredStudents.length} طالب',
      );
    } catch (e) {
      print('❌ خطأ في البحث عن الطلاب: $e');
      return ClassStudentsResponse.error('حدث خطأ أثناء البحث: ${e.toString()}');
    }
  }

  /// جلب تفاصيل طالب معين (اختياري للمستقبل)
  Future<Student?> getStudentDetails(String studentId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على رمز المصادقة');
      }

      final url = Uri.parse('$baseUrl/school/StudentDetails/$studentId');
      
      final response = await http.get(
        url,
        headers: {
          'accept': 'text/plain',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> studentData = jsonDecode(response.body);
        return Student.fromJson(studentData);
      } else {
        throw Exception('فشل في جلب تفاصيل الطالب');
      }
    } catch (e) {
      print('❌ خطأ في جلب تفاصيل الطالب: $e');
      return null;
    }
  }
}
