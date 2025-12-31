import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Ventas',
      debugShowCheckedModeBanner: false,
      // Inyectamos el tema global que definimos
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}