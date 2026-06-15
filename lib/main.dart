import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/local_db_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/seed_service.dart';

/// ForgeFit entry point.
Future<void> main() async {
  await runZonedGuarded(_boot, (error, stack) {
    runApp(_ErrorApp('$error\n\n$stack'));
  });
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final db = LocalDbService.instance;
  await db.init();
  await SeedService(db).seedIfNeeded();

  await NotificationService.instance.init();

  runApp(const ProviderScope(child: ForgeFitApp()));
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              'ForgeFit startup error:\n\n$message',
              style: const TextStyle(
                  color: Colors.red, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  }
}
