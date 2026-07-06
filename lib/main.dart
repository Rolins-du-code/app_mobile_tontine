import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/hub/create_tontine_screen.dart';


void main() async {
  // ce bout de code est necessaire avant tout appel asynchrone au demarrage de l'application
  WidgetsFlutterBinding.ensureInitialized();
  // connecte l'app au projet firebase configure par flutterFire CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MonAmicaleApp());
}

class MonAmicaleApp extends StatefulWidget {
  const MonAmicaleApp({super.key});

  @override
  State<MonAmicaleApp> createState() => _MonAmicaleAppState();
}

class _MonAmicaleAppState extends State<MonAmicaleApp> {
  final ThemeMode _themeMode = ThemeMode.light;

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
        '/register': (context) =>  RegisterScreen(),
        // route provisoir 
        '/hub': (context) => const Scaffold(
          body: Center(child: Text('Hub membre - Bientot'),),
        ),
        '/bureau': (context) => const CreateTontineScreen(),
      },
    );
  }
}
