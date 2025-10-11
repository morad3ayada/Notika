import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/teacher_class_setting_model.dart';
import '../services/auth_service.dart';

/// Repository لجلب وتحديث صلاحيات الطلاب
class TeacherClassSettingsRepository {
  static const String baseUrl = 'https://nouraleelemorg.runasp.net/api';

  /// جلب إعدادات صلاحيات الطلاب من السيرفر
  Future<TeacherClassSettingsResponse> getSettings() async {
    try {
      print('📚 جلب إعدادات صلاحيات الطلاب...');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return TeacherClassSettingsResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse('$baseUrl/teacherclasssetting');
      
      print('🌐 إرسال طلب إلى: $uri');

      // إرسال الطلب
      final response = await http.get(
        uri,
        headers: {
          'accept': 'text/plain',
          'Authorization': token, // بدون Bearer
        },
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('📄 نص الاستجابة: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        try {
          final dynamic responseData = jsonDecode(response.body);
          
          List<dynamic> settingsData;
          
          // التحقق من شكل الاستجابة
          if (responseData is List) {
            settingsData = responseData;
          } else if (responseData is Map) {
            settingsData = responseData['data'] as List? ??
                responseData['settings'] as List? ??
                responseData['items'] as List? ??
                [];
          } else {
            settingsData = [];
          }
          
          print('📋 عدد الإعدادات من السيرفر: ${settingsData.length}');
          
          final List<TeacherClassSetting> settings = [];
          for (int i = 0; i < settingsData.length; i++) {
            try {
              final setting = TeacherClassSetting.fromJson(settingsData[i]);
              settings.add(setting);
            } catch (e) {
              print('⚠️ خطأ في تحليل إعداد رقم $i: $e');
            }
          }
          
          print('✅ تم تحليل ${settings.length} إعداد بنجاح');
          
          return TeacherClassSettingsResponse.success(settings);
        } catch (e) {
          print('❌ خطأ في تحليل JSON: $e');
          return TeacherClassSettingsResponse.error('خطأ في تحليل البيانات من السيرفر');
        }
      } else if (response.statusCode == 401) {
        return TeacherClassSettingsResponse.error('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 404) {
        return TeacherClassSettingsResponse.success([]); // لا توجد إعدادات
      } else {
        return TeacherClassSettingsResponse.error('فشل جلب الإعدادات. كود الخطأ: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في جلب الإعدادات: $e');
      return TeacherClassSettingsResponse.error('خطأ في الاتصال بالسيرفر: ${e.toString()}');
    }
  }

  /// تحديث إعدادات صلاحيات الطلاب بشكل جماعي
  Future<TeacherClassSettingsResponse> updateSettings(List<TeacherClassSetting> settings) async {
    try {
      print('📝 تحديث إعدادات صلاحيات الطلاب...');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return TeacherClassSettingsResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse('$baseUrl/teacherclasssetting/updatebulk');
      
      // تحويل الإعدادات إلى JSON
      final body = jsonEncode(settings.map((s) => s.toJson()).toList());
      
      print('🌐 إرسال طلب إلى: $uri');
      print('📦 البيانات المرسلة: $body');

      // إرسال الطلب
      final response = await http.post(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': token, // بدون Bearer
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('📄 نص الاستجابة: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ تم تحديث الإعدادات بنجاح');
        return TeacherClassSettingsResponse.success(settings);
      } else if (response.statusCode == 401) {
        return TeacherClassSettingsResponse.error('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else {
        return TeacherClassSettingsResponse.error('فشل تحديث الإعدادات. كود الخطأ: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في تحديث الإعدادات: $e');
      return TeacherClassSettingsResponse.error('خطأ في الاتصال بالسيرفر: ${e.toString()}');
    }
  }
}
