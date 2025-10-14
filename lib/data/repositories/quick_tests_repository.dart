import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quick_tests_model.dart';
import '../services/auth_service.dart';
import '../../config/api_config.dart';

class QuickTestsRepository {
  String get baseUrl => ApiConfig.baseUrl;

  QuickTestsRepository();

  Future<QuickTestModel> addQuickTest(CreateQuickTestRequest request) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على رمز المصادقة. يرجى تسجيل الدخول مرة أخرى.');
      }

      // Remove Bearer prefix if present
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;

      final url = Uri.parse('$baseUrl/api/quiz/add');
      
      print('QuickTestsRepository: Sending POST request to $url');
      print('QuickTestsRepository: Request body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        url,
        headers: {
          'accept': 'text/plain',
          'Authorization': cleanToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('QuickTestsRepository: Response status: ${response.statusCode}');
      print('QuickTestsRepository: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse response as JSON
        try {
          final responseData = jsonDecode(response.body);
          
          // Check if response contains quiz data
          if (responseData is Map<String, dynamic>) {
            // Look for quiz data in different possible structures
            Map<String, dynamic>? quizData;
            
            if (responseData.containsKey('id')) {
              quizData = responseData;
            } else if (responseData.containsKey('quiz')) {
              quizData = responseData['quiz'];
            } else if (responseData.containsKey('data')) {
              quizData = responseData['data'];
            } else if (responseData.containsKey('result')) {
              quizData = responseData['result'];
            }
            
            if (quizData != null && quizData.containsKey('id')) {
              return QuickTestModel.fromJson(quizData);
            }
          }
          
          // If no quiz data found but success response, create from request
          return QuickTestModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            levelSubjectId: request.levelSubjectId,
            levelId: request.levelId,
            classId: request.classId,
            title: request.title,
            deadline: request.deadline,
            questionsJson: request.questionsJson,
            answersJson: request.answersJson,
            durationMinutes: request.durationMinutes,
            maxGrade: request.maxGrade,
            createdAt: DateTime.now(),
          );
        } catch (e) {
          print('QuickTestsRepository: Failed to parse JSON response: $e');
          // If JSON parsing fails but status is success, create from request
          return QuickTestModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            levelSubjectId: request.levelSubjectId,
            levelId: request.levelId,
            classId: request.classId,
            title: request.title,
            deadline: request.deadline,
            questionsJson: request.questionsJson,
            answersJson: request.answersJson,
            durationMinutes: request.durationMinutes,
            maxGrade: request.maxGrade,
            createdAt: DateTime.now(),
          );
        }
      } else {
        // Handle error responses
        String errorMessage = 'فشل في إضافة الاختبار';
        
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('message')) {
              errorMessage = errorData['message'].toString();
            } else if (errorData.containsKey('error')) {
              errorMessage = errorData['error'].toString();
            } else if (errorData.containsKey('errors')) {
              final errors = errorData['errors'];
              if (errors is List && errors.isNotEmpty) {
                errorMessage = errors.first.toString();
              } else if (errors is Map) {
                errorMessage = errors.values.first.toString();
              }
            }
          }
        } catch (e) {
          print('QuickTestsRepository: Failed to parse error response: $e');
          errorMessage = 'خطأ في الخادم (${response.statusCode})';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('QuickTestsRepository: Exception occurred: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  Future<List<QuickTestModel>> getQuickTests() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على رمز المصادقة. يرجى تسجيل الدخول مرة أخرى.');
      }

      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;
      final url = Uri.parse('$baseUrl/api/quiz');
      
      print('QuickTestsRepository: Fetching quick tests from $url');

      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': cleanToken,
        },
      );

      print('QuickTestsRepository: Response status: ${response.statusCode}');
      print('QuickTestsRepository: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        List<dynamic> quizList = [];
        if (responseData is List) {
          quizList = responseData;
        } else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('quizzes')) {
            quizList = responseData['quizzes'] as List? ?? [];
          } else if (responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) {
              quizList = data;
            } else if (data is Map && data.containsKey('quizzes')) {
              quizList = data['quizzes'] as List? ?? [];
            }
          }
        }
        
        return quizList
            .map((json) => QuickTestModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('فشل في جلب الاختبارات: ${response.statusCode}');
      }
    } catch (e) {
      print('QuickTestsRepository: Exception in getQuickTests: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }
}
