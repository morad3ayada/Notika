import 'package:equatable/equatable.dart';

/// نموذج جدول الامتحانات
class ExamScheduleModel extends Equatable {
  final String? id;
  final String? levelId;
  final String? classId;
  final String? subjectId;
  final String? subjectName;
  final DateTime? examDate;
  final String? examTime;
  final int? duration; // مدة الامتحان بالدقائق
  final String? examType;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExamScheduleModel({
    this.id,
    this.levelId,
    this.classId,
    this.subjectId,
    this.subjectName,
    this.examDate,
    this.examTime,
    this.duration,
    this.examType,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// تحويل من JSON
  factory ExamScheduleModel.fromJson(Map<String, dynamic> json) {
    return ExamScheduleModel(
      id: json['id']?.toString(),
      levelId: json['levelId']?.toString(),
      classId: json['classId']?.toString(),
      subjectId: json['subjectId']?.toString(),
      subjectName: json['subjectName']?.toString(),
      examDate: json['examDate'] != null 
          ? DateTime.tryParse(json['examDate'].toString())
          : null,
      examTime: json['examTime']?.toString(),
      duration: json['duration'] != null 
          ? int.tryParse(json['duration'].toString())
          : null,
      examType: json['examType']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'levelId': levelId,
      'classId': classId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'examDate': examDate?.toIso8601String(),
      'examTime': examTime,
      'duration': duration,
      'examType': examType,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// نسخة محدثة من النموذج
  ExamScheduleModel copyWith({
    String? id,
    String? levelId,
    String? classId,
    String? subjectId,
    String? subjectName,
    DateTime? examDate,
    String? examTime,
    int? duration,
    String? examType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamScheduleModel(
      id: id ?? this.id,
      levelId: levelId ?? this.levelId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      examDate: examDate ?? this.examDate,
      examTime: examTime ?? this.examTime,
      duration: duration ?? this.duration,
      examType: examType ?? this.examType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// تنسيق التاريخ والوقت للعرض
  String get formattedDateTime {
    if (examDate == null) return 'غير محدد';
    
    final date = examDate!;
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    if (examTime != null && examTime!.isNotEmpty) {
      return '$dateStr - $examTime';
    }
    
    return dateStr;
  }

  /// تنسيق المدة للعرض
  String get formattedDuration {
    if (duration == null) return 'غير محدد';
    
    if (duration! < 60) {
      return '$duration دقيقة';
    } else {
      final hours = duration! ~/ 60;
      final minutes = duration! % 60;
      if (minutes == 0) {
        return '$hours ساعة';
      } else {
        return '$hours ساعة و $minutes دقيقة';
      }
    }
  }

  @override
  List<Object?> get props => [
        id,
        levelId,
        classId,
        subjectId,
        subjectName,
        examDate,
        examTime,
        duration,
        examType,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// استجابة API لجدول الامتحانات
class ExamScheduleResponse extends Equatable {
  final bool success;
  final String message;
  final List<ExamScheduleModel> schedules;
  final int totalCount;

  const ExamScheduleResponse({
    required this.success,
    required this.message,
    required this.schedules,
    this.totalCount = 0,
  });

  factory ExamScheduleResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> schedulesJson = json['data'] ?? json['schedules'] ?? [];
    final schedules = schedulesJson
        .map((item) => ExamScheduleModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return ExamScheduleResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'تم جلب البيانات بنجاح',
      schedules: schedules,
      totalCount: json['totalCount'] ?? schedules.length,
    );
  }

  /// إنشاء استجابة فارغة
  factory ExamScheduleResponse.empty() {
    return const ExamScheduleResponse(
      success: true,
      message: 'لا توجد امتحانات مجدولة',
      schedules: [],
      totalCount: 0,
    );
  }

  /// إنشاء استجابة خطأ
  factory ExamScheduleResponse.error(String message) {
    return ExamScheduleResponse(
      success: false,
      message: message,
      schedules: const [],
      totalCount: 0,
    );
  }

  @override
  List<Object?> get props => [success, message, schedules, totalCount];
}
