import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/firebase_options.dart';

import 'src/home_page.dart';
import 'src/login_page.dart';

const apiUrl = !kReleaseMode
    ? 'http://localhost:3000'
    : 'https://your-project.globeapp.dev';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey();
  bool _loading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      init();
    });
  }

  void init() async {
    setState(() => _loading = true);

    final user = await FirebaseAuth.instance.signInAnonymously();
    _currentUser = user.user;

    setState(() => _loading = false);

    if (_currentUser == null) {
      _navigator.currentState!.pushNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (_) => const HomePage(),
        '/login': (_) => const LoginPage(),
      },
      builder: (_, child) {
        if (_loading) {
          return Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: const SizedBox(child: CircularProgressIndicator()),
          );
        }
        return child!;
      },
    );
  }
}
