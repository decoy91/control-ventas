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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarVenta,
        icon: const Icon(Icons.check),
        label: const Text('Guardar Venta'),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                const SizedBox(height: 24),
                
                // 🔥 Campo de Abono con nuevo diseño
                _buildModernTextField(
                  label: 'Abono inicial (opcional)',
                  controller: _abonoCtrl,
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => abono = int.tryParse(v) ?? 0),
                ),
                
                const SizedBox(height: 20),

                // 🔥 Campo de Nota con nuevo diseño
                _buildModernTextField(
                  label: 'Nota o referencia',
                  controller: _notaCtrl,
                  icon: Icons.description_outlined,
                  maxLines: 2,
                ),

                const SizedBox(height: 30),
                _resumenDinamico(),
                const SizedBox(height: 100), // Espacio para que el FAB no tape el resumen
              ],
            ),
    );
  }

  // 🔥 Widget para campos de texto con el estilo de los buscadores
  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  $label",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              hintText: 'Escribe aquí...',
              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectorCard({required String label, String? seleccionado, required IconData icon, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  $label",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: seleccionado != null ? Theme.of(context).primaryColor.withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: seleccionado != null ? Theme.of(context).primaryColor : Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: seleccionado != null ? Theme.of(context).primaryColor : Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    seleccionado ?? 'Toca para seleccionar', 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: seleccionado != null ? FontWeight.bold : FontWeight.normal,
                      color: seleccionado != null ? Colors.black87 : Colors.grey.shade400
                    )
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _resumenDinamico() {
    if (_producto == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _filaResumen('Total Producto', '\$$total'),
          _filaResumen('Abono Inicial', '-\$$abono'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white24, height: 1),
          ),
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
          Text(label, style: TextStyle(color: Colors.white70, fontSize: esTotal ? 16 : 14)),
          Text(valor, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: esTotal ? 24 : 16)),
        ],
      ),
    );
  }
}

// =========================
// Componente Genérico de Buscador (Actualizado con estilo moderno)
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
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          Container(
            width: 40, height: 4, 
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
          ),
          Text(widget.titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // Buscador dentro del Modal
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (v) {
                setState(() => filtrados = widget.items.where((item) => widget.filter(item, v)).toList());
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: filtrados.length,
              separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
              itemBuilder: (context, i) => widget.itemBuilder(filtrados[i]),
            ),
          ),
        ],
      ),
    );
  }
}