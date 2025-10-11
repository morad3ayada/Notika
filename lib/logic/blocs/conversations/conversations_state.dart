import 'package:equatable/equatable.dart';
import '../../../data/models/conversation_model.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

/// الحالة الابتدائية
class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

/// حالة التحميل
class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

/// حالة تحميل المحادثات بنجاح
class ConversationsLoaded extends ConversationsState {
  final List<Conversation> conversations;
  final List<Conversation> allConversations; // للاحتفاظ بالقائمة الكاملة للبحث

  const ConversationsLoaded({
    required this.conversations,
    required this.allConversations,
  });

  @override
  List<Object?> get props => [conversations, allConversations];
}

/// حالة عدم وجود محادثات
class ConversationsEmpty extends ConversationsState {
  final String message;

  const ConversationsEmpty({
    this.message = 'لا توجد محادثات حالياً',
  });

  @override
  List<Object?> get props => [message];
}

/// حالة الخطأ
class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError(this.message);

  @override
  List<Object?> get props => [message];
}
