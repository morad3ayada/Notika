import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'teacher_class_settings_event.dart';
import 'teacher_class_settings_state.dart';
import '../../../data/repositories/teacher_class_settings_repository.dart';
import '../../../data/models/teacher_class_setting_model.dart';

class TeacherClassSettingsBloc extends Bloc<TeacherClassSettingsEvent, TeacherClassSettingsState> {
  final TeacherClassSettingsRepository repository;

  TeacherClassSettingsBloc(this.repository) : super(const TeacherClassSettingsInitial()) {
    on<LoadTeacherClassSettingsEvent>(_onLoadSettings);
    on<UpdateTeacherClassSettingsEvent>(_onUpdateSettings);
    on<ToggleStudentChatPermissionEvent>(_onTogglePermission);
  }

  Future<void> _onLoadSettings(
    LoadTeacherClassSettingsEvent event,
    Emitter<TeacherClassSettingsState> emit,
  ) async {
    try {
      emit(const TeacherClassSettingsLoading());
      
      debugPrint('🔄 جاري جلب إعدادات صلاحيات الطلاب من السيرفر...');
      
      final response = await repository.getSettings();

      if (!response.isSuccess) {
        debugPrint('❌ فشل جلب الإعدادات: ${response.message}');
        emit(TeacherClassSettingsError(response.message ?? 'فشل جلب الإعدادات'));
        return;
      }

      if (response.settings.isEmpty) {
        debugPrint('📭 لا توجد إعدادات');
        emit(const TeacherClassSettingsEmpty(message: 'لا توجد إعدادات حالياً'));
        return;
      }

      debugPrint('✅ تم جلب ${response.settings.length} إعداد بنجاح');
      emit(TeacherClassSettingsLoaded(settings: response.settings));
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإعدادات: $e');
      emit(TeacherClassSettingsError('حدث خطأ أثناء جلب الإعدادات: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSettings(
    UpdateTeacherClassSettingsEvent event,
    Emitter<TeacherClassSettingsState> emit,
  ) async {
    try {
      emit(TeacherClassSettingsUpdating(currentSettings: event.settings));
      
      debugPrint('🔄 جاري تحديث إعدادات صلاحيات الطلاب...');
      
      final response = await repository.updateSettings(event.settings);

      if (!response.isSuccess) {
        debugPrint('❌ فشل تحديث الإعدادات: ${response.message}');
        emit(TeacherClassSettingsError(response.message ?? 'فشل تحديث الإعدادات'));
        return;
      }

      debugPrint('✅ تم تحديث الإعدادات بنجاح');
      emit(TeacherClassSettingsUpdateSuccess(
        settings: event.settings,
        message: 'تم تحديث الإعدادات بنجاح',
      ));
      
      // العودة لحالة Loaded
      emit(TeacherClassSettingsLoaded(settings: event.settings));
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الإعدادات: $e');
      emit(TeacherClassSettingsError('حدث خطأ أثناء تحديث الإعدادات: ${e.toString()}'));
    }
  }

  Future<void> _onTogglePermission(
    ToggleStudentChatPermissionEvent event,
    Emitter<TeacherClassSettingsState> emit,
  ) async {
    try {
      // الحصول على الإعدادات الحالية
      List<TeacherClassSetting> currentSettings = [];
      
      if (state is TeacherClassSettingsLoaded) {
        currentSettings = (state as TeacherClassSettingsLoaded).settings;
      } else if (state is TeacherClassSettingsUpdating) {
        currentSettings = (state as TeacherClassSettingsUpdating).currentSettings;
      }

      // البحث عن الإعداد المطلوب وتحديثه
      final updatedSettings = currentSettings.map((setting) {
        if (setting.classId == event.classId && setting.levelId == event.levelId) {
          return setting.copyWith(studentChatPermission: event.newValue);
        }
        return setting;
      }).toList();

      // إرسال التحديث للسيرفر
      emit(TeacherClassSettingsUpdating(currentSettings: updatedSettings));
      
      debugPrint('🔄 جاري تحديث صلاحية الدردشة...');
      
      final response = await repository.updateSettings(updatedSettings);

      if (!response.isSuccess) {
        debugPrint('❌ فشل تحديث الصلاحية: ${response.message}');
        // العودة للإعدادات القديمة
        emit(TeacherClassSettingsLoaded(settings: currentSettings));
        emit(TeacherClassSettingsError(response.message ?? 'فشل تحديث الصلاحية'));
        return;
      }

      debugPrint('✅ تم تحديث الصلاحية بنجاح');
      emit(TeacherClassSettingsUpdateSuccess(
        settings: updatedSettings,
        message: 'تم تحديث صلاحية الدردشة بنجاح',
      ));
      
      // العودة لحالة Loaded
      emit(TeacherClassSettingsLoaded(settings: updatedSettings));
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الصلاحية: $e');
      emit(TeacherClassSettingsError('حدث خطأ أثناء تحديث الصلاحية: ${e.toString()}'));
    }
  }
}
