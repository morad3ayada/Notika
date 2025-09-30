import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/exam_export_repository.dart';
import '../../../data/models/exam_export_model.dart';
import 'exam_export_event.dart';
import 'exam_export_state.dart';

/// BLoC لإدارة تصدير الأسئلة إلى ملف Word
/// يتعامل مع جميع العمليات المتعلقة بتصدير الأسئلة
class ExamExportBloc extends Bloc<ExamExportEvent, ExamExportState> {
  final ExamExportRepository _repository;

  ExamExportBloc(this._repository) : super(const ExamExportInitial()) {
    on<ExportExamToWordEvent>(_onExportExamToWord);
    on<ResetExamExportEvent>(_onResetExamExport);
  }

  /// معالج حدث تصدير الأسئلة إلى Word
  Future<void> _onExportExamToWord(
    ExportExamToWordEvent event,
    Emitter<ExamExportState> emit,
  ) async {
    try {
      print('🚀 بدء عملية تصدير الأسئلة...');
      
      emit(const ExamExportLoading());

      // التحقق من صحة البيانات
      final validationError = _validateExamData(event.examData);
      if (validationError != null) {
        print('❌ خطأ في التحقق من البيانات: $validationError');
        emit(ExamExportFailure(message: validationError));
        return;
      }

      print('✅ البيانات صحيحة، بدء التصدير...');
      print('   عدد الأسئلة: ${event.examData.totalQuestions}');
      print('   المادة: ${event.examData.subjectName ?? "غير محدد"}');

      // تصدير الأسئلة
      final response = await _repository.exportToWord(event.examData);

      if (response.success) {
        print('✅ تم التصدير بنجاح: ${response.filePath}');
        emit(ExamExportSuccess(response: response));
      } else {
        print('❌ فشل التصدير: ${response.message}');
        emit(ExamExportFailure(message: response.message));
      }

    } catch (e, stackTrace) {
      print('❌ خطأ غير متوقع أثناء التصدير: $e');
      print('Stack trace: $stackTrace');
      
      emit(ExamExportFailure(
        message: 'حدث خطأ غير متوقع أثناء تصدير الأسئلة: ${e.toString()}',
      ));
    }
  }

  /// معالج حدث إعادة تعيين الحالة
  void _onResetExamExport(
    ResetExamExportEvent event,
    Emitter<ExamExportState> emit,
  ) {
    print('🔄 إعادة تعيين حالة تصدير الأسئلة');
    emit(const ExamExportInitial());
  }

  /// التحقق من صحة بيانات الامتحان
  String? _validateExamData(ExamExportModel examData) {
    // التحقق من وجود أسئلة
    if (examData.questions.isEmpty) {
      return 'لا توجد أسئلة للتصدير';
    }

    // التحقق من صحة الأسئلة
    for (int i = 0; i < examData.questions.length; i++) {
      final question = examData.questions[i];
      
      // التحقق من وجود نص السؤال
      if (question.questionText.trim().isEmpty) {
        return 'السؤال رقم ${i + 1} لا يحتوي على نص';
      }

      // التحقق من الأسئلة الاختيارية
      if (question.type == 'choice') {
        if (question.options.length < 2) {
          return 'السؤال الاختياري رقم ${i + 1} يجب أن يحتوي على اختيارين على الأقل';
        }
        
        // التحقق من وجود اختيارات فارغة
        for (int j = 0; j < question.options.length; j++) {
          if (question.options[j].trim().isEmpty) {
            return 'الاختيار رقم ${j + 1} في السؤال ${i + 1} فارغ';
          }
        }
        
        // التحقق من وجود إجابة صحيحة
        if (question.correctAnswer == null) {
          return 'السؤال الاختياري رقم ${i + 1} لا يحتوي على إجابة صحيحة';
        }
      }

      // التحقق من أسئلة صح أو خطأ
      if (question.type == 'truefalse') {
        if (question.correctAnswer == null) {
          return 'سؤال صح أو خطأ رقم ${i + 1} لا يحتوي على إجابة صحيحة';
        }
      }

      // التحقق من أسئلة أكمل الفراغ
      if (question.type == 'complete') {
        if (question.correctAnswer == null || question.correctAnswer!.trim().isEmpty) {
          return 'سؤال أكمل الفراغ رقم ${i + 1} لا يحتوي على إجابة صحيحة';
        }
      }
    }

    print('✅ جميع الأسئلة صحيحة');
    return null; // كل شيء صحيح
  }

  @override
  Future<void> close() {
    print('🔒 إغلاق ExamExportBloc');
    return super.close();
  }
}
