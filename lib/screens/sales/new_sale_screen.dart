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

  @override
  void dispose() {
    _notaCtrl.dispose();
    _abonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    clientes = await _clienteRepo.obtenerClientes();
    productos = await _productoRepo.obtenerProductos();
    setState(() => cargando = false);
  }

  int get total => _producto?.precio ?? 0;
  int get pendiente => total - abono;

  // =========================
  // Lógica de Selección con Buscador
  // =========================
  void _buscarCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ModalBuscador(
        titulo: 'Seleccionar Cliente',
        hint: 'Nombre del cliente...',
        items: clientes,
        itemBuilder: (cliente) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(cliente.nombre),
          subtitle: Text(cliente.telefono),
          onTap: () => Navigator.pop(context, cliente),
        ),
        filter: (cliente, query) => cliente.nombre.toLowerCase().contains(query.toLowerCase()),
      ),
    ).then((resultado) {
      if (resultado != null) setState(() => _cliente = resultado);
    });
  }

  void _buscarProducto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ModalBuscador(
        titulo: 'Seleccionar Producto',
        hint: 'Nombre del producto...',
        items: productos,
        itemBuilder: (producto) => ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(producto.nombre),
          trailing: Text('\$${producto.precio}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          onTap: () => Navigator.pop(context, producto),
        ),
        filter: (producto, query) => producto.nombre.toLowerCase().contains(query.toLowerCase()),
      ),
    ).then((resultado) {
      if (resultado != null) {
        setState(() {
          _producto = resultado;
          abono = 0;
          _abonoCtrl.clear();
        });
      }
    });
  }

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

    final venta = Venta(
      clienteId: _cliente!.id!,
      clienteNombre: _cliente!.nombre,
      productoId: _producto!.id!,
      productoNombre: _producto!.nombre,
      total: total,
      pagado: parsedAbono,
      liquidada: parsedAbono >= total,
      fecha: DateTime.now(),
      nota: _notaCtrl.text.trim(),
    );

    final ventaId = await _ventaRepo.insertarVenta(venta);

    if (parsedAbono > 0) {
      await _abonoRepo.insertarAbono(Abono(
        ventaId: ventaId,
        monto: parsedAbono,
        fecha: DateTime.now(),
      ));
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva venta'),
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarVenta,
        icon: const Icon(Icons.check),
        label: const Text('Guardar Venta'),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _selectorCard(
                  label: 'Cliente',
                  seleccionado: _cliente?.nombre,
                  icon: Icons.person_add_alt_1,
                  onTap: _buscarCliente,
                ),
                const SizedBox(height: 16),
                _selectorCard(
                  label: 'Producto',
                  seleccionado: _producto != null ? '${_producto!.nombre} (\$${_producto!.precio})' : null,
                  icon: Icons.shopping_bag_outlined,
                  onTap: _buscarProducto,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _abonoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Abono inicial (opcional)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  onChanged: (v) => setState(() => abono = int.tryParse(v) ?? 0),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notaCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Nota o referencia',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                _resumenDinamico(),
              ],
            ),
    );
  }

  Widget _selectorCard({required String label, String? seleccionado, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionado != null ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: seleccionado != null ? Theme.of(context).primaryColor : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: seleccionado != null ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(seleccionado ?? 'Toca para seleccionar', 
                       style: TextStyle(fontSize: 16, fontWeight: seleccionado != null ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _resumenDinamico() {
    if (_producto == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _filaResumen('Total Producto', '\$$total'),
          _filaResumen('Abono Inicial', '-\$$abono'),
          const Divider(color: Colors.white24),
          _filaResumen('Saldo Pendiente', '\$${pendiente < 0 ? 0 : pendiente}', esTotal: true),
        ],
      ),
    );
  }

  Widget _filaResumen(String label, String valor, {bool esTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: esTotal ? 18 : 14)),
          Text(valor, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: esTotal ? 22 : 16)),
        ],
      ),
    );
  }
}

// =========================
// Componente Genérico de Buscador
// =========================
class _ModalBuscador<T> extends StatefulWidget {
  final String titulo;
  final String hint;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final bool Function(T, String) filter;

  const _ModalBuscador({
    required this.titulo,
    required this.hint,
    required this.items,
    required this.itemBuilder,
    required this.filter,
  });

  @override
  State<_ModalBuscador<T>> createState() => _ModalBuscadorState<T>();
}

class _ModalBuscadorState<T> extends State<_ModalBuscador<T>> {
  late List<T> filtrados;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtrados = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(widget.titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
            ),
            onChanged: (v) {
              setState(() => filtrados = widget.items.where((item) => widget.filter(item, v)).toList());
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filtrados.length,
              itemBuilder: (context, i) => widget.itemBuilder(filtrados[i]),
            ),
          ),
        ],
      ),
    );
  }
}