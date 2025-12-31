//lib/repositories/venta_repository.dart
import 'package:control_ventapps/db/database_helper.dart';

import '../models/venta.dart';

class VentaRepository {
  final _db = DatabaseHelper.instance;

  Future<int> insertarVenta(Venta venta) async {
    final db = await _db.database;
    return await db.insert('ventas', venta.toMap());
  }

  Future<List<Venta>> obtenerVentas() async {
    final db = await _db.database;
    final result = await db.query('ventas', orderBy: 'fecha DESC');

    return result.map((e) => Venta.fromMap(e)).toList();
  }

  Future<void> actualizarVenta(Venta venta) async {
    final db = await _db.database;
    await db.update(
      'ventas',
      venta.toMap(),
      where: 'id = ?',
      whereArgs: [venta.id],
    );
  }

  Future<void> eliminarVenta(int id) async {
    final db = await _db.database;
    await db.delete('ventas', where: 'id = ?', whereArgs: [id]);
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
}
