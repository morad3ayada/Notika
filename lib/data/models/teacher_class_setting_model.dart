import 'package:equatable/equatable.dart';

/// نموذج بيانات إعدادات صلاحيات الطلاب للمعلم
class TeacherClassSetting extends Equatable {
  final String classId;
  final String levelId;
  final bool studentChatPermission;

  const TeacherClassSetting({
    required this.classId,
    required this.levelId,
    required this.studentChatPermission,
  });

  factory TeacherClassSetting.fromJson(Map<String, dynamic> json) {
    return TeacherClassSetting(
      classId: json['classID']?.toString() ?? 
          json['classId']?.toString() ?? 
          json['ClassID']?.toString() ?? 
          json['ClassId']?.toString() ?? '',
      levelId: json['levelID']?.toString() ?? 
          json['levelId']?.toString() ?? 
          json['LevelID']?.toString() ?? 
          json['LevelId']?.toString() ?? '',
      studentChatPermission: json['studentChatPermission'] as bool? ?? 
          json['StudentChatPermission'] as bool? ?? 
          false,
    );
  }

  Map<String, dynamic> toJson() => {
        'classID': classId,
        'levelID': levelId,
        'studentChatPermission': studentChatPermission,
      };

  TeacherClassSetting copyWith({
    String? classId,
    String? levelId,
    bool? studentChatPermission,
  }) {
    return TeacherClassSetting(
      classId: classId ?? this.classId,
      levelId: levelId ?? this.levelId,
      studentChatPermission: studentChatPermission ?? this.studentChatPermission,
    );
  }

  @override
  List<Object?> get props => [classId, levelId, studentChatPermission];
}

/// استجابة API لإعدادات الصلاحيات
class TeacherClassSettingsResponse extends Equatable {
  final List<TeacherClassSetting> settings;
  final String? message;
  final bool isSuccess;

  const TeacherClassSettingsResponse({
    required this.settings,
    this.message,
    this.isSuccess = true,
  });

  factory TeacherClassSettingsResponse.success(List<TeacherClassSetting> settings) {
    return TeacherClassSettingsResponse(
      settings: settings,
      isSuccess: true,
    );
  }

  factory TeacherClassSettingsResponse.error(String message) {
    return TeacherClassSettingsResponse(
      settings: const [],
      message: message,
      isSuccess: false,
    );
  }

  @override
  List<Object?> get props => [settings, message, isSuccess];
}
