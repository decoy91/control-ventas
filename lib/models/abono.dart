//lib/models/abono.dart
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'venta_id': ventaId,
        'monto': monto,
        'fecha': fecha.millisecondsSinceEpoch,
      };

  factory Abono.fromMap(Map<String, dynamic> map) => Abono(
        id: map['id'],
        ventaId: map['venta_id'],
        monto: map['monto'],
        fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha']),
      );
}
