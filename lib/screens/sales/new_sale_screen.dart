import 'package:control_ventapps/models/cliente.dart';
import 'package:control_ventapps/models/producto.dart';
import 'package:control_ventapps/models/venta.dart';
import 'package:control_ventapps/models/abono.dart';
import 'package:control_ventapps/repositories/cliente_repository.dart';
import 'package:control_ventapps/repositories/producto_repository.dart';
import 'package:control_ventapps/repositories/venta_repository.dart';
import 'package:control_ventapps/repositories/abono_repository.dart';
import 'package:flutter/material.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _ventaRepo = VentaRepository();
  final _abonoRepo = AbonoRepository();
  final _clienteRepo = ClienteRepository();
  final _productoRepo = ProductoRepository();

  Cliente? _cliente;
  Producto? _producto;

  final _notaCtrl = TextEditingController();
  final _abonoCtrl = TextEditingController();

  List<Cliente> clientes = [];
  List<Producto> productos = [];

  bool cargando = true;
  int abono = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    clientes = await _clienteRepo.obtenerClientes();
    productos = await _productoRepo.obtenerProductos();

    setState(() => cargando = false);
  }

  int get total => _producto?.precio ?? 0;
  int get pendiente => total - abono;

  // =========================
  // Guardar venta con abono inicial
  // =========================
  Future<void> _guardarVenta() async {
    if (_cliente == null || _producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona cliente y producto')),
      );
      return;
    }

    final parsedAbono = int.tryParse(_abonoCtrl.text) ?? 0;
    if (parsedAbono < 0 || parsedAbono > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El abono inicial debe estar entre 0 y \$$total')),
      );
      return;
    }

    // Crear la venta
    final venta = Venta(
      clienteId: _cliente!.id!,
      clienteNombre: _cliente!.nombre,
      productoId: _producto!.id!,
      productoNombre: _producto!.nombre,
      total: total,
      pagado: 0,
      liquidada: false,
      fecha: DateTime.now(),
      nota: _notaCtrl.text.trim(),
    );

    final ventaId = await _ventaRepo.insertarVenta(venta);

    // Crear abono inicial si existe
    if (parsedAbono > 0) {
      final abonoInicial = Abono(
        ventaId: ventaId,
        monto: parsedAbono,
        fecha: DateTime.now(),
      );
      await _abonoRepo.insertarAbono(abonoInicial);
    }

    // Actualizar venta con pagado y liquidada
    final liquidada = parsedAbono >= total;
    final ventaActualizada = venta.copyWith(
      pagado: parsedAbono,
      liquidada: liquidada,
    );
    await _ventaRepo.actualizarVenta(ventaActualizada);

    // ignore: use_build_context_synchronously
    Navigator.pop(context, true);
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva venta')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarVenta,
        icon: const Icon(Icons.check),
        label: const Text('Guardar'),
      ),

      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _selectorCliente(),
                  const SizedBox(height: 16),
                  _selectorProducto(),
                  const SizedBox(height: 16),
                  _campoAbono(),
                  const SizedBox(height: 16),
                  _campoNota(),
                  const SizedBox(height: 24),
                  _resumen(),
                ],
              ),
            ),
    );
  }

  // =========================
  // Widgets
  // =========================
  Widget _selectorCliente() {
    return DropdownButtonFormField<Cliente>(
      initialValue: _cliente,
      decoration: const InputDecoration(
        labelText: 'Cliente',
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: clientes
          .map((c) => DropdownMenuItem(value: c, child: Text(c.nombre)))
          .toList(),
      onChanged: (v) => setState(() => _cliente = v),
    );
  }

  Widget _selectorProducto() {
    return DropdownButtonFormField<Producto>(
      initialValue: _producto,
      decoration: const InputDecoration(
        labelText: 'Producto',
        prefixIcon: Icon(Icons.inventory_2_outlined),
      ),
      items: productos
          .map((p) =>
              DropdownMenuItem(value: p, child: Text('${p.nombre} - \$${p.precio}')))
          .toList(),
      onChanged: (v) => setState(() => _producto = v),
    );
  }

  Widget _campoAbono() {
    return TextField(
      controller: _abonoCtrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Abono inicial (opcional)',
        prefixIcon: const Icon(Icons.money),
        suffixText: 'Pendiente: \$${pendiente < 0 ? 0 : pendiente}',
      ),
      onChanged: (v) => setState(() => abono = int.tryParse(v) ?? 0),
    );
  }

  Widget _campoNota() {
    return TextField(
      controller: _notaCtrl,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Nota (opcional)',
        prefixIcon: Icon(Icons.note_outlined),
      ),
    );
  }

  Widget _resumen() {
    if (_producto == null) return const SizedBox();

    return Card(
      child: ListTile(
        title: const Text('Resumen'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: \$$total'),
            Text('Abonado: \$$abono'),
            Text('Pendiente: \$${pendiente < 0 ? 0 : pendiente}'),
          ],
        ),
      ),
    );
  }
}
