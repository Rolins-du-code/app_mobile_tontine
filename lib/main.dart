import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/login_screen.dart';
import 'package:mon_amical/firebase_options.dart';

void main() {
  runApp(const MonAmicaleApp());
}

class MonAmicaleApp extends StatefulWidget {
  const MonAmicaleApp({super.key});

  @override
  State<MonAmicaleApp> createState() => _MonAmicaleAppState();
}

class _MonAmicaleAppState extends State<MonAmicaleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonAmical',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context)  => const SplashScreen(),
        // on ajoutera /light, /register , hub etc. au fure et a mesure 
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
