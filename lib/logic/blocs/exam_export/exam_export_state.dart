import 'package:equatable/equatable.dart';
import '../../../data/models/exam_export_model.dart';

/// الحالات الخاصة بتصدير الأسئلة
abstract class ExamExportState extends Equatable {
  const ExamExportState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class ExamExportInitial extends ExamExportState {
  const ExamExportInitial();
}

/// حالة جاري التصدير
class ExamExportLoading extends ExamExportState {
  const ExamExportLoading();
}

/// حالة نجاح التصدير
class ExamExportSuccess extends ExamExportState {
  final ExamExportResponse response;

  const ExamExportSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

/// حالة فشل التصدير
class ExamExportFailure extends ExamExportState {
  final String message;

  const ExamExportFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
