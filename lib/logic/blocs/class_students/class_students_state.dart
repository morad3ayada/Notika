import 'package:equatable/equatable.dart';
import '../../../data/models/class_students_model.dart';

/// الحالات الخاصة بطلاب الفصل
abstract class ClassStudentsState extends Equatable {
  const ClassStudentsState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class ClassStudentsInitial extends ClassStudentsState {
  const ClassStudentsInitial();
}

/// حالة التحميل
class ClassStudentsLoading extends ClassStudentsState {
  const ClassStudentsLoading();
}

/// حالة التحديث (عند إعادة جلب البيانات)
class ClassStudentsRefreshing extends ClassStudentsState {
  final List<Student> currentStudents;

  const ClassStudentsRefreshing({
    required this.currentStudents,
  });

  @override
  List<Object?> get props => [currentStudents];
}

/// حالة نجاح جلب الطلاب
class ClassStudentsLoaded extends ClassStudentsState {
  final List<Student> students;
  final String message;
  final int totalCount;
  final bool isSearchResult;

  const ClassStudentsLoaded({
    required this.students,
    required this.message,
    this.totalCount = 0,
    this.isSearchResult = false,
  });

  @override
  List<Object?> get props => [students, message, totalCount, isSearchResult];
}

/// حالة عدم وجود طلاب
class ClassStudentsEmpty extends ClassStudentsState {
  final String message;
  final bool isSearchResult;

  const ClassStudentsEmpty({
    required this.message,
    this.isSearchResult = false,
  });

  @override
  List<Object?> get props => [message, isSearchResult];
}

/// حالة الخطأ
class ClassStudentsError extends ClassStudentsState {
  final String message;

  const ClassStudentsError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
