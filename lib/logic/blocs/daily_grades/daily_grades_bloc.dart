import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'daily_grades_event.dart';
import 'daily_grades_state.dart';
import '../../../data/repositories/daily_grades_repository.dart';

class DailyGradesBloc extends Bloc<DailyGradesEvent, DailyGradesState> {
  final DailyGradesRepository repository;

  DailyGradesBloc(this.repository) : super(const DailyGradesInitial()) {
    on<LoadClassStudentsGradesEvent>(_onLoadClassStudentsGrades);
    on<ResetDailyGradesEvent>(_onReset);
  }

  Future<void> _onLoadClassStudentsGrades(
    LoadClassStudentsGradesEvent event,
    Emitter<DailyGradesState> emit,
  ) async {
    try {
      emit(const DailyGradesLoading());

      debugPrint('🔄 جاري جلب درجات طلاب الفصل من السيرفر...');
      debugPrint('📚 subjectId: ${event.subjectId}');
      debugPrint('🎓 levelId: ${event.levelId}');
      debugPrint('🏫 classId: ${event.classId}');
      debugPrint('📅 date: ${event.date}');

      final response = await repository.getClassStudentsGrades(
        subjectId: event.subjectId,
        levelId: event.levelId,
        classId: event.classId,
        date: event.date,
      );

      if (!response.success) {
        debugPrint('❌ فشل جلب الدرجات: ${response.message}');
        emit(DailyGradesError(response.message ?? 'فشل جلب الدرجات'));
        return;
      }

      if (response.studentGrades.isEmpty) {
        debugPrint('📭 لا توجد درجات مسجلة');
        emit(const DailyGradesEmpty(message: 'لا توجد درجات مسجلة لهذا التاريخ'));
        return;
      }

      debugPrint('✅ تم جلب درجات ${response.studentGrades.length} طالب بنجاح');
      emit(DailyGradesLoaded(studentGrades: response.studentGrades));
    } catch (e) {
      debugPrint('❌ خطأ في جلب الدرجات: $e');
      emit(DailyGradesError('حدث خطأ أثناء جلب الدرجات: ${e.toString()}'));
    }
  }

  Future<void> _onReset(
    ResetDailyGradesEvent event,
    Emitter<DailyGradesState> emit,
  ) async {
    emit(const DailyGradesInitial());
  }
}
