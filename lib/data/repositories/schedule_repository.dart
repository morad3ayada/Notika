import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../api/api_client.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  // إنشاء ApiClient ديناميكياً ليستخدم ApiConfig.baseUrl الحالي
  ApiClient get _client => ApiClient(baseUrl: ApiConfig.baseUrl);
  final String endpoint;

  ScheduleRepository({this.endpoint = '/api/profile'});

  Future<List<Schedule>> getSchedule() async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('📅 ScheduleRepository: جلب الجدول');
      print('   - Endpoint: $endpoint');
      print('═══════════════════════════════════════════════════════');
      
      final response = await _client.get(endpoint);
      
      print('📥 Schedule Response:');
      print('   - Type: ${response.runtimeType}');
      
      try {
        // Profile API يرجع Map مع 'classes' array
        if (response is Map<String, dynamic>) {
          print('   - Response is Map with keys: ${response.keys.join(", ")}');
          
          // البيانات في 'classes' key
          final classes = response['classes'];
          if (classes is List) {
            print('   - Found ${classes.length} classes in profile');
            final schedules = classes.map((e) => Schedule.fromJson(e as Map<String, dynamic>)).toList();
            print('✅ Parsed ${schedules.length} schedule items from profile');
            return schedules;
          } else {
            print('⚠️ classes is not a List or is null');
          }
        } else if (response is List) {
          // للتوافق مع API القديم
          print('   - Response is List with ${response.length} items');
          final schedules = response.map((e) => Schedule.fromJson(e as Map<String, dynamic>)).toList();
          print('✅ Parsed ${schedules.length} schedule items');
          return schedules;
        }
        
        print('⚠️ No valid data found, returning empty list');
        return [];
      } catch (e) {
        debugPrint('❌ ScheduleRepository parse error: $e');
        rethrow;
      }
    } catch (e) {
      print('❌ ScheduleRepository error: $e');
      
      // If API returns 404 ("لم يتم العثور على البيانات المطلوبة."), treat as empty list
      final msg = e.toString();
      if (msg.contains(ApiConfig.notFoundMessage)) {
        print('⚠️ API returned 404, treating as empty schedule');
        return [];
      }
      rethrow;
    }
  }
}
