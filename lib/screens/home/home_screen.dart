import 'package:flutter/material.dart';
import '../Schedule/schedule_screen.dart';
import '../chat/Chat_screen.dart';
import '../Profile/profile.dart';
import '../pdf/pdf_upload_screen.dart';
import '../attendance/student_attendance_screen.dart';
import '../exam/exam_questions_screen.dart';
import '../tests/quick_tests_screen.dart';
import '../grades/grades_screen.dart';
import '../assignments/assignments_screen.dart';
import '../Conferences/conferences_screen.dart';
import '../../main.dart';
import '../../utils/responsive_helper.dart';
import '../admin notifications/admin_notifications.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

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

  // صفحات البار السفلي
  List<Widget> _buildPages(UserProvider userProvider) {
    final userProfile = userProvider.userProfile;
    final organization = userProvider.organization;
    final profileData = userProfile != null ? ProfileData(
      userId: userProfile.userId,
      userName: userProfile.userName,
      userType: userProfile.userType,
      fullName: userProfile.fullName,
      firstName: userProfile.firstName,
      secondName: userProfile.secondName,
      thirdName: userProfile.thirdName,
      fourthName: userProfile.fourthName,
      phone: userProfile.phone ?? '',
      organizationName: organization?.name,
    ) : ProfileData(
      userId: '',
      userName: '',
      userType: '',
      fullName: 'مستخدم',
      firstName: '',
      secondName: '',
      phone: '',
      organizationName: organization?.name,
    );

    return <Widget>[
      HomeScreenContent(),
      ChatScreen(),
      ScheduleScreen(),
      AdminNotificationsScreen(),
      ProfileScreen(profile: profileData),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // دالة محسنة لبناء عناصر البار السفلي
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _selectedIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? (ResponsiveHelper.isTablet(context) ? 16 : 12) : 8,
            vertical: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1976D2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                padding: EdgeInsets.all(isActive ? (ResponsiveHelper.isTablet(context) ? 8 : 6) : 0),
                child: Icon(
                  icon,
                  size: isActive 
                      ? ResponsiveHelper.getResponsiveIconSize(context, mobile: 28, tablet: 32, desktop: 36)
                      : ResponsiveHelper.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF607D8B),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isActive
                    ? Container(
                        key: ValueKey(label),
                        margin: EdgeInsets.only(top: ResponsiveHelper.isTablet(context) ? 4 : 2),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: const Color(0xFF1976D2),
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 14,
                              desktop: 15,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
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
          body: IndexedStack(
            index: _selectedIndex,
            children: _buildPages(userProvider),
          ),
          bottomNavigationBar: RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.isTablet(context) ? 12 : 8, 
                    horizontal: ResponsiveHelper.isTablet(context) ? 24 : 18
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(0, Icons.home, 'الرئيسية'),
                      _buildNavItem(1, Icons.chat, 'المحادثات'),
                      _buildNavItem(2, Icons.schedule, 'جدول الحصص'),
                      _buildNavItem(3, Icons.campaign, 'التبليغات'),
                      _buildNavItem(4, Icons.person, 'البروفايل'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

  String _getUserTypeInArabic(String userType) {
    switch (userType.toLowerCase()) {
      case 'teacher':
        return 'معلم';
      case 'admin':
        return 'مدير النظام';
      case 'student':
        return 'طالب';
      case 'parent':
        return 'ولي أمر';
      default:
        return userType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final organization = userProvider.organization;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background with blue gradient and transparent squares
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
                          child: organization?.logo != null
                              ? ClipOval(
                                  child: Image.network(
                                    'https://nouraleelemorg.runasp.net${organization!.logo}',
                                    width: ResponsiveHelper.getResponsiveIconSize(
                                      context,
                                      mobile: 130,
                                      tablet: 160,
                                      desktop: 180,
                                    ),
                                    height: ResponsiveHelper.getResponsiveIconSize(
                                      context,
                                      mobile: 130,
                                      tablet: 160,
                                      desktop: 180,
                                    ),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => CircleAvatar(
                                      radius: ResponsiveHelper.getResponsiveIconSize(
                                        context,
                                        mobile: 65,
                                        tablet: 80,
                                        desktop: 90,
                                      ),
                                      backgroundColor: Colors.grey[200],
                                      child: Icon(Icons.school, size: 60, color: Colors.grey[600]),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: ResponsiveHelper.getResponsiveIconSize(
                                    context,
                                    mobile: 65,
                                    tablet: 80,
                                    desktop: 90,
                                  ),
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(Icons.school, size: 60, color: Colors.grey[600]),
                                ),
                        ),
                        SizedBox(height: ResponsiveHelper.isTablet(context) ? 14 : 10),
                        if (organization?.name != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                              organization!.name,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.titleLarge?.color ?? Color(0xFF233A5A),
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  mobile: 22,
                                  tablet: 26,
                                  desktop: 30,
                                ),
                                letterSpacing: 0.1,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        SizedBox(height: ResponsiveHelper.isTablet(context) ? 6 : 4),
                        if (userProvider.userProfile?.userType != null)
                          Text(
                            _getUserTypeInArabic(userProvider.userProfile!.userType),
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                              fontWeight: FontWeight.w500,
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
                                  } else if (card["title"].contains("ارسال اسئله الامتحانيه")) {
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
                                  } else if (card["title"] == "الجلسات التعليمية") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ConferencesScreen()),
                                    );
                                  }
                                },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      height: 220, // Increased height to prevent overflow
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                                        boxShadow: ResponsiveHelper.getResponsiveShadow(context),
                                      ),
                                      margin: EdgeInsets.only(top: 24),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 16.0,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(height: 18), // Space for the icon
                                            Flexible(
                                              child: Text(
                                                card["title"],
                                                style: TextStyle(
                                                  color: Theme.of(context).textTheme.titleMedium?.color ?? Color(0xFF233A5A),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                  height: 1.0,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(height: 20),
                                            Flexible(
                                              child: Text(
                                                card["hint"] ?? '',
                                                style: TextStyle(
                                                  color: Color(0xFFB0BEC5),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.2,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
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
    {
      "title": "الجلسات التعليمية",
      "icon": Icons.video_call,
      "iconColor": Color(0xFFFF5722),
      "iconBg": Color(0xFFFFCCBC),
      "hint": "إدارة المحاضرات الافتراضية",
      "gradient":
          LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF8A65)]),
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
