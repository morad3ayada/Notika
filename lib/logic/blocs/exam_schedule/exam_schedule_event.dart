import 'package:equatable/equatable.dart';

/// الأحداث الخاصة بجدول الامتحانات
abstract class ExamScheduleEvent extends Equatable {
  const ExamScheduleEvent();

  @override
  List<Object?> get props => [];
}

/// حدث جلب جدول الامتحانات للمرحلة والشعبة
class FetchClassExamSchedulesEvent extends ExamScheduleEvent {
  final String levelId;
  final String classId;

  const FetchClassExamSchedulesEvent({
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object?> get props => [levelId, classId];
}

/// حدث جلب جدول امتحانات مادة معينة
class FetchSubjectExamSchedulesEvent extends ExamScheduleEvent {
  final String levelId;
  final String classId;
  final String subjectId;

  const FetchSubjectExamSchedulesEvent({
    required this.levelId,
    required this.classId,
    required this.subjectId,
  });

  @override
  List<Object?> get props => [levelId, classId, subjectId];
}

/// حدث البحث في جدول الامتحانات
class SearchExamSchedulesEvent extends ExamScheduleEvent {
  final String levelId;
  final String classId;
  final String? subjectName;
  final DateTime? fromDate;
  final DateTime? toDate;

  const SearchExamSchedulesEvent({
    required this.levelId,
    required this.classId,
    this.subjectName,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [levelId, classId, subjectName, fromDate, toDate];
}

/// حدث إعادة تعيين حالة جدول الامتحانات
class ResetExamScheduleEvent extends ExamScheduleEvent {
  const ResetExamScheduleEvent();
}

/// حدث تحديث جدول الامتحانات
class RefreshExamScheduleEvent extends ExamScheduleEvent {
  final String levelId;
  final String classId;

  const RefreshExamScheduleEvent({
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object?> get props => [levelId, classId];
}
