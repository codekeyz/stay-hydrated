// Configure routes.
import 'dart:async';

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pharaoh/pharaoh.dart';
import 'package:server/firebase_admin.dart';

Middleware _authMiddleware = (req, res, next) async {
  final userMap = JwtDecoder.decode(req.headers['FIREBASE_TOKEN']);
  req.auth = await firebaseAuth.getUser(userMap['uid']);
  next(req);
};

final _tasksRouter = Pharaoh.router
  ..post('/notify-water-intake', (req, res) {
    return res.ok('Hello World');
  });

final app = Pharaoh()
  ..group('/tasks', _tasksRouter)
  ..use(_authMiddleware)
  ..post('/log-intake', _logWaterIntake);

FutureOr<Response> _logWaterIntake(Request request, Response res) {
  final message = request.params['message'];
  return res.ok('$message\n');
}
