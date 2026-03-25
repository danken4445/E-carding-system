import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takopos/app.dart';
import 'package:takopos/core/config/supabase_config.dart';
import 'package:takopos/core/database/database.dart';
import 'package:takopos/core/services/sync_service.dart';
import 'package:takopos/features/cms/domain/entities/shop_settings.dart';

/// Global database instance
late final AppDatabase database;

/// Global Supabase client
SupabaseClient get supabase => Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (landscape for tablets, any for phones)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Hive for key-value storage (sync queue, settings)
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ShopSettingsAdapter());

  // Initialize local database
  database = AppDatabase();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize and start sync service
  syncServiceProvider.initialize();

  // Perform initial catalog sync to populate local database
  try {
    await syncServiceProvider.syncCatalogFromServer();
  } catch (e) {
    debugPrint('Initial catalog sync failed: $e');
    // Continue anyway - app can work offline with existing data
  }

  // Run the app
  runApp(
    ProviderScope(
      child: const TakoPOSApp(),
    ),
  );
}
