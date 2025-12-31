import 'package:control_ventapps/screens/sales/sale_detail_screen.dart';
import 'package:flutter/material.dart';
import '../models/venta.dart';
import '../repositories/venta_repository.dart';
import '../screens/sales/new_sale_screen.dart';
import 'clients_screen.dart';
import 'products_screen.dart'; // ✅ Import correcto

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
  String filtro = 'todas'; // 'todas', 'pendientes', 'liquidadas'
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarVentas();
  }

  Future<void> cargarVentas() async {
    setState(() => cargando = true);
    ventas = await _ventaRepo.obtenerVentas();
    _aplicarFiltros(); // Aplica filtros iniciales
    setState(() => cargando = false);
  }

  void filtrarVentas(String tipo) {
    busqueda = ''; // Borra búsqueda al presionar un InfoCard

    // Alterna filtro: si se presiona el mismo, mostrar todas
    if (filtro == tipo) {
      filtro = 'todas';
    } else {
      filtro = tipo;
    }

    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    List<Venta> temp;

    if (filtro == 'pendientes') {
      temp = ventas.where((v) => !v.liquidada).toList();
    } else if (filtro == 'liquidadas') {
      temp = ventas.where((v) => v.liquidada).toList();
    } else {
      temp = List.from(ventas);
    }

    // Aplica búsqueda si hay texto
    if (busqueda.isNotEmpty) {
      temp = temp.where((v) =>
          v.clienteNombre.toLowerCase().contains(busqueda.toLowerCase()) ||
          v.productoNombre.toLowerCase().contains(busqueda.toLowerCase())
      ).toList();
    }

    ventasFiltradas = temp;
    setState(() {});
  }

  void actualizarBusqueda(String texto) {
    busqueda = texto;
    _aplicarFiltros();
  }

  int get pendientes => ventas.where((v) => !v.liquidada).length;
  int get liquidadas => ventas.where((v) => v.liquidada).length;

  void eliminarVenta(Venta venta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: const Text('¿Seguro que deseas eliminar esta venta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      await _ventaRepo.eliminarVenta(venta.id!);
      cargarVentas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductsScreen()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva venta'),
        onPressed: () async {
          final recargar = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewSaleScreen()),
          );

          if (recargar == true) {
            cargarVentas();
          }
        },
      ),

      body: Padding(
        padding: const EdgeInsets.all(9),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => filtrarVentas('pendientes'),
                          child: _InfoCard(
                            title: 'Pendientes',
                            value: pendientes.toString(),
                            color: Colors.orange,
                            icon: Icons.schedule,
                            activo: filtro == 'pendientes',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => filtrarVentas('liquidadas'),
                          child: _InfoCard(
                            title: 'Liquidadas',
                            value: liquidadas.toString(),
                            color: Colors.green,
                            icon: Icons.check_circle,
                            activo: filtro == 'liquidadas',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // =========================
                  // Buscador
                  // =========================
                  TextField(
                    onChanged: actualizarBusqueda,
                    decoration: InputDecoration(
                      labelText: 'Buscar ventas',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ventas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ventasFiltradas.isEmpty
                        ? const Center(child: Text('No hay ventas registradas'))
                        : ListView.builder(
                            itemCount: ventasFiltradas.length,
                            itemBuilder: (_, i) {
                              final v = ventasFiltradas[i];
                              return Dismissible(
                                key: ValueKey(v.id),
                                direction: DismissDirection.startToEnd,
                                background: Container(                                  
                                  color: Colors.red,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 16),
                                  child: const Icon(Icons.delete_forever, color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  eliminarVenta(v);
                                  return false; // Evita eliminar automáticamente, se elimina tras confirmación
                                },
                                child: Card(
                                  child: ListTile(
                                    leading: Icon(
                                      v.liquidada
                                          ? Icons.check_circle
                                          : Icons.schedule,
                                      color: v.liquidada
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    title: Text(v.clienteNombre),
                                    subtitle: Text('${v.productoNombre}\n\$${v.total}'),
                                    isThreeLine: true,
                                    trailing: Text(
                                      v.liquidada ? 'Liquidada' : 'Pendiente',
                                      style: TextStyle(
                                        color: v.liquidada
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SaleDetailScreen(venta: v),
                                        ),
                                      );
                                      cargarVentas();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

// =========================
// Widgets
// =========================
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool activo;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: activo ? color.withOpacity(0.15) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: activo ? color.withOpacity(0.25) : color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
