import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize date formatting for Indonesian locale
      await initializeDateFormatting('id_ID', null);

      // Catch synchronous Flutter framework errors
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (kReleaseMode) {
          // In production: log to crash reporting service (e.g., Firebase Crashlytics)
          debugPrint('FlutterError: ${details.exceptionAsString()}');
        }
      };

      // Catch uncaught async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Uncaught async error: $error\n$stack');
        return true; // Prevent app crash
      };

      runApp(const ProviderScope(child: ApoTrackApp()));
    },
    (error, stack) {
      debugPrint('Unhandled zone error: $error\n$stack');
    },
  );
}

class ApoTrackApp extends ConsumerWidget {
  const ApoTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(AppRouter.routerProvider);

    return MaterialApp.router(
      title: 'ApoTrack',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
    );
  }
}
