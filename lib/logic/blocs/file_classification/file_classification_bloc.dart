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

      print('FileClassificationBloc: Adding file classification with data:');
      print('- levelSubjectId: ${event.levelSubjectId}');
      print('- levelId: ${event.levelId}');
      print('- classId: ${event.classId}');
      print('- name: ${event.name}');

      final fileClassification = await _repository.addFileClassification(
        levelSubjectId: event.levelSubjectId,
        levelId: event.levelId,
        classId: event.classId,
        name: event.name,
      );

      print('FileClassificationBloc: Successfully added file classification: ${fileClassification.toJson()}');

      emit(AddFileClassificationSuccess(
        fileClassification: fileClassification,
        message: 'تم إضافة "${event.name}" بنجاح',
      ));
    } catch (e) {
      print('FileClassificationBloc: Error adding file classification: $e');
      
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
      emit(const FileClassificationLoading());

      print('FileClassificationBloc: Loading file classifications with data:');
      print('- levelSubjectId: ${event.levelSubjectId}');
      print('- levelId: ${event.levelId}');
      print('- classId: ${event.classId}');

      final fileClassifications = await _repository.getFileClassifications(
        levelSubjectId: event.levelSubjectId,
        levelId: event.levelId,
        classId: event.classId,
      );

      print('FileClassificationBloc: Successfully loaded ${fileClassifications.length} file classifications');

      emit(FileClassificationsLoaded(fileClassifications: fileClassifications));
    } catch (e) {
      print('FileClassificationBloc: Error loading file classifications: $e');
      
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
