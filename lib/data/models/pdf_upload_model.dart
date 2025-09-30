import 'package:equatable/equatable.dart';
import 'dart:io';

/// نموذج البيانات لرفع الملفات (PDF, صور, فيديو, صوت)
/// يحتوي على كل الحقول اللي محتاجينها عشان نبعت الملف للسيرفر
class PdfUploadModel extends Equatable {
  final String levelSubjectId;    // معرف المادة في المرحلة
  final String levelId;           // معرف المرحلة
  final String classId;           // معرف الفصل/الشعبة
  final String fileClassificationId; // معرف تصنيف الملف (الوحدة/الفصل)
  final String title;             // عنوان الملف
  final String fileType;          // نوع الملف (pdf, jpg, aac, etc.)
  final String path;              // مسار حفظ الملف على السيرفر
  final String? note;             // ملاحظات اختيارية
  final File file;                // الملف نفسه
  final File? voiceFile;          // الملف الصوتي (اختياري)

  const PdfUploadModel({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    required this.fileClassificationId,
    required this.title,
    required this.fileType,
    required this.path,
    this.note,
    required this.file,
    this.voiceFile, // الملف الصوتي اختياري
  });

  /// دالة عشان نحول البيانات لـ Map عشان نبعتها في الـ MultipartRequest
  Map<String, String> toFormData() {
    return {
      'LevelSubjectId': levelSubjectId,
      'LevelId': levelId,
      'ClassId': classId,
      'FileClassificationId': fileClassificationId,
      'Title': title,
      'FileType': fileType,
      'Path': path,
      if (note != null) 'Note': note!,
    };
  }

  /// دالة عشان نحدد نوع الملف بناءً على الامتداد
  static String getFileTypeFromExtension(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return 'pdf';
      case 'jpg':
      case 'jpeg':
        return 'image';
      case 'png':
        return 'image';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
        return 'aac'; // نوع الملف الصوتي كما في الـ cURL
      default:
        return 'file';
    }
  }

  /// دالة عشان نحدد الـ MIME type للملف
  static String getMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/vnd.dlna.adts'; // نفس النوع في الـ cURL
      default:
        return 'application/octet-stream';
    }
  }

  @override
  List<Object?> get props => [
        levelSubjectId,
        levelId,
        classId,
        fileClassificationId,
        title,
        fileType,
        path,
        note,
        file.path,
        voiceFile?.path, // إضافة مسار الملف الصوتي
      ];
}

/// نموذج الاستجابة من السيرفر بعد رفع الملف
class PdfUploadResponse extends Equatable {
  final bool success;
  final String message;
  final String? fileId;
  final String? filePath;

  const PdfUploadResponse({
    required this.success,
    required this.message,
    this.fileId,
    this.filePath,
  });

  /// تحويل الاستجابة من JSON
  factory PdfUploadResponse.fromJson(Map<String, dynamic> json) {
    return PdfUploadResponse(
      success: json['success'] ?? json['isSuccess'] ?? false,
      message: json['message'] ?? json['Message'] ?? 'تم رفع الملف بنجاح',
      fileId: json['fileId'] ?? json['id'],
      filePath: json['filePath'] ?? json['path'],
    );
  }

  @override
  List<Object?> get props => [success, message, fileId, filePath];
}
