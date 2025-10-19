import 'package:flutter_bloc/flutter_bloc.dart';
import 'term_grades_event.dart';
import 'term_grades_state.dart';
import '../../../data/repositories/term_grades_repository.dart';

/// Bloc لإدارة الدرجات الفصلية
class TermGradesBloc extends Bloc<TermGradesEvent, TermGradesState> {
  final TermGradesRepository _repository;

  TermGradesBloc(this._repository) : super(const TermGradesInitial()) {
    on<LoadTermGradesEvent>(_onLoadTermGrades);
  }

  Future<void> _onLoadTermGrades(
    LoadTermGradesEvent event,
    Emitter<TermGradesState> emit,
  ) async {
    print('🔄 Bloc: بدء جلب الدرجات الفصلية...');
    emit(const TermGradesLoading());

    try {
      final response = await _repository.getClassStudentsTermGrades(
        subjectId: event.subjectId,
        levelId: event.levelId,
        classId: event.classId,
      );

      if (response.success) {
        if (response.studentGrades.isEmpty) {
          print('📭 Bloc: لا توجد درجات');
          emit(const TermGradesEmpty());
        } else {
          print('✅ Bloc: تم جلب ${response.studentGrades.length} طالب');
          emit(TermGradesLoaded(response.studentGrades));
        }
      } else {
        print('❌ Bloc: خطأ - ${response.message}');
        emit(TermGradesError(response.message ?? 'حدث خطأ غير معروف'));
      }
    } catch (e) {
      print('❌ Bloc: استثناء - $e');
      emit(TermGradesError('حدث خطأ أثناء جلب الدرجات: ${e.toString()}'));
    }
  }
}
