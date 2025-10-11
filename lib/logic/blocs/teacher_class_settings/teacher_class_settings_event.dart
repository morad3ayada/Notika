import 'package:equatable/equatable.dart';
import '../../../data/models/teacher_class_setting_model.dart';

abstract class TeacherClassSettingsEvent extends Equatable {
  const TeacherClassSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// حدث لجلب إعدادات الصلاحيات من السيرفر
class LoadTeacherClassSettingsEvent extends TeacherClassSettingsEvent {
  const LoadTeacherClassSettingsEvent();
}

/// حدث لتحديث إعدادات الصلاحيات
class UpdateTeacherClassSettingsEvent extends TeacherClassSettingsEvent {
  final List<TeacherClassSetting> settings;

  const UpdateTeacherClassSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

/// حدث لتبديل صلاحية طالب واحد (toggle)
class ToggleStudentChatPermissionEvent extends TeacherClassSettingsEvent {
  final String classId;
  final String levelId;
  final bool newValue;

  const ToggleStudentChatPermissionEvent({
    required this.classId,
    required this.levelId,
    required this.newValue,
  });

  @override
  List<Object?> get props => [classId, levelId, newValue];
}
