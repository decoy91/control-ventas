//lib/models/venta.dart
class Venta {
  final int? id;
  final int clienteId;
  final String clienteNombre;
  final int productoId;
  final String productoNombre;
  final int total;
  final int pagado;
  final bool liquidada;
  final DateTime fecha;
  final String? nota;
  

  Venta({
    this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.productoId,
    required this.productoNombre,
    required this.total,
    required this.pagado,
    required this.liquidada,
    required this.fecha,
    this.nota,
  });

  // =========================
  // copyWith 🔥
  // =========================
  Venta copyWith({
    int? id,
    int? clienteId,
    String? clienteNombre,
    int? productoId,
    String? productoNombre,
    int? total,
    int? pagado,
    bool? liquidada,
    DateTime? fecha,
    String? nota,
  }) {
    return Venta(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      productoId: productoId ?? this.productoId,
      productoNombre: productoNombre ?? this.productoNombre,
      total: total ?? this.total,
      pagado: pagado ?? this.pagado,
      liquidada: liquidada ?? this.liquidada,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
    );
  }

  // =========================
  // SQLite
  // =========================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'cliente_nombre': clienteNombre,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'total': total,
      'pagado': pagado,
      'liquidada': liquidada ? 1 : 0,
      'fecha': fecha.millisecondsSinceEpoch,
      'nota': nota,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'],
      clienteId: map['cliente_id'],
      clienteNombre: map['cliente_nombre'],
      productoId: map['producto_id'],
      productoNombre: map['producto_nombre'],
      total: map['total'],
      pagado: map['pagado'],
      liquidada: map['liquidada'] == 1,
      fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha']),
      nota: map['nota'],
    );
  }
}
