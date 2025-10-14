import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_messages_model.dart';
import '../services/auth_service.dart';
import '../../config/api_config.dart';

/// Repository لجلب المحادثات من السيرفر
class ChatRepository {
  // استخدام ApiConfig.baseUrl الديناميكي بدلاً من URL ثابت
  String get baseUrl => '${ApiConfig.baseUrl}/api';

  /// جلب المحادثة بين المعلم والطالب
  /// teacherId: userId للمعلم (المستخدم الحالي)
  /// studentId: userId للطالب
  Future<ChatConversationResponse> getConversation({
    required String teacherId,
    required String studentId,
  }) async {
    try {
      print('💬 جلب المحادثة...');
      print('👨‍🏫 userId المعلم: $teacherId');
      print('👨‍🎓 userId الطالب: $studentId');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return ChatConversationResponse.error('لم يتم العثور على رمز المصادقة');
      }

      final uri = Uri.parse('$baseUrl/Chat/conversation/$teacherId/$studentId');
      
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
          
          List<ChatMessage> messages = [];
          
          // التحقق من نوع الاستجابة
          if (responseData is List) {
            // الاستجابة عبارة عن array مباشرة
            print('📋 عدد الرسائل من السيرفر: ${responseData.length}');
            
            // تحويل البيانات مع معالجة آمنة للأخطاء
            for (int i = 0; i < responseData.length; i++) {
              try {
                final message = ChatMessage.fromJson(responseData[i]);
                messages.add(message);
                if (i < 3) {
                  print('✅ رسالة ${i + 1}: ${message.message?.substring(0, message.message!.length > 50 ? 50 : message.message!.length)}...');
                }
              } catch (e) {
                print('⚠️ خطأ في تحويل الرسالة ${i + 1}: $e');
                // نتخطى هذا العنصر ونكمل مع الباقي
              }
            }
          } else if (responseData is Map) {
            // الاستجابة عبارة عن object يحتوي على array
            final messagesData = responseData['messages'] ?? 
                                 responseData['Messages'] ?? 
                                 responseData['data'] ?? 
                                 responseData['Data'] ?? 
                                 [];
            
            if (messagesData is List) {
              print('📋 عدد الرسائل من السيرفر: ${messagesData.length}');
              
              for (int i = 0; i < messagesData.length; i++) {
                try {
                  final message = ChatMessage.fromJson(messagesData[i]);
                  messages.add(message);
                } catch (e) {
                  print('⚠️ خطأ في تحويل الرسالة ${i + 1}: $e');
                }
              }
            }
          }
          
          // ترتيب الرسائل حسب الوقت (الأقدم أولاً)
          messages.sort((a, b) {
            if (a.timestamp == null && b.timestamp == null) return 0;
            if (a.timestamp == null) return -1;
            if (b.timestamp == null) return 1;
            return a.timestamp!.compareTo(b.timestamp!);
          });
          
          print('✅ تم جلب ${messages.length} رسالة بنجاح');
          
          return ChatConversationResponse.success(
            messages: messages,
            message: 'تم جلب ${messages.length} رسالة بنجاح',
          );
        } catch (e) {
          print('❌ خطأ في تحليل البيانات: $e');
          return ChatConversationResponse.error('خطأ في تحليل بيانات المحادثة: ${e.toString()}');
        }
      } else if (response.statusCode == 400) {
        return ChatConversationResponse.error('خطأ في معاملات الطلب');
      } else if (response.statusCode == 401) {
        return ChatConversationResponse.error('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 403) {
        return ChatConversationResponse.error('ليس لديك صلاحية للوصول لهذه المحادثة');
      } else if (response.statusCode == 404) {
        // لا توجد محادثة بعد - نرجع قائمة فارغة
        return ChatConversationResponse.success(
          messages: [],
          message: 'لا توجد رسائل بعد',
        );
      } else if (response.statusCode >= 500) {
        return ChatConversationResponse.error('خطأ في الخادم، يرجى المحاولة لاحقاً');
      } else {
        return ChatConversationResponse.error('حدث خطأ غير متوقع (${response.statusCode})');
      }
    } catch (e) {
      print('❌ خطأ في جلب المحادثة: $e');
      
      if (e.toString().contains('SocketException') || e.toString().contains('NetworkException')) {
        return ChatConversationResponse.error('لا يوجد اتصال بالإنترنت');
      } else if (e.toString().contains('TimeoutException')) {
        return ChatConversationResponse.error('انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى');
      } else if (e.toString().contains('FormatException')) {
        return ChatConversationResponse.error('خطأ في تنسيق البيانات المُستلمة');
      } else {
        return ChatConversationResponse.error('حدث خطأ أثناء جلب البيانات: ${e.toString()}');
      }
    }
  }

  /// إرسال رسالة جديدة
  Future<bool> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    try {
      print('📤 إرسال رسالة...');
      print('📨 المستقبل: $receiverId');
      print('💬 الرسالة: $message');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ لا يوجد token');
        return false;
      }

      final uri = Uri.parse('$baseUrl/Chat/send');
      
      print('🌐 إرسال طلب إلى: $uri');

      final response = await http.post(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiverId': receiverId,
          'message': message,
        }),
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('📄 نص الاستجابة: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ تم إرسال الرسالة بنجاح');
        return true;
      } else {
        print('❌ فشل إرسال الرسالة: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في إرسال الرسالة: $e');
      return false;
    }
  }

  /// تحديد الرسائل كمقروءة
  /// currentUserId: userId للمستخدم الحالي (المعلم)
  /// otherUserId: userId للطرف الآخر (الطالب)
  Future<bool> markAsRead({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      print('📖 تحديد الرسائل كمقروءة...');
      print('👤 المستخدم الحالي: $currentUserId');
      print('👤 الطرف الآخر: $otherUserId');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ لا يوجد token');
        return false;
      }

      final uri = Uri.parse('$baseUrl/Chat/markAsRead/$currentUserId/$otherUserId');
      
      print('🌐 إرسال طلب إلى: $uri');

      final response = await http.post(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': token,
        },
      );

      print('📊 كود الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ تم تحديد الرسائل كمقروءة');
        return true;
      } else {
        print('❌ فشل تحديد الرسائل كمقروءة: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في تحديد الرسائل كمقروءة: $e');
      return false;
    }
  }
}
