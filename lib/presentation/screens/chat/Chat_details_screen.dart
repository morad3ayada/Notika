import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/chat/chat_barrel.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../di/injector.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String userName;
  final String avatar;
  final String studentUserId;
  
  const ChatDetailsScreen({
    super.key, 
    required this.userName, 
    required this.avatar,
    required this.studentUserId,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  late final ChatBloc _chatBloc;
  final TextEditingController _messageController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(sl<ChatRepository>());
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    // الحصول على معرف المعلم الحالي (userId)
    _currentUserId = await AuthService.getUserId();
    
    if (_currentUserId != null && widget.studentUserId.isNotEmpty) {
      // جلب المحادثة
      _chatBloc.add(LoadConversationEvent(
        teacherId: _currentUserId!,
        studentId: widget.studentUserId,
      ));
      
      // تحديد الرسائل كمقروءة (في الخلفية)
      _chatBloc.add(MarkMessagesAsReadEvent(
        currentUserId: _currentUserId!,
        otherUserId: widget.studentUserId,
      ));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatBloc.close();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    
    if (message.isEmpty) {
      return;
    }
    
    if (_currentUserId == null || widget.studentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: لا يمكن إرسال الرسالة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // إرسال الرسالة
    _chatBloc.add(SendMessageEvent(
      senderId: _currentUserId!,
      receiverId: widget.studentUserId,
      message: message,
    ));

    // مسح حقل الإدخال
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _MeshBackgroundPainter(),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1976D2)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF64B5F6),
                        child: Text(
                          widget.avatar,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF233A5A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    bloc: _chatBloc,
                    builder: (context, state) {
                      // حالة التحميل
                      if (state is ChatLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('جاري تحميل المحادثة...'),
                            ],
                          ),
                        );
                      }
                      
                      // حالة الخطأ
                      if (state is ChatError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 60, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadConversation,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // حالة القائمة الفارغة
                      if (state is ChatEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // حالة النجاح - عرض الرسائل
                      if (state is ChatLoaded) {
                        final messages = state.messages;
                        
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.isSentByMe(_currentUserId ?? '');
                            
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                constraints: const BoxConstraints(maxWidth: 260),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF1976D2) : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.message ?? '',
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color ?? const Color(0xFF233A5A),
                                        fontSize: 15.5,
                                      ),
                                    ),
                                    // علامات القراءة (فقط للرسائل المرسلة من المعلم)
                                    if (isMe) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.done_all,
                                            size: 16,
                                            color: msg.isRead == true 
                                                ? Colors.lightBlueAccent  // لون مضيء للمقروءة
                                                : Colors.white60,          // لون مطفي لغير المقروءة
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                      
                      // حالة افتراضية
                      return const Center(
                        child: Text('لا توجد بيانات'),
                      );
                    },
                  ),
                ),
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'اكتب رسالة...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            textAlign: TextAlign.right,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF1976D2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper to get first Arabic letter
String getArabicInitial(String name) {
  final parts = name.trim().split(' ');
  return parts[0].substring(0, 1);
}

class _MeshBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFB0BEC5).withAlpha(33)
      ..strokeWidth = 1;
    final paintDot = Paint()
      ..color = const Color(0xFF3B5998).withAlpha(25)
      ..style = PaintingStyle.fill;
    for (double y = 40; y < size.height; y += 120) {
      for (double x = 0; x < size.width; x += 180) {
        canvas.drawLine(Offset(x, y), Offset(x + 120, y + 40), paintLine);
        canvas.drawLine(Offset(x + 60, y + 80), Offset(x + 180, y), paintLine);
      }
    }
    for (double y = 30; y < size.height; y += 100) {
      for (double x = 20; x < size.width; x += 140) {
        canvas.drawCircle(Offset(x, y), 3, paintDot);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(16)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
