import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

/// Repository لإرسال الأسئلة للسيرفر
class ExamQuestionsRepository {
  static const String baseUrl = 'https://nouraleelemorg.runasp.net/api';

  /// إرسال الأسئلة للسيرفر
  Future<ExamQuestionsResponse> uploadExamQuestions({
    required String examTableId,
    required List<Map<String, dynamic>> questions,
    File? examFile,
  }) async {
    try {
      print('📤 إرسال الأسئلة للسيرفر...');
      print('📋 عدد الأسئلة: ${questions.length}');
      print('🆔 ExamTableId: $examTableId');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ExamQuestionsResponse.error('لم يتم العثور على رمز المصادقة');
      }

      // بناء الرابط
      final url = Uri.parse('$baseUrl/file/uploadExamFile');
      print('🌐 إرسال طلب إلى: $url');

      // إنشاء multipart request
      var request = http.MultipartRequest('POST', url);

      // إضافة Headers
      request.headers.addAll({
        'accept': 'text/plain',
        'Authorization': token, // بدون Bearer
      });

      // إضافة ExamTableId
      request.fields['ExamTableId'] = examTableId;
      request.fields['Path'] = 'Exam';

      // إضافة بيانات الأسئلة كـ JSON
      final questionsJson = jsonEncode({
        'questions': questions,
        'totalQuestions': questions.length,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // إنشاء ملف مؤقت للأسئلة
      if (examFile != null) {
        // إضافة الملف المرفوع من المستخدم
        request.files.add(await http.MultipartFile.fromPath(
          'File',
          examFile.path,
          filename: examFile.path.split('/').last,
        ));
      } else {
        // إنشاء ملف JSON للأسئلة
        request.files.add(http.MultipartFile.fromString(
          'File',
          questionsJson,
          filename: 'exam_questions_${DateTime.now().millisecondsSinceEpoch}.json',
        ));
      }

      print('📦 إرسال البيانات...');
      
      // إرسال الطلب
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📨 رد السيرفر - Status Code: ${response.statusCode}');
      print('📨 رد السيرفر - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          return ExamQuestionsResponse.success(
            message: 'تم إرسال الأسئلة بنجاح',
            data: responseData,
          );
        } catch (e) {
          // إذا لم يكن الرد JSON، نعتبره نجاح
          return ExamQuestionsResponse.success(
            message: 'تم إرسال الأسئلة بنجاح',
            data: {'response': response.body},
          );
        }
      } else {
        String errorMessage = 'حدث خطأ أثناء إرسال الأسئلة';
        
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
        }
        
        return ExamQuestionsResponse.error(errorMessage);
      }
    } catch (e) {
      print('❌ خطأ في إرسال الأسئلة: $e');
      return ExamQuestionsResponse.error('حدث خطأ في الاتصال: ${e.toString()}');
    }
  }
}

/// نموذج الاستجابة من السيرفر
class ExamQuestionsResponse {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  const ExamQuestionsResponse({
    required this.isSuccess,
    required this.message,
    this.data,
  });

  factory ExamQuestionsResponse.success({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return ExamQuestionsResponse(
      isSuccess: true,
      message: message,
      data: data,
    );
  }

  factory ExamQuestionsResponse.error(String message) {
    return ExamQuestionsResponse(
      isSuccess: false,
      message: message,
    );
  }
}
