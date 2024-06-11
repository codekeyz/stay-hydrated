import 'package:server/firebase_admin.dart';
import 'package:server/router.dart';

void main(List<String> args) async {
  initFirebase();

  if (kReleaseMode) {
    app.onError((_, req, res) => res.internalServerError('An error occurred'));
  }

  final port = int.parse(env['PORT'] ?? '3000');

  await app.listen(port: port);
}
