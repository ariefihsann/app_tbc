import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/screens/login_screen.dart';
import 'package:app_tbc/core/services/notification_service.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (wajib, tapi cepat)
  await Supabase.initialize(
    url: 'https://qsbfmwpmufranowatdba.supabase.co',
    anonKey: 'sb_publishable_9E9t3ZRaNGwRnpajy0chjA_iLFSSbc7',
  );
  
  // Initialize Notification Service (jalan di background)
  // Jangan di-await biar tidak ngeblock
  NotificationService().init();
  
  // Langsung run app tanpa nunggu notification service selesai
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TB Checker',
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: const OnboardingScreen(), // Langsung ke onboarding
    );
  }
}