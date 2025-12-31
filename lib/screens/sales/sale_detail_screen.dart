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
                final nuevaLiquidada = totalAbonado >= _venta.total;
                _venta = _venta.copyWith(pagado: totalAbonado, liquidada: nuevaLiquidada);
                await _ventaRepo.actualizarVenta(_venta);
                
                if (nuevaLiquidada) _confettiController.play();
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
      appBar: AppBar(title: const Text('Detalles de Venta')),
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
      color: Theme.of(context).primaryColor,
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
    if (abonos.isEmpty) return const Center(child: Text('No hay abonos registrados todavía.'));
    return Column(
      children: abonos.map((a) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.arrow_downward, color: Colors.green, size: 20)),
          title: Text('\$${a.monto}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(f.format(a.fecha)),
          trailing: !_venta.liquidada ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirModalAbono(a)) : null,
        ),
      )).toList(),
    );
  }
}