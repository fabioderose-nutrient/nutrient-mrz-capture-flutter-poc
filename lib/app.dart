import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class MrzCaptureApp extends StatelessWidget {
  const MrzCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MRZ Capture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
