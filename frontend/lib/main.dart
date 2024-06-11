import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontend/firebase_options.dart';

import 'src/home_page.dart';

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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _loading = true);
      await FirebaseAuth.instance.signInAnonymously();
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
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
