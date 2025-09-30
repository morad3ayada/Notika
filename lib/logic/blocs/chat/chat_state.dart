import 'package:equatable/equatable.dart';
import '../../../data/models/chat_messages_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// حالة التحميل
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// حالة النجاح - تم جلب المحادثة
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String teacherId;
  final String studentId;

  const ChatLoaded({
    required this.messages,
    required this.teacherId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [messages, teacherId, studentId];
}

/// حالة المحادثة الفارغة
class ChatEmpty extends ChatState {
  final String message;
  final String teacherId;
  final String studentId;

  const ChatEmpty({
    required this.message,
    required this.teacherId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [message, teacherId, studentId];
}

/// حالة الخطأ
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

/// حالة إرسال رسالة
class ChatSending extends ChatState {
  const ChatSending();
}

/// حالة نجاح إرسال الرسالة
class ChatMessageSent extends ChatState {
  const ChatMessageSent();
}
