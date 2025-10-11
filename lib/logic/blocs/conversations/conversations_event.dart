import 'package:equatable/equatable.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object?> get props => [];
}

/// حدث لجلب المحادثات من السيرفر
class LoadConversationsEvent extends ConversationsEvent {
  const LoadConversationsEvent();
}

/// حدث لإعادة تحميل المحادثات (refresh)
class RefreshConversationsEvent extends ConversationsEvent {
  const RefreshConversationsEvent();
}

/// حدث للبحث في المحادثات
class SearchConversationsEvent extends ConversationsEvent {
  final String query;

  const SearchConversationsEvent(this.query);

  @override
  List<Object?> get props => [query];
}
