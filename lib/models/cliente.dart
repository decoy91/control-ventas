// lib/models/cliente.dart
class Cliente {
  int? id;
  String nombre;
  String telefono;
  String? notas;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    this.notas,
  });

  // =========================
  // copyWith 🔥 
  // (Fundamental para actualizar el ID después de insertar)
  // =========================
  Cliente copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? notas,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      notas: notas ?? this.notas,
    );
  }

  // =========================
  // SQLite
  // =========================
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      notas: map['notas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'notas': notas,
    };
  }

  // =========================
  // Firebase Firestore 🔥
  // =========================

  // Convertir a Map para la nube
  Map<String, dynamic> toJson() {
    return {
      'id_local': id,
      'nombre': nombre,
      'telefono': telefono,
      'notas': notas,
    };
  }

  // Crear objeto desde datos de la nube
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id_local'],
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'] ?? '',
      notas: json['notas'],
    );
  }
}