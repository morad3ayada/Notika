import 'package:equatable/equatable.dart';
import '../../../data/models/daily_grades_model.dart';

abstract class DailyGradesState extends Equatable {
  const DailyGradesState();

  @override
  List<Object?> get props => [];
}

/// الحالة الابتدائية
class DailyGradesInitial extends DailyGradesState {
  const DailyGradesInitial();
}

/// حالة التحميل
class DailyGradesLoading extends DailyGradesState {
  const DailyGradesLoading();
}

/// حالة تحميل الدرجات بنجاح
class DailyGradesLoaded extends DailyGradesState {
  final List<StudentDailyGrades> studentGrades;

  const DailyGradesLoaded({
    required this.studentGrades,
  });

  @override
  List<Object?> get props => [studentGrades];
}

/// حالة عدم وجود درجات
class DailyGradesEmpty extends DailyGradesState {
  final String message;

  const DailyGradesEmpty({
    this.message = 'لا توجد درجات مسجلة لهذا التاريخ',
  });

  @override
  List<Object?> get props => [message];
}

/// حالة الخطأ
class DailyGradesError extends DailyGradesState {
  final String message;

  const DailyGradesError(this.message);

  @override
  List<Object?> get props => [message];
}
