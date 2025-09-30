import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ExamQuestionsEvent extends Equatable {
  const ExamQuestionsEvent();

  @override
  List<Object?> get props => [];
}

/// حدث إرسال الأسئلة للسيرفر
class SubmitExamQuestionsEvent extends ExamQuestionsEvent {
  final String examTableId;
  final List<Map<String, dynamic>> questions;
  final File? examFile;

  const SubmitExamQuestionsEvent({
    required this.examTableId,
    required this.questions,
    this.examFile,
  });

  @override
  List<Object?> get props => [examTableId, questions, examFile];
}

/// حدث إعادة تعيين الحالة
class ResetExamQuestionsEvent extends ExamQuestionsEvent {
  const ResetExamQuestionsEvent();
}
