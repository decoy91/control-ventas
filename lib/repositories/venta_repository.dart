import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/venta.dart';

class VentaRepository {
  final _db = DatabaseHelper.instance;
  final _firestore = FirebaseFirestore.instance;

  // Método auxiliar para obtener el código de licencia guardado
  Future<String?> _getCodigoLicencia() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('codigo_licencia');
  }

  // ==========================================
  // INSERTAR
  // ==========================================
  Future<int> insertarVenta(Venta venta) async {
    final db = await _db.database;
    // 1. Guardar en SQLite local
    final id = await db.insert('ventas', venta.toMap());
    
    // 2. Sincronizar con Firebase (usando el ID generado)
    final ventaConId = venta.copyWith(id: id);
    _sincronizarVentaFirebase(ventaConId);
    
    return id;
  }

  // ==========================================
  // OBTENER
  // ==========================================
  Future<List<Venta>> obtenerVentas() async {
    final db = await _db.database;
    final result = await db.query('ventas', orderBy: 'fecha DESC');
    return result.map((e) => Venta.fromMap(e)).toList();
  }

  // ==========================================
  // ACTUALIZAR
  // ==========================================
  Future<void> actualizarVenta(Venta venta) async {
    final db = await _db.database;
    // 1. Actualizar local
    await db.update(
      'ventas',
      venta.toMap(),
      where: 'id = ?',
      whereArgs: [venta.id],
    );
    
    // 2. Sincronizar actualización en la nube
    _sincronizarVentaFirebase(venta);
  }

  // ==========================================
  // ELIMINAR
  // ==========================================
  Future<void> eliminarVenta(int id) async {
    final db = await _db.database;
    // 1. Eliminar local
    await db.delete('ventas', where: 'id = ?', whereArgs: [id]);
    
    // 2. Eliminar de la nube
    final codigo = await _getCodigoLicencia();
    if (codigo != null) {
      _firestore
          .collection('licencias')
          .doc(codigo)
          .collection('ventas_respaldo')
          .doc(id.toString())
          .delete();
    }
  }

  // ==========================================
  // SINCRONIZACIÓN INDIVIDUAL (FIREBASE)
  // ==========================================
  Future<void> _sincronizarVentaFirebase(Venta venta) async {
    try {
      final codigo = await _getCodigoLicencia();
      if (codigo != null) {
        await _firestore
            .collection('licencias')
            .doc(codigo)
            .collection('ventas_respaldo')
            .doc(venta.id.toString())
            .set(venta.toJson()); 
      }
    } catch (e) {
      print("Error sincronizando venta: $e");
    }
  }

  // ==========================================
  // RECUPERACIÓN MASIVA (DESDE LA NUBE)
  // ==========================================
  Future<void> recuperarVentasDesdeNube(String codigoLicencia) async {
    try {
      // 1. Obtener datos de Firebase
      final queryVentas = await _firestore
          .collection('licencias')
          .doc(codigoLicencia)
          .collection('ventas_respaldo')
          .get();

      final db = await _db.database;
      final batch = db.batch();

      // 🔥 2. LIMPIEZA PREVENTIVA: Borramos ventas y abonos locales antes de insertar
      // Esto evita que se mezclen datos de sesiones anteriores
      batch.delete('abonos');
      batch.delete('ventas');

      if (queryVentas.docs.isNotEmpty) {
        for (var doc in queryVentas.docs) {
          final ventaNube = Venta.fromJson(doc.data());
          batch.insert(
            'ventas', 
            ventaNube.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // 3. Recuperar abonos de cada venta si los tienes en subcolecciones
          // Si manejas una tabla global de abonos, deberías descargarla igual que las ventas
          await _recuperarAbonosDeVenta(codigoLicencia, ventaNube.id!, batch);
        }
      }

      await batch.commit(noResult: true);
      print("Ventas recuperadas y base de datos local sincronizada.");
    } catch (e) {
      print("Error al recuperar datos: $e");
    }
  }

  // Método privado para recuperar abonos asociados (opcional según tu estructura)
  Future<void> _recuperarAbonosDeVenta(String codigo, int ventaId, Batch batch) async {
    final queryAbonos = await _firestore
        .collection('licencias')
        .doc(codigo)
        .collection('ventas_respaldo')
        .doc(ventaId.toString())
        .collection('abonos')
        .get();

    for (var doc in queryAbonos.docs) {
      batch.insert(
        'abonos',
        doc.data(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Venta?> obtenerVentaPorId(int id) async {
    final db = await _db.database;
    final result = await db.query(
      'ventas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Venta.fromMap(result.first);
  }

  // 🔥 MÉTODO PARA LIMPIEZA MANUAL DESDE EL REPO
  Future<void> limpiarDatosLocales() async {
    final db = await _db.database;
    await db.delete('ventas');
    await db.delete('abonos');
  }
}