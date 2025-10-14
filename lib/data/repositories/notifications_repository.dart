import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../../config/api_config.dart';

/// Repository لجلب الإشعارات من السيرفر
class NotificationsRepository {
  // استخدام ApiConfig.baseUrl الديناميكي بدلاً من URL ثابت
  String get baseUrl => '${ApiConfig.baseUrl}/api';

  /// جلب جميع الإشعارات من السيرفر
  Future<NotificationsResponse> getNotifications() async {
    try {
      print('📚 جلب الإشعارات...');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return NotificationsResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse('$baseUrl/notifications/my-notifications');
      
      print('🌐 إرسال طلب إلى: $uri');

      // إرسال الطلب
      final response = await http.get(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': token, // بدون Bearer
        },
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('📄 نص الاستجابة: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        // نجح الطلب
        try {
          // محاولة تحليل الاستجابة كـ JSON array مباشرة
          final dynamic responseData = jsonDecode(response.body);
          
          List<dynamic> notificationsData;
          
          // التحقق من شكل الاستجابة
          if (responseData is List) {
            notificationsData = responseData;
          } else if (responseData is Map) {
            // البحث عن الإشعارات في مفاتيح مختلفة
            notificationsData = responseData['notifications'] as List? ??
                responseData['data'] as List? ??
                responseData['items'] as List? ??
                [];
          } else {
            notificationsData = [];
          }
          
          print('📋 عدد الإشعارات من السيرفر: ${notificationsData.length}');
          
          // تحويل البيانات مع معالجة آمنة للأخطاء
          final List<NotificationModel> notifications = [];
          for (int i = 0; i < notificationsData.length; i++) {
            try {
              final notification = NotificationModel.fromJson(notificationsData[i]);
              notifications.add(notification);
            } catch (e) {
              print('⚠️ خطأ في تحليل إشعار رقم $i: $e');
              // تخطي الإشعار الذي به خطأ والاستمرار
            }
          }
          
          print('✅ تم تحليل ${notifications.length} إشعار بنجاح');
          
          return NotificationsResponse.success(notifications);
        } catch (e) {
          print('❌ خطأ في تحليل JSON: $e');
          return NotificationsResponse.error('خطأ في تحليل البيانات من السيرفر');
        }
      } else if (response.statusCode == 401) {
        return NotificationsResponse.error('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 404) {
        return NotificationsResponse.success([]); // لا توجد إشعارات
      } else {
        return NotificationsResponse.error('فشل جلب الإشعارات. كود الخطأ: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في جلب الإشعارات: $e');
      return NotificationsResponse.error('خطأ في الاتصال بالسيرفر: ${e.toString()}');
    }
  }

  /// إعادة جلب الإشعارات (refresh)
  Future<NotificationsResponse> refreshNotifications() async {
    return getNotifications();
  }
}
