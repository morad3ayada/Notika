import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/exam_schedule_repository.dart';
import 'exam_schedule_event.dart';
import 'exam_schedule_state.dart';

/// BLoC لإدارة حالة جدول الامتحانات
class ExamScheduleBloc extends Bloc<ExamScheduleEvent, ExamScheduleState> {
  final ExamScheduleRepository _repository;

  ExamScheduleBloc(this._repository) : super(const ExamScheduleInitial()) {
    on<FetchClassExamSchedulesEvent>(_onFetchClassExamSchedules);
    on<FetchSubjectExamSchedulesEvent>(_onFetchSubjectExamSchedules);
    on<SearchExamSchedulesEvent>(_onSearchExamSchedules);
    on<ResetExamScheduleEvent>(_onResetExamSchedule);
    on<RefreshExamScheduleEvent>(_onRefreshExamSchedule);
  }

  /// معالج حدث جلب جدول الامتحانات للمرحلة والشعبة
  Future<void> _onFetchClassExamSchedules(
    FetchClassExamSchedulesEvent event,
    Emitter<ExamScheduleState> emit,
  ) async {
    try {
      emit(const ExamScheduleLoading());

      print('🔄 BLoC: جلب جدول الامتحانات للمرحلة ${event.levelId} والشعبة ${event.classId}');

      final response = await _repository.getClassExamSchedules(
        levelId: event.levelId,
        classId: event.classId,
      );

      if (response.success) {
        if (response.schedules.isEmpty) {
          emit(ExamScheduleEmpty(
            message: response.message,
            levelId: event.levelId,
            classId: event.classId,
          ));
        } else {
          emit(ExamScheduleLoaded(
            schedules: response.schedules,
            message: response.message,
            totalCount: response.totalCount,
            levelId: event.levelId,
            classId: event.classId,
          ));
        }
      } else {
        emit(ExamScheduleError(
          message: response.message,
          levelId: event.levelId,
          classId: event.classId,
        ));
      }
    } catch (e) {
      print('❌ BLoC خطأ في جلب جدول الامتحانات: $e');
      emit(ExamScheduleError(
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
        levelId: event.levelId,
        classId: event.classId,
      ));
    }
  }

  /// معالج حدث جلب جدول امتحانات مادة معينة
  Future<void> _onFetchSubjectExamSchedules(
    FetchSubjectExamSchedulesEvent event,
    Emitter<ExamScheduleState> emit,
  ) async {
    try {
      emit(const ExamScheduleLoading());

      print('🔄 BLoC: جلب جدول امتحانات المادة ${event.subjectId}');

      final response = await _repository.getSubjectExamSchedules(
        levelId: event.levelId,
        classId: event.classId,
        subjectId: event.subjectId,
      );

      if (response.success) {
        if (response.schedules.isEmpty) {
          emit(ExamScheduleEmpty(
            message: 'لا توجد امتحانات مجدولة لهذه المادة',
            levelId: event.levelId,
            classId: event.classId,
          ));
        } else {
          emit(ExamScheduleLoaded(
            schedules: response.schedules,
            message: response.message,
            totalCount: response.totalCount,
            levelId: event.levelId,
            classId: event.classId,
          ));
        }
      } else {
        emit(ExamScheduleError(
          message: response.message,
          levelId: event.levelId,
          classId: event.classId,
        ));
      }
    } catch (e) {
      print('❌ BLoC خطأ في جلب امتحانات المادة: $e');
      emit(ExamScheduleError(
        message: 'حدث خطأ في جلب امتحانات المادة',
        levelId: event.levelId,
        classId: event.classId,
      ));
    }
  }

  /// معالج حدث البحث في جدول الامتحانات
  Future<void> _onSearchExamSchedules(
    SearchExamSchedulesEvent event,
    Emitter<ExamScheduleState> emit,
  ) async {
    try {
      emit(const ExamScheduleSearching());

      print('🔍 BLoC: البحث في جدول الامتحانات');

      final response = await _repository.searchExamSchedules(
        levelId: event.levelId,
        classId: event.classId,
        subjectName: event.subjectName,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (response.success) {
        final query = event.subjectName ?? 'البحث المتقدم';
        emit(ExamScheduleSearchResults(
          results: response.schedules,
          query: query,
          totalResults: response.totalCount,
        ));
      } else {
        emit(ExamScheduleError(
          message: response.message,
          levelId: event.levelId,
          classId: event.classId,
        ));
      }
    } catch (e) {
      print('❌ BLoC خطأ في البحث: $e');
      emit(ExamScheduleError(
        message: 'حدث خطأ أثناء البحث',
        levelId: event.levelId,
        classId: event.classId,
      ));
    }
  }

  /// معالج حدث إعادة تعيين الحالة
  Future<void> _onResetExamSchedule(
    ResetExamScheduleEvent event,
    Emitter<ExamScheduleState> emit,
  ) async {
    emit(const ExamScheduleInitial());
  }

  /// معالج حدث تحديث البيانات
  Future<void> _onRefreshExamSchedule(
    RefreshExamScheduleEvent event,
    Emitter<ExamScheduleState> emit,
  ) async {
    // إعادة جلب البيانات
    add(FetchClassExamSchedulesEvent(
      levelId: event.levelId,
      classId: event.classId,
    ));
  }
}
