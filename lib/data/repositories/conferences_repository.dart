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

  /// Creates a new conference and returns updated conferences list
  /// Takes conference data and formats it according to API requirements
  Future<List<ConferenceModel>> createConference(Map<String, dynamic> conferenceData) async {
    try {
      debugPrint('🔄 Creating new conference...');
      
      // Format the request body according to API requirements
      final requestBody = {
        'levelSubjectId': conferenceData['levelSubjectId'],
        'levelId': conferenceData['levelId'],
        'classId': conferenceData['classId'],
        'title': conferenceData['title'],
        'link': conferenceData['link'],
        'startAt': conferenceData['startAt'], // Should already be ISO string
        'durationMinutes': conferenceData['durationMinutes'],
      };
      
      debugPrint('📤 Sending request body: $requestBody');
      
      final response = await _apiClient.post(
        endpoint: '/api/session/add',
        body: requestBody,
      );
      
      if (response == null) {
        throw Exception('لم يتم استلام رد من الخادم');
      }

      debugPrint('📥 Create response: $response');

      // Check if the response indicates success
      final isSuccess = response['isSuccess'] == true;
      final message = response['message']?.toString() ?? '';
      
      if (!isSuccess) {
        throw Exception(message.isNotEmpty ? message : 'فشل في إنشاء الجلسة');
      }

      debugPrint('✅ Conference created successfully: $message');
      
      // After successful creation, fetch updated conferences list
      debugPrint('🔄 Fetching updated conferences list...');
      final updatedConferences = await getConferences();
      
      debugPrint('✅ Retrieved ${updatedConferences.length} conferences after creation');
      return updatedConferences;
      
    } catch (e) {
      debugPrint('❌ Error creating conference: $e');
      
      if (e.toString().contains('400')) {
        throw Exception('بيانات الجلسة غير صالحة. يرجى التحقق من المعلومات المدخلة.');
      } else if (e.toString().contains('401')) {
        throw Exception('غير مصرح لك بإنشاء جلسات. يرجى تسجيل الدخول مرة أخرى.');
      } else if (e.toString().contains('422')) {
        throw Exception('بيانات الجلسة غير مكتملة أو غير صحيحة.');
      } else {
        throw Exception('فشل في إنشاء الجلسة: ${e.toString()}');
      }
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
