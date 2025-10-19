import 'package:equatable/equatable.dart';

/// أحداث Bloc الدرجات الفصلية
abstract class TermGradesEvent extends Equatable {
  const TermGradesEvent();

  @override
  List<Object?> get props => [];
}

/// حدث جلب درجات طلاب الفصل الفصلية
class LoadTermGradesEvent extends TermGradesEvent {
  final String subjectId;
  final String levelId;
  final String classId;

  const LoadTermGradesEvent({
    required this.subjectId,
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object?> get props => [subjectId, levelId, classId];
}
