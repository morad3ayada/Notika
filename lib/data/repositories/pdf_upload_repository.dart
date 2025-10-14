import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/pdf_upload_model.dart';
import '../../config/api_config.dart';
import '../../data/services/auth_service.dart';
import '../../di/injector.dart';

/// Repository مسؤول عن رفع الملفات للسيرفر
/// بيستخدم MultipartRequest عشان يقدر يبعت الملفات مع البيانات
class PdfUploadRepository {
  // إنشاء baseUrl ديناميكياً ليستخدم ApiConfig.baseUrl الحالي
  String get _baseUrl => ApiConfig.baseUrl;

  /// الميثود الرئيسي لرفع الملف
  /// بياخد PdfUploadModel ويبعته للسيرفر باستخدام multipart/form-data
  Future<PdfUploadResponse> uploadPdf(PdfUploadModel model) async {
    try {
      print('🚀 بدء رفع الملف: ${model.title}');
      
      // جلب التوكن من AuthService (static method)
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على رمز المصادقة');
      }

      // إنشاء MultipartRequest
      final uri = Uri.parse('$_baseUrl/api/file/add');
      final request = http.MultipartRequest('POST', uri);

      // إضافة الهيدرز المطلوبة
      request.headers.addAll({
        'accept': 'text/plain',
        'Authorization': token, // بدون Bearer كما هو مطلوب في المشروع
      });

      // إضافة البيانات النصية للـ form
      final formData = model.toFormData();
      request.fields.addAll(formData);

      print('📝 بيانات الفورم:');
      formData.forEach((key, value) {
        print('   $key: $value');
      });

      // إضافة الملف الأساسي
      if (!model.file.existsSync()) {
        throw Exception('الملف المحدد غير موجود');
      }

      final mimeType = PdfUploadModel.getMimeType(model.file.path);
      final multipartFile = await http.MultipartFile.fromPath(
        'File', // اسم الحقل في الـ API
        model.file.path,
        contentType: _parseMediaType(mimeType),
      );
      
      request.files.add(multipartFile);
      
      print('📎 تم إضافة الملف: ${model.file.path.split(Platform.pathSeparator).last}');
      print('📄 نوع الملف: $mimeType');

      // إضافة الملف الصوتي إذا كان موجود
      if (model.voiceFile != null) {
        if (!model.voiceFile!.existsSync()) {
          print('⚠️ الملف الصوتي غير موجود، سيتم تجاهله');
        } else {
          print('🎵 إضافة الملف الصوتي...');
          
          // رفع الملف الصوتي كملف منفصل بنفس البيانات لكن مسار مختلف
          await _uploadVoiceFile(model);
          
          print('✅ تم رفع الملف الصوتي بنجاح');
        }
      }

      // إرسال الطلب
      print('📤 إرسال الطلب إلى: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📨 رد السيرفر:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');

      // معالجة الاستجابة
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // نجح الرفع
        return _handleSuccessResponse(response);
      } else {
        // فشل الرفع
        return _handleErrorResponse(response);
      }

    } catch (e) {
      print('❌ خطأ أثناء رفع الملف: $e');
      return PdfUploadResponse(
        success: false,
        message: 'حدث خطأ أثناء رفع الملف: ${e.toString()}',
      );
    }
  }

  /// معالجة الاستجابة الناجحة من السيرفر
  PdfUploadResponse _handleSuccessResponse(http.Response response) {
    try {
      // محاولة تحليل JSON إذا كان موجود
      if (response.body.isNotEmpty) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic>) {
          return PdfUploadResponse.fromJson(jsonResponse);
        }
      }
      
      // إذا مفيش JSON أو مش واضح، نرجع استجابة نجاح عامة
      return const PdfUploadResponse(
        success: true,
        message: 'تم رفع الملف بنجاح!',
      );
    } catch (e) {
      print('⚠️ خطأ في تحليل استجابة النجاح: $e');
      return const PdfUploadResponse(
        success: true,
        message: 'تم رفع الملف بنجاح!',
      );
    }
  }

  /// معالجة الاستجابة عند حدوث خطأ
  PdfUploadResponse _handleErrorResponse(http.Response response) {
    try {
      String errorMessage = 'حدث خطأ أثناء رفع الملف';
      
      // محاولة استخراج رسالة الخطأ من الاستجابة
      if (response.body.isNotEmpty) {
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse is Map<String, dynamic>) {
            errorMessage = jsonResponse['message'] ?? 
                          jsonResponse['Message'] ?? 
                          jsonResponse['error'] ?? 
                          errorMessage;
          } else if (jsonResponse is String) {
            errorMessage = jsonResponse;
          }
        } catch (e) {
          // إذا مش JSON، نستخدم النص كما هو
          errorMessage = response.body;
        }
      }

      // إضافة معلومات إضافية حسب كود الخطأ
      switch (response.statusCode) {
        case 400:
          errorMessage = 'بيانات غير صحيحة: $errorMessage';
          break;
        case 401:
          errorMessage = 'غير مصرح لك برفع الملفات';
          break;
        case 403:
          errorMessage = 'ليس لديك صلاحية لرفع الملفات';
          break;
        case 404:
          errorMessage = 'الخدمة غير متاحة حالياً';
          break;
        case 413:
          errorMessage = 'حجم الملف كبير جداً';
          break;
        case 500:
          errorMessage = 'خطأ في السيرفر، يرجى المحاولة لاحقاً';
          break;
      }

      return PdfUploadResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      return PdfUploadResponse(
        success: false,
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  /// رفع الملف الصوتي كملف منفصل
  /// بنفس البيانات لكن بمسار "Voices" ونوع "aac"
  Future<void> _uploadVoiceFile(PdfUploadModel model) async {
    try {
      // إنشاء طلب منفصل للملف الصوتي
      final uri = Uri.parse('$_baseUrl/api/file/add');
      final request = http.MultipartRequest('POST', uri);

      // جلب التوكن
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('لم يتم العثور على رمز المصادقة للملف الصوتي');
      }

      // إضافة الهيدرز
      request.headers.addAll({
        'accept': 'text/plain',
        'Authorization': token,
      });

      // إضافة البيانات مع تعديل المسار والنوع للملف الصوتي
      final voiceFormData = {
        'LevelSubjectId': model.levelSubjectId,
        'LevelId': model.levelId,
        'ClassId': model.classId,
        'FileClassificationId': model.fileClassificationId,
        'Title': 'Voice', // عنوان ثابت للملف الصوتي كما في الـ cURL
        'FileType': 'aac', // نوع ثابت للملف الصوتي
        'Path': 'Voices', // مسار خاص بالملفات الصوتية
        if (model.note != null) 'Note': model.note!,
      };

      request.fields.addAll(voiceFormData);

      // إضافة الملف الصوتي
      final voiceMimeType = PdfUploadModel.getMimeType(model.voiceFile!.path);
      final voiceMultipartFile = await http.MultipartFile.fromPath(
        'File',
        model.voiceFile!.path,
        contentType: _parseMediaType(voiceMimeType),
      );

      request.files.add(voiceMultipartFile);

      print('🎵 بيانات الملف الصوتي:');
      voiceFormData.forEach((key, value) {
        print('   $key: $value');
      });
      print('   الملف: ${model.voiceFile!.path.split(Platform.pathSeparator).last}');
      print('   نوع MIME: $voiceMimeType');

      // إرسال طلب الملف الصوتي
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📨 رد السيرفر للملف الصوتي:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('⚠️ فشل رفع الملف الصوتي: ${response.statusCode}');
        // لا نرمي خطأ هنا عشان ما نوقفش رفع الملف الأساسي
      }

    } catch (e) {
      print('❌ خطأ أثناء رفع الملف الصوتي: $e');
      // لا نرمي خطأ هنا عشان ما نوقفش رفع الملف الأساسي
    }
  }

  /// دالة مساعدة لتحويل MIME type إلى MediaType
  /// عشان نستخدمها مع MultipartFile
  dynamic _parseMediaType(String mimeType) {
    try {
      // استخدام dynamic عشان نتجنب مشاكل الـ imports
      // الـ http package هيتعامل مع الـ string عادي
      return null; // خلي الـ package يحدد النوع تلقائياً
    } catch (e) {
      return null;
    }
  }
}
