import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/firebase_options.dart';

import 'src/home_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await setupNotifications();

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
      init();
    });
  }

  void init() async {
    setState(() => _loading = true);

    // Request notification permissions
    final result = await FirebaseMessaging.instance.requestPermission();
    if (result.authorizationStatus != AuthorizationStatus.authorized) {
      exit(0);
    }

    // Ensure we're authenticated
    var user = FirebaseAuth.instance.currentUser;
    user ??= (await FirebaseAuth.instance.signInAnonymously()).user;

    // Get messaging token & update user data
    final token = await FirebaseMessaging.instance.getToken();
    await userCollection.doc(user!.uid).set({
      'fcm_token': token,
      'updated_at': DateTime.timestamp().toIso8601String(),
    });

    setState(() => _loading = false);
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

Future<void> setupNotifications() async {
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // Required to display a heads up notification
    badge: true,
    sound: true,
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null || android == null) return;

    // If `onMessage` is triggered with a notification, construct our own
    // local notification to show to users using the created channel.
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: "ic_launcher",
        ),
      ),
    );
  });
}
