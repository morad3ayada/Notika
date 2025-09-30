import 'package:equatable/equatable.dart';
import '../../../data/models/pdf_upload_model.dart';

/// الأحداث اللي ممكن تحصل في PdfUploadBloc
/// كل event بيمثل إجراء معين المستخدم عايز يعمله
abstract class PdfUploadEvent extends Equatable {
  const PdfUploadEvent();

  @override
  List<Object?> get props => [];
}

/// حدث رفع الملف
/// بيحتوي على كل البيانات اللي محتاجينها عشان نرفع الملف
class UploadPdfEvent extends PdfUploadEvent {
  final PdfUploadModel uploadModel;

  const UploadPdfEvent({
    required this.uploadModel,
  });

  @override
  List<Object?> get props => [uploadModel];
}

/// حدث إعادة تعيين حالة الرفع
/// بيخلي الـ BLoC يرجع للحالة الأولية
class ResetPdfUploadEvent extends PdfUploadEvent {
  const ResetPdfUploadEvent();
}

/// حدث التحقق من صحة البيانات قبل الرفع
/// بيتأكد إن كل البيانات المطلوبة موجودة وصحيحة
class ValidatePdfUploadEvent extends PdfUploadEvent {
  final PdfUploadModel uploadModel;

  const ValidatePdfUploadEvent({
    required this.uploadModel,
  });

  @override
  List<Object?> get props => [uploadModel];
}
