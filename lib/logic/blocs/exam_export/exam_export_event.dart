import 'package:equatable/equatable.dart';
import '../../../data/models/exam_export_model.dart';

/// الأحداث الخاصة بتصدير الأسئلة
abstract class ExamExportEvent extends Equatable {
  const ExamExportEvent();

  @override
  List<Object?> get props => [];
}

/// حدث تصدير الأسئلة إلى ملف Word
class ExportExamToWordEvent extends ExamExportEvent {
  final ExamExportModel examData;

  const ExportExamToWordEvent({required this.examData});

  @override
  List<Object?> get props => [examData];
}

/// حدث إعادة تعيين حالة التصدير
class ResetExamExportEvent extends ExamExportEvent {
  const ResetExamExportEvent();
}
