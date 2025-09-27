import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../api/api_client.dart';
import '../../config/api_config.dart';
import '../models/conference_model.dart';

class ConferencesRepository {
  final ApiClient _apiClient;

  ConferencesRepository(this._apiClient);

  /// Fetches conferences from the API
  /// Returns a list of ConferenceModel objects
  Future<List<ConferenceModel>> getConferences() async {
    try {
      debugPrint('🔄 Fetching conferences from API...');
      
      final response = await _apiClient.get('/api/session');
      
      if (response == null) {
        debugPrint('⚠️ API returned null response');
        return [];
      }

      // Handle both array response and object with array property
      List<dynamic> conferencesList;
      if (response is List) {
        conferencesList = response;
      } else if (response is Map<String, dynamic>) {
        // Check if response contains conferences in a nested property
        conferencesList = response['sessions'] ?? response['conferences'] ?? response['data'] ?? [];
      } else {
        debugPrint('⚠️ Unexpected response format: ${response.runtimeType}');
        return [];
      }

      if (conferencesList.isEmpty) {
        debugPrint('ℹ️ No conferences found in API response');
        return [];
      }

      final List<ConferenceModel> conferences = [];
      
      for (int i = 0; i < conferencesList.length; i++) {
        try {
          final conferenceJson = conferencesList[i];
          if (conferenceJson is Map<String, dynamic>) {
            final conference = ConferenceModel.fromJson(conferenceJson);
            conferences.add(conference);
            debugPrint('✅ Parsed conference: ${conference.title}');
          } else {
            debugPrint('⚠️ Skipping invalid conference at index $i: not a Map');
          }
        } catch (e) {
          debugPrint('⚠️ Skipping conference at index $i due to parsing error: $e');
          // Continue processing other conferences instead of failing completely
          continue;
        }
      }

      debugPrint('✅ Successfully parsed ${conferences.length} conferences from ${conferencesList.length} items');
      return conferences;
      
    } catch (e) {
      debugPrint('❌ Error fetching conferences: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('404')) {
        throw Exception('لم يتم العثور على نقطة نهاية الجلسات. يرجى التحقق من إعدادات الخادم.');
      } else if (e.toString().contains('401')) {
        throw Exception('غير مصرح لك بالوصول إلى الجلسات. يرجى تسجيل الدخول مرة أخرى.');
      } else if (e.toString().contains('500')) {
        throw Exception('خطأ في الخادم أثناء جلب الجلسات. يرجى المحاولة لاحقاً.');
      } else if (e.toString().contains('لا يوجد اتصال بالإنترنت')) {
        throw Exception('لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك بالشبكة.');
      } else {
        throw Exception('فشل في جلب الجلسات: ${e.toString()}');
      }
    }
  }

  /// Creates a new conference with robust response handling
  /// Sends data to /api/session/add endpoint as specified in requirements
  Future<ConferenceModel> createConference(Map<String, dynamic> conferenceData) async {
    try {
      debugPrint('🔄 Creating new conference...');
      debugPrint('📤 Request body: $conferenceData');
      
      final response = await _apiClient.post(
        endpoint: '/api/session/add',
        body: conferenceData,
      );
      
      debugPrint('📥 Raw server response: $response');
      debugPrint('📥 Response type: ${response.runtimeType}');
      
      if (response == null) {
        throw Exception('لم يتم استلام رد من الخادم');
      }

      // Parse response safely
      Map<String, dynamic> responseBody;
      if (response is Map<String, dynamic>) {
        responseBody = response;
      } else if (response is String) {
        try {
          responseBody = json.decode(response);
        } catch (e) {
          debugPrint('❌ Failed to parse response as JSON: $e');
          throw Exception('استجابة السيرفر غير صالحة: $response');
        }
      } else {
        throw Exception('تنسيق استجابة السيرفر غير متوقع: ${response.runtimeType}');
      }

      debugPrint('📥 Parsed response body: $responseBody');

      // Case A: Response contains full conference object with ID
      if (_hasConferenceWithId(responseBody)) {
        debugPrint('✅ Found complete conference object with ID');
        return _extractConferenceFromResponse(responseBody);
      }

      // Case B: Response indicates success but no conference object
      if (_isSuccessResponse(responseBody)) {
        debugPrint('⚠️ Success response without conference object, attempting re-fetch...');
        
        // Try to re-fetch and find the created conference
        try {
          final createdConference = await _refetchAndFindConference(conferenceData);
          if (createdConference != null) {
            debugPrint('✅ Found conference via re-fetch: ${createdConference.title}');
            return createdConference;
          }
        } catch (e) {
          debugPrint('⚠️ Re-fetch failed: $e');
        }

        // Fallback: Create temporary conference
        debugPrint('⚠️ Creating temporary conference from request data');
        final tempConference = ConferenceModel.fromRequestData(conferenceData);
        debugPrint('✅ Created temporary conference: ${tempConference.title} (ID: ${tempConference.id})');
        return tempConference;
      }

      // Case C: Error response
      if (_isErrorResponse(responseBody)) {
        final errorMessage = _extractErrorMessage(responseBody);
        debugPrint('❌ Server returned error: $errorMessage');
        throw Exception(errorMessage);
      }

      // Unknown response format
      debugPrint('❌ Unknown response format: $responseBody');
      throw Exception('تنسيق استجابة السيرفر غير معروف');
      
    } catch (e) {
      debugPrint('❌ Error creating conference: $e');
      
      // Enhanced error logging
      debugPrint('🔍 Request data: $conferenceData');
      debugPrint('🔍 Error type: ${e.runtimeType}');
      debugPrint('🔍 Full error details: ${e.toString()}');
      
      if (e.toString().contains('400')) {
        throw Exception('بيانات الجلسة غير صالحة. يرجى التحقق من المعلومات المدخلة.\nتفاصيل الخطأ: ${e.toString()}');
      } else if (e.toString().contains('401')) {
        throw Exception('غير مصرح لك بإنشاء جلسات. يرجى تسجيل الدخول مرة أخرى.');
      } else if (e.toString().contains('422')) {
        throw Exception('بيانات الجلسة غير مكتملة أو غير صحيحة.\nتفاصيل الخطأ: ${e.toString()}');
      } else {
        throw Exception('فشل في إنشاء الجلسة: ${e.toString()}');
      }
    }
  }

  /// Checks if response contains a conference object with valid ID
  bool _hasConferenceWithId(Map<String, dynamic> response) {
    // Check direct response
    if (response.containsKey('id') && response['id'] != null && response['id'].toString().isNotEmpty) {
      return true;
    }
    
    // Check nested in common wrapper keys
    for (final key in ['session', 'data', 'result', 'conference']) {
      if (response.containsKey(key) && response[key] is Map<String, dynamic>) {
        final nested = response[key] as Map<String, dynamic>;
        if (nested.containsKey('id') && nested['id'] != null && nested['id'].toString().isNotEmpty) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Extracts conference from response
  ConferenceModel _extractConferenceFromResponse(Map<String, dynamic> response) {
    // Try direct response first
    if (response.containsKey('id')) {
      return ConferenceModel.fromJson(response);
    }
    
    // Try nested keys
    for (final key in ['session', 'data', 'result', 'conference']) {
      if (response.containsKey(key) && response[key] is Map<String, dynamic>) {
        final nested = response[key] as Map<String, dynamic>;
        if (nested.containsKey('id')) {
          return ConferenceModel.fromJson(nested);
        }
      }
    }
    
    throw Exception('لم يتم العثور على بيانات الجلسة في الاستجابة');
  }

  /// Checks if response indicates success
  bool _isSuccessResponse(Map<String, dynamic> response) {
    return response['isSuccess'] == true || 
           response['success'] == true ||
           (response.containsKey('message') && 
            response['message'].toString().toLowerCase().contains('success'));
  }

  /// Checks if response indicates error
  bool _isErrorResponse(Map<String, dynamic> response) {
    return response['isSuccess'] == false || 
           response['success'] == false ||
           response.containsKey('error') ||
           (response.containsKey('message') && 
            response['message'].toString().toLowerCase().contains('error'));
  }

  /// Extracts error message from response
  String _extractErrorMessage(Map<String, dynamic> response) {
    return response['message']?.toString() ?? 
           response['error']?.toString() ?? 
           'حدث خطأ غير معروف';
  }

  /// Attempts to re-fetch conferences and find the newly created one
  Future<ConferenceModel?> _refetchAndFindConference(Map<String, dynamic> requestData) async {
    try {
      debugPrint('🔄 Re-fetching conferences to find newly created one...');
      
      final conferences = await getConferences();
      debugPrint('📊 Found ${conferences.length} conferences after re-fetch');
      
      // Search criteria
      final requestTitle = requestData['title']?.toString() ?? '';
      final requestStartAt = requestData['startAt']?.toString() ?? '';
      
      debugPrint('🔍 Searching for conference:');
      debugPrint('   Title: $requestTitle');
      debugPrint('   StartAt: $requestStartAt');
      
      // Find conference by title and startAt
      for (final conference in conferences) {
        final titleMatch = conference.title.trim().toLowerCase() == requestTitle.trim().toLowerCase();
        final startAtMatch = conference.startAt.toIso8601String() == requestStartAt;
        
        debugPrint('🔍 Checking conference: ${conference.title}');
        debugPrint('   Title match: $titleMatch');
        debugPrint('   StartAt match: $startAtMatch (${conference.startAt.toIso8601String()})');
        
        if (titleMatch && startAtMatch) {
          debugPrint('✅ Found matching conference: ${conference.id}');
          return conference;
        }
      }
      
      // Try fuzzy matching by title only (in case of time zone differences)
      for (final conference in conferences) {
        final titleMatch = conference.title.trim().toLowerCase() == requestTitle.trim().toLowerCase();
        if (titleMatch) {
          // Check if created recently (within last 5 minutes)
          final timeDiff = DateTime.now().difference(conference.createdAt).inMinutes;
          if (timeDiff <= 5) {
            debugPrint('✅ Found recently created conference with matching title: ${conference.id}');
            return conference;
          }
        }
      }
      
      debugPrint('❌ No matching conference found in re-fetch');
      return null;
      
    } catch (e) {
      debugPrint('❌ Error during re-fetch: $e');
      return null;
    }
  }

  /// Updates an existing conference
  /// This method can be implemented later if needed
  Future<ConferenceModel> updateConference(String conferenceId, Map<String, dynamic> conferenceData) async {
    try {
      debugPrint('🔄 Updating conference: $conferenceId');
      
      final response = await _apiClient.put(
        endpoint: '/api/session/$conferenceId',
        body: conferenceData,
      );
      
      if (response == null) {
        throw Exception('لم يتم استلام رد من الخادم');
      }

      final conference = ConferenceModel.fromJson(response);
      debugPrint('✅ Conference updated successfully: ${conference.title}');
      return conference;
      
    } catch (e) {
      debugPrint('❌ Error updating conference: $e');
      throw Exception('فشل في تحديث الجلسة: ${e.toString()}');
    }
  }

  /// Deletes a conference
  /// This method can be implemented later if needed
  Future<void> deleteConference(String conferenceId) async {
    try {
      debugPrint('🔄 Deleting conference: $conferenceId');
      
      await _apiClient.delete('/api/session/$conferenceId');
      
      debugPrint('✅ Conference deleted successfully');
      
    } catch (e) {
      debugPrint('❌ Error deleting conference: $e');
      throw Exception('فشل في حذف الجلسة: ${e.toString()}');
    }
  }
}
