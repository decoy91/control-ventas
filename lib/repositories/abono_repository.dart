// lib/repositories/abono_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/abono.dart';

class AbonoRepository {
  final _db = DatabaseHelper.instance;
  final _firestore = FirebaseFirestore.instance;

  // Método auxiliar para obtener el código de licencia
  Future<String?> _getCodigoLicencia() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('codigo_licencia');
  }

  // ==========================================
  // INSERTAR Y SINCRONIZAR
  // ==========================================
  Future<int> insertarAbono(Abono abono) async {
    final db = await _db.database;
    
    // 1. Guardar en SQLite local
    final id = await db.insert('abonos', abono.toMap());
    
    // 2. Sincronizar con Firebase
    final abonoConId = abono.copyWith(id: id);
    _sincronizarAbonoFirebase(abonoConId);
    
    return id;
  }

  // ==========================================
  // OBTENER ABONOS POR VENTA
  // ==========================================
  Future<List<Abono>> obtenerAbonosPorVenta(int ventaId) async {
    final db = await _db.database;

    final result = await db.query(
      'abonos',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
      orderBy: 'fecha ASC',
    );

    return result.map((e) => Abono.fromMap(e)).toList();
  }

  // ==========================================
  // ACTUALIZAR Y SINCRONIZAR
  // ==========================================
  Future<void> actualizarAbono(Abono abono) async {
    final db = await _db.database;

    // 1. Actualizar local
    await db.update(
      'abonos',
      abono.toMap(),
      where: 'id = ?',
      whereArgs: [abono.id],
    );

    // 2. Actualizar en Firebase
    _sincronizarAbonoFirebase(abono);
  }

  // ==========================================
  // ELIMINAR Y SINCRONIZAR
  // ==========================================
  Future<void> eliminarAbono(int id) async {
    final db = await _db.database;

    // 1. Eliminar local
    await db.delete(
      'abonos',
      where: 'id = ?',
      whereArgs: [id],
    );

    // 2. Eliminar de Firebase
    final codigo = await _getCodigoLicencia();
    if (codigo != null) {
      await _firestore
          .collection('licencias')
          .doc(codigo)
          .collection('abonos_respaldo')
          .doc(id.toString())
          .delete();
    }
  }

  // ==========================================
  // SINCRONIZACIÓN INDIVIDUAL (FIREBASE)
  // ==========================================
  Future<void> _sincronizarAbonoFirebase(Abono abono) async {
    try {
      final codigo = await _getCodigoLicencia();
      if (codigo != null) {
        await _firestore
            .collection('licencias')
            .doc(codigo)
            .collection('abonos_respaldo')
            .doc(abono.id.toString())
            .set(abono.toMap()); // Usamos toMap para Firestore también
      }
    } 
    catch (e) {
      // print("Error sincronizando abono: $e");
    }
  }

  // ==========================================
  // RECUPERACIÓN MASIVA (DESDE LA NUBE)
  // ==========================================
  Future<void> recuperarAbonosDesdeNube(String codigoLicencia) async {
    try {
      final query = await _firestore
          .collection('licencias')
          .doc(codigoLicencia)
          .collection('abonos_respaldo')
          .get();

      final db = await _db.database;
      final batch = db.batch();

      // 🔥 Limpieza preventiva para evitar mezcla de datos de sesiones anteriores
      batch.delete('abonos');

      if (query.docs.isNotEmpty) {
        for (var doc in query.docs) {
          batch.insert(
            'abonos', 
            doc.data(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(noResult: true);
      // print("Abonos recuperados con éxito.");
    } catch (e) {
      // print("Error al recuperar abonos: $e");
    }
  }

  // ==========================================
  // LIMPIEZA MANUAL (LOGOUT)
  // ==========================================
  Future<void> limpiarDatosLocales() async {
    final db = await _db.database;
    await db.delete('abonos');
  }
}