import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/file_classification_model.dart';
import '../services/auth_service.dart';

class FileClassificationRepository {
  static const String baseUrl = 'https://nouraleelemorg.runasp.net/api';

  Future<FileClassification> addFileClassification({
    required String levelSubjectId,
    required String levelId,
    required String classId,
    required String name,
  }) async {
    try {
      // Get authentication token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('لم يتم العثور على رمز المصادقة');
      }

      // Remove Bearer prefix if present
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;

      // Prepare request
      final request = CreateFileClassificationRequest(
        levelSubjectId: levelSubjectId,
        levelId: levelId,
        classId: classId,
        name: name,
      );

      print('Sending file classification request: ${request.toJson()}');

      // Send POST request
      final response = await http.post(
        Uri.parse('$baseUrl/fileclassification/add'),
        headers: {
          'accept': 'text/plain',
          'Authorization': cleanToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('File classification API Response - Status: ${response.statusCode}');
      print('File classification API Response - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle successful response
        try {
          // Try to parse as JSON first
          final responseData = jsonDecode(response.body);
          
          // Check if response contains the created file classification
          if (responseData is Map<String, dynamic>) {
            // Look for the file classification data in various possible structures
            Map<String, dynamic>? fileClassificationData;
            
            if (responseData.containsKey('id')) {
              // Direct response
              fileClassificationData = responseData;
            } else if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
              // Wrapped in 'data'
              fileClassificationData = responseData['data'];
            } else if (responseData.containsKey('result') && responseData['result'] is Map<String, dynamic>) {
              // Wrapped in 'result'
              fileClassificationData = responseData['result'];
            } else if (responseData.containsKey('fileClassification') && responseData['fileClassification'] is Map<String, dynamic>) {
              // Wrapped in 'fileClassification'
              fileClassificationData = responseData['fileClassification'];
            }
            
            if (fileClassificationData != null && fileClassificationData.containsKey('id')) {
              return FileClassification.fromJson(fileClassificationData);
            }
          }
          
          // If no ID found in response, create a temporary FileClassification from request data
          return FileClassification(
            id: null, // Server didn't return ID
            levelSubjectId: levelSubjectId,
            levelId: levelId,
            classId: classId,
            name: name,
            createdAt: DateTime.now(),
          );
        } catch (e) {
          print('Could not parse response as JSON: $e');
          // Create temporary FileClassification from request data
          return FileClassification(
            id: null,
            levelSubjectId: levelSubjectId,
            levelId: levelId,
            classId: classId,
            name: name,
            createdAt: DateTime.now(),
          );
        }
      } else {
        // Handle error response
        String errorMessage = 'فشل في إضافة الفصل/الوحدة';
        
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
          print('Could not parse error response: $e');
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in addFileClassification: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('حدث خطأ أثناء إضافة الفصل/الوحدة: ${e.toString()}');
    }
  }

  Future<List<FileClassification>> getFileClassifications({
    required String levelSubjectId,
    required String levelId,
    required String classId,
  }) async {
    try {
      // Get authentication token
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('لم يتم العثور على رمز المصادقة');
      }

      // Remove Bearer prefix if present
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;

      // Send GET request
      final response = await http.get(
        Uri.parse('$baseUrl/fileclassification?levelSubjectId=$levelSubjectId&levelId=$levelId&classId=$classId'),
        headers: {
          'accept': 'application/json',
          'Authorization': cleanToken,
        },
      );

      print('Get file classifications API Response - Status: ${response.statusCode}');
      print('Get file classifications API Response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData is List) {
          return responseData
              .map((item) => FileClassification.fromJson(item))
              .toList();
        } else if (responseData is Map<String, dynamic>) {
          // Check if data is wrapped in another object
          final data = responseData['data'] ?? responseData['result'] ?? responseData;
          if (data is List) {
            return data
                .map((item) => FileClassification.fromJson(item))
                .toList();
          }
        }
        
        return [];
      } else {
        // Handle error response
        String errorMessage = 'فشل في جلب قائمة الفصول/الوحدات';
        
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
          print('Could not parse error response: $e');
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in getFileClassifications: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('حدث خطأ أثناء جلب قائمة الفصول/الوحدات: ${e.toString()}');
    }
  }
}
