import 'package:equatable/equatable.dart';

/// نموذج البيانات لتصدير الأسئلة إلى ملف Word
/// يحتوي على كل الأسئلة والاختيارات والإجابات
class ExamExportModel extends Equatable {
  final String examTitle;           // عنوان الامتحان
  final String? schoolName;         // اسم المدرسة
  final String? stageName;          // اسم المرحلة
  final String? sectionName;        // اسم الشعبة
  final String? subjectName;        // اسم المادة
  final List<ExamQuestion> questions; // قائمة الأسئلة
  final DateTime createdAt;         // تاريخ الإنشاء

  const ExamExportModel({
    required this.examTitle,
    this.schoolName,
    this.stageName,
    this.sectionName,
    this.subjectName,
    required this.questions,
    required this.createdAt,
  });

  /// دالة لحساب إجمالي عدد الأسئلة
  int get totalQuestions => questions.length;

  /// دالة لحساب عدد الأسئلة حسب النوع
  Map<String, int> get questionCountsByType {
    final counts = <String, int>{};
    for (final question in questions) {
      counts[question.type] = (counts[question.type] ?? 0) + 1;
    }
    return counts;
  }

  @override
  List<Object?> get props => [
        examTitle,
        schoolName,
        stageName,
        sectionName,
        subjectName,
        questions,
        createdAt,
      ];
}

/// نموذج السؤال المفرد
class ExamQuestion extends Equatable {
  final String type;              // نوع السؤال (choice, truefalse, complete, essay)
  final String questionText;      // نص السؤال
  final List<String> options;     // الاختيارات (للأسئلة الاختيارية)
  final String? correctAnswer;    // الإجابة الصحيحة
  final int questionNumber;       // رقم السؤال

  const ExamQuestion({
    required this.type,
    required this.questionText,
    this.options = const [],
    this.correctAnswer,
    required this.questionNumber,
  });

  /// دالة لتحويل نوع السؤال إلى نص عربي
  String get typeInArabic {
    switch (type) {
      case 'choice':
        return 'اختياري';
      case 'truefalse':
        return 'صح أو خطأ';
      case 'complete':
        return 'أكمل الفراغ';
      case 'essay':
        return 'مقالي';
      default:
        return 'غير محدد';
    }
  }

  /// دالة لتحويل الإجابة الصحيحة إلى نص مناسب
  String get formattedCorrectAnswer {
    switch (type) {
      case 'choice':
        if (correctAnswer != null) {
          final index = int.tryParse(correctAnswer!) ?? 0;
          if (index < options.length) {
            return options[index];
          }
        }
        return 'غير محدد';
      case 'truefalse':
        return correctAnswer == 'true' ? 'صح' : 'خطأ';
      case 'complete':
      case 'essay':
        return correctAnswer ?? 'غير محدد';
      default:
        return 'غير محدد';
    }
  }

  @override
  List<Object?> get props => [
        type,
        questionText,
        options,
        correctAnswer,
        questionNumber,
      ];
}

/// نموذج استجابة تصدير الملف
class ExamExportResponse extends Equatable {
  final bool success;
  final String message;
  final String? filePath;
  final String? fileName;

  const ExamExportResponse({
    required this.success,
    required this.message,
    this.filePath,
    this.fileName,
  });

  @override
  List<Object?> get props => [success, message, filePath, fileName];
}
