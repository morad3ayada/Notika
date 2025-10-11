import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';
import '../../../data/repositories/notifications_repository.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;

  NotificationsBloc(this.repository) : super(const NotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<RefreshNotificationsEvent>(_onRefreshNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      emit(const NotificationsLoading());
      
      debugPrint('🔄 جاري جلب الإشعارات من السيرفر...');
      
      final response = await repository.getNotifications();

      if (!response.isSuccess) {
        debugPrint('❌ فشل جلب الإشعارات: ${response.message}');
        emit(NotificationsError(response.message ?? 'فشل جلب الإشعارات'));
        return;
      }

      if (response.notifications.isEmpty) {
        debugPrint('📭 لا توجد إشعارات');
        emit(const NotificationsEmpty(message: 'لا توجد إشعارات حالياً'));
        return;
      }

      debugPrint('✅ تم جلب ${response.notifications.length} إشعار بنجاح');
      emit(NotificationsLoaded(
        notifications: response.notifications,
      ));
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإشعارات: $e');
      emit(NotificationsError('حدث خطأ أثناء جلب الإشعارات: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      debugPrint('🔄 إعادة تحميل الإشعارات...');
      
      final response = await repository.refreshNotifications();

      if (!response.isSuccess) {
        debugPrint('❌ فشل تحديث الإشعارات: ${response.message}');
        emit(NotificationsError(response.message ?? 'فشل تحديث الإشعارات'));
        return;
      }

      if (response.notifications.isEmpty) {
        debugPrint('📭 لا توجد إشعارات بعد التحديث');
        emit(const NotificationsEmpty(message: 'لا توجد إشعارات حالياً'));
        return;
      }

      debugPrint('✅ تم تحديث ${response.notifications.length} إشعار');
      emit(NotificationsLoaded(
        notifications: response.notifications,
      ));
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الإشعارات: $e');
      emit(NotificationsError('حدث خطأ أثناء تحديث الإشعارات: ${e.toString()}'));
    }
  }
}
