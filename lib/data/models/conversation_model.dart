import 'package:equatable/equatable.dart';

/// نموذج بيانات محادثة واحدة
class Conversation extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? avatar;
  final bool isOnline;

  const Conversation({
    required this.id,
    required this.userId,
    required this.userName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.avatar,
    this.isOnline = false,
  });

  /// الحرف الأول من الاسم للعرض في الصورة الرمزية
  String get initial {
    if (userName.isEmpty) return '؟';
    return userName.trim().substring(0, 1);
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['receiverId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? json['receiverName']?.toString() ?? 'مستخدم',
      lastMessage: json['lastMessage']?.toString(),
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString())
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      avatar: json['avatar']?.toString(),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime?.toIso8601String(),
        'unreadCount': unreadCount,
        'avatar': avatar,
        'isOnline': isOnline,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        lastMessage,
        lastMessageTime,
        unreadCount,
        avatar,
        isOnline,
      ];
}

/// استجابة API للمحادثات
class ConversationsResponse extends Equatable {
  final List<Conversation> conversations;
  final String? message;
  final bool isSuccess;

  const ConversationsResponse({
    required this.conversations,
    this.message,
    this.isSuccess = true,
  });

  factory ConversationsResponse.success(List<Conversation> conversations) {
    return ConversationsResponse(
      conversations: conversations,
      isSuccess: true,
    );
  }

  factory ConversationsResponse.error(String message) {
    return ConversationsResponse(
      conversations: const [],
      message: message,
      isSuccess: false,
    );
  }

  @override
  List<Object?> get props => [conversations, message, isSuccess];
}
