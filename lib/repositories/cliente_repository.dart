import 'package:control_ventapps/db/database_helper.dart';
import 'package:control_ventapps/models/cliente.dart';

class ClienteRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertarCliente(Cliente cliente) async {
    final db = await dbHelper.database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> obtenerClientes() async {
    final db = await dbHelper.database;
    final res = await db.query(
      'clientes',
      orderBy: 'nombre ASC',
    );
    return res.map((e) => Cliente.fromMap(e)).toList();
  }

  Future<int> actualizarCliente(Cliente cliente) async {
    final db = await dbHelper.database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<int> eliminarCliente(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
