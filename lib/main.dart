import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
// Uses the new HiveLocalStorage from core/services — the ILocalStorage interface
// allows swapping to a different backend (e.g., Drift, cloud) in the future.
import 'core/services/storage/hive_local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive and seed default data before launching the app.
  await HiveLocalStorage().init();
  runApp(
    const ProviderScope(
      child: GentleNotesApp(),
    ),
  );
}
