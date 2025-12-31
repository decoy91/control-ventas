import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/producto.dart';

class ProductoRepository {
  final _dbHelper = DatabaseHelper.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<String?> _getCodigo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('codigo_licencia');
  }

  // ==========================================
  // INSERTAR
  // ==========================================
  Future<int> insertarProducto(Producto producto) async {
    final db = await _dbHelper.database;
    // 1. Local
    final id = await db.insert('productos', producto.toMap());
    
    // 2. Nube
    _sincronizarFirebase(producto.copyWith(id: id));
    
    return id;
  }

  // ==========================================
  // OBTENER
  // ==========================================
  Future<List<Producto>> obtenerProductos() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('productos', orderBy: 'id DESC');

    return maps.map((e) => Producto.fromMap(e)).toList();
  }

  // ==========================================
  // ACTUALIZAR
  // ==========================================
  Future<int> actualizarProducto(Producto producto) async {
    final db = await _dbHelper.database;
    // 1. Local
    final res = await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
    
    // 2. Nube
    _sincronizarFirebase(producto);
    
    return res;
  }

  // ==========================================
  // ELIMINAR
  // ==========================================
  Future<int> eliminarProducto(int id) async {
    final db = await _dbHelper.database;
    // 1. Local
    final res = await db.delete('productos', where: 'id = ?', whereArgs: [id]);
    
    // 2. Nube
    final codigo = await _getCodigo();
    if (codigo != null) {
      _firestore
          .collection('licencias')
          .doc(codigo)
          .collection('productos_respaldo')
          .doc(id.toString())
          .delete();
    }
    
    return res;
  }

  // ==========================================
  // SINCRONIZACIÓN FIREBASE
  // ==========================================
  Future<void> _sincronizarFirebase(Producto producto) async {
    try {
      final codigo = await _getCodigo();
      if (codigo != null) {
        await _firestore
            .collection('licencias')
            .doc(codigo)
            .collection('productos_respaldo')
            .doc(producto.id.toString())
            .set(producto.toJson());
      }
    } catch (e) {
      print("Error sincronizando producto: $e");
    }
  }

  // ==========================================
  // RECUPERACIÓN MASIVA
  // ==========================================
  Future<void> recuperarProductosDesdeNube(String codigo) async {
    try {
      final query = await _firestore
          .collection('licencias')
          .doc(codigo)
          .collection('productos_respaldo')
          .get();

      if (query.docs.isEmpty) return;

      final db = await _dbHelper.database;
      final batch = db.batch();

      for (var doc in query.docs) {
        final prodNube = Producto.fromJson(doc.data());
        batch.insert(
          'productos', 
          prodNube.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print("Error al recuperar productos: $e");
    }
  }
}