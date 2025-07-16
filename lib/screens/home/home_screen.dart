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
import '../../utils/responsive_helper.dart';

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
        preferredSize: Size.fromHeight(ResponsiveHelper.isTablet(context) ? 100 : 80),
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
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.isTablet(context) ? 24.0 : 18.0, 
                vertical: ResponsiveHelper.isTablet(context) ? 12 : 8
              ),
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
                    padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 8 : 6),
                    child: Image.asset(
                      'assets/notika_logo.png', 
                      height: ResponsiveHelper.isTablet(context) ? 48 : 38
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.isTablet(context) ? 18 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "مؤسسة نوتيكا التعليمية",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 18,
                              tablet: 22,
                              desktop: 24,
                            ),
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          "ابتدائية - ثانوية بنين - ثانوية بنات",
                          style: TextStyle(
                            color: Color(0xFFB0BEC5),
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 11,
                              tablet: 13,
                              desktop: 14,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  // أيقونة جانبية (إشعارات أو إعدادات)
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: Colors.white, 
                      size: ResponsiveHelper.getResponsiveIconSize(
                        context,
                        mobile: 28,
                        tablet: 32,
                        desktop: 36,
                      ),
                    ),
                    onPressed: () {},
                  ),
                  // زر تبديل الوضع الليلي
                  IconButton(
                    icon: Icon(
                      MyApp.themeNotifier.value == ThemeMode.dark
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_round,
                      color: Colors.white,
                      size: ResponsiveHelper.getResponsiveIconSize(
                        context,
                        mobile: 26,
                        tablet: 30,
                        desktop: 34,
                      ),
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
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.isTablet(context) ? 14 : 10, 
                  horizontal: ResponsiveHelper.isTablet(context) ? 24 : 18
                ),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: isActive ? (ResponsiveHelper.isTablet(context) ? 20 : 16) : 0
                        ),
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
                              padding: EdgeInsets.all(isActive ? (ResponsiveHelper.isTablet(context) ? 10 : 8) : 0),
                              child: Icon(
                                icons[index],
                                size: isActive 
                                    ? ResponsiveHelper.getResponsiveIconSize(context, mobile: 30, tablet: 34, desktop: 38)
                                    : ResponsiveHelper.getResponsiveIconSize(context, mobile: 26, tablet: 30, desktop: 34),
                                color: isActive
                                    ? Color(0xFF1976D2)
                                    : Color(0xFF607D8B),
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.isTablet(context) ? 4 : 2),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isActive
                                  ? Text(
                                      labels[index],
                                      key: ValueKey(labels[index]),
                                      style: TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                                          context,
                                          mobile: 13,
                                          tablet: 15,
                                          desktop: 16,
                                        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
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
                  SizedBox(height: ResponsiveHelper.isTablet(context) ? 130 : 110),
                  // صورة دائرية عصرية مع ظل وحد أبيض
                  Center(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF1976D2), 
                              width: ResponsiveHelper.isTablet(context) ? 4 : 3
                            ),
                            color: Theme.of(context).cardColor,
                          ),
                          child: CircleAvatar(
                            radius: ResponsiveHelper.getResponsiveIconSize(
                              context,
                              mobile: 65,
                              tablet: 80,
                              desktop: 90,
                            ),
                            backgroundColor: Colors.transparent,
                            backgroundImage: AssetImage('assets/ALAnamel.jpg'),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.isTablet(context) ? 14 : 10),
                        Text(
                          'مدارس الانامل الواعدة الاهلية',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleLarge?.color ?? Color(0xFF233A5A),
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 24,
                              tablet: 28,
                              desktop: 32,
                            ),
                            letterSpacing: 0.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: ResponsiveHelper.isTablet(context) ? 6 : 4),
                        Text(
                          'ترخيص إدارة مالية ',
                          style: TextStyle(
                            color: Color(0xFFB0BEC5),
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 15,
                              tablet: 17,
                              desktop: 18,
                            ),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.isTablet(context) ? 8 : 4),
                  // كروت الإجراءات
                  Padding(
                    padding: EdgeInsets.only(
                      top: 0.0, 
                      bottom: ResponsiveHelper.isTablet(context) ? 32.0 : 24.0, 
                      left: ResponsiveHelper.isTablet(context) ? 16 : 12, 
                      right: ResponsiveHelper.isTablet(context) ? 16 : 12
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: HomePageContent.cardsData.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
                            crossAxisSpacing: ResponsiveHelper.getGridSpacing(context),
                            mainAxisSpacing: ResponsiveHelper.getGridSpacing(context),
                            childAspectRatio: ResponsiveHelper.getGridChildAspectRatio(context),
                          ),
                          itemBuilder: (context, index) {
                            final card = HomePageContent.cardsData[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
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
                                  } else if (card["title"] == "ارسال اسئله الامتحانيه الخاصه بالطلبة") {
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
                                        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                                        boxShadow: ResponsiveHelper.getResponsiveShadow(context),
                                      ),
                                      margin: EdgeInsets.only(top: ResponsiveHelper.isTablet(context) ? 36 : 28),
                                      padding: EdgeInsets.only(
                                        top: ResponsiveHelper.isTablet(context) ? 40 : 32, 
                                        left: ResponsiveHelper.isTablet(context) ? 8 : 6, 
                                        right: ResponsiveHelper.isTablet(context) ? 8 : 6, 
                                        bottom: ResponsiveHelper.isTablet(context) ? 12 : 8
                                      ),
                                      child: SingleChildScrollView(
                                        physics: NeverScrollableScrollPhysics(),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              card["title"],
                                              style: TextStyle(
                                                color: Theme.of(context).textTheme.titleMedium?.color ?? Color(0xFF233A5A),
                                                fontWeight: FontWeight.bold,
                                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                                  context,
                                                  mobile: 15.5,
                                                  tablet: 17.5,
                                                  desktop: 19,
                                                ),
                                                letterSpacing: 0.1,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: ResponsiveHelper.isTablet(context) ? 6 : 4),
                                            Text(
                                              card["hint"] ?? '',
                                              style: TextStyle(
                                                color: Color(0xFFB0BEC5),
                                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                                  context,
                                                  mobile: 12.5,
                                                  tablet: 14.5,
                                                  desktop: 15,
                                                ),
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
                                          width: ResponsiveHelper.getResponsiveIconSize(
                                            context,
                                            mobile: 54,
                                            tablet: 68,
                                            desktop: 72,
                                          ),
                                          height: ResponsiveHelper.getResponsiveIconSize(
                                            context,
                                            mobile: 54,
                                            tablet: 68,
                                            desktop: 72,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (card["iconBg"] ?? Colors.white)
                                                .withOpacity(0.18),
                                            border: Border.all(
                                              color: Colors.white, 
                                              width: ResponsiveHelper.isTablet(context) ? 3 : 2
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (card["iconBg"] ?? Colors.blue)
                                                    .withOpacity(0.18),
                                                blurRadius: ResponsiveHelper.isTablet(context) ? 12 : 8,
                                                offset: Offset(0, ResponsiveHelper.isTablet(context) ? 4 : 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              card["icon"],
                                              color: card["iconColor"] ?? Color(0xFF1976D2),
                                              size: ResponsiveHelper.getResponsiveIconSize(
                                                context,
                                                mobile: 30,
                                                tablet: 36,
                                                desktop: 40,
                                              ),
                                            ),
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
      "title": "ارسال اسئله الامتحانيه ",
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
