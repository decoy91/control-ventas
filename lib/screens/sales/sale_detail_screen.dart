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
    setState(() => cargando = true);
    abonos = await _abonoRepo.obtenerAbonosPorVenta(_venta.id!);
    setState(() => cargando = false);
  }

  int get totalAbonado => abonos.fold(0, (sum, a) => sum + a.monto);
  int get pendiente => _venta.total - totalAbonado;
  double get porcentajePago => (_venta.total > 0) ? (totalAbonado / _venta.total) : 0;

  // Lógica para actualizar la venta en la DB después de cambios en abonos
  Future<void> _actualizarEstadoVenta() async {
    final nuevoTotalAbonado = totalAbonado;
    final nuevaLiquidada = nuevoTotalAbonado >= _venta.total;
    
    _venta = _venta.copyWith(pagado: nuevoTotalAbonado, liquidada: nuevaLiquidada);
    await _ventaRepo.actualizarVenta(_venta);
    
    if (nuevaLiquidada) _confettiController.play();
    setState(() {});
  }

  Future<void> _eliminarAbono(Abono abono) async {
    await _abonoRepo.eliminarAbono(abono.id!);
    await cargarAbonos();
    await _actualizarEstadoVenta();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Abono eliminado correctamente"))
      );
    }
  }

  void _abrirModalAbono([Abono? abono]) {
    final ctrl = TextEditingController(text: abono?.monto.toString() ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text(abono == null ? 'Nuevo Abono' : 'Editar Abono', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Monto a pagar',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: 'Max: \$$pendiente',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final monto = int.tryParse(ctrl.text);
                if (monto == null || monto <= 0 || monto > (abono == null ? pendiente : pendiente + abono.monto)) return;
                
                if (abono == null) {
                  await _abonoRepo.insertarAbono(Abono(ventaId: _venta.id!, monto: monto, fecha: DateTime.now()));
                } else {
                  await _abonoRepo.actualizarAbono(Abono(id: abono.id, ventaId: _venta.id!, monto: monto, fecha: abono.fecha));
                }
                
                await cargarAbonos();
                await _actualizarEstadoVenta();
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              child: const Text('Confirmar Pago'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd MMM, yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Venta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true), // Retornamos true para recargar lista en Home
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildProgressCard(),
              const SizedBox(height: 24),
              const Text('Historial de Abonos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildAbonosList(f),
            ],
          ),
          Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive)),
        ],
      ),
      floatingActionButton: !_venta.liquidada 
        ? FloatingActionButton.extended(onPressed: () => _abrirModalAbono(), label: const Text('Abonar'), icon: const Icon(Icons.add))
        : null,
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1), child: Icon(Icons.person, color: Theme.of(context).primaryColor)),
                const SizedBox(width: 12),
                Text(_venta.clienteNombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            Text('Producto: ${_venta.productoNombre}', style: const TextStyle(fontSize: 16)),
            if (_venta.nota != null && _venta.nota!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Nota: ${_venta.nota}', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat('Total', '\$${_venta.total}', Colors.white70),
                _miniStat('Pendiente', '\$$pendiente', Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: porcentajePago,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            Text('${(porcentajePago * 100).toInt()}% Pagado', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAbonosList(DateFormat f) {
    if (abonos.isEmpty) {
      return const Center(child: Padding(
      padding: EdgeInsets.all(20.0),
      child: Text('No hay abonos registrados todavía.', style: TextStyle(color: Colors.grey)),
    ));
    }

    return Column(
      children: abonos.map((a) {
        // 🔥 Determinamos si se puede editar/borrar
        final bool puedeModificar = !_venta.liquidada;

        return Dismissible(
          key: Key(a.id.toString()),
          // 🔥 Si está liquidada, la dirección es 'none' (bloquea el deslizamiento)
          direction: puedeModificar ? DismissDirection.startToEnd : DismissDirection.none, 
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("¿Eliminar abono?"),
                content: const Text("El saldo pendiente se ajustará automáticamente."),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true), 
                    child: const Text("ELIMINAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                  ),
                ],
              )
            );
          },
          onDismissed: (_) => _eliminarAbono(a),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent, 
              borderRadius: BorderRadius.circular(12)
            ),
            child: const Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Eliminar Abono", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade100)
            ),
            child: ListTile(
              leading: CircleAvatar(
                // Cambia el color del icono si está liquidada para diferenciar
                backgroundColor: puedeModificar ? Colors.green : Colors.blueGrey.shade100, 
                child: Icon(
                  puedeModificar ? Icons.arrow_downward : Icons.lock_outline, 
                  color: Colors.white, 
                  size: 20
                )
              ),
              title: Text('\$${a.monto}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(f.format(a.fecha)),
              trailing: puedeModificar 
                  ? IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), 
                      onPressed: () => _abrirModalAbono(a)
                    ) 
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: const Text(
                        "PAGADO", 
                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}