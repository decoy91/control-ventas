import '../db/database_helper.dart';
import '../models/abono.dart';

class AbonoRepository {
  final _db = DatabaseHelper.instance;

  // =========================
  // Insertar abono
  // =========================
  Future<int> insertarAbono(Abono abono) async {
    final db = await _db.database;
    return await db.insert('abonos', abono.toMap());
  }

  // =========================
  // Obtener abonos por venta
  // =========================
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

  // =========================
  // Actualizar abono ✅ (ESTE FALTABA)
  // =========================
  Future<void> actualizarAbono(Abono abono) async {
    final db = await _db.database;

    await db.update(
      'abonos',
      abono.toMap(),
      where: 'id = ?',
      whereArgs: [abono.id],
    );
  }

  // =========================
  // Eliminar abono
  // =========================
  Future<void> eliminarAbono(int id) async {
    final db = await _db.database;

    await db.delete(
      'abonos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
