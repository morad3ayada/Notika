import 'package:equatable/equatable.dart';

/// الأحداث الخاصة بعناوين الدرجات اليومية
abstract class DailyGradeTitlesEvent extends Equatable {
  const DailyGradeTitlesEvent();

  @override
  List<Object?> get props => [];
}

/// حدث جلب عناوين الدرجات اليومية
class LoadDailyGradeTitlesEvent extends DailyGradeTitlesEvent {
  final String levelSubjectId;
  final String levelId;
  final String classId;

  const LoadDailyGradeTitlesEvent({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object?> get props => [levelSubjectId, levelId, classId];
}

/// حدث البحث عن عناوين الدرجات
class SearchDailyGradeTitlesEvent extends DailyGradeTitlesEvent {
  final String levelSubjectId;
  final String levelId;
  final String classId;
  final String searchQuery;

  const SearchDailyGradeTitlesEvent({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    required this.searchQuery,
  });

  @override
  List<Object?> get props => [levelSubjectId, levelId, classId, searchQuery];
}

/// حدث إعادة تعيين حالة عناوين الدرجات
class ResetDailyGradeTitlesEvent extends DailyGradeTitlesEvent {
  const ResetDailyGradeTitlesEvent();
}

/// حدث تحديث عناوين الدرجات
class RefreshDailyGradeTitlesEvent extends DailyGradeTitlesEvent {
  final String levelSubjectId;
  final String levelId;
  final String classId;

  const RefreshDailyGradeTitlesEvent({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object?> get props => [levelSubjectId, levelId, classId];
}
