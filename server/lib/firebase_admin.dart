import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:dart_firebase_admin/messaging.dart';
import 'package:dotenv/dotenv.dart';

final env = DotEnv(includePlatformEnvironment: true)..load();

final userCollection = firestore.collection('users');
final waterIntakeCollection = firestore.collection('water_intakes');

late Firestore firestore;
late Messaging messaging;

void initFirebase() {
  final cred = Credential.fromApplicationDefaultCredentials();

  // ignore: invalid_use_of_internal_member
  if (cred.serviceAccountCredentials == null) {
    throw Exception(
      'Please provide GOOGLE_APPLICATION_CREDENTIALS variable in environment.',
    );
  }

  final projectId = env['FIREBASE_PROJECT_ID'];
  if (projectId == null) {
    throw Exception('Please provide FIREBASE_PROJECT_ID in environment');
  }

  final admin = FirebaseAdminApp.initializeApp(projectId, cred);

  firestore = Firestore(admin);
  messaging = Messaging(admin);
}
