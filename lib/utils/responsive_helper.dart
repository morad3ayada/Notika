import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // أحجام الخطوط المتجاوبة
  static double getResponsiveFontSize(BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // أحجام الأيقونات المتجاوبة
  static double getResponsiveIconSize(BuildContext context, {
    double mobile = 24,
    double tablet = 28,
    double desktop = 32,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // المسافات المتجاوبة
  static EdgeInsets getResponsivePadding(BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    mobile ??= const EdgeInsets.all(16);
    tablet ??= const EdgeInsets.all(20);
    desktop ??= const EdgeInsets.all(24);

    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // عدد الأعمدة في الشبكة
  static int getGridCrossAxisCount(BuildContext context) {
    if (isLargeDesktop(context)) return 4;
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 3; // Mobile
  }

  // نسبة العرض إلى الارتفاع للكروت
  static double getGridChildAspectRatio(BuildContext context) {
    if (isLargeDesktop(context)) return 0.85;
    if (isDesktop(context)) return 0.80;
    if (isTablet(context)) return 0.75;
    return 0.78; // Mobile
  }

  // المسافات بين العناصر في الشبكة
  static double getGridSpacing(BuildContext context) {
    if (isDesktop(context)) return 16;
    if (isTablet(context)) return 14;
    return 12; // Mobile
  }

  // أحجام الحدود
  static double getBorderRadius(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    return 16; // Mobile
  }

  // أحجام الظلال
  static List<BoxShadow> getResponsiveShadow(BuildContext context) {
    double blurRadius = isDesktop(context) ? 16 : (isTablet(context) ? 12 : 8);
    double offset = isDesktop(context) ? 6 : (isTablet(context) ? 4 : 2);
    
    return [
      BoxShadow(
        color: Colors.black12,
        blurRadius: blurRadius,
        offset: Offset(0, offset),
      ),
    ];
  }
}

// كلاس مساعد للتصميم المتجاوب
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveHelper.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

// كلاس مساعد للتصميم المتجاوب مع Builder
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;

  const ResponsiveLayoutBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      ResponsiveHelper.isMobile(context),
      ResponsiveHelper.isTablet(context),
      ResponsiveHelper.isDesktop(context),
    );
  }
} 