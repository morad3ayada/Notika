import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../api/api_client.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  final ApiClient _client;
  final String endpoint;

  ScheduleRepository({ApiClient? client, this.endpoint = '/api/school/TeacherClasses'})
      : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);

  Future<List<Schedule>> getSchedule() async {
    try {
      final response = await _client.get(endpoint);
      try {
        if (response is List) {
          return response.map((e) => Schedule.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (response is Map<String, dynamic>) {
          // Some APIs wrap the list in a key like 'data'
          final data = response['data'];
          if (data is List) {
            return data.map((e) => Schedule.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
        return [];
      } catch (e) {
        debugPrint('ScheduleRepository parse error: $e');
        rethrow;
      }
    } catch (e) {
      // If API returns 404 ("لم يتم العثور على البيانات المطلوبة."), treat as empty list
      final msg = e.toString();
      if (msg.contains(ApiConfig.notFoundMessage)) {
        return [];
      }
      rethrow;
    }
  }
}
