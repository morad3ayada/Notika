import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/daily_grade_titles_repository.dart';
import 'daily_grade_titles_event.dart';
import 'daily_grade_titles_state.dart';

/// BLoC للتعامل مع عناوين الدرجات اليومية
class DailyGradeTitlesBloc extends Bloc<DailyGradeTitlesEvent, DailyGradeTitlesState> {
  final DailyGradeTitlesRepository _repository;

  DailyGradeTitlesBloc(this._repository) : super(const DailyGradeTitlesInitial()) {
    on<LoadDailyGradeTitlesEvent>(_onLoadDailyGradeTitles);
    on<SearchDailyGradeTitlesEvent>(_onSearchDailyGradeTitles);
    on<RefreshDailyGradeTitlesEvent>(_onRefreshDailyGradeTitles);
    on<ResetDailyGradeTitlesEvent>(_onResetDailyGradeTitles);
  }

  /// معالجة حدث جلب عناوين الدرجات اليومية
  Future<void> _onLoadDailyGradeTitles(
    LoadDailyGradeTitlesEvent event,
    Emitter<DailyGradeTitlesState> emit,
  ) async {
    try {
      emit(const DailyGradeTitlesLoading());
      
      print('🔄 بدء جلب عناوين الدرجات اليومية...');
      print('📊 LevelSubjectId: ${event.levelSubjectId}');
      print('📊 LevelId: ${event.levelId}');
      print('📊 ClassId: ${event.classId}');
      
      final response = await _repository.getDailyGradeTitles(
        levelSubjectId: event.levelSubjectId,
        levelId: event.levelId,
        classId: event.classId,
      );
      
      if (response.success) {
        if (response.titles.isEmpty) {
          print('📭 لا توجد عناوين درجات لهذا الفصل');
          emit(const DailyGradeTitlesEmpty(
            message: 'لا توجد عناوين درجات محددة لهذا الفصل',
          ));
        } else {
          print('✅ تم جلب ${response.titles.length} عنوان درجة بنجاح');
          print('📝 العناوين: ${response.titles.map((t) => t.displayTitle).join(', ')}');
          emit(DailyGradeTitlesLoaded(
            titles: response.titles,
            message: response.message,
            totalCount: response.totalCount,
          ));
        }
      } else {
        print('❌ فشل جلب عناوين الدرجات: ${response.message}');
        emit(DailyGradeTitlesError(message: response.message));
      }
    } catch (e) {
      print('❌ خطأ في BLoC أثناء جلب عناوين الدرجات: $e');
      emit(DailyGradeTitlesError(
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      ));
    }
  }

  /// معالجة حدث البحث عن عناوين الدرجات
  Future<void> _onSearchDailyGradeTitles(
    SearchDailyGradeTitlesEvent event,
    Emitter<DailyGradeTitlesState> emit,
  ) async {
    try {
      emit(const DailyGradeTitlesLoading());
      
      print('🔍 بدء البحث عن عناوين الدرجات...');
      print('🔍 البحث عن: ${event.searchQuery}');
      
      final response = await _repository.searchGradeTitles(
        levelSubjectId: event.levelSubjectId,
        levelId: event.levelId,
        classId: event.classId,
        searchQuery: event.searchQuery,
      );
      
      if (response.success) {
        if (response.titles.isEmpty) {
          print('🔍 لم يتم العثور على عناوين درجات مطابقة للبحث');
          emit(const DailyGradeTitlesEmpty(
            message: 'لم يتم العثور على عناوين درجات مطابقة للبحث',
            isSearchResult: true,
          ));
        } else {
          print('✅ تم العثور على ${response.titles.length} عنوان درجة');
          emit(DailyGradeTitlesLoaded(
            titles: response.titles,
            message: response.message,
            totalCount: response.totalCount,
            isSearchResult: true,
          ));
        }
      } else {
        print('❌ فشل البحث عن عناوين الدرجات: ${response.message}');
        emit(DailyGradeTitlesError(message: response.message));
      }
    } catch (e) {
      print('❌ خطأ في BLoC أثناء البحث عن عناوين الدرجات: $e');
      emit(DailyGradeTitlesError(
        message: 'حدث خطأ أثناء البحث: ${e.toString()}',
      ));
    }
  }

  /// معالجة حدث تحديث عناوين الدرجات
  Future<void> _onRefreshDailyGradeTitles(
    RefreshDailyGradeTitlesEvent event,
    Emitter<DailyGradeTitlesState> emit,
  ) async {
    try {
      // إذا كانت هناك عناوين محملة، أظهر حالة التحديث
      if (state is DailyGradeTitlesLoaded) {
        final currentState = state as DailyGradeTitlesLoaded;
        emit(DailyGradeTitlesRefreshing(currentTitles: currentState.titles));
      } else {
        emit(const DailyGradeTitlesLoading());
      }
      
      print('🔄 تحديث عناوين الدرجات...');
      
      final response = await _repository.getDailyGradeTitles(
        levelSubjectId: event.levelSubjectId,
        levelId: event.levelId,
        classId: event.classId,
      );
      
      if (response.success) {
        if (response.titles.isEmpty) {
          emit(const DailyGradeTitlesEmpty(
            message: 'لا توجد عناوين درجات محددة لهذا الفصل',
          ));
        } else {
          print('✅ تم تحديث عناوين الدرجات: ${response.titles.length} عنوان');
          emit(DailyGradeTitlesLoaded(
            titles: response.titles,
            message: 'تم تحديث عناوين الدرجات',
            totalCount: response.totalCount,
          ));
        }
      } else {
        emit(DailyGradeTitlesError(message: response.message));
      }
    } catch (e) {
      print('❌ خطأ في BLoC أثناء تحديث عناوين الدرجات: $e');
      emit(DailyGradeTitlesError(
        message: 'حدث خطأ أثناء التحديث: ${e.toString()}',
      ));
    }
  }

  /// معالجة حدث إعادة تعيين الحالة
  void _onResetDailyGradeTitles(
    ResetDailyGradeTitlesEvent event,
    Emitter<DailyGradeTitlesState> emit,
  ) {
    emit(const DailyGradeTitlesInitial());
  }
}
