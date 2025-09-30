import 'package:equatable/equatable.dart';

/// نموذج بيانات الرسالة الواحدة
class ChatMessage extends Equatable {
  final String? id;
  final String? senderId;
  final String? receiverId;
  final String? message;
  final DateTime? timestamp;
  final bool? isRead;
  final String? senderName;
  final String? receiverName;

  const ChatMessage({
    this.id,
    this.senderId,
    this.receiverId,
    this.message,
    this.timestamp,
    this.isRead,
    this.senderName,
    this.receiverName,
  });

  /// هل الرسالة من المستخدم الحالي
  bool isSentByMe(String currentUserId) {
    return senderId == currentUserId;
  }

  /// إنشاء من JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? 
          json['Id']?.toString() ??
          json['messageId']?.toString(),
      senderId: json['senderId']?.toString() ?? 
                json['SenderId']?.toString(),
      receiverId: json['receiverId']?.toString() ?? 
                  json['ReceiverId']?.toString(),
      message: json['message']?.toString() ?? 
               json['Message']?.toString() ??
               json['content']?.toString() ??
               json['Content']?.toString(),
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString())
          : json['Timestamp'] != null 
              ? DateTime.tryParse(json['Timestamp'].toString())
              : json['createdAt'] != null
                  ? DateTime.tryParse(json['createdAt'].toString())
                  : json['CreatedAt'] != null
                      ? DateTime.tryParse(json['CreatedAt'].toString())
                      : DateTime.now(),
      isRead: json['isRead'] as bool? ?? 
              json['IsRead'] as bool? ?? 
              false,
      senderName: json['senderName']?.toString() ?? 
                  json['SenderName']?.toString(),
      receiverName: json['receiverName']?.toString() ?? 
                    json['ReceiverName']?.toString(),
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp?.toIso8601String(),
      'isRead': isRead,
      'senderName': senderName,
      'receiverName': receiverName,
    };
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        message,
        timestamp,
        isRead,
        senderName,
        receiverName,
      ];
}

/// نموذج استجابة جلب المحادثة
class ChatConversationResponse extends Equatable {
  final bool success;
  final String message;
  final List<ChatMessage> messages;
  final int totalCount;

  const ChatConversationResponse({
    required this.success,
    required this.message,
    required this.messages,
    this.totalCount = 0,
  });

  factory ChatConversationResponse.success({
    required List<ChatMessage> messages,
    String message = 'تم جلب المحادثة بنجاح',
  }) {
    return ChatConversationResponse(
      success: true,
      message: message,
      messages: messages,
      totalCount: messages.length,
    );
  }

  factory ChatConversationResponse.error(String message) {
    return ChatConversationResponse(
      success: false,
      message: message,
      messages: const [],
      totalCount: 0,
    );
  }

  @override
  List<Object?> get props => [success, message, messages, totalCount];
}
