import 'package:equatable/equatable.dart';

/// Base state لجميع BLoC states
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

/// حالة التحميل
class BaseLoadingState extends BaseState {
  const BaseLoadingState();
}

/// حالة البيانات المحملة بنجاح
class BaseLoadedState extends BaseState {
  final Map<String, dynamic>? data;

  const BaseLoadedState({this.data});

  @override
  List<Object?> get props => [data];
}

/// حالة الخطأ
class BaseErrorState extends BaseState {
  final String message;
  final String? errorCode;

  const BaseErrorState(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// Base events للـ BLoC
abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object?> get props => [];
}

/// حدث جلب البيانات
class LoadDataEvent extends BaseEvent {
  const LoadDataEvent();
}

/// حدث إعادة تحميل البيانات
class RefreshDataEvent extends BaseEvent {
  const RefreshDataEvent();
}
