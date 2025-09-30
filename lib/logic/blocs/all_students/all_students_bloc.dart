import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/all_students_repository.dart';
import 'all_students_event.dart';
import 'all_students_state.dart';

class AllStudentsBloc extends Bloc<AllStudentsEvent, AllStudentsState> {
  final AllStudentsRepository repository;

  AllStudentsBloc(this.repository) : super(const AllStudentsInitial()) {
    on<LoadAllStudentsEvent>(_onLoadAllStudents);
    on<SearchAllStudentsEvent>(_onSearchAllStudents);
    on<RefreshAllStudentsEvent>(_onRefreshAllStudents);
  }

  /// معالج حدث جلب جميع الطلاب
  Future<void> _onLoadAllStudents(
    LoadAllStudentsEvent event,
    Emitter<AllStudentsState> emit,
  ) async {
    try {
      emit(const AllStudentsLoading());

      final response = await repository.getAllStudents();

      if (response.success) {
        if (response.students.isEmpty) {
          emit(AllStudentsEmpty(message: response.message));
        } else {
          emit(AllStudentsLoaded(
            students: response.students,
            message: response.message,
          ));
        }
      } else {
        emit(AllStudentsError(response.message));
      }
    } catch (e) {
      emit(AllStudentsError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  /// معالج حدث البحث عن طلاب
  Future<void> _onSearchAllStudents(
    SearchAllStudentsEvent event,
    Emitter<AllStudentsState> emit,
  ) async {
    try {
      emit(const AllStudentsLoading());

      final response = await repository.searchStudents(event.query);

      if (response.success) {
        if (response.students.isEmpty) {
          emit(AllStudentsEmpty(
            message: event.query.isEmpty
                ? 'لا يوجد طلاب'
                : 'لم يتم العثور على طلاب بهذا الاسم',
          ));
        } else {
          emit(AllStudentsLoaded(
            students: response.students,
            message: response.message,
          ));
        }
      } else {
        emit(AllStudentsError(response.message));
      }
    } catch (e) {
      emit(AllStudentsError('حدث خطأ أثناء البحث: ${e.toString()}'));
    }
  }

  /// معالج حدث تحديث قائمة الطلاب
  Future<void> _onRefreshAllStudents(
    RefreshAllStudentsEvent event,
    Emitter<AllStudentsState> emit,
  ) async {
    // نفس منطق LoadAllStudentsEvent
    add(const LoadAllStudentsEvent());
  }
}
