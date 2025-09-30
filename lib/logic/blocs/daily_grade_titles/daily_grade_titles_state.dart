import 'package:equatable/equatable.dart';
import '../../../data/models/daily_grade_titles_model.dart';

/// الحالات الخاصة بعناوين الدرجات اليومية
abstract class DailyGradeTitlesState extends Equatable {
  const DailyGradeTitlesState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class DailyGradeTitlesInitial extends DailyGradeTitlesState {
  const DailyGradeTitlesInitial();
}

/// حالة التحميل
class DailyGradeTitlesLoading extends DailyGradeTitlesState {
  const DailyGradeTitlesLoading();
}

/// حالة التحديث (عند إعادة جلب البيانات)
class DailyGradeTitlesRefreshing extends DailyGradeTitlesState {
  final List<DailyGradeTitle> currentTitles;

  const DailyGradeTitlesRefreshing({
    required this.currentTitles,
  });

  @override
  List<Object?> get props => [currentTitles];
}

/// حالة نجاح جلب عناوين الدرجات
class DailyGradeTitlesLoaded extends DailyGradeTitlesState {
  final List<DailyGradeTitle> titles;
  final String message;
  final int totalCount;
  final bool isSearchResult;

  const DailyGradeTitlesLoaded({
    required this.titles,
    required this.message,
    this.totalCount = 0,
    this.isSearchResult = false,
  });

  /// الحصول على قائمة أسماء العناوين فقط
  List<String> get titleNames {
    return titles.map((title) => title.displayTitle).toList();
  }

  @override
  List<Object?> get props => [titles, message, totalCount, isSearchResult];
}

/// حالة عدم وجود عناوين درجات
class DailyGradeTitlesEmpty extends DailyGradeTitlesState {
  final String message;
  final bool isSearchResult;

  const DailyGradeTitlesEmpty({
    required this.message,
    this.isSearchResult = false,
  });

  @override
  List<Object?> get props => [message, isSearchResult];
}

/// حالة الخطأ
class DailyGradeTitlesError extends DailyGradeTitlesState {
  final String message;

  const DailyGradeTitlesError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
