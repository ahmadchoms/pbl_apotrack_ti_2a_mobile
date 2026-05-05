import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const ApoTrackApp());
}

class ApoTrackApp extends StatelessWidget {
  const ApoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ApoTrack Staff',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D70F5),
          primary: const Color(0xFF1D70F5),
          surface: Colors.white,
          background: const Color(0xFFF9FAFB),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
    );
  }
}
