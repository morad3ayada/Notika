import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

/// الحالة الابتدائية
class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

/// حالة التحميل
class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

/// حالة تحميل الإشعارات بنجاح
class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;

  const NotificationsLoaded({
    required this.notifications,
  });

  @override
  List<Object?> get props => [notifications];
}

/// حالة عدم وجود إشعارات
class NotificationsEmpty extends NotificationsState {
  final String message;

  const NotificationsEmpty({
    this.message = 'لا توجد إشعارات حالياً',
  });

  @override
  List<Object?> get props => [message];
}

/// حالة الخطأ
class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}
