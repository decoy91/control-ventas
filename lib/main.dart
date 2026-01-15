import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Importaciones necesarias para la validación de huella
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

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
  bool estaActivado = prefs.getBool('activado') ?? false;
  final String? codigoLicenciaDocId = prefs.getString('codigo_licencia');

  // --- LÓGICA DE VERIFICACIÓN DE HUELLA DIGITAL ---
  if (estaActivado && codigoLicenciaDocId != null) {
    try {
      // 1. Generar la huella actual del dispositivo
      String currentFingerprint = await _obtenerHuellaServicio();

      // 2. Consultar en Firebase si la huella coincide
      final doc = await FirebaseFirestore.instance
          .collection('licencias')
          .doc(codigoLicenciaDocId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final String? registradoId = data?['device_id'];

        // Si la huella no coincide, invalidamos el acceso
        if (registradoId != currentFingerprint) {
          estaActivado = false;
          await prefs.setBool('activado', false);
        }
      } else {
        // Si el documento ya no existe, invalidamos
        estaActivado = false;
        await prefs.setBool('activado', false);
      }
    } catch (e) {
      // Si hay error de red, permitimos entrar (opcional), 
      // o puedes forzar re-validación. Aquí lo dejamos pasar por UX.
      debugPrint("Error verificando huella: $e");
    }
  }

  runApp(MyApp(iniciarActivado: estaActivado));
}

// Función auxiliar idéntica a la de ActivationScreen para mantener consistencia
Future<String> _obtenerHuellaServicio() async {
  const storage = FlutterSecureStorage();
  var deviceInfo = DeviceInfoPlugin();
  String hardwareId = '';
  String model = '';

  if (Platform.isAndroid) {
    var androidInfo = await deviceInfo.androidInfo;
    hardwareId = androidInfo.id;
    model = androidInfo.model;
  } else if (Platform.isIOS) {
    var iosInfo = await deviceInfo.iosInfo;
    hardwareId = iosInfo.identifierForVendor ?? 'unknown_ios';
    model = iosInfo.utsname.machine;
  }

  String? internalUuid = await storage.read(key: 'internal_device_uuid');
  if (internalUuid == null) {
    internalUuid = const Uuid().v4();
    await storage.write(key: 'internal_device_uuid', value: internalUuid);
  }

  String fid = "no_fid";
  try {
    fid = await FirebaseInstallations.instance.getId();
  } catch (e) {
    fid = "error_fid";
  }

  return "${model}_${hardwareId}_${fid}_$internalUuid";
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