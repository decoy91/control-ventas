import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/activation_screen.dart';
import 'firebase_options.dart'; // Generado por FlutterFire CLI

void main() async {
  // Asegura que los bindings de Flutter estén listos antes de inicializar Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Revisa el estado de activación local
  final prefs = await SharedPreferences.getInstance();
  final bool estaActivado = prefs.getBool('activado') ?? false;

  runApp(MyApp(iniciarActivado: estaActivado));
}

class MyApp extends StatelessWidget {
  final bool iniciarActivado;

  const MyApp({super.key, required this.iniciarActivado});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Ventas PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // Estilo global para los botones elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      // Si está activado, va al Home, si no, a la pantalla de activación
      home: iniciarActivado ? const HomeScreen() : const ActivationScreen(),
    );
  }
}