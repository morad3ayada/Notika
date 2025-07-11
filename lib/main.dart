import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // ValueNotifier لإدارة الثيم
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Notika Teacher',
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
            dialogBackgroundColor: Colors.white,
            canvasColor: Color(0xFFF5F7FA),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF233A5A)),
              bodyMedium: TextStyle(color: Color(0xFF233A5A)),
              titleLarge: TextStyle(color: Color(0xFF233A5A)),
              titleMedium: TextStyle(color: Color(0xFF233A5A)),
            ),
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
            dialogBackgroundColor: Color(0xFF1A1F35),
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
              background: Color(0xFF0A0E21),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.white,
              onBackground: Colors.white,
            ),
          ),
          themeMode: currentMode,
          home: SignInScreen(),
          routes: {
            '/home': (context) => MainScreen(),
          },
        );
      },
    );
  }
}
