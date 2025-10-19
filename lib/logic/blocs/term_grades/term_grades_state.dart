import 'package:equatable/equatable.dart';
import '../../../data/models/term_grades_model.dart';

/// حالات Bloc الدرجات الفصلية
abstract class TermGradesState extends Equatable {
  const TermGradesState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class TermGradesInitial extends TermGradesState {
  const TermGradesInitial();
}

/// حالة التحميل
class TermGradesLoading extends TermGradesState {
  const TermGradesLoading();
}

/// حالة نجاح تحميل الدرجات
class TermGradesLoaded extends TermGradesState {
  final List<StudentTermGrades> studentGrades;

  const TermGradesLoaded(this.studentGrades);

  @override
  List<Object?> get props => [studentGrades];
}

/// حالة فشل تحميل الدرجات
class TermGradesError extends TermGradesState {
  final String message;

  const TermGradesError(this.message);

  @override
  List<Object?> get props => [message];
}

/// حالة عدم وجود درجات
class TermGradesEmpty extends TermGradesState {
  const TermGradesEmpty();
}
