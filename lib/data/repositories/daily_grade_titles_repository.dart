import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_grade_titles_model.dart';
import '../services/auth_service.dart';

/// Repository لجلب عناوين الدرجات اليومية من السيرفر
class DailyGradeTitlesRepository {
  static const String baseUrl = 'https://nouraleelemorg.runasp.net/api';

  /// جلب عناوين الدرجات اليومية من السيرفر
  Future<DailyGradeTitlesResponse> getDailyGradeTitles({
    required String levelSubjectId,
    required String levelId,
    required String classId,
  }) async {
    try {
      print('📊 جلب عناوين الدرجات اليومية...');
      print('🔍 LevelSubjectId: $levelSubjectId');
      print('🔍 LevelId: $levelId');
      print('🔍 ClassId: $classId');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return DailyGradeTitlesResponse.error('لم يتم العثور على رمز المصادقة');
      }

      // بناء الرابط مع query parameters
      final queryParams = {
        'LevelSubjectId': levelSubjectId,
        'LevelId': levelId,
        'ClassId': classId,
      };

      final uri = Uri.parse('$baseUrl/dailygradetitles').replace(
        queryParameters: queryParams,
      );

      print('🌐 إرسال طلب إلى: $uri');

      // إرسال الطلب
      final response = await http.get(
        uri,
        headers: {
          'accept': 'text/plain',
          'Authorization': token, // بدون Bearer حسب النمط المُتبع في المشروع
        },
      );

      print('📊 كود الاستجابة: ${response.statusCode}');
      print('📄 نص الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        // نجح الطلب
        try {
          // محاولة تحليل الاستجابة كـ JSON array مباشرة
          final List<dynamic> titlesData = jsonDecode(response.body);

          // طباعة البيانات الخام للتشخيص
          print('📋 البيانات الخام من السيرفر:');
          for (int i = 0; i < titlesData.length && i < 5; i++) {
            print('عنوان $i: ${titlesData[i]}');
          }

          // تحويل البيانات مع معالجة آمنة للأخطاء
          final List<DailyGradeTitle> titles = [];
          for (int i = 0; i < titlesData.length; i++) {
            try {
              final title = DailyGradeTitle.fromJson(titlesData[i]);
              titles.add(title);
              print(
                  '✅ تم تحويل العنوان ${i + 1}: ${title.displayTitle} (maxGrade: ${title.maxGrade})');
            } catch (e) {
              print('⚠️ خطأ في تحويل العنوان ${i + 1}: $e');
              print('   البيانات: ${titlesData[i]}');
              // نتخطى هذا العنصر ونكمل مع الباقي
            }
          }

          // ترتيب العناوين حسب الترتيب المحدد
          titles.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

          print(
              '✅ تم جلب ${titles.length} عنوان درجة بنجاح من أصل ${titlesData.length}');
          if (titles.isNotEmpty) {
            print('📝 أول عنوان محول: ${titles.first.toJson()}');
          }

          return DailyGradeTitlesResponse.success(
            titles: titles,
            message: 'تم جلب ${titles.length} عنوان درجة بنجاح',
          );
        } catch (e) {
          print('❌ خطأ في تحليل البيانات: $e');
          print('   Stack trace: ${StackTrace.current}');

          // محاولة تحليل كـ object يحتوي على array
          try {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            return DailyGradeTitlesResponse.fromJson(responseData);
          } catch (e2) {
            print('❌ فشل التحليل البديل: $e2');
            return DailyGradeTitlesResponse.error(
                'خطأ في تحليل بيانات عناوين الدرجات: ${e.toString()}');
          }
        }
      } else if (response.statusCode == 400) {
        // خطأ في المعاملات المُرسلة
        String errorMessage = 'خطأ في معاملات الطلب';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        return DailyGradeTitlesResponse.error(errorMessage);
      } else if (response.statusCode == 401) {
        return DailyGradeTitlesResponse.error(
            'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى');
      } else if (response.statusCode == 403) {
        return DailyGradeTitlesResponse.error(
            'ليس لديك صلاحية للوصول لعناوين الدرجات');
      } else if (response.statusCode == 404) {
        return DailyGradeTitlesResponse.error(
            'لم يتم العثور على عناوين درجات لهذا الفصل');
      } else if (response.statusCode >= 500) {
        return DailyGradeTitlesResponse.error(
            'خطأ في الخادم، يرجى المحاولة لاحقاً');
      } else {
        return DailyGradeTitlesResponse.error(
            'حدث خطأ غير متوقع (${response.statusCode})');
      }
    } catch (e) {
      print('❌ خطأ في جلب عناوين الدرجات: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        return DailyGradeTitlesResponse.error('لا يوجد اتصال بالإنترنت');
        return DailyGradeTitlesResponse.error(
            'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى');
      } else if (e.toString().contains('FormatException')) {
        return DailyGradeTitlesResponse.error(
            'خطأ في تنسيق البيانات المُستلمة');
      } else {
        return DailyGradeTitlesResponse.error(
            'حدث خطأ أثناء جلب البيانات: ${e.toString()}');
      }
    }
  }

  /// إضافة عنوان درجة يومية جديد
  Future<bool> createDailyGradeTitle({
    required String title,
    required int maxGrade,
    required String levelId,
    required String classId,
    required String levelSubjectId,
    String? description,
    int? order,
  }) async {
    try {
      print('📝 إنشاء عنوان درجة يومية جديد...');
      print('📌 العنوان: $title');
      print('📊 الدرجة القصوى: $maxGrade');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ لا يوجد token');
        return false;
      }

      final uri = Uri.parse('$baseUrl/dailygradetitles');

      final body = {
        'title': title,
        'maxGrade': maxGrade,
        'levelId': levelId,
        'classId': classId,
        'levelSubjectId': levelSubjectId,
        if (description != null) 'description': description,
        if (order != null) 'order': order,
      };

      print('📦 البيانات المرسلة: $body');

      final response = await http.post(
        uri,
        headers: {
          'accept': 'text/plain',
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('📊 كود الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ تم إنشاء عنوان الدرجة بنجاح');
        return true;
      } else {
        print('❌ فشل إنشاء عنوان الدرجة: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في إنشاء عنوان الدرجة: $e');
      return false;
    }
  }

  /// البحث عن عناوين الدرجات
  Future<DailyGradeTitlesResponse> searchGradeTitles({
    required String levelSubjectId,
    required String levelId,
    required String classId,
    required String searchQuery,
  }) async {
    try {
      // جلب جميع العناوين أولاً
      final allTitlesResponse = await getDailyGradeTitles(
        levelSubjectId: levelSubjectId,
        levelId: levelId,
        classId: classId,
      );

      if (!allTitlesResponse.success) {
        return allTitlesResponse;
      }

      // تصفية العناوين حسب البحث
      final filteredTitles = allTitlesResponse.titles.where((title) {
        final query = searchQuery.toLowerCase();
        return (title.title?.toLowerCase().contains(query) ?? false) ||
            (title.description?.toLowerCase().contains(query) ?? false);
      }).toList();

      return DailyGradeTitlesResponse.success(
        titles: filteredTitles,
        message: 'تم العثور على ${filteredTitles.length} عنوان درجة',
      );
    } catch (e) {
      print('❌ خطأ في البحث عن عناوين الدرجات: $e');
      return DailyGradeTitlesResponse.error(
          'حدث خطأ أثناء البحث: ${e.toString()}');
    }
  }

  /// جلب تفاصيل عنوان درجة معين (اختياري للمستقبل)
  Future<DailyGradeTitle?> getGradeTitleDetails(String titleId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على رمز المصادقة');
      }

      final url = Uri.parse('$baseUrl/dailygradetitles/$titleId');

      final response = await http.get(
        url,
        headers: {
          'accept': 'text/plain',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> titleData = jsonDecode(response.body);
        return DailyGradeTitle.fromJson(titleData);
      } else {
        throw Exception('فشل في جلب تفاصيل عنوان الدرجة');
      }
    } catch (e) {
      print('❌ خطأ في جلب تفاصيل عنوان الدرجة: $e');
      return null;
    }
  }
}
