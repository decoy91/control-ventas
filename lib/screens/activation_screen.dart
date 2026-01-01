import 'dart:io';
import 'dart:math' as math; 
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/cliente_repository.dart';
import '../repositories/producto_repository.dart';
import '../repositories/venta_repository.dart';
import '../repositories/abono_repository.dart';
import 'home_screen.dart';
import 'admin_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> with SingleTickerProviderStateMixin {
  final _codeCtrl = TextEditingController();
  bool _cargando = false;
  String _estadoSync = ""; 

  // Variables para la animación de moneda
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // La animación se configura, pero NO se inicia (no hay .repeat() aquí)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }
    return 'unknown';
  }

  Future<void> _validarCodigo() async {
    final codigoIngresado = _codeCtrl.text.trim().toUpperCase();
    if (codigoIngresado.isEmpty) {
      _mensaje("Por favor ingresa un código.");
      return;
    }

    setState(() {
      _cargando = true;
      _estadoSync = "Verificando...";
    });

    // 🔥 INICIAMOS EL GIRO DE MONEDA
    _animationController.repeat();

    try {
      final deviceId = await _getDeviceId();
      final querySnap = await FirebaseFirestore.instance
          .collection('licencias')
          .where('codigo_activacion', isEqualTo: codigoIngresado)
          .limit(1)
          .get();

      if (querySnap.docs.isEmpty) {
        _stopAnimation();
        _mensaje("El código ingresado no existe.");
      } else {
        final doc = querySnap.docs.first;
        final data = doc.data();
        
        if (data['is_admin'] == true) {
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
          return;
        }

        final Timestamp? fechaExp = data['fecha_expiracion'];
        final String? registradoId = data['device_id'];
        final ahora = DateTime.now();

        if (fechaExp == null || ahora.isAfter(fechaExp.toDate())) {
          _stopAnimation();
          _mensaje("Esta licencia ha expirado.");
        } else if (registradoId != null && registradoId != "" && registradoId != deviceId) {
          _stopAnimation();
          _mensaje("Código vinculado a otro dispositivo.");
        } else {
          if (registradoId == null || registradoId == "") {
            await doc.reference.update({'device_id': deviceId});
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('activado', true);
          await prefs.setString('codigo_licencia', doc.id);

          // Actualización de estados de sincronización
          setState(() => _estadoSync = "Clientes...");
          await ClienteRepository().recuperarClientesDesdeNube(doc.id);
          
          setState(() => _estadoSync = "Productos...");
          await ProductoRepository().recuperarProductosDesdeNube(doc.id);
          
          setState(() => _estadoSync = "Ventas...");
          await VentaRepository().recuperarVentasDesdeNube(doc.id);
          
          setState(() => _estadoSync = "Abonos...");
          await AbonoRepository().recuperarAbonosDesdeNube(doc.id);

          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const HomeScreen())
            );
          }
        }
      }
    } catch (e) {
      _stopAnimation();
      _mensaje("Error de conexión: $e");
    }
  }

  // Función para detener la animación suavemente
  void _stopAnimation() {
    if (mounted) {
      setState(() {
        _cargando = false;
        _estadoSync = "";
      });
      _animationController.stop();
      _animationController.animateTo(0, duration: const Duration(milliseconds: 500)); // Regresa a posición frontal
    }
  }

  void _mensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating)
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO CON EFECTO MONEDA ACTIVADO POR CARGA
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_animationController.value * 2 * math.pi),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: _cargando ? primaryColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02), 
                          blurRadius: 20, 
                          spreadRadius: 5
                        )
                      ]
                    ),
                    child: Icon(
                      _cargando ? Icons.sync : Icons.cloud_done_rounded, 
                      size: 70, 
                      color: primaryColor
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Activación",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Sincroniza tus datos para comenzar",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _codeCtrl,
                        enabled: !_cargando, // Bloqueamos el input mientras gira
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: "CÓDIGO DE LICENCIA",
                          hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 0, fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF4F7FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: _cargando ? null : _validarCodigo,
                          child: _cargando
                              ? Text("DESCARGANDO $_estadoSync", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
                              : const Text(
                                  "ACTIVAR Y ENTRAR",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: _cargando ? null : () {},
                  child: const Text("¿Necesitas ayuda?", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}