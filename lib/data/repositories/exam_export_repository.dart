import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/exam_export_model.dart';

/// Repository مسؤول عن تصدير الأسئلة إلى ملف نصي منسق
/// ينشئ ملف نصي منسق يحتوي على جميع الأسئلة والإجابات
class ExamExportRepository {
  
  /// الدالة الرئيسية لتصدير الأسئلة إلى ملف نصي
  /// تأخذ ExamExportModel وتنشئ ملف نصي منسق
  Future<ExamExportResponse> exportToWord(ExamExportModel examData) async {
    try {
      print('📄 بدء تصدير الأسئلة إلى ملف نصي...');
      
      // إنشاء محتوى الوثيقة
      final docContent = await _createDocumentContent(examData);
      
      // حفظ الملف
      final filePath = await _saveFile(docContent, examData);
      
      print('✅ تم تصدير الأسئلة بنجاح إلى: $filePath');
      
      return ExamExportResponse(
        success: true,
        message: 'تم إنشاء الملف بنجاح',
        filePath: filePath,
        fileName: filePath.split(Platform.pathSeparator).last,
      );
      
    } catch (e) {
      print('❌ خطأ أثناء تصدير الأسئلة: $e');
      return ExamExportResponse(
        success: false,
        message: 'حدث خطأ أثناء إنشاء الملف: ${e.toString()}',
      );
    }
  }

  /// إنشاء محتوى الوثيقة من الأسئلة
  Future<String> _createDocumentContent(ExamExportModel examData) async {
    final buffer = StringBuffer();
    
    // إضافة معلومات الامتحان
    buffer.writeln('امتحان ${examData.subjectName ?? ""}');
    buffer.writeln('المدرسة: ${examData.schoolName ?? "غير محدد"}');
    buffer.writeln('المرحلة: ${examData.stageName ?? "غير محدد"}');
    buffer.writeln('الشعبة: ${examData.sectionName ?? "غير محدد"}');
    buffer.writeln('التاريخ: ${_formatDate(examData.createdAt)}');
    buffer.writeln('عدد الأسئلة: ${examData.totalQuestions}');
    buffer.writeln('');
    buffer.writeln('=' * 50);
    buffer.writeln('');

    // تجميع الأسئلة حسب النوع
    final questionsByType = <String, List<ExamQuestion>>{};
    for (final question in examData.questions) {
      questionsByType.putIfAbsent(question.type, () => []).add(question);
    }

    int questionCounter = 1;

    // إضافة الأسئلة الاختيارية
    if (questionsByType.containsKey('choice')) {
      buffer.writeln('الأسئلة الاختيارية:');
      buffer.writeln('-' * 30);
      for (final question in questionsByType['choice']!) {
        buffer.writeln('السؤال $questionCounter: ${question.questionText}');
        
        for (int i = 0; i < question.options.length; i++) {
          final letter = String.fromCharCode(65 + i); // A, B, C, D
          buffer.writeln('   $letter) ${question.options[i]}');
        }
        
        buffer.writeln('الإجابة الصحيحة: ${question.formattedCorrectAnswer}');
        buffer.writeln('');
        questionCounter++;
      }
      buffer.writeln('');
    }

    // إضافة أسئلة صح أو خطأ
    if (questionsByType.containsKey('truefalse')) {
      buffer.writeln('أسئلة صح أو خطأ:');
      buffer.writeln('-' * 30);
      for (final question in questionsByType['truefalse']!) {
        buffer.writeln('السؤال $questionCounter: ${question.questionText}');
        buffer.writeln('الإجابة الصحيحة: ${question.formattedCorrectAnswer}');
        buffer.writeln('');
        questionCounter++;
      }
      buffer.writeln('');
    }

    // إضافة أسئلة أكمل الفراغ
    if (questionsByType.containsKey('complete')) {
      buffer.writeln('أسئلة أكمل الفراغ:');
      buffer.writeln('-' * 30);
      for (final question in questionsByType['complete']!) {
        buffer.writeln('السؤال $questionCounter: ${question.questionText}');
        buffer.writeln('الإجابة الصحيحة: ${question.formattedCorrectAnswer}');
        buffer.writeln('');
        questionCounter++;
      }
      buffer.writeln('');
    }

    // إضافة الأسئلة المقالية
    if (questionsByType.containsKey('essay')) {
      buffer.writeln('الأسئلة المقالية:');
      buffer.writeln('-' * 30);
      for (final question in questionsByType['essay']!) {
        buffer.writeln('السؤال $questionCounter: ${question.questionText}');
        if (question.correctAnswer != null && question.correctAnswer!.isNotEmpty) {
          buffer.writeln('الإجابة النموذجية: ${question.correctAnswer}');
        }
        buffer.writeln('');
        questionCounter++;
      }
    }

    return buffer.toString();
  }

  /// حفظ الملف في مجلد التحميلات
  Future<String> _saveFile(String content, ExamExportModel examData) async {
    try {
      // الحصول على مجلد التحميلات
      Directory? directory;
      
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // محاولة الوصول لمجلد التحميلات
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          directory = downloadDir;
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }
      
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }

      // إنشاء اسم الملف
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final subjectName = examData.subjectName?.replaceAll(' ', '_') ?? 'امتحان';
      final fileName = 'اسئلة_${subjectName}_$timestamp.txt';
      
      // إنشاء مسار الملف
      final filePath = '${directory.path}${Platform.pathSeparator}$fileName';
      
      // كتابة المحتوى كملف نصي
      final file = File(filePath);
      await file.writeAsString(content, encoding: utf8);
      
      print('💾 تم حفظ الملف في: $filePath');
      
      return filePath;
      
    } catch (e) {
      print('❌ خطأ في حفظ الملف: $e');
      rethrow;
    }
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
