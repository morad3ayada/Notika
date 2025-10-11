import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';
import '../../../data/repositories/conversations_repository.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final ConversationsRepository repository;

  ConversationsBloc(this.repository) : super(const ConversationsInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<RefreshConversationsEvent>(_onRefreshConversations);
    on<SearchConversationsEvent>(_onSearchConversations);
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      emit(const ConversationsLoading());
      
      debugPrint('🔄 جاري جلب المحادثات من السيرفر...');
      
      final response = await repository.getConversations();

      if (!response.isSuccess) {
        debugPrint('❌ فشل جلب المحادثات: ${response.message}');
        emit(ConversationsError(response.message ?? 'فشل جلب المحادثات'));
        return;
      }

      if (response.conversations.isEmpty) {
        debugPrint('📭 لا توجد محادثات');
        emit(const ConversationsEmpty(message: 'لا توجد محادثات حالياً'));
        return;
      }

      debugPrint('✅ تم جلب ${response.conversations.length} محادثة بنجاح');
      emit(ConversationsLoaded(
        conversations: response.conversations,
        allConversations: response.conversations,
      ));
    } catch (e) {
      debugPrint('❌ خطأ في جلب المحادثات: $e');
      emit(ConversationsError('حدث خطأ أثناء جلب المحادثات: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshConversations(
    RefreshConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      debugPrint('🔄 إعادة تحميل المحادثات...');
      
      final response = await repository.refreshConversations();

      if (!response.isSuccess) {
        debugPrint('❌ فشل تحديث المحادثات: ${response.message}');
        emit(ConversationsError(response.message ?? 'فشل تحديث المحادثات'));
        return;
      }

      if (response.conversations.isEmpty) {
        debugPrint('📭 لا توجد محادثات بعد التحديث');
        emit(const ConversationsEmpty(message: 'لا توجد محادثات حالياً'));
        return;
      }

      debugPrint('✅ تم تحديث ${response.conversations.length} محادثة');
      emit(ConversationsLoaded(
        conversations: response.conversations,
        allConversations: response.conversations,
      ));
    } catch (e) {
      debugPrint('❌ خطأ في تحديث المحادثات: $e');
      emit(ConversationsError('حدث خطأ أثناء تحديث المحادثات: ${e.toString()}'));
    }
  }

  Future<void> _onSearchConversations(
    SearchConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ConversationsLoaded) {
        debugPrint('⚠️ لا يمكن البحث: القائمة غير محملة');
        return;
      }

      debugPrint('🔍 البحث عن: "${event.query}"');

      final response = await repository.searchConversations(
        currentState.allConversations,
        event.query,
      );

      if (!response.isSuccess) {
        debugPrint('❌ فشل البحث: ${response.message}');
        return;
      }

      if (response.conversations.isEmpty) {
        debugPrint('📭 لم يتم العثور على نتائج');
        emit(ConversationsLoaded(
          conversations: [],
          allConversations: currentState.allConversations,
        ));
        return;
      }

      debugPrint('✅ تم العثور على ${response.conversations.length} نتيجة');
      emit(ConversationsLoaded(
        conversations: response.conversations,
        allConversations: currentState.allConversations,
      ));
    } catch (e) {
      debugPrint('❌ خطأ في البحث: $e');
      // لا نغير الحالة في حالة خطأ البحث
    }
  }
}
