import 'package:equatable/equatable.dart';
import '../../../data/models/pdf_upload_model.dart';

/// الحالات المختلفة لـ PdfUploadBloc
/// كل state بيمثل حالة معينة من عملية رفع الملف
abstract class PdfUploadState extends Equatable {
  const PdfUploadState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية - لما الـ BLoC يتم إنشاؤه أول مرة
class PdfUploadInitial extends PdfUploadState {
  const PdfUploadInitial();
}

/// حالة التحقق من صحة البيانات
/// لما نكون بنتأكد إن البيانات صحيحة قبل الرفع
class PdfUploadValidating extends PdfUploadState {
  const PdfUploadValidating();
}

/// حالة نجاح التحقق من البيانات
/// لما البيانات تكون صحيحة وجاهزة للرفع
class PdfUploadValidationSuccess extends PdfUploadState {
  const PdfUploadValidationSuccess();
}

/// حالة فشل التحقق من البيانات
/// لما يكون في مشكلة في البيانات المدخلة
class PdfUploadValidationFailure extends PdfUploadState {
  final String message;

  const PdfUploadValidationFailure({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

/// حالة جاري الرفع
/// لما نكون بنرفع الملف فعلياً للسيرفر
class PdfUploadLoading extends PdfUploadState {
  const PdfUploadLoading();
}

/// حالة نجاح الرفع
/// لما الملف يتم رفعه بنجاح
class PdfUploadSuccess extends PdfUploadState {
  final PdfUploadResponse response;

  const PdfUploadSuccess({
    required this.response,
  });

  @override
  List<Object?> get props => [response];
}

/// حالة فشل الرفع
/// لما يحصل خطأ أثناء رفع الملف
class PdfUploadFailure extends PdfUploadState {
  final String message;

  const PdfUploadFailure({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
