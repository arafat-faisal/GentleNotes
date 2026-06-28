import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app/app.dart';
import 'core/config/flavor_config.dart';
import 'core/services/storage/hive_local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up Flavor
  FlavorConfig(
    flavor: Flavor.prod,
    appName: 'GentleNotes',
  );

  // Initialize Hive and seed default data before launching the app.
  await HiveLocalStorage().init();
  
  // Initialize pdfrx
  await pdfrxFlutterInitialize();
  
  runApp(
    const ProviderScope(
      child: GentleNotesApp(),
    ),
  );
}
