import 'package:flutter/material.dart';
import 'features/auth/presentation/pages/splash_page.dart';

class RuvimboApp extends StatelessWidget {
  const RuvimboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ruvimbo Motherhood',
      theme: ThemeData(
        colorSchemeSeed: Colors.pink,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const SplashPage(),
    );
  }
}