import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// حدث لجلب الإشعارات من السيرفر
class LoadNotificationsEvent extends NotificationsEvent {
  const LoadNotificationsEvent();
}

/// حدث لإعادة تحميل الإشعارات (refresh)
class RefreshNotificationsEvent extends NotificationsEvent {
  const RefreshNotificationsEvent();
}
