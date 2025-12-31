import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/cliente.dart';

class ClienteRepository {
  final dbHelper = DatabaseHelper.instance;
  final _firestore = FirebaseFirestore.instance;

  // Método privado para obtener el código de licencia (candado)
  Future<String?> _getCodigo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('codigo_licencia');
  }

  // ==========================================
  // OBTENER POR ID (Para cobrar por WhatsApp)
  // ==========================================
  Future<Cliente?> obtenerClientePorId(int id) async {
    final db = await dbHelper.database;
    // Buscamos en la tabla clientes donde el id coincida
    final res = await db.query(
      'clientes', 
      where: 'id = ?', 
      whereArgs: [id]
    );

    if (res.isNotEmpty) {
      return Cliente.fromMap(res.first);
    }
    return null; // Si no lo encuentra
  }

  // ==========================================
  // INSERTAR
  // ==========================================
  Future<int> insertarCliente(Cliente cliente) async {
    final db = await dbHelper.database;
    // 1. Guardar local
    final id = await db.insert('clientes', cliente.toMap());
    
    // 2. Sincronizar (usamos copyWith para incluir el ID generado)
    _sincronizarFirebase(cliente.copyWith(id: id));
    
    return id;
  }

  // ==========================================
  // OBTENER
  // ==========================================
  Future<List<Cliente>> obtenerClientes() async {
    final db = await dbHelper.database;
    final res = await db.query('clientes', orderBy: 'nombre ASC');
    return res.map((e) => Cliente.fromMap(e)).toList();
  }

  // ==========================================
  // ACTUALIZAR
  // ==========================================
  Future<int> actualizarCliente(Cliente cliente) async {
    final db = await dbHelper.database;
    // 1. Actualizar local
    final res = await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
    
    // 2. Actualizar en la nube
    _sincronizarFirebase(cliente);
    
    return res;
  }

  // ==========================================
  // ELIMINAR
  // ==========================================
  Future<int> eliminarCliente(int id) async {
    final db = await dbHelper.database;
    // 1. Eliminar local
    final res = await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
    
    // 2. Eliminar de la nube
    final codigo = await _getCodigo();
    if (codigo != null) {
      _firestore
          .collection('licencias')
          .doc(codigo)
          .collection('clientes_respaldo')
          .doc(id.toString())
          .delete();
    }
    
    return res;
  }

  // ==========================================
  // SINCRONIZACIÓN FIREBASE
  // ==========================================
  Future<void> _sincronizarFirebase(Cliente cliente) async {
    try {
      final codigo = await _getCodigo();
      if (codigo != null) {
        await _firestore
            .collection('licencias')
            .doc(codigo)
            .collection('clientes_respaldo')
            .doc(cliente.id.toString())
            .set(cliente.toJson());
      }
    } catch (e) {
      print("Error sincronizando cliente: $e");
    }
  }

  // ==========================================
  // RECUPERACIÓN MASIVA
  // ==========================================
  Future<void> recuperarClientesDesdeNube(String codigo) async {
    try {
      final query = await _firestore
          .collection('licencias')
          .doc(codigo)
          .collection('clientes_respaldo')
          .get();

      if (query.docs.isEmpty) return;

      final db = await dbHelper.database;
      final batch = db.batch();

      for (var doc in query.docs) {
        final clienteNube = Cliente.fromJson(doc.data());
        batch.insert(
          'clientes', 
          clienteNube.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print("Error al recuperar clientes: $e");
    }
  }
}