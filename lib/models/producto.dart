// lib/models/producto.dart
class Producto {
  int? id;
  String nombre;
  int precio;
  String? imagenPath;
  String? descripcion;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    this.imagenPath,
    this.descripcion,
  });

  // =========================
  // copyWith 🔥
  // =========================
  Producto copyWith({
    int? id,
    String? nombre,
    int? precio,
    String? imagenPath,
    String? descripcion,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      imagenPath: imagenPath ?? this.imagenPath,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  // =========================
  // SQLite
  // =========================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'imagenPath': imagenPath,
      'descripcion': descripcion,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      precio: map['precio'],
      imagenPath: map['imagenPath'],
      descripcion: map['descripcion'],
    );
  }

  // =========================
  // Firebase Firestore 🔥
  // =========================

  // Convertir a Map para la nube
  Map<String, dynamic> toJson() {
    return {
      'id_local': id,
      'nombre': nombre,
      'precio': precio,
      'imagenPath': imagenPath,
      'descripcion': descripcion,
    };
  }

  // Crear objeto desde datos de la nube
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id_local'],
      nombre: json['nombre'] ?? '',
      precio: json['precio'] ?? 0,
      imagenPath: json['imagenPath'],
      descripcion: json['descripcion'],
    );
  }
}