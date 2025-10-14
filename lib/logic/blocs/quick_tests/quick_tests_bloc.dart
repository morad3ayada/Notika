import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/quick_tests_repository.dart';
import '../../../data/models/quick_tests_model.dart';
import '../../../utils/teacher_class_matcher.dart';
import '../../../data/models/profile_models.dart';
import 'quick_tests_event.dart';
import 'quick_tests_state.dart';

class QuickTestsBloc extends Bloc<QuickTestsEvent, QuickTestsState> {
  final QuickTestsRepository _repository;

  QuickTestsBloc(this._repository) : super(const QuickTestsInitial()) {
    on<AddQuickTestEvent>(_onAddQuickTest);
    on<LoadQuickTestsEvent>(_onLoadQuickTests);
    on<RefreshQuickTestsEvent>(_onRefreshQuickTests);
    on<ResetQuickTestsEvent>(_onResetQuickTests);
    on<ValidateQuickTestEvent>(_onValidateQuickTest);
  }

  Future<void> _onAddQuickTest(
    AddQuickTestEvent event,
    Emitter<QuickTestsState> emit,
  ) async {
    try {
      emit(const QuickTestsLoading());

      // Validate the request data
      final validationResult = _validateQuickTestRequest(event.request);
      if (validationResult != null) {
        emit(QuickTestsFailure(validationResult));
        return;
      }

      final quickTest = await _repository.addQuickTest(event.request);
      
      emit(QuickTestsSuccess(
        quickTest: quickTest,
        message: 'تم إضافة الاختبار "${quickTest.title}" بنجاح',
      ));
    } catch (e) {
      String errorMessage = 'فشل في إضافة الاختبار';
      
      if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.contains('Exception: ')) {
          errorMessage = exceptionMessage.replaceFirst('Exception: ', '');
        } else {
          errorMessage = exceptionMessage;
        }
      } else {
        errorMessage = 'حدث خطأ غير متوقع: $e';
      }
      
      emit(QuickTestsFailure(errorMessage));
    }
  }

  Future<void> _onLoadQuickTests(
    LoadQuickTestsEvent event,
    Emitter<QuickTestsState> emit,
  ) async {
    try {
      emit(const QuickTestsLoading());

      final quickTests = await _repository.getQuickTests();
      
      emit(QuickTestsLoaded(quickTests));
    } catch (e) {
      String errorMessage = 'فشل في تحميل الاختبارات';
      
      if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.contains('Exception: ')) {
          errorMessage = exceptionMessage.replaceFirst('Exception: ', '');
        } else {
          errorMessage = exceptionMessage;
        }
      }
      
      emit(QuickTestsFailure(errorMessage));
    }
  }

  Future<void> _onRefreshQuickTests(
    RefreshQuickTestsEvent event,
    Emitter<QuickTestsState> emit,
  ) async {
    // Same as load but without showing loading state if already loaded
    try {
      final quickTests = await _repository.getQuickTests();
      
      emit(QuickTestsLoaded(quickTests));
    } catch (e) {
      String errorMessage = 'فشل في تحديث الاختبارات';
      
      if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.contains('Exception: ')) {
          errorMessage = exceptionMessage.replaceFirst('Exception: ', '');
        } else {
          errorMessage = exceptionMessage;
        }
      }
      
      emit(QuickTestsFailure(errorMessage));
    }
  }

  void _onResetQuickTests(
    ResetQuickTestsEvent event,
    Emitter<QuickTestsState> emit,
  ) {
    emit(const QuickTestsInitial());
  }

  void _onValidateQuickTest(
    ValidateQuickTestEvent event,
    Emitter<QuickTestsState> emit,
  ) {
    emit(const QuickTestsValidating());

    final validationResult = _validateQuickTestRequest(event.request);
    if (validationResult != null) {
      emit(QuickTestsValidationFailure(validationResult));
    } else {
      emit(const QuickTestsValidationSuccess());
    }
  }

  String? _validateQuickTestRequest(CreateQuickTestRequest request) {
    // Validate required fields
    if (request.title.trim().isEmpty) {
      return 'يرجى إدخال عنوان الاختبار';
    }

    if (request.levelSubjectId.trim().isEmpty) {
      return 'يرجى اختيار المادة';
    }

    if (request.levelId.trim().isEmpty) {
      return 'يرجى اختيار المرحلة';
    }

    if (request.classId.trim().isEmpty) {
      return 'يرجى اختيار الشعبة';
    }

    if (request.durationMinutes <= 0) {
      return 'يرجى تحديد مدة الاختبار بالدقائق';
    }

    if (request.maxGrade <= 0) {
      return 'يرجى تحديد الدرجة القصوى للاختبار';
    }

    // Validate deadline
    if (request.deadline.isBefore(DateTime.now())) {
      return 'يجب أن يكون موعد الاختبار في المستقبل';
    }

    // Validate JSON format
    try {
      final questions = jsonDecode(request.questionsJson);
      if (questions is! List || questions.isEmpty) {
        return 'يرجى إضافة أسئلة للاختبار';
      }

      final answers = jsonDecode(request.answersJson);
      if (answers is! List || answers.isEmpty) {
        return 'لم يتم العثور على إجابات للأسئلة';
      }

      // Validate that questions and answers count match
      if (questions.length != answers.length) {
        return 'عدد الأسئلة لا يطابق عدد الإجابات';
      }
    } catch (e) {
      return 'خطأ في تنسيق الأسئلة أو الإجابات';
    }

    return null; // No validation errors
  }

  /// Helper method to create a quick test request from form data
  static CreateQuickTestRequest createRequestFromFormData({
    required List<TeacherClass> classes,
    required String selectedSchool,
    required String selectedStage,
    required String selectedSection,
    required String selectedSubject,
    required String title,
    required DateTime deadline,
    required Map<String, List<Map<String, dynamic>>> questionsByType,
    required int durationMinutes,
    required int maxGrade,
  }) {
    // Find matching TeacherClass
    final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
      classes,
      selectedSchool,
      selectedStage,
      selectedSection,
      selectedSubject,
    );

    if (matchingClass == null) {
      throw Exception('لم يتم العثور على الفصل المطابق للاختيارات المحددة');
    }

    // Convert questions and answers to JSON
    final questionsJson = _convertQuestionsToJson(questionsByType);
    final answersJson = _convertAnswersToJson(questionsByType);

    return CreateQuickTestRequest(
      levelSubjectId: matchingClass.levelSubjectId ?? 
                     matchingClass.subjectId ?? 
                     '00000000-0000-0000-0000-000000000000',
      levelId: matchingClass.levelId ?? '00000000-0000-0000-0000-000000000000',
      classId: matchingClass.classId ?? '00000000-0000-0000-0000-000000000000',
      title: title.trim(),
      deadline: deadline,
      questionsJson: questionsJson,
      answersJson: answersJson,
      durationMinutes: durationMinutes,
      maxGrade: maxGrade,
    );
  }

  static String _convertQuestionsToJson(Map<String, List<Map<String, dynamic>>> questionsByType) {
    final List<Map<String, dynamic>> allQuestions = [];
    int questionIndex = 1;

    for (final entry in questionsByType.entries) {
      final type = entry.key;
      final questions = entry.value;

      for (final question in questions) {
        final questionData = {
          'id': questionIndex,
          'type': type,
          'question': question['question'] ?? '',
        };

        if (type == 'choice') {
          questionData['options'] = question['options'] ?? [];
        }

        allQuestions.add(questionData);
        questionIndex++;
      }
    }

    return jsonEncode(allQuestions);
  }

  static String _convertAnswersToJson(Map<String, List<Map<String, dynamic>>> questionsByType) {
    final List<Map<String, dynamic>> allAnswers = [];
    int questionIndex = 1;

    for (final entry in questionsByType.entries) {
      final type = entry.key;
      final questions = entry.value;

      for (final question in questions) {
        final answerData = {
          'questionId': questionIndex,
          'type': type,
        };

        switch (type) {
          case 'choice':
            answerData['correctOption'] = question['correctOption'];
            break;
          case 'truefalse':
            answerData['answer'] = question['trueFalseAnswer'];
            break;
          case 'complete':
            answerData['answer'] = question['completeAnswer'] ?? '';
            break;
        }

        allAnswers.add(answerData);
        questionIndex++;
      }
    }

    return jsonEncode(allAnswers);
  }
}
