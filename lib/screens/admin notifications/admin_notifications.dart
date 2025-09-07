import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import 'dart:ui';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notifications = [
      {
        'title': 'تنبيه هام',
        'body': 'يرجى حضور الاجتماع الإداري يوم الأحد القادم الساعة 10 صباحاً.'
      },
      {
        'title': 'تحديث بيانات',
        'body': 'يرجى تحديث بياناتك الشخصية في أقرب وقت.'
      },
      {
        'title': 'إعلان',
        'body': 'تم إضافة مواد جديدة للمرحلة الابتدائية.'
      },
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // No AppBar
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
          ListView.separated(
            padding: EdgeInsetsDirectional.only(
              top: MediaQuery.of(context).padding.top + 24,
              start: 18, // في RTL = يمين
              end: 18,   // في RTL = يسار
              bottom: 32,
            ),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Container(
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Color(0xFF1976D2), width: 1.1),
                ),
                padding: const EdgeInsetsDirectional.only(
                  start: 18,  // RTL: يمين
                  end: 10,    // RTL: يسار أقل
                  top: 18,
                  bottom: 18,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart, // RTL: يبدأ من اليمين
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // RTL: إلى اليمين
                    children: [
                      Text(
                        notif['title']!,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif['body']!,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Color(0xFF233A5A),
                          fontSize: 15.5,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // No bottomNavigationBar
    ),
    );
  }
}

// ثابت: بار سفلي متوافق مع المشروع
class MainScreenBottomBar extends StatelessWidget {
  final int selectedIndex;
  const MainScreenBottomBar({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home,
      Icons.chat,
      Icons.schedule,
      Icons.person,
      Icons.notifications,
    ];
    final labels = [
      'الرئيسية',
      'المحادثات',
      'جدول الحصص',
      'البروفايل',
      'الإشعارات',
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Theme.of(context).cardColor.withOpacity(0.75),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final isActive = selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      if (index == 0) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 0)));
                      } else if (index == 1) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 1)));
                      } else if (index == 2) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 2)));
                      } else if (index == 3) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 3)));
                      } else if (index == 4) {
                        // Stay on notifications
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.transparent,
                              shape: BoxShape.circle,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            padding: EdgeInsets.all(isActive ? 8 : 0),
                            child: Icon(
                              icons[index],
                              size: isActive ? 30 : 26,
                              color: isActive ? Color(0xFF1976D2) : Color(0xFF607D8B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isActive
                                ? Text(
                                    labels[index],
                                    key: ValueKey(labels[index]),
                                    style: const TextStyle(
                                      color: Color(0xFF1976D2),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// خلفية متوافقة مع المشروع
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
