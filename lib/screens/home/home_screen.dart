import 'package:flutter/material.dart';
import '../Schedule/schedule_screen.dart';
import 'dart:ui';
import '../chat/Chat_screen.dart';
import '../Profile/profile.dart';
import '../pdf/pdf_upload_screen.dart';
import '../attendance/student_attendance_screen.dart';
import '../exam/exam_questions_screen.dart';
import '../tests/quick_tests_screen.dart';
import '../grades/grades_screen.dart';
import '../assignments/assignments_screen.dart';
import '../../main.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // صفحات البار السفلي (يمكنك استبدالها لاحقًا بصفحات حقيقية)
  static final List<Widget> _pages = <Widget>[
    HomeScreenContent(),
    ChatScreen(),
    ScheduleScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF233A5A), Color(0xFF1976D2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
              child: Row(
                children: [
                  // شعار في دائرة بيضاء مع ظل
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/notika_logo.png', height: 38),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "مؤسسة نوتيكا التعليمية",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 1),
                        Text(
                          "ابتدائية - ثانوية بنين - ثانوية بنات",
                          style: TextStyle(
                            color: Color(0xFFB0BEC5),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  // أيقونة جانبية (إشعارات أو إعدادات)
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white, size: 28),
                    onPressed: () {},
                  ),
                  // زر تبديل الوضع الليلي
                  IconButton(
                    icon: Icon(
                      MyApp.themeNotifier.value == ThemeMode.dark
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_round,
                      color: Colors.white,
                      size: 26,
                    ),
                    tooltip: MyApp.themeNotifier.value == ThemeMode.dark ? 'وضع النهار' : 'وضع الليل',
                    onPressed: () {
                      MyApp.themeNotifier.value =
                          MyApp.themeNotifier.value == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
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
              color: Theme.of(context).cardColor.withValues(alpha: 0.75),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    final icons = [
                      Icons.home,
                      Icons.chat,
                      Icons.schedule,
                      Icons.person,
                    ];
                    final labels = [
                      'الرئيسية',
                      'المحادثات',
                      'جدول الحصص',
                      'البروفايل',
                    ];
                    final isActive = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () => _onItemTapped(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding:
                            EdgeInsets.symmetric(horizontal: isActive ? 16 : 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.transparent,
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
                                color: isActive
                                    ? Color(0xFF1976D2)
                                    : Color(0xFF607D8B),
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
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color gridColor;
  
  _GridPainter({required this.gridColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withAlpha(16)
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

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // خلفية بتدرج أزرق ومربعات شفافة
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        CustomPaint(
          size: Size.infinite,
          painter: _MeshBackgroundPainter(),
        ),
        // مربعات شفافة (grid overlay)
        CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(gridColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        ),
        // محتوى الصفحة
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 110),
              // صورة دائرية عصرية مع ظل وحد أبيض
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFF1976D2), width: 3),
                        color: Theme.of(context).cardColor,
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.transparent,
                        backgroundImage: AssetImage('assets/ALAnamel.jpg'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'مدارس الانامل الواعدة الاهلية',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color ?? Color(0xFF233A5A),
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        letterSpacing: 0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ترخيص إدارة مالية ',
                      style: TextStyle(
                        color: Color(0xFFB0BEC5),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // كروت الإجراءات
              Padding(
                padding: const EdgeInsets.only(
                    top: 0.0, bottom: 24.0, left: 12, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: HomePageContent.cardsData.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, index) {
                        final card = HomePageContent.cardsData[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              if (card["title"] == "رفع الملفات") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PdfUploadScreen()),
                                );
                              } else if (card["title"] == "حضور الطلاب") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
                                );
                              } else if (card["title"] == "إرسال أسئلة امتحانات") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ExamQuestionsScreen()),
                                );
                              } else if (card["title"] == "اختبارات قصيرة تفاعلية") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => QuickTestsScreen()),
                                );
                              } else if (card["title"] == "إدخال الدرجات") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => GradesScreen()),
                                );
                              } else if (card["title"] == "تحديد الواجبات") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AssignmentsScreen()),
                                );
                              }
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
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
                                  margin: const EdgeInsets.only(top: 28),
                                  padding: const EdgeInsets.only(
                                      top: 32, left: 6, right: 6, bottom: 8),
                                  child: SingleChildScrollView(
                                    physics: NeverScrollableScrollPhysics(),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          card["title"],
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.titleMedium?.color ?? Color(0xFF233A5A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15.5,
                                            letterSpacing: 0.1,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          card["hint"] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFFB0BEC5),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (card["iconBg"] ?? Colors.white)
                                            .withOpacity(0.18),
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (card["iconBg"] ?? Colors.blue)
                                                    .withOpacity(0.18),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(card["icon"],
                                            color: card["iconColor"] ??
                                                Color(0xFF1976D2),
                                            size: 30),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomePageContent {
  static final List<Map<String, dynamic>> cardsData = [
    {
      "title": "حضور الطلاب",
      "icon": Icons.how_to_reg,
      "iconColor": Color(0xFF1976D2),
      "iconBg": Color(0xFF64B5F6),
      "hint": "تسجيل الحضور اليومي",
      "gradient":
          LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF64B5F6)]),
    },
    {
      "title": "تحديد الواجبات",
      "icon": Icons.assignment,
      "iconColor": Color(0xFF1A237E),
      "iconBg": Color(0xFF7986CB),
      "hint": "إضافة أو تعديل الواجب",
      "gradient":
          LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF7986CB)]),
    },
    {
      "title": "إدخال الدرجات",
      "icon": Icons.grade,
      "iconColor": Color(0xFF43A047),
      "iconBg": Color(0xFFB2FF59),
      "hint": "تقييم الطلاب بسهولة",
      "gradient":
          LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF43A047)]),
    },
    {
      "title": "رفع الملفات",
      "icon": Icons.upload_file,
      "iconColor": Color(0xFF00BCD4),
      "iconBg": Color(0xFFB2EBF2),
      "hint": "مشاركة ملفات مع الطلاب",
      "gradient":
          LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF00BCD4)]),
    },
    {
      "title": "اختبارات قصيرة تفاعلية",
      "icon": Icons.quiz,
      "iconColor": Color(0xFFFFC107),
      "iconBg": Color(0xFFFFF9C4),
      "hint": "إنشاء اختبارات سريعة",
      "gradient":
          LinearGradient(colors: [Color(0xFF1976D2), Color(0xFFFFC107)]),
    },
    {
      "title": "إرسال أسئلة امتحانات",
      "icon": Icons.send,
      "iconColor": Color(0xFFE040FB),
      "iconBg": Color(0xFFF3E5F5),
      "hint": "مراسلة الطلاب بالأسئلة",
      "gradient":
          LinearGradient(colors: [Color(0xFF1A237E), Color(0xFFE040FB)]),
    },
  ];
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
    // خطوط عشوائية
    for (double y = 40; y < size.height; y += 120) {
      for (double x = 0; x < size.width; x += 180) {
        canvas.drawLine(Offset(x, y), Offset(x + 120, y + 40), paintLine);
        canvas.drawLine(Offset(x + 60, y + 80), Offset(x + 180, y), paintLine);
      }
    }
    // نقاط عشوائية
    for (double y = 30; y < size.height; y += 100) {
      for (double x = 20; x < size.width; x += 140) {
        canvas.drawCircle(Offset(x, y), 3, paintDot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
