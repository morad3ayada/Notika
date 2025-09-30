import 'package:equatable/equatable.dart';
import '../../../data/models/exam_schedule_model.dart';

/// الحالات الخاصة بجدول الامتحانات
abstract class ExamScheduleState extends Equatable {
  const ExamScheduleState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class ExamScheduleInitial extends ExamScheduleState {
  const ExamScheduleInitial();
}

/// حالة جاري التحميل
class ExamScheduleLoading extends ExamScheduleState {
  const ExamScheduleLoading();
}

/// حالة نجاح جلب البيانات
class ExamScheduleLoaded extends ExamScheduleState {
  final List<ExamScheduleModel> schedules;
  final String message;
  final int totalCount;
  final String? levelId;
  final String? classId;

  const ExamScheduleLoaded({
    required this.schedules,
    required this.message,
    this.totalCount = 0,
    this.levelId,
    this.classId,
  });

  /// التحقق من وجود امتحانات
  bool get hasSchedules => schedules.isNotEmpty;

  /// الحصول على امتحانات اليوم
  List<ExamScheduleModel> get todaySchedules {
    final today = DateTime.now();
    return schedules.where((schedule) {
      if (schedule.examDate == null) return false;
      final examDate = schedule.examDate!;
      return examDate.year == today.year &&
             examDate.month == today.month &&
             examDate.day == today.day;
    }).toList();
  }

  /// الحصول على امتحانات الأسبوع القادم
  List<ExamScheduleModel> get upcomingSchedules {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    return schedules.where((schedule) {
      if (schedule.examDate == null) return false;
      final examDate = schedule.examDate!;
      return examDate.isAfter(now) && examDate.isBefore(nextWeek);
    }).toList();
  }

  /// الحصول على امتحانات مادة معينة
  List<ExamScheduleModel> getSchedulesBySubject(String subjectName) {
    return schedules.where((schedule) {
      return schedule.subjectName?.toLowerCase().contains(subjectName.toLowerCase()) ?? false;
    }).toList();
  }

  /// ترتيب الامتحانات حسب التاريخ
  List<ExamScheduleModel> get sortedSchedules {
    final sortedList = List<ExamScheduleModel>.from(schedules);
    sortedList.sort((a, b) {
      if (a.examDate == null && b.examDate == null) return 0;
      if (a.examDate == null) return 1;
      if (b.examDate == null) return -1;
      return a.examDate!.compareTo(b.examDate!);
    });
    return sortedList;
  }

  @override
  List<Object?> get props => [schedules, message, totalCount, levelId, classId];
}

/// حالة عدم وجود بيانات
class ExamScheduleEmpty extends ExamScheduleState {
  final String message;
  final String? levelId;
  final String? classId;

  const ExamScheduleEmpty({
    required this.message,
    this.levelId,
    this.classId,
  });

  @override
  List<Object?> get props => [message, levelId, classId];
}

/// حالة فشل جلب البيانات
class ExamScheduleError extends ExamScheduleState {
  final String message;
  final String? levelId;
  final String? classId;

  const ExamScheduleError({
    required this.message,
    this.levelId,
    this.classId,
  });

  @override
  List<Object?> get props => [message, levelId, classId];
}

/// حالة البحث
class ExamScheduleSearching extends ExamScheduleState {
  const ExamScheduleSearching();
}

/// حالة نتائج البحث
class ExamScheduleSearchResults extends ExamScheduleState {
  final List<ExamScheduleModel> results;
  final String query;
  final int totalResults;

  const ExamScheduleSearchResults({
    required this.results,
    required this.query,
    this.totalResults = 0,
  });

  bool get hasResults => results.isNotEmpty;

  @override
  List<Object?> get props => [results, query, totalResults];
}
