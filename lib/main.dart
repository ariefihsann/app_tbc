import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Tambahkan ini

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TBChecker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Semua Scaffold akan otomatis berwarna putih
      ),
      home: const LoginScreen(),
    );
  }
}