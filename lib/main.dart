import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/local_db_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/seed_service.dart';

/// ForgeFit entry point.
///
/// Boot sequence (offline-first):
///   1. Initialise Hive local storage.
///   2. Seed the exercise/food/routine catalogues on first launch.
///   3. Initialise local notifications.
///   4. (Optional) initialise Firebase for cloud sync & auth — see
///      `docs/FIREBASE_SETUP.md`. The app runs fully offline if Firebase is
///      not configured.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final db = LocalDbService.instance;
  await db.init();
  await SeedService(db).seedIfNeeded();

  await NotificationService.instance.init();

  // --- Firebase (optional) ---------------------------------------------------
  // Uncomment after running `flutterfire configure` to enable cloud sync/auth:
  //
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //
  // The repositories are designed so a FirestoreSyncService can mirror the
  // local Hive boxes without touching the UI. See docs/ARCHITECTURE.md.

  runApp(const ProviderScope(child: ForgeFitApp()));
}
