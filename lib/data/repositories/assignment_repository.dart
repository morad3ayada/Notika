import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/assignment_model.dart';
import '../services/auth_service.dart';

class AssignmentRepository {
  static const String baseUrl = 'https://nouraleelemorg.runasp.net/api';

  AssignmentRepository();

  Future<bool> createAssignment(CreateAssignmentRequest request) async {
    try {
      developer.log('Creating assignment with data: ${request.toJson()}');
      
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('لم يتم العثور على رمز المصادقة');
      }

      // Remove Bearer prefix if present
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;

      final response = await http.post(
        Uri.parse('$baseUrl/assignment/add'),
        headers: {
          'accept': 'text/plain',
          'Authorization': cleanToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      developer.log('Assignment API Response - Status: ${response.statusCode}');
      developer.log('Assignment API Response - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check for success indicators in response
        final responseBody = response.body.toLowerCase();
        if (responseBody.contains('success') || 
            responseBody.contains('تم') || 
            responseBody.contains('نجح') ||
            response.statusCode == 201) {
          developer.log('Assignment created successfully');
          return true;
        }
      }

      // Handle error responses
      String errorMessage = 'فشل في إنشاء الواجب';
      
      if (response.statusCode == 400) {
        errorMessage = 'بيانات غير صحيحة. تحقق من جميع الحقول المطلوبة';
      } else if (response.statusCode == 401) {
        errorMessage = 'غير مصرح لك بهذا الإجراء. تحقق من تسجيل الدخول';
      } else if (response.statusCode == 403) {
        errorMessage = 'ليس لديك صلاحية لإنشاء واجبات';
      } else if (response.statusCode == 404) {
        errorMessage = 'الخدمة غير متوفرة حالياً';
      } else if (response.statusCode >= 500) {
        errorMessage = 'خطأ في الخادم. حاول مرة أخرى لاحقاً';
      }

      // Try to parse error message from response
      try {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'] ?? 
                          responseData['error'] ?? 
                          responseData['Message'] ?? 
                          responseData['Error'];
          if (message != null && message.toString().isNotEmpty) {
            errorMessage = message.toString();
          }
        }
      } catch (e) {
        developer.log('Could not parse error response: $e');
      }

      throw Exception(errorMessage);

    } catch (e) {
      developer.log('Error creating assignment: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  Future<List<AssignmentModel>> getAssignments() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('لم يتم العثور على رمز المصادقة');
      }

      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;

      final response = await http.get(
        Uri.parse('$baseUrl/assignment'),
        headers: {
          'accept': 'application/json',
          'Authorization': cleanToken,
        },
      );

      developer.log('Get assignments API Response - Status: ${response.statusCode}');
      developer.log('Get assignments API Response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AssignmentModel.fromJson(json)).toList();
      } else {
        throw Exception('فشل في جلب الواجبات');
      }
    } catch (e) {
      developer.log('Error getting assignments: $e');
      throw Exception('حدث خطأ في جلب الواجبات: ${e.toString()}');
    }
  }
}
