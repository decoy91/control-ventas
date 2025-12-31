//lib/models/cliente.dart
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
}
