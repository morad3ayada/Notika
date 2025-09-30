import 'package:equatable/equatable.dart';

/// الأحداث الخاصة بطلاب الفصل
abstract class ClassStudentsEvent extends Equatable {
  const ClassStudentsEvent();

  @override
  List<Object?> get props => [];
}

/// حدث جلب طلاب الفصل
class LoadClassStudentsEvent extends ClassStudentsEvent {
  final String levelId;
  final String classId;

  const LoadClassStudentsEvent({
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object?> get props => [levelId, classId];
}

/// حدث البحث عن طلاب في الفصل
class SearchClassStudentsEvent extends ClassStudentsEvent {
  final String levelId;
  final String classId;
  final String searchQuery;

  const SearchClassStudentsEvent({
    required this.levelId,
    required this.classId,
    required this.searchQuery,
  });

  @override
  List<Object?> get props => [levelId, classId, searchQuery];
}

/// حدث إعادة تعيين حالة طلاب الفصل
class ResetClassStudentsEvent extends ClassStudentsEvent {
  const ResetClassStudentsEvent();
}

/// حدث تحديث قائمة الطلاب
class RefreshClassStudentsEvent extends ClassStudentsEvent {
  final String levelId;
  final String classId;

  const RefreshClassStudentsEvent({
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object?> get props => [levelId, classId];
}
