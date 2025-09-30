import 'package:equatable/equatable.dart';

abstract class ExamQuestionsState extends Equatable {
  const ExamQuestionsState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class ExamQuestionsInitial extends ExamQuestionsState {
  const ExamQuestionsInitial();
}

/// حالة التحميل
class ExamQuestionsLoading extends ExamQuestionsState {
  const ExamQuestionsLoading();
}

/// حالة النجاح
class ExamQuestionsSuccess extends ExamQuestionsState {
  final String message;
  final Map<String, dynamic>? data;

  const ExamQuestionsSuccess({
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [message, data];
}

/// حالة الخطأ
class ExamQuestionsError extends ExamQuestionsState {
  final String message;

  const ExamQuestionsError(this.message);

  @override
  List<Object> get props => [message];
}
