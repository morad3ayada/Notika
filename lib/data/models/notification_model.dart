import 'package:equatable/equatable.dart';

/// نموذج بيانات إشعار واحد
class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? type;
  final DateTime? createdAt;
  final bool isRead;
  final String? imageUrl;
  final String? videoUrl;
  final String? senderName;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.videoUrl,
    this.senderName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // محاولة الحصول على الـ body من مفاتيح مختلفة
    final bodyValue = json['details']?.toString() ?? // السيرفر بيستخدم details
        json['Details']?.toString() ?? 
        json['body']?.toString() ?? 
        json['Body']?.toString() ?? 
        json['message']?.toString() ?? 
        json['Message']?.toString() ?? 
        json['content']?.toString() ?? 
        json['Content']?.toString() ?? 
        json['description']?.toString() ?? 
        json['Description']?.toString() ?? 
        '';
    
    return NotificationModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['Title']?.toString() ?? 'إشعار',
      body: bodyValue,
      type: json['type']?.toString() ?? json['Type']?.toString(),
      createdAt: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : (json['Date'] != null
              ? DateTime.tryParse(json['Date'].toString())
              : (json['createdAt'] != null
                  ? DateTime.tryParse(json['createdAt'].toString())
                  : (json['CreatedAt'] != null
                      ? DateTime.tryParse(json['CreatedAt'].toString())
                      : null))),
      isRead: json['isRead'] as bool? ?? json['IsRead'] as bool? ?? json['is_read'] as bool? ?? false,
      imageUrl: json['imageUrl']?.toString() ?? json['ImageUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString() ?? json['VideoUrl']?.toString(),
      senderName: json['senderName']?.toString() ?? json['SenderName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'createdAt': createdAt?.toIso8601String(),
        'isRead': isRead,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'senderName': senderName,
      };

  @override
  List<Object?> get props => [id, title, body, type, createdAt, isRead, imageUrl, videoUrl, senderName];
}

/// استجابة API للإشعارات
class NotificationsResponse extends Equatable {
  final List<NotificationModel> notifications;
  final String? message;
  final bool isSuccess;

  const NotificationsResponse({
    required this.notifications,
    this.message,
    this.isSuccess = true,
  });

  factory NotificationsResponse.success(List<NotificationModel> notifications) {
    return NotificationsResponse(
      notifications: notifications,
      isSuccess: true,
    );
  }

  factory NotificationsResponse.error(String message) {
    return NotificationsResponse(
      notifications: const [],
      message: message,
      isSuccess: false,
    );
  }

  @override
  List<Object?> get props => [notifications, message, isSuccess];
}
