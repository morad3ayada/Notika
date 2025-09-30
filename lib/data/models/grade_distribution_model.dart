import 'package:equatable/equatable.dart';

/// نموذج البيانات لتوزيع الدرجات
class GradeDistributionModel extends Equatable {
  final String title;
  final int maxGrade;
  final String levelId;
  final String classId;
  final String subjectId;

  const GradeDistributionModel({
    required this.title,
    required this.maxGrade,
    required this.levelId,
    required this.classId,
    required this.subjectId,
  });

  /// تحويل إلى JSON للإرسال للسيرفر
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'maxGrade': maxGrade,
      'levelId': levelId,
      'classId': classId,
      'subjectId': subjectId,
    };
  }

  /// إنشاء من JSON
  factory GradeDistributionModel.fromJson(Map<String, dynamic> json) {
    return GradeDistributionModel(
      title: json['title'] ?? '',
      maxGrade: json['maxGrade'] ?? 0,
      levelId: json['levelId'] ?? '',
      classId: json['classId'] ?? '',
      subjectId: json['subjectId'] ?? '',
    );
  }

  @override
  List<Object?> get props => [title, maxGrade, levelId, classId, subjectId];
}

/// نموذج استجابة إرسال توزيع الدرجات
class GradeDistributionResponse extends Equatable {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const GradeDistributionResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory GradeDistributionResponse.success(String message, {Map<String, dynamic>? data}) {
    return GradeDistributionResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  factory GradeDistributionResponse.error(String message) {
    return GradeDistributionResponse(
      success: false,
      message: message,
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// نموذج مكون الدرجة (للاستخدام المحلي)
class GradeComponent extends Equatable {
  final String name;
  final int grade;

  const GradeComponent({
    required this.name,
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grade': grade,
    };
  }

  factory GradeComponent.fromJson(Map<String, dynamic> json) {
    return GradeComponent(
      name: json['name'] ?? '',
      grade: json['grade'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [name, grade];
}
