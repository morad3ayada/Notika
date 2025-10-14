import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/all_students_model.dart';
import '../services/auth_service.dart';
import '../../config/api_config.dart';

/// Repository لجلب جميع الطلاب من السيرفر
class AllStudentsRepository {
  String get baseUrl => '${ApiConfig.baseUrl}/api';

  /// جلب جميع الطلاب من السيرفر
  Future<AllStudentsResponse> getAllStudents() async {
    try {
      print('📚 جلب جميع الطلاب...');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return AllStudentsResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse('$baseUrl/school/AllStudents');
      
      print('🌐 إرسال طلب إلى: $uri');

      // إرسال الطلب
      final response = await http.get(
        uri,
        headers: {
          'accept': 'text/plain',
          'Authorization': token, // بدون Bearer
        },
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('📄 نص الاستجابة: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        // نجح الطلب
        try {
          // محاولة تحليل الاستجابة كـ JSON array مباشرة
          final List<dynamic> studentsData = jsonDecode(response.body);
          
          print('📋 عدد الطلاب من السيرفر: ${studentsData.length}');
          
          // تحويل البيانات مع معالجة آمنة للأخطاء
          final List<AllStudent> students = [];
          for (int i = 0; i < studentsData.length; i++) {
            try {
              final student = AllStudent.fromJson(studentsData[i]);
              students.add(student);
              if (i < 3) {
                print('✅ طالب ${i + 1}: ${student.displayName}');
              }
            } catch (e) {
              print('⚠️ خطأ في تحويل الطالب ${i + 1}: $e');
              // نتخطى هذا العنصر ونكمل مع الباقي
            }
          }
          
          print('✅ تم جلب ${students.length} طالب بنجاح من أصل ${studentsData.length}');
          
          return AllStudentsResponse.success(
            students: students,
            message: 'تم جلب ${students.length} طالب بنجاح',
          );
        } catch (e) {
          print('❌ خطأ في تحليل البيانات: $e');
          return AllStudentsResponse.error('خطأ في تحليل بيانات الطلاب: ${e.toString()}');
        }
      } else if (response.statusCode == 400) {
        return AllStudentsResponse.error('خطأ في معاملات الطلب');
      } else if (response.statusCode == 401) {
        return AllStudentsResponse.error('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 403) {
        return AllStudentsResponse.error('ليس لديك صلاحية للوصول لقائمة الطلاب');
      } else if (response.statusCode == 404) {
        return AllStudentsResponse.error('لم يتم العثور على طلاب');
      } else if (response.statusCode >= 500) {
        return AllStudentsResponse.error('خطأ في الخادم، يرجى المحاولة لاحقاً');
      } else {
        return AllStudentsResponse.error('حدث خطأ غير متوقع (${response.statusCode})');
      }
    } catch (e) {
      print('❌ خطأ في جلب الطلاب: $e');
      
      if (e.toString().contains('SocketException') || e.toString().contains('NetworkException')) {
        return AllStudentsResponse.error('لا يوجد اتصال بالإنترنت');
      } else if (e.toString().contains('TimeoutException')) {
        return AllStudentsResponse.error('انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى');
      } else if (e.toString().contains('FormatException')) {
        return AllStudentsResponse.error('خطأ في تنسيق البيانات المُستلمة');
      } else {
        return AllStudentsResponse.error('حدث خطأ أثناء جلب البيانات: ${e.toString()}');
      }
    }
  }

  /// البحث عن طلاب حسب الاسم
  Future<AllStudentsResponse> searchStudents(String query) async {
    try {
      // جلب جميع الطلاب أولاً
      final allStudentsResponse = await getAllStudents();

      if (!allStudentsResponse.success) {
        return allStudentsResponse;
      }

      // تصفية الطلاب حسب البحث
      final filteredStudents = allStudentsResponse.students.where((student) {
        final q = query.toLowerCase().trim();
        if (q.isEmpty) return true;
        
        return (student.fullName.toLowerCase().contains(q)) ||
               (student.displayName.toLowerCase().contains(q)) ||
               (student.nickName?.toLowerCase().contains(q) ?? false) ||
               (student.firstName?.toLowerCase().contains(q) ?? false) ||
               (student.secondName?.toLowerCase().contains(q) ?? false) ||
               (student.thirdName?.toLowerCase().contains(q) ?? false) ||
               (student.fourthName?.toLowerCase().contains(q) ?? false);
      }).toList();

      return AllStudentsResponse.success(
        students: filteredStudents,
        message: 'تم العثور على ${filteredStudents.length} طالب',
      );
    } catch (e) {
      print('❌ خطأ في البحث: $e');
      return AllStudentsResponse.error('حدث خطأ أثناء البحث: ${e.toString()}');
    }
  }
}
