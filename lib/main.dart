import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/auth/sign_in.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/models/grade_components.dart';
import 'providers/user_provider.dart';
import 'di/injector.dart';
import 'logic/blocs/auth/auth_bloc.dart';
import 'logic/blocs/auth/auth_event.dart';
import 'logic/blocs/auth/auth_state.dart';
import 'logic/blocs/profile/profile_bloc.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/services/auth_service.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // معالجة جميع الأخطاء غير المعالجة في Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('⚠️ Flutter Error Caught:');
    debugPrint('${details.exception}');
    debugPrint('Stack: ${details.stack}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    // لا نوقف التطبيق - فقط نسجل الخطأ
  };

  // معالجة الأخطاء في Platform (للأخطاء خارج Flutter framework)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('⚠️ Platform Error Caught:');
    debugPrint('Error: $error');
    debugPrint('Stack: $stack');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return true; // نعيد true لمنع crash التطبيق
  };

  // معالجة الأخطاء في async zones
  runZonedGuarded(() async {
    await initializeDateFormatting('ar', null);
    setupDependencies();

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚀 Notika Teacher App Starting...');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // التحقق الشامل من البيانات المحفوظة
    final isValidAuth = await AuthService.validateSavedAuth();
    debugPrint('📊 Auth validation result: ${isValidAuth ? "VALID ✓" : "INVALID ✗"}');
    
    if (isValidAuth) {
      // تحميل organization URL للمستخدم المسجل
      await AuthService.loadSavedOrganizationUrl();
      debugPrint('✅ Restoring user session...');
    } else {
      // مسح أي organization URL قديم
      ApiConfig.resetBaseUrl();
      debugPrint('⚠️ No valid session - showing login screen');
    }

    debugPrint('🎯 AuthBloc will be initialized by BlocProvider');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    runApp(const MyApp());
  }, (error, stackTrace) {
    // معالجة الأخطاء التي تحدث في async operations
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('⚠️ Async Error Caught:');
    debugPrint('Error: $error');
    debugPrint('Stack: $stackTrace');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    // لا نوقف التطبيق - فقط نسجل الخطأ
  });
}

class MyApp extends StatelessWidget {
  // ValueNotifier لإدارة الثيم
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GradeComponents()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUserData()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(
            value: sl<AuthBloc>(),
          ),
          BlocProvider<ProfileBloc>.value(
            value: sl<ProfileBloc>(),
          ),
        ],
        child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Notika Teacher',
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('ar', 'SA'),
            const Locale('en', 'US'),
          ],
          locale: const Locale('ar', 'SA'),
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Color(0xFFF5F7FA),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF1976D2),
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            cardColor: Colors.white,
            canvasColor: Color(0xFFF5F7FA),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF233A5A)),
              bodyMedium: TextStyle(color: Color(0xFF233A5A)),
              titleLarge: TextStyle(color: Color(0xFF233A5A)),
              titleMedium: TextStyle(color: Color(0xFF233A5A)),
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Color(0xFF0A0E21),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF1A1F35),
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            cardColor: Color(0xFF1A1F35),
            canvasColor: Color(0xFF0A0E21),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
              titleLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
            ),
            dividerColor: Color(0xFF2A2F45),
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF1976D2),
              secondary: Color(0xFF64B5F6),
              surface: Color(0xFF1A1F35),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: Color(0xFF1A1F35)),
          ),
          themeMode: currentMode,
          home: AuthInitializer(),
          routes: {
            '/home': (context) => MainScreen(),
          },
        );
      },
    ),
      ),
    );
  }
}

class AuthInitializer extends StatefulWidget {
  const AuthInitializer({super.key});

  @override
  State<AuthInitializer> createState() => _AuthInitializerState();
}

class _AuthInitializerState extends State<AuthInitializer> {
  @override
  void initState() {
    super.initState();
    // إرسال حدث فحص المصادقة المحفوظة بعد إعداد BlocProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const CheckSavedAuth());
      debugPrint('🎯 CheckSavedAuth event dispatched');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        debugPrint('🎨 Building AuthInitializer - State: ${state.runtimeType}');

        if (state is AuthLoading) {
          // Show splash screen while checking authentication
          debugPrint('⏳ AuthLoading - Showing splash screen');
          return const SplashScreen();
        } else if (state is AuthSuccess) {
          // User is logged in, go to main screen
          debugPrint('✅ AuthSuccess - Going to MainScreen');
          return MainScreen();
        } else {
          // User is not logged in, show sign in screen
          debugPrint('⚠️ AuthInitial/AuthFailure - Showing SignInScreen');
          return SignInScreen();
        }
      },
    );
  }
}
