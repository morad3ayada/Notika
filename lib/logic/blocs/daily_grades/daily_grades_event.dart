import 'package:equatable/equatable.dart';

abstract class DailyGradesEvent extends Equatable {
  const DailyGradesEvent();

  @override
  List<Object?> get props => [];
}

/// حدث لجلب درجات طلاب الفصل
class LoadClassStudentsGradesEvent extends DailyGradesEvent {
  final String subjectId;
  final String levelId;
  final String classId;
  final String date; // بصيغة "2-10-2025"

  const LoadClassStudentsGradesEvent({
    required this.subjectId,
    required this.levelId,
    required this.classId,
    required this.date,
  });

  @override
  List<Object?> get props => [subjectId, levelId, classId, date];
}

/// حدث لإعادة تعيين الحالة
class ResetDailyGradesEvent extends DailyGradesEvent {
  const ResetDailyGradesEvent();
}
