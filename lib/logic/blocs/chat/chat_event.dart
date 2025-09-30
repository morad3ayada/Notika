import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// حدث جلب المحادثة
class LoadConversationEvent extends ChatEvent {
  final String teacherId;
  final String studentId;

  const LoadConversationEvent({
    required this.teacherId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [teacherId, studentId];
}

/// حدث إرسال رسالة
class SendMessageEvent extends ChatEvent {
  final String senderId;
  final String receiverId;
  final String message;

  const SendMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.message,
  });

  @override
  List<Object?> get props => [senderId, receiverId, message];
}

/// حدث تحديث المحادثة
class RefreshConversationEvent extends ChatEvent {
  final String teacherId;
  final String studentId;

  const RefreshConversationEvent({
    required this.teacherId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [teacherId, studentId];
}

/// حدث تحديد الرسائل كمقروءة
class MarkMessagesAsReadEvent extends ChatEvent {
  final String currentUserId;
  final String otherUserId;

  const MarkMessagesAsReadEvent({
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  List<Object?> get props => [currentUserId, otherUserId];
}
