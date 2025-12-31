// lib/models/abono.dart
class Abono {
  final int? id;
  final int ventaId;
  final int monto;
  final DateTime fecha;

  Abono({
    this.id,
    required this.ventaId,
    required this.monto,
    required this.fecha,
  });

  // 🔥 Crea una copia del objeto con un ID nuevo (Usado al insertar)
  Abono copyWith({int? id}) => Abono(
        id: id ?? this.id,
        ventaId: ventaId,
        monto: monto,
        fecha: fecha,
      );

  // 🔥 Convierte a Mapa para SQLite
  Map<String, dynamic> toMap() => {
        'id': id,
        'venta_id': ventaId,
        'monto': monto,
        'fecha': fecha.millisecondsSinceEpoch,
      };

  // 🔥 Convierte a Mapa para Firebase (Firestore prefiere nombres claros)
  Map<String, dynamic> toJson() => {
        'id': id,
        'venta_id': ventaId,
        'monto': monto,
        'fecha': fecha.millisecondsSinceEpoch,
      };

  // 🔥 Crea el objeto desde SQLite
  factory Abono.fromMap(Map<String, dynamic> map) => Abono(
        id: map['id'],
        ventaId: map['venta_id'],
        monto: map['monto'],
        fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha']),
      );

  // 🔥 Crea el objeto desde Firebase
  factory Abono.fromJson(Map<String, dynamic> json) => Abono(
        id: json['id'],
        ventaId: json['venta_id'],
        monto: json['monto'],
        fecha: DateTime.fromMillisecondsSinceEpoch(json['fecha']),
      );
}