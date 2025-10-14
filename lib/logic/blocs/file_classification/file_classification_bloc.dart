import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/file_classification_repository.dart';
import 'file_classification_event.dart';
import 'file_classification_state.dart';

class FileClassificationBloc extends Bloc<FileClassificationEvent, FileClassificationState> {
  final FileClassificationRepository _repository;

  FileClassificationBloc(this._repository) : super(const FileClassificationInitial()) {
    on<AddFileClassificationEvent>(_onAddFileClassification);
    on<LoadFileClassificationsEvent>(_onLoadFileClassifications);
    on<ResetFileClassificationEvent>(_onResetFileClassification);
  }

  Future<void> _onAddFileClassification(
    AddFileClassificationEvent event,
    Emitter<FileClassificationState> emit,
  ) async {
    try {
      emit(const AddFileClassificationLoading());

      final fileClassification = await _repository.addFileClassification(
        levelSubjectId: event.levelSubjectId,
        levelId: event.levelId,
        classId: event.classId,
        name: event.name,
      );

      emit(AddFileClassificationSuccess(
        fileClassification: fileClassification,
        message: 'تم إضافة "${event.name}" بنجاح',
      ));
    } catch (e) {
      
      String errorMessage = 'فشل في إضافة الفصل/الوحدة';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      emit(AddFileClassificationFailure(message: errorMessage));
    }
  }

  Future<void> _onLoadFileClassifications(
    LoadFileClassificationsEvent event,
    Emitter<FileClassificationState> emit,
  ) async {
    try {
      print('🔷 FileClassificationBloc: بدء جلب FileClassifications');
      print('   - LevelSubjectId: ${event.levelSubjectId}');
      print('   - LevelId: ${event.levelId}');
      print('   - ClassId: ${event.classId}');
      
      emit(const FileClassificationLoading());

      final fileClassifications = await _repository.getFileClassifications(
        levelSubjectId: event.levelSubjectId,
        levelId: event.levelId,
        classId: event.classId,
      );

      print('🔷 FileClassificationBloc: تم الحصول على ${fileClassifications.length} عنصر');
      
      emit(FileClassificationsLoaded(fileClassifications: fileClassifications));
      
      print('✅ FileClassificationBloc: تم emit حالة FileClassificationsLoaded');
    } catch (e) {
      print('❌ FileClassificationBloc: خطأ في جلب FileClassifications: $e');
      
      String errorMessage = 'فشل في جلب قائمة الفصول/الوحدات';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      emit(FileClassificationError(message: errorMessage));
    }
  }

  void _onResetFileClassification(
    ResetFileClassificationEvent event,
    Emitter<FileClassificationState> emit,
  ) {
    emit(const FileClassificationInitial());
  }
}
