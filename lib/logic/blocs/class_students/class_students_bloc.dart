import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/class_students_repository.dart';
import 'class_students_event.dart';
import 'class_students_state.dart';

/// BLoC للتعامل مع طلاب الفصل
class ClassStudentsBloc extends Bloc<ClassStudentsEvent, ClassStudentsState> {
  final ClassStudentsRepository _repository;

  ClassStudentsBloc(this._repository) : super(const ClassStudentsInitial()) {
    on<LoadClassStudentsEvent>(_onLoadClassStudents);
    on<SearchClassStudentsEvent>(_onSearchClassStudents);
    on<RefreshClassStudentsEvent>(_onRefreshClassStudents);
    on<ResetClassStudentsEvent>(_onResetClassStudents);
  }

  /// معالجة حدث جلب طلاب الفصل
  Future<void> _onLoadClassStudents(
    LoadClassStudentsEvent event,
    Emitter<ClassStudentsState> emit,
  ) async {
    try {
      emit(const ClassStudentsLoading());
      
      print('🔄 بدء جلب طلاب الفصل...');
      print('📚 LevelId: ${event.levelId}');
      print('📚 ClassId: ${event.classId}');
      
      final response = await _repository.getClassStudents(
        levelId: event.levelId,
        classId: event.classId,
      );
      
      if (response.success) {
        if (response.students.isEmpty) {
          print('📭 لا يوجد طلاب في هذا الفصل');
          emit(const ClassStudentsEmpty(
            message: 'لا يوجد طلاب مسجلين في هذا الفصل',
          ));
        } else {
          print('✅ تم جلب ${response.students.length} طالب بنجاح');
          emit(ClassStudentsLoaded(
            students: response.students,
            message: response.message,
            totalCount: response.totalCount,
          ));
        }
      } else {
        print('❌ فشل جلب طلاب الفصل: ${response.message}');
        emit(ClassStudentsError(message: response.message));
      }
    } catch (e) {
      print('❌ خطأ في BLoC أثناء جلب طلاب الفصل: $e');
      emit(ClassStudentsError(
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      ));
    }
  }

  /// معالجة حدث البحث عن طلاب
  Future<void> _onSearchClassStudents(
    SearchClassStudentsEvent event,
    Emitter<ClassStudentsState> emit,
  ) async {
    try {
      emit(const ClassStudentsLoading());
      
      print('🔍 بدء البحث عن طلاب...');
      print('🔍 البحث عن: ${event.searchQuery}');
      
      final response = await _repository.searchStudents(
        levelId: event.levelId,
        classId: event.classId,
        searchQuery: event.searchQuery,
      );
      
      if (response.success) {
        if (response.students.isEmpty) {
          print('🔍 لم يتم العثور على طلاب مطابقين للبحث');
          emit(const ClassStudentsEmpty(
            message: 'لم يتم العثور على طلاب مطابقين للبحث',
            isSearchResult: true,
          ));
        } else {
          print('✅ تم العثور على ${response.students.length} طالب');
          emit(ClassStudentsLoaded(
            students: response.students,
            message: response.message,
            totalCount: response.totalCount,
            isSearchResult: true,
          ));
        }
      } else {
        print('❌ فشل البحث عن الطلاب: ${response.message}');
        emit(ClassStudentsError(message: response.message));
      }
    } catch (e) {
      print('❌ خطأ في BLoC أثناء البحث عن الطلاب: $e');
      emit(ClassStudentsError(
        message: 'حدث خطأ أثناء البحث: ${e.toString()}',
      ));
    }
  }

  /// معالجة حدث تحديث طلاب الفصل
  Future<void> _onRefreshClassStudents(
    RefreshClassStudentsEvent event,
    Emitter<ClassStudentsState> emit,
  ) async {
    try {
      // إذا كان هناك طلاب محملين، أظهر حالة التحديث
      if (state is ClassStudentsLoaded) {
        final currentState = state as ClassStudentsLoaded;
        emit(ClassStudentsRefreshing(currentStudents: currentState.students));
      } else {
        emit(const ClassStudentsLoading());
      }
      
      print('🔄 تحديث قائمة طلاب الفصل...');
      
      final response = await _repository.getClassStudents(
        levelId: event.levelId,
        classId: event.classId,
      );
      
      if (response.success) {
        if (response.students.isEmpty) {
          emit(const ClassStudentsEmpty(
            message: 'لا يوجد طلاب مسجلين في هذا الفصل',
          ));
        } else {
          print('✅ تم تحديث قائمة الطلاب: ${response.students.length} طالب');
          emit(ClassStudentsLoaded(
            students: response.students,
            message: 'تم تحديث قائمة الطلاب',
            totalCount: response.totalCount,
          ));
        }
      } else {
        emit(ClassStudentsError(message: response.message));
      }
    } catch (e) {
      print('❌ خطأ في BLoC أثناء تحديث طلاب الفصل: $e');
      emit(ClassStudentsError(
        message: 'حدث خطأ أثناء التحديث: ${e.toString()}',
      ));
    }
  }

  /// معالجة حدث إعادة تعيين الحالة
  void _onResetClassStudents(
    ResetClassStudentsEvent event,
    Emitter<ClassStudentsState> emit,
  ) {
    emit(const ClassStudentsInitial());
  }
}
