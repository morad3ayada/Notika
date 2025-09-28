import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../services/auth_service.dart';

class AttendanceRepository {
  static const String baseUrl = 'https://nouraleelemorg.runasp.net';

  AttendanceRepository();

  Future<AttendanceResponse> submitAttendance(AttendanceSubmission submission) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على رمز المصادقة. يرجى تسجيل الدخول مرة أخرى.');
      }

      // Remove Bearer prefix if present
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;

      final url = Uri.parse('$baseUrl/api/absences');
      
      print('AttendanceRepository: Sending POST request to $url');
      print('AttendanceRepository: Request body: ${jsonEncode(submission.toJson())}');

      final response = await http.post(
        url,
        headers: {
          'accept': 'text/plain',
          'Authorization': cleanToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(submission.toJson()),
      );

      print('AttendanceRepository: Response status: ${response.statusCode}');
      print('AttendanceRepository: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse response as JSON
        try {
          final responseData = jsonDecode(response.body);
          
          // Check if response contains attendance data
          if (responseData is Map<String, dynamic>) {
            // Look for attendance data in different possible structures
            Map<String, dynamic>? attendanceData;
            
            if (responseData.containsKey('id') || responseData.containsKey('message')) {
              attendanceData = responseData;
            } else if (responseData.containsKey('attendance')) {
              attendanceData = responseData['attendance'];
            } else if (responseData.containsKey('data')) {
              attendanceData = responseData['data'];
            } else if (responseData.containsKey('result')) {
              attendanceData = responseData['result'];
            }
            
            if (attendanceData != null) {
              return AttendanceResponse.fromJson(attendanceData);
            }
          }
          
          // If no attendance data found but success response, create success response
          return AttendanceResponse(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            message: 'تم تسجيل الحضور بنجاح',
            success: true,
            createdAt: DateTime.now(),
          );
        } catch (e) {
          print('AttendanceRepository: Failed to parse JSON response: $e');
          // If JSON parsing fails but status is success, create success response
          return AttendanceResponse(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            message: 'تم تسجيل الحضور بنجاح',
            success: true,
            createdAt: DateTime.now(),
          );
        }
      } else {
        // Handle error responses
        String errorMessage = 'فشل في تسجيل الحضور';
        
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
          print('AttendanceRepository: Failed to parse error response: $e');
          errorMessage = 'خطأ في الخادم (${response.statusCode})';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('AttendanceRepository: Exception occurred: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  Future<List<AttendanceSubmission>> getAttendanceHistory({
    String? subjectId,
    String? levelId,
    String? classId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على رمز المصادقة. يرجى تسجيل الدخول مرة أخرى.');
      }

      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (subjectId != null) queryParams['subjectId'] = subjectId;
      if (levelId != null) queryParams['levelId'] = levelId;
      if (classId != null) queryParams['classId'] = classId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      
      final uri = Uri.parse('$baseUrl/api/absences').replace(queryParameters: queryParams);
      
      print('AttendanceRepository: Fetching attendance history from $uri');

      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': cleanToken,
        },
      );

      print('AttendanceRepository: Response status: ${response.statusCode}');
      print('AttendanceRepository: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        List<dynamic> attendanceList = [];
        if (responseData is List) {
          attendanceList = responseData;
        } else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('attendances')) {
            attendanceList = responseData['attendances'] as List? ?? [];
          } else if (responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) {
              attendanceList = data;
            } else if (data is Map && data.containsKey('attendances')) {
              attendanceList = data['attendances'] as List? ?? [];
            }
          }
        }
        
        return attendanceList
            .map((json) => AttendanceSubmission.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('فشل في جلب سجل الحضور: ${response.statusCode}');
      }
    } catch (e) {
      print('AttendanceRepository: Exception in getAttendanceHistory: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }

  // Helper method to build full name from student data
  String _buildFullName(Map<String, dynamic> student) {
    final parts = [
      student['firstName'],
      student['secondName'],
      student['thirdName'],
      student['fourthName']
    ].where((part) => part != null && part.isNotEmpty);
    
    return parts.join(' ').trim();
  }

  Future<List<StudentAttendance>> getStudentsList({
    required String subjectId,
    required String levelId,
    required String classId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على رمز المصادقة. يرجى تسجيل الدخول مرة أخرى.');
      }

      final cleanToken = token.startsWith('Bearer ') ? token.substring(7) : token;
      
      // Using the correct endpoint for fetching class students
      final queryParams = {
        'LevelID': levelId,
        'ClassID': classId,
      };
      
      final uri = Uri.parse('$baseUrl/api/school/ClassStudents').replace(queryParameters: queryParams);
      
      print('Using ClassStudents endpoint: $uri');
      
      print('AttendanceRepository: Fetching students list from $uri');

      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      );

      print('AttendanceRepository: Response status: ${response.statusCode}');
      print('AttendanceRepository: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        List<dynamic> studentsList = [];
        if (responseData is List) {
          studentsList = responseData;
          
          // Map the response to StudentAttendance format
          return studentsList.map<StudentAttendance>((student) {
            return StudentAttendance(
              studentId: student['studentId']?.toString() ?? '',
              name: _buildFullName(student),
              status: 'present', // Default status
            );
          }).toList();
        }
        
        return studentsList
            .map((json) => StudentAttendance.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('فشل في جلب قائمة الطلاب: ${response.statusCode}');
      }
    } catch (e) {
      print('AttendanceRepository: Exception in getStudentsList: $e');
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ غير متوقع: $e');
      }
    }
  }
}
