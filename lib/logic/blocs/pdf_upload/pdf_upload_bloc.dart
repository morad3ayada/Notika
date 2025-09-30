import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'pdf_upload_event.dart';
import 'pdf_upload_state.dart';
import '../../../data/repositories/pdf_upload_repository.dart';
import '../../../data/models/pdf_upload_model.dart';

/// BLoC مسؤول عن إدارة عملية رفع الملفات
/// بيتعامل مع الأحداث ويغير الحالات حسب نتيجة العمليات
class PdfUploadBloc extends Bloc<PdfUploadEvent, PdfUploadState> {
  final PdfUploadRepository _repository;

  PdfUploadBloc(this._repository) : super(const PdfUploadInitial()) {
    // تسجيل معالجات الأحداث
    on<UploadPdfEvent>(_onUploadPdf);
    on<ResetPdfUploadEvent>(_onResetPdfUpload);
    on<ValidatePdfUploadEvent>(_onValidatePdfUpload);
  }

  /// معالج حدث رفع الملف
  /// بياخد البيانات ويبعتها للـ Repository عشان يرفعها للسيرفر
  Future<void> _onUploadPdf(
    UploadPdfEvent event,
    Emitter<PdfUploadState> emit,
  ) async {
    try {
      print('🔄 بدء عملية رفع الملف في BLoC');
      
      // تغيير الحالة لـ Loading
      emit(const PdfUploadLoading());

      // التحقق من صحة البيانات أولاً
      final validationResult = _validateUploadData(event.uploadModel);
      if (validationResult != null) {
        emit(PdfUploadValidationFailure(message: validationResult));
        return;
      }

      print('✅ البيانات صحيحة، بدء الرفع');

      // رفع الملف عبر الـ Repository
      final response = await _repository.uploadPdf(event.uploadModel);

      // تحديد الحالة بناءً على النتيجة
      if (response.success) {
        print('✅ تم رفع الملف بنجاح');
        emit(PdfUploadSuccess(response: response));
      } else {
        print('❌ فشل رفع الملف: ${response.message}');
        emit(PdfUploadFailure(message: response.message));
      }

    } catch (e) {
      print('❌ خطأ في BLoC أثناء رفع الملف: $e');
      emit(PdfUploadFailure(
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      ));
    }
  }

  /// معالج حدث إعادة تعيين الحالة
  /// بيخلي الـ BLoC يرجع للحالة الأولية
  void _onResetPdfUpload(
    ResetPdfUploadEvent event,
    Emitter<PdfUploadState> emit,
  ) {
    print('🔄 إعادة تعيين حالة رفع الملف');
    emit(const PdfUploadInitial());
  }

  /// معالج حدث التحقق من صحة البيانات
  /// بيتأكد إن كل البيانات المطلوبة موجودة وصحيحة
  void _onValidatePdfUpload(
    ValidatePdfUploadEvent event,
    Emitter<PdfUploadState> emit,
  ) {
    print('🔍 التحقق من صحة بيانات الرفع');
    
    emit(const PdfUploadValidating());

    final validationResult = _validateUploadData(event.uploadModel);
    
    if (validationResult != null) {
      print('❌ فشل التحقق: $validationResult');
      emit(PdfUploadValidationFailure(message: validationResult));
    } else {
      print('✅ البيانات صحيحة');
      emit(const PdfUploadValidationSuccess());
    }
  }

  /// دالة مساعدة للتحقق من صحة البيانات
  /// بترجع null إذا البيانات صحيحة، أو رسالة خطأ إذا في مشكلة
  String? _validateUploadData(PdfUploadModel model) {
    // التحقق من وجود المعرفات المطلوبة
    if (model.levelSubjectId.isEmpty) {
      return 'معرف المادة مطلوب';
    }

    if (model.levelId.isEmpty) {
      return 'معرف المرحلة مطلوب';
    }

    if (model.classId.isEmpty) {
      return 'معرف الفصل مطلوب';
    }

    if (model.fileClassificationId.isEmpty) {
      return 'يجب اختيار الفصل/الوحدة';
    }

    // التحقق من العنوان
    if (model.title.trim().isEmpty) {
      return 'عنوان الملف مطلوب';
    }

    // التحقق من نوع الملف
    if (model.fileType.isEmpty) {
      return 'نوع الملف غير محدد';
    }

    // التحقق من المسار
    if (model.path.isEmpty) {
      return 'مسار حفظ الملف مطلوب';
    }

    // التحقق من وجود الملف
    if (!model.file.existsSync()) {
      return 'الملف المحدد غير موجود';
    }

    // التحقق من حجم الملف (مثلاً أقل من 50 ميجا)
    final fileSizeInMB = model.file.lengthSync() / (1024 * 1024);
    if (fileSizeInMB > 50) {
      return 'حجم الملف كبير جداً (أقصى حد 50 ميجابايت)';
    }

    // التحقق من امتداد الملف
    final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'];
    final fileExtension = model.file.path.toLowerCase().split('.').last;
    if (!allowedExtensions.contains(fileExtension)) {
      return 'نوع الملف غير مدعوم. الأنواع المدعومة: ${allowedExtensions.join(', ')}';
    }

    // التحقق من الملف الصوتي إذا كان موجود
    if (model.voiceFile != null) {
      if (!model.voiceFile!.existsSync()) {
        return 'الملف الصوتي المحدد غير موجود';
      }

      // التحقق من حجم الملف الصوتي (أقل من 20 ميجا)
      final voiceFileSizeInMB = model.voiceFile!.lengthSync() / (1024 * 1024);
      if (voiceFileSizeInMB > 20) {
        return 'حجم الملف الصوتي كبير جداً (أقصى حد 20 ميجابايت)';
      }

      // التحقق من امتداد الملف الصوتي
      final allowedAudioExtensions = ['mp3', 'wav', 'm4a', 'aac'];
      final audioExtension = model.voiceFile!.path.toLowerCase().split('.').last;
      if (!allowedAudioExtensions.contains(audioExtension)) {
        return 'نوع الملف الصوتي غير مدعوم. الأنواع المدعومة: ${allowedAudioExtensions.join(', ')}';
      }

      print('✅ الملف الصوتي صحيح: ${model.voiceFile!.path.split('/').last}');
    }

    // التحقق من صحة تنسيق المعرفات (GUID)
    final guidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );

    if (!guidPattern.hasMatch(model.levelSubjectId)) {
      return 'تنسيق معرف المادة غير صحيح';
    }

    if (!guidPattern.hasMatch(model.levelId)) {
      return 'تنسيق معرف المرحلة غير صحيح';
    }

    if (!guidPattern.hasMatch(model.classId)) {
      return 'تنسيق معرف الفصل غير صحيح';
    }

    if (!guidPattern.hasMatch(model.fileClassificationId)) {
      return 'تنسيق معرف الوحدة غير صحيح';
    }

    // كل شيء تمام
    return null;
  }
}
