import 'package:flutter/material.dart';

class ChatDetailsScreen extends StatelessWidget {
  final String userName;
  final String avatar;
  const ChatDetailsScreen({super.key, required this.userName, required this.avatar});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> messages = [
      {"fromMe": false, "text": "السلام عليكم"},
      {"fromMe": true, "text": "وعليكم السلام"},
      {"fromMe": false, "text": "متى الامتحان القادم؟"},
      {"fromMe": true, "text": "يوم الأحد القادم بإذن الله"},
      {"fromMe": false, "text": "شكرًا لك"},
      {"fromMe": true, "text": "العفو"},
    ];
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
                          getArabicInitial(userName),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        userName,
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg["fromMe"] as bool;
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            msg["text"],
                            style: TextStyle(
                              color: isMe ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color ?? const Color(0xFF233A5A),
                              fontSize: 15.5,
                            ),
                          ),
                        ),
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
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'اكتب رسالة...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
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
                          onPressed: () {},
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
