import 'package:equatable/equatable.dart';

/// نموذج درجة يومية واحدة
class DailyGrade extends Equatable {
  final String? id;
  final String dailyGradeTitleId;
  final double grade;
  final String? note;

  const DailyGrade({
    this.id,
    required this.dailyGradeTitleId,
    required this.grade,
    this.note,
  });

  factory DailyGrade.fromJson(Map<String, dynamic> json) {
    return DailyGrade(
      id: json['id']?.toString(),
      dailyGradeTitleId: json['dailyGradeTitleId']?.toString() ?? '',
      grade: (json['grade'] as num?)?.toDouble() ?? 0.0,
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'dailyGradeTitleId': dailyGradeTitleId,
        'grade': grade,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  @override
  List<Object?> get props => [id, dailyGradeTitleId, grade, note];
}

/// نموذج درجة كويز واحد
class QuizGrade extends Equatable {
  final String? id;
  final String title;
  final double grade;
  final double? maxGrade;
  final String? note;

  const QuizGrade({
    this.id,
    required this.title,
    required this.grade,
    this.maxGrade,
    this.note,
  });

  factory QuizGrade.fromJson(Map<String, dynamic> json) {
    return QuizGrade(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? 
          json['quizTitle']?.toString() ?? 
          json['name']?.toString() ?? 
          'كويز',
      grade: (json['grade'] as num?)?.toDouble() ?? 0.0,
      maxGrade: (json['maxGrade'] as num?)?.toDouble() ?? 
          (json['totalGrade'] as num?)?.toDouble(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'grade': grade,
        if (maxGrade != null) 'maxGrade': maxGrade,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  @override
  List<Object?> get props => [id, title, grade, maxGrade, note];
}

/// نموذج درجة اسيمنت واحد
class AssignmentGrade extends Equatable {
  final String? id;
  final String title;
  final double grade;
  final double? maxGrade;
  final String? note;

  const AssignmentGrade({
    this.id,
    required this.title,
    required this.grade,
    this.maxGrade,
    this.note,
  });

  factory AssignmentGrade.fromJson(Map<String, dynamic> json) {
    return AssignmentGrade(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? 
          json['assignmentTitle']?.toString() ?? 
          json['name']?.toString() ?? 
          'واجب',
      grade: (json['grade'] as num?)?.toDouble() ?? 0.0,
      maxGrade: (json['maxGrade'] as num?)?.toDouble() ?? 
          (json['totalGrade'] as num?)?.toDouble(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'grade': grade,
        if (maxGrade != null) 'maxGrade': maxGrade,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  @override
  List<Object?> get props => [id, title, grade, maxGrade, note];
}

/// نموذج درجات طالب واحد
class StudentDailyGrades extends Equatable {
  final String studentId;
  final DateTime date;
  final List<DailyGrade> dailyGrades;
  final List<QuizGrade> quizzes;
  final List<AssignmentGrade> assignments;
  final int? absenceTimes;

  const StudentDailyGrades({
    required this.studentId,
    required this.date,
    required this.dailyGrades,
    this.quizzes = const [],
    this.assignments = const [],
    this.absenceTimes,
  });

  factory StudentDailyGrades.fromJson(Map<String, dynamic> json) {
    return StudentDailyGrades(
      studentId: json['studentId']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      dailyGrades: (json['dailyGrades'] as List<dynamic>?)
              ?.map((e) => DailyGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map((e) => QuizGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['Quizzes'] as List<dynamic>?)
              ?.map((e) => QuizGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => AssignmentGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['Assignments'] as List<dynamic>?)
              ?.map((e) => AssignmentGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      absenceTimes: json['absenceTimes'] as int? ?? 
          json['AbsenceTimes'] as int? ?? 
          json['absence_times'] as int? ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'date': date.toIso8601String(),
        'dailyGrades': dailyGrades.map((e) => e.toJson()).toList(),
        'quizzes': quizzes.map((e) => e.toJson()).toList(),
        'assignments': assignments.map((e) => e.toJson()).toList(),
        if (absenceTimes != null) 'absenceTimes': absenceTimes,
      };

  @override
  List<Object?> get props => [studentId, date, dailyGrades, quizzes, assignments, absenceTimes];
}

/// نموذج الطلب لتحديث الدرجات بشكل جماعي
class BulkDailyGradesRequest extends Equatable {
  final String levelId;
  final String classId;
  final String subjectId;
  final DateTime date;
  final List<StudentDailyGrades> studentsDailyGrades;

  const BulkDailyGradesRequest({
    required this.levelId,
    required this.classId,
    required this.subjectId,
    required this.date,
    required this.studentsDailyGrades,
  });

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'classId': classId,
        'subjectId': subjectId,
        'date': date.toIso8601String(),
        'studentsDailyGrades':
            studentsDailyGrades.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props =>
      [levelId, classId, subjectId, date, studentsDailyGrades];
}

/// نموذج الاستجابة
class DailyGradesResponse extends Equatable {
  final bool success;
  final String message;
  final dynamic data;

  const DailyGradesResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory DailyGradesResponse.success({String? message, dynamic data}) {
    return DailyGradesResponse(
      success: true,
      message: message ?? 'تم حفظ الدرجات بنجاح',
      data: data,
    );
  }

  factory DailyGradesResponse.error(String message) {
    return DailyGradesResponse(
      success: false,
      message: message,
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
