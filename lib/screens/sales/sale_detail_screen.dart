import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';

import '../../models/venta.dart';
import '../../models/abono.dart';
import '../../repositories/venta_repository.dart';
import '../../repositories/abono_repository.dart';

class SaleDetailScreen extends StatefulWidget {
  final Venta venta;

  const SaleDetailScreen({super.key, required this.venta});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final _ventaRepo = VentaRepository();
  final _abonoRepo = AbonoRepository();

  late ConfettiController _confettiController;
  late Venta _venta;
  List<Abono> abonos = [];
  bool cargando = true;

  bool get estaLiquidada => _venta.liquidada;
  int get totalAbonado => abonos.fold(0, (sum, a) => sum + a.monto);
  int get pendiente => _venta.total - totalAbonado;

  @override
  void initState() {
    super.initState();
    _venta = widget.venta;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    cargarAbonos();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> cargarAbonos() async {
    if (_venta.id == null) {
      setState(() => cargando = false);
      return;
    }
    try {
      setState(() => cargando = true);
      abonos = await _abonoRepo.obtenerAbonosPorVenta(_venta.id!);
    } catch (e) {
      _msg('Error al cargar abonos: $e');
      abonos = [];
    } finally {
      setState(() => cargando = false);
    }
  }

  void agregarOEditarAbono([Abono? abono]) {
    final ctrl = TextEditingController(text: abono?.monto.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(abono == null ? 'Agregar abono' : 'Editar abono'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monto',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade400),
            onPressed: () async {
              final monto = int.tryParse(ctrl.text);
              if (monto == null || monto <= 0) {
                _msg('Ingresa un monto válido');
                return;
              }
              final montoMax = abono == null ? pendiente : pendiente + abono.monto;
              if (monto > montoMax) {
                _msg('El abono no puede ser mayor al pendiente (\$$montoMax)');
                return;
              }

              try {
                if (abono == null) {
                  final nuevo = Abono(
                    ventaId: _venta.id!,
                    monto: monto,
                    fecha: DateTime.now(),
                  );
                  await _abonoRepo.insertarAbono(nuevo);
                } else {
                  final editado = Abono(
                    id: abono.id,
                    ventaId: _venta.id!,
                    monto: monto,
                    fecha: abono.fecha,
                  );
                  await _abonoRepo.actualizarAbono(editado);
                }

                await cargarAbonos();

                final nuevaLiquidada = totalAbonado >= _venta.total;

                _venta = Venta(
                  id: _venta.id,
                  clienteId: _venta.clienteId,
                  clienteNombre: _venta.clienteNombre,
                  productoId: _venta.productoId,
                  productoNombre: _venta.productoNombre,
                  total: _venta.total,
                  pagado: totalAbonado,
                  liquidada: nuevaLiquidada,
                  fecha: _venta.fecha,
                  nota: _venta.nota,
                );

                await _ventaRepo.actualizarVenta(_venta);

                if (nuevaLiquidada) _confettiController.play();

                if (mounted) Navigator.pop(context);
              } catch (e) {
                _msg('Error al guardar abono: $e');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void eliminarAbono(Abono abono) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar abono'),
        content: Text('¿Seguro que quieres eliminar el abono de \$${abono.monto}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _abonoRepo.eliminarAbono(abono.id!);
      await cargarAbonos();

      _venta = Venta(
        id: _venta.id,
        clienteId: _venta.clienteId,
        clienteNombre: _venta.clienteNombre,
        productoId: _venta.productoId,
        productoNombre: _venta.productoNombre,
        total: _venta.total,
        pagado: totalAbonado,
        liquidada: false,
        fecha: _venta.fecha,
        nota: _venta.nota,
      );

      await _ventaRepo.actualizarVenta(_venta);
    } catch (e) {
      _msg('Error al eliminar abono: $e');
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd/MM/yyyy');

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Detalle de venta')),
          floatingActionButton: pendiente > 0 && !estaLiquidada
              ? FloatingActionButton(
                  onPressed: () => agregarOEditarAbono(),
                  child: const Icon(Icons.add),
                )
              : null,
          body: cargando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cliente / Producto
                      Text(
                        _venta.clienteNombre,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(_venta.productoNombre),

                      const SizedBox(height: 8),

                      // Nota
                      if (_venta.nota!.isNotEmpty)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.note),
                            title: const Text('Nota'),
                            subtitle: Text(_venta.nota ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                final ctrl = TextEditingController(text: _venta.nota);
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Editar nota'),
                                    content: TextField(
                                      controller: ctrl,
                                      maxLines: 3,
                                      decoration: const InputDecoration(labelText: 'Nota'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          _venta = Venta(
                                            id: _venta.id,
                                            clienteId: _venta.clienteId,
                                            clienteNombre: _venta.clienteNombre,
                                            productoId: _venta.productoId,
                                            productoNombre: _venta.productoNombre,
                                            total: _venta.total,
                                            pagado: totalAbonado,
                                            liquidada: _venta.liquidada,
                                            fecha: _venta.fecha,
                                            nota: ctrl.text.trim(),
                                          );
                                          await _ventaRepo.actualizarVenta(_venta);
                                          setState(() {});
                                          // ignore: use_build_context_synchronously
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Guardar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Resumen
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _Resumen('Total', _venta.total),
                              _Resumen('Pagado', totalAbonado),
                              _Resumen('Pendiente', pendiente),
                            ],
                          ),
                        ),
                      ),

                      if (estaLiquidada)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Venta liquidada',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Abonos
                      const Text('Abonos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: abonos.isEmpty
                            ? const Center(child: Text('Sin abonos'))
                            : ListView.builder(
                                itemCount: abonos.length,
                                itemBuilder: (_, i) {
                                  final a = abonos[i];
                                  return Card(
                                    child: ListTile(
                                      title: Text('\$${a.monto}'),
                                      subtitle: Text(f.format(a.fecha)),
                                      trailing: !estaLiquidada
                                          ? IconButton(
                                              icon: const Icon(Icons.more_vert),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  builder: (_) => SafeArea(
                                                    child: Wrap(
                                                      children: [
                                                        ListTile(
                                                          leading: const Icon(Icons.edit),
                                                          title: const Text('Editar'),
                                                          onTap: () {
                                                            Navigator.pop(context);
                                                            agregarOEditarAbono(a);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: const Icon(Icons.delete, color: Colors.red),
                                                          title: const Text('Eliminar'),
                                                          onTap: () {
                                                            Navigator.pop(context);
                                                            eliminarAbono(a);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
        ),

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.orange, Colors.purple],
          ),
        ),
      ],
    );
  }
}

// =========================
// Widgets
// =========================
class _Resumen extends StatelessWidget {
  final String label;
  final int value;

  const _Resumen(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label),
        Text('\$$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
