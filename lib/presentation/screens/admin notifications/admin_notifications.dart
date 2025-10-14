import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../home/home_screen.dart';
import 'dart:ui';
import '../../../logic/blocs/notifications/notifications_barrel.dart';
import '../../../data/repositories/notifications_repository.dart';
import '../../../di/injector.dart';
import '../../../config/api_config.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late final NotificationsBloc _notificationsBloc;

  @override
  void initState() {
    super.initState();
    _notificationsBloc = NotificationsBloc(sl<NotificationsRepository>())
      ..add(const LoadNotificationsEvent());
  }

  @override
  void dispose() {
    _notificationsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          BlocBuilder<NotificationsBloc, NotificationsState>(
            bloc: _notificationsBloc,
            builder: (context, state) {
              // حالة التحميل
              if (state is NotificationsLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'جاري تحميل الإشعارات...',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF233A5A),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // حالة الخطأ
              if (state is NotificationsError) {
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
                        onPressed: () => _notificationsBloc.add(const RefreshNotificationsEvent()),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }
              
              // حالة القائمة الفارغة
              if (state is NotificationsEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 60, color: Colors.grey[400]),
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
              
              // حالة النجاح - عرض الإشعارات
              if (state is NotificationsLoaded) {
                final notifications = state.notifications;
                
                return ListView.separated(
                  padding: EdgeInsetsDirectional.only(
                    top: MediaQuery.of(context).padding.top + 24,
                    start: 18,
                    end: 18,
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
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF1976D2), width: 1.1),
                      ),
                      padding: const EdgeInsetsDirectional.only(
                        start: 18,
                        end: 10,
                        top: 18,
                        bottom: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // العنوان
                          Text(
                            notif.title,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 8),
                          
                          // المحتوى
                          Text(
                            notif.body,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF233A5A),
                              fontSize: 15.5,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          
                          // الصورة
                          if (notif.imageUrl != null && notif.imageUrl!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                '${ApiConfig.baseUrl}${notif.imageUrl}',
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ],
                          
                          // رابط الفيديو
                          if (notif.videoUrl != null && notif.videoUrl!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                // يمكن فتح الرابط في المتصفح
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('رابط الفيديو: ${notif.videoUrl}'),
                                    action: SnackBarAction(
                                      label: 'نسخ',
                                      onPressed: () {
                                        // نسخ الرابط للحافظة
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF1976D2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.play_circle_outline, color: Color(0xFF1976D2), size: 24),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        notif.videoUrl!,
                                        style: const TextStyle(
                                          color: Color(0xFF1976D2),
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          
                          // التاريخ والمرسل والنوع
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (notif.createdAt != null)
                                _buildInfoChip(
                                  Icons.access_time,
                                  _formatDate(notif.createdAt!),
                                  Colors.blue,
                                ),
                              if (notif.senderName != null && notif.senderName!.isNotEmpty)
                                _buildInfoChip(
                                  Icons.person,
                                  notif.senderName!,
                                  Colors.green,
                                ),
                              if (notif.type != null && notif.type!.isNotEmpty)
                                _buildInfoChip(
                                  Icons.label,
                                  notif.type!,
                                  Colors.orange,
                                ),
                            ],
                          ),
                        ],
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
        ],
      ),
      // No bottomNavigationBar
    ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        }
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ثابت: بار سفلي متوافق مع المشروع
class MainScreenBottomBar extends StatelessWidget {
  final int selectedIndex;
  const MainScreenBottomBar({super.key, required this.selectedIndex});

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
