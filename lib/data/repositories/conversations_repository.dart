import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation_model.dart';
import '../services/auth_service.dart';

/// Repository لجلب المحادثات من السيرفر
class ConversationsRepository {
  static const String baseUrl = 'https://nouraleelemorg.runasp.net/api';

  /// جلب جميع المحادثات من السيرفر
  Future<ConversationsResponse> getConversations() async {
    try {
      print('📚 جلب المحادثات...');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ConversationsResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse('$baseUrl/Chat/conversations');
      
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
          final List<dynamic> conversationsData = jsonDecode(response.body);
          
          print('📋 عدد المحادثات من السيرفر: ${conversationsData.length}');
          
          // تحويل البيانات مع معالجة آمنة للأخطاء
          final List<Conversation> conversations = [];
          for (int i = 0; i < conversationsData.length; i++) {
            try {
              final conversation = Conversation.fromJson(conversationsData[i]);
              conversations.add(conversation);
            } catch (e) {
              print('⚠️ خطأ في تحليل محادثة رقم $i: $e');
              // تخطي المحادثة التي بها خطأ والاستمرار
            }
          }
          
          print('✅ تم تحليل ${conversations.length} محادثة بنجاح');
          
          return ConversationsResponse.success(conversations);
        } catch (e) {
          print('❌ خطأ في تحليل JSON: $e');
          return ConversationsResponse.error('خطأ في تحليل البيانات من السيرفر');
        }
      } else if (response.statusCode == 401) {
        return ConversationsResponse.error('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 404) {
        return ConversationsResponse.error('لا توجد محادثات');
      } else {
        return ConversationsResponse.error('فشل جلب المحادثات. كود الخطأ: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في جلب المحادثات: $e');
      return ConversationsResponse.error('خطأ في الاتصال بالسيرفر: ${e.toString()}');
    }
  }

  /// إعادة جلب المحادثات (refresh)
  Future<ConversationsResponse> refreshConversations() async {
    return getConversations();
  }

  /// البحث في المحادثات محلياً
  Future<ConversationsResponse> searchConversations(
    List<Conversation> allConversations,
    String query,
  ) async {
    try {
      final lowercaseQuery = query.toLowerCase().trim();
      
      if (lowercaseQuery.isEmpty) {
        return ConversationsResponse.success(allConversations);
      }

      final filtered = allConversations.where((conversation) {
        final userName = conversation.userName.toLowerCase();
        return userName.contains(lowercaseQuery);
      }).toList();

      return ConversationsResponse.success(filtered);
    } catch (e) {
      print('❌ خطأ في البحث: $e');
      return ConversationsResponse.error('خطأ في البحث');
    }
  }
}
