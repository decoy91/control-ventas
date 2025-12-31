import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/venta.dart';
import '../repositories/venta_repository.dart';
import '../screens/sales/new_sale_screen.dart';
import '../screens/sales/sale_detail_screen.dart';
import 'clients_screen.dart';
import 'products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ventaRepo = VentaRepository();
  List<Venta> ventas = [];
  List<Venta> ventasFiltradas = [];
  bool cargando = true;
  String filtro = 'todas';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarVentas();
  }

  Future<void> cargarVentas() async {
    setState(() => cargando = true);
    ventas = await _ventaRepo.obtenerVentas();
    _aplicarFiltros();
    setState(() => cargando = false);
  }

  void _aplicarFiltros() {
    List<Venta> temp = List.from(ventas);

    if (filtro == 'pendientes') {
      temp = temp.where((v) => !v.liquidada).toList();
    } else if (filtro == 'liquidadas') {
      temp = temp.where((v) => v.liquidada).toList();
    }

    if (busqueda.isNotEmpty) {
      temp = temp.where((v) =>
          v.clienteNombre.toLowerCase().contains(busqueda.toLowerCase()) ||
          v.productoNombre.toLowerCase().contains(busqueda.toLowerCase())).toList();
    }

    setState(() => ventasFiltradas = temp);
  }

  void filtrarVentas(String tipo) {
    setState(() {
      filtro = (filtro == tipo) ? 'todas' : tipo;
      _aplicarFiltros();
    });
  }

  // ==========================================
  // Confirmación de salida de la App
  // ==========================================
  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Salir de la aplicación?"),
        content: const Text("Se cerrará la sesión actual de Mis Ventas."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("SALIR"),
          ),
        ],
      ),
    ) ?? false;
  }

  void _contactarCliente(Venta v) async {
    final saldoPendiente = v.total - v.pagado;
    String mensaje;

    if (v.liquidada) {
      mensaje = "👋 Hola ${v.clienteNombre}, gracias por liquidar tu compra de ${v.productoNombre}. ¡Espero que lo disfrutes!😎";
    } else {
      mensaje = "👋 Hola ${v.clienteNombre}, te contacto para saludarte y recordarte el saldo pendiente de 💸 \$$saldoPendiente por tu compra de ${v.productoNombre}. ¿Cuándo podrías realizar tu próximo abono?";
    }

    final encodeMsg = Uri.encodeComponent(mensaje);
    final uri = Uri.parse("whatsapp://send?text=$encodeMsg");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir WhatsApp")),
        );
      }
    }
  }

  Future<void> _eliminarVenta(int id) async {
    await _ventaRepo.eliminarVenta(id);
    cargarVentas();
  }

  Future<bool?> _confirmarEliminacion(Venta v) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Venta"),
        content: Text("¿Deseas borrar definitivamente la venta de ${v.clienteNombre}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimary = Theme.of(context).primaryColor;

    // ✅ Uso de PopScope para interceptar el botón atrás
    return PopScope(
      canPop: false, // Bloqueamos la salida automática
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          // Si el usuario confirma, cerramos la app manualmente
          Navigator.of(context).pop(); 
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStats(colorPrimary),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: cargando 
                    ? const Center(child: CircularProgressIndicator()) 
                    : _buildSalesList(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final recargar = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewSaleScreen()),
            );
            if (recargar == true) cargarVentas();
          },
          icon: const Icon(Icons.add),
          label: const Text('Nueva Venta'),
        ),
      ),
    );
  }

  // --- El resto de tus métodos widgets se mantienen igual ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hola 👋", style: TextStyle(color: Colors.grey, fontSize: 16)),
            Text("Mis Ventas", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          children: [
            _CircleIconButton(
              icon: Icons.people_outline, 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen()))
            ),
            const SizedBox(width: 10),
            _CircleIconButton(
              icon: Icons.inventory_2_outlined, 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStats(Color primary) {
    int pendientes = ventas.where((v) => !v.liquidada).length;
    int liquidadas = ventas.where((v) => v.liquidada).length;

    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Pendientes', 
          count: pendientes, 
          color: Colors.orange, 
          isActive: filtro == 'pendientes',
          onTap: () => filtrarVentas('pendientes')
        )),
        const SizedBox(width: 15),
        Expanded(child: _StatCard(
          label: 'Pagadas', 
          count: liquidadas, 
          color: Colors.green, 
          isActive: filtro == 'liquidadas',
          onTap: () => filtrarVentas('liquidadas')
        )),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) {
        busqueda = v;
        _aplicarFiltros();
      },
      decoration: const InputDecoration(
        hintText: 'Buscar por cliente o producto...',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }

  Widget _buildSalesList() {
    if (ventasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("No hay ventas registradas", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: ventasFiltradas.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (_, i) {
        final v = ventasFiltradas[i];
        
        return Dismissible(
          key: Key(v.id.toString()),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.white),
                Text("Eliminar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Cobrar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.wechat_rounded, color: Colors.white),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              return await _confirmarEliminacion(v);
            } else {
              _contactarCliente(v);
              return false;
            }
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              _eliminarVenta(v.id!);
            }
          },
          child: _SaleCard(
            venta: v, 
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => SaleDetailScreen(venta: v)));
              cargarVentas();
            }
          ),
        );
      },
    );
  }
}

// --- Se mantienen los Widgets de Apoyo _StatCard, _SaleCard y _CircleIconButton ---
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _StatCard({required this.label, required this.count, required this.color, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color : Colors.grey.shade200),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(count.toString(), style: TextStyle(color: isActive ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Venta venta;
  final VoidCallback onTap;

  const _SaleCard({required this.venta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: (venta.liquidada ? Colors.green : Colors.orange).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            venta.liquidada ? Icons.check_rounded : Icons.timer_outlined,
            color: venta.liquidada ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(venta.clienteNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(venta.productoNombre),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${venta.total}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(venta.liquidada ? 'Liquidada' : 'Pendiente', 
              style: TextStyle(color: venta.liquidada ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IconButton(icon: Icon(icon, color: Colors.black87), onPressed: onTap),
    );
  }
}