import 'package:equatable/equatable.dart';
import '../../../data/models/teacher_class_setting_model.dart';

abstract class TeacherClassSettingsState extends Equatable {
  const TeacherClassSettingsState();

  @override
  List<Object?> get props => [];
}

/// الحالة الابتدائية
class TeacherClassSettingsInitial extends TeacherClassSettingsState {
  const TeacherClassSettingsInitial();
}

/// حالة التحميل
class TeacherClassSettingsLoading extends TeacherClassSettingsState {
  const TeacherClassSettingsLoading();
}

/// حالة تحميل الإعدادات بنجاح
class TeacherClassSettingsLoaded extends TeacherClassSettingsState {
  final List<TeacherClassSetting> settings;

  const TeacherClassSettingsLoaded({
    required this.settings,
  });

  @override
  List<Object?> get props => [settings];
}

/// حالة التحديث جاري
class TeacherClassSettingsUpdating extends TeacherClassSettingsState {
  final List<TeacherClassSetting> currentSettings;

  const TeacherClassSettingsUpdating({
    required this.currentSettings,
  });

  @override
  List<Object?> get props => [currentSettings];
}

/// حالة نجاح التحديث
class TeacherClassSettingsUpdateSuccess extends TeacherClassSettingsState {
  final List<TeacherClassSetting> settings;
  final String message;

  const TeacherClassSettingsUpdateSuccess({
    required this.settings,
    this.message = 'تم تحديث الإعدادات بنجاح',
  });

  @override
  List<Object?> get props => [settings, message];
}

/// حالة عدم وجود إعدادات
class TeacherClassSettingsEmpty extends TeacherClassSettingsState {
  final String message;

  const TeacherClassSettingsEmpty({
    this.message = 'لا توجد إعدادات حالياً',
  });

  @override
  List<Object?> get props => [message];
}

/// حالة الخطأ
class TeacherClassSettingsError extends TeacherClassSettingsState {
  final String message;

  const TeacherClassSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
