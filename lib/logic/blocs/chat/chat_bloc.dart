import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  ChatBloc(this.repository) : super(const ChatInitial()) {
    on<LoadConversationEvent>(_onLoadConversation);
    on<SendMessageEvent>(_onSendMessage);
    on<RefreshConversationEvent>(_onRefreshConversation);
    on<MarkMessagesAsReadEvent>(_onMarkMessagesAsRead);
  }

  /// معالج حدث جلب المحادثة
  Future<void> _onLoadConversation(
    LoadConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatLoading());

      final response = await repository.getConversation(
        teacherId: event.teacherId,
        studentId: event.studentId,
      );

      if (response.success) {
        if (response.messages.isEmpty) {
          emit(ChatEmpty(
            message: 'لا توجد رسائل بعد. ابدأ المحادثة!',
            teacherId: event.teacherId,
            studentId: event.studentId,
          ));
        } else {
          emit(ChatLoaded(
            messages: response.messages,
            teacherId: event.teacherId,
            studentId: event.studentId,
          ));
        }
      } else {
        emit(ChatError(response.message));
      }
    } catch (e) {
      emit(ChatError('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  /// معالج حدث إرسال رسالة
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // لا نغير الحالة إلى ChatSending لأننا نريد الاحتفاظ بالرسائل المعروضة
      
      final success = await repository.sendMessage(
        receiverId: event.receiverId,
        message: event.message,
      );

      if (success) {
        // إعادة تحميل المحادثة لعرض الرسالة الجديدة
        add(LoadConversationEvent(
          teacherId: event.senderId,
          studentId: event.receiverId,
        ));
      } else {
        emit(const ChatError('فشل إرسال الرسالة'));
      }
    } catch (e) {
      emit(ChatError('حدث خطأ أثناء إرسال الرسالة: ${e.toString()}'));
    }
  }

  /// معالج حدث تحديث المحادثة
  Future<void> _onRefreshConversation(
    RefreshConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    // نفس منطق LoadConversationEvent
    add(LoadConversationEvent(
      teacherId: event.teacherId,
      studentId: event.studentId,
    ));
  }

  /// معالج حدث تحديد الرسائل كمقروءة
  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await repository.markAsRead(
        currentUserId: event.currentUserId,
        otherUserId: event.otherUserId,
      );
      // لا نغير الحالة، فقط نحدث الرسائل في الخلفية
    } catch (e) {
      // نتجاهل الأخطاء لأن هذه عملية في الخلفية
      print('خطأ في تحديد الرسائل كمقروءة: $e');
    }
  }
}
