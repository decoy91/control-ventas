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
}
