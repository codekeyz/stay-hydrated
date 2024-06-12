import 'dart:async';
import 'dart:io';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:dart_firebase_admin/messaging.dart';
import 'package:server/firebase_admin.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final app = Router()..post('/tasks/notify-water-intake', _notifyWaterIntake);

FutureOr<Response> _notifyWaterIntake(Request request) async {
  final threeDaysAgo = DateTime.timestamp().subtract(const Duration(days: 3));

  // Get only users who opened app within last 3 days
  final userQuery = await userCollection
      .where(
        'updated_at',
        WhereFilter.greaterThanOrEqual,
        threeDaysAgo.toIso8601String(),
      )
      .orderBy('updated_at')
      .get();
  final userDocs = userQuery.docs;
  if (userDocs.isEmpty) {
    return Response.ok('Nothing to do here');
  }

  final users =
      userDocs.map((e) => {...e.data(), 'id': e.id}).toList(growable: false);

  final pendingMessages = <TokenMessage>[];

  /// For each of these users, check their last water intake and notify
  /// where necessary.
  for (final user in users) {
    final result = await waterIntakeCollection
        .where('user_uid', WhereFilter.equal, user['id'])
        .orderBy('timestamp')
        .limitToLast(1)
        .get();
    if (result.docs.isEmpty) continue;

    final lastIntakeDate =
        DateTime.parse(result.docs.first.data()['timestamp'].toString());

    final nextIntakeDue =
        DateTime.timestamp().difference(lastIntakeDate).inHours >= 2;
    if (!nextIntakeDue) continue;

    final message = TokenMessage(
      token: user['fcm_token'].toString(),
      notification: Notification(
        title: 'Drink water 💦',
        body: "It's time to drink water again 🥛, stay hydrated",
      ),
    );
    pendingMessages.add(message);
  }

  if (pendingMessages.isEmpty) {
    return Response.ok('Nothing to do here');
  }

  // Send messages
  await messaging.sendEach(pendingMessages);

  return Response.ok('${pendingMessages.length} messages sent');
}

void main(List<String> args) async {
  initFirebase();

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(app.call);

  final port = int.parse(env['PORT'] ?? '3000');

  await io.serve(handler, InternetAddress.anyIPv4, port);

  print('Server running on PORT: $port');
}
