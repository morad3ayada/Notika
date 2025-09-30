import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/exam_questions_repository.dart';
import 'exam_questions_event.dart';
import 'exam_questions_state.dart';

class ExamQuestionsBloc extends Bloc<ExamQuestionsEvent, ExamQuestionsState> {
  final ExamQuestionsRepository _repository;

  ExamQuestionsBloc(this._repository) : super(const ExamQuestionsInitial()) {
    on<SubmitExamQuestionsEvent>(_onSubmitExamQuestions);
    on<ResetExamQuestionsEvent>(_onResetExamQuestions);
  }

  Future<void> _onSubmitExamQuestions(
    SubmitExamQuestionsEvent event,
    Emitter<ExamQuestionsState> emit,
  ) async {
    try {
      emit(const ExamQuestionsLoading());

      final response = await _repository.uploadExamQuestions(
        examTableId: event.examTableId,
        questions: event.questions,
        examFile: event.examFile,
      );

      if (response.isSuccess) {
        emit(ExamQuestionsSuccess(
          message: response.message,
          data: response.data,
        ));
      } else {
        emit(ExamQuestionsError(response.message));
      }
    } catch (e) {
      emit(ExamQuestionsError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  void _onResetExamQuestions(
    ResetExamQuestionsEvent event,
    Emitter<ExamQuestionsState> emit,
  ) {
    emit(const ExamQuestionsInitial());
  }
}
