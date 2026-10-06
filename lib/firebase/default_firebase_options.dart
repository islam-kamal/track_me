import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import '../firebase_options.dart' as generated;

/// App-facing Firebase options.
///
/// Values come from `lib/firebase_options.dart`, which `flutterfire configure`
/// writes for project track-me-8e64a. [databaseURL] on those options, when
/// present, is the default database. Location data uses [trackingDatabaseUrl].
class DefaultFirebaseOptions {
  static bool get isConfigured {
    final projectId = generated.DefaultFirebaseOptions.android.projectId;
    final apiKey = generated.DefaultFirebaseOptions.android.apiKey;
    return projectId.isNotEmpty &&
        !projectId.startsWith('YOUR_') &&
        apiKey.isNotEmpty &&
        !apiKey.startsWith('YOUR_');
  }

  static FirebaseOptions get currentPlatform =>
      generated.DefaultFirebaseOptions.currentPlatform;
}
