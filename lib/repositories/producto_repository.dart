//lib/repositories/producto_repository.dart
import 'package:control_ventapps/db/database_helper.dart';
import 'package:control_ventapps/models/producto.dart';

class ProductoRepository {
  final _dbHelper = DatabaseHelper.instance;

  Future<int> insertarProducto(Producto producto) async {
    final db = await _dbHelper.database;
    return await db.insert('productos', producto.toMap());
  }

  Future<List<Producto>> obtenerProductos() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query('productos', orderBy: 'id DESC');

    return maps.map((e) => Producto.fromMap(e)).toList();
  }

  Future<int> actualizarProducto(Producto producto) async {
    final db = await _dbHelper.database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> eliminarProducto(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
