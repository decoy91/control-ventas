import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  // =========================
  // DB getter
  // =========================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // =========================
  // Init DB
  // =========================
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'control_ventas.db');

    return await openDatabase(
      path,
      version: 4, // 👈 IMPORTANTE
      onCreate: _onCreate,
    );
  }

  // =========================
  // Create tables
  // =========================
  Future<void> _onCreate(Database db, int version) async {
    // ---------- CLIENTES ----------
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        notas TEXT
      );
    ''');

    // ---------- PRODUCTOS ----------
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio INTEGER NOT NULL,
        imagenPath TEXT,
        descripcion TEXT
      );
    ''');

    // ---------- VENTAS ----------
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        cliente_nombre TEXT NOT NULL,
        producto_id INTEGER NOT NULL,
        producto_nombre TEXT NOT NULL,
        total INTEGER NOT NULL,
        pagado INTEGER NOT NULL,
        liquidada INTEGER NOT NULL,
        fecha INTEGER NOT NULL,
        nota TEXT
      );
    ''');

    // ---------- ABONOS ----------
    await db.execute('''
      CREATE TABLE abonos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        monto INTEGER NOT NULL,
        fecha INTEGER NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE
      );
    ''');
  }
}
