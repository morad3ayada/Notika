import 'package:flutter/material.dart';
import 'Chat_details_screen.dart';

class ChatScreen extends StatelessWidget {
  final List<Map<String, String>> users = [
    {"name": "أحمد محمد", "lastMessage": "السلام عليكم", "avatar": "A"},
    {"name": "سارة علي", "lastMessage": "تم إرسال الواجب", "avatar": "S"},
    {"name": "محمد سمير", "lastMessage": "شكرًا لك", "avatar": "M"},
    {"name": "منى خالد", "lastMessage": "متى الامتحان؟", "avatar": "M"},
    {"name": "يوسف إبراهيم", "lastMessage": "تم الحضور اليوم", "avatar": "Y"},
  ];

   ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
      children: [
        // خلفية mesh/grid مثل الرئيسية
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
        // قائمة الأشخاص
        ListView.separated(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 18, horizontal: 14),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, index) {
            final user = users[index];
            // Get Arabic initial (first letter)
            String getArabicInitial(String name) {
              final parts = name.trim().split(' ');
              return parts[0].substring(0, 1);
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailsScreen(userName: user["name"]!, avatar: user["avatar"]!),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsetsDirectional.only(start: 60, end: 16, top: 14, bottom: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user["name"]!,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user["lastMessage"]!,
                                  style: const TextStyle(
                                    color: Color(0xFF90A4AE),
                                    fontSize: 14.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Change avatar to use only one Arabic initial
                Positioned(
                  right: -18,
                  top: 12,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Theme.of(context).cardColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        getArabicInitial(user["name"]!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
    );
  }
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
