import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/firebase_options.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User get user => FirebaseAuth.instance.currentUser!;

  bool _loading = false;

  void logWaterIntake() async {
    setState(() => _loading = true);

    await waterIntakeCollection.add({
      "timestamp": DateTime.timestamp().toIso8601String(),
      "user_uid": user.uid,
    });

    setState(() => _loading = false);
  }

  Future<DateTime?> get lastIntake async {
    final result = await waterIntakeCollection
        .where('user_uid', isEqualTo: user.uid)
        .orderBy('timestamp')
        .limitToLast(1)
        .get();

    final docs = result.docs;
    if (docs.isEmpty) return null;

    return DateTime.parse(docs.first.data()['timestamp']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<DateTime?>(
            future: lastIntake,
            builder: (context, snapshot) {
              if (_loading ||
                  snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              final lastWaterIntake = snapshot.data;
              final timeSinceLastIntake = lastWaterIntake == null
                  ? null
                  : DateTime.now().difference(lastWaterIntake).inHours;

              final shouldLogIntake =
                  timeSinceLastIntake != null && timeSinceLastIntake >= 2;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!shouldLogIntake && lastWaterIntake != null) ...[
                    Text.rich(
                      TextSpan(
                        text: 'Last Intake:',
                        children: [
                          TextSpan(text: timeago.format(lastWaterIntake))
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'You are doing well\nYou will be notified for your next intake.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ] else
                    OutlinedButton(
                      onPressed: logWaterIntake,
                      child: const Text(
                        'Log Water Intake',
                        style: TextStyle(fontSize: 15),
                      ),
                    )
                ],
              );
            }),
      ),
    );
  }
}
