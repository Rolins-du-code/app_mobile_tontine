import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mon_amical/features/onboarding/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'core/theme_provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/hub/hub_screen.dart';

void main() async {
  // ce bout de code est necessaire avant tout appel asynchrone au demarrage de l'application
  WidgetsFlutterBinding.ensureInitialized();
  // connecte l'app au projet firebase configure par flutterFire CLI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MonAmicaleApp(),
    ),
  );
}

class MonAmicaleApp extends StatefulWidget {
  const MonAmicaleApp({super.key});

  @override
  State<MonAmicaleApp> createState() => _MonAmicaleAppState();
}

class _MonAmicaleAppState extends State<MonAmicaleApp> {
  @override
  Widget build(BuildContext context) {
    // Écoute les changements de thème
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'MonAmicale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.mode, // ← dynamique
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/hub': (context) => const HubScreen(),
        '/bureau': (context) => const HubScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}
