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
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarVentas();
  }

  Future<void> cargarVentas() async {
    setState(() => cargando = true);
    ventas = await _ventaRepo.obtenerVentas();
    setState(() => cargando = false);
  }

  int get pendientes => ventas.where((v) => !v.liquidada).length;
  int get liquidadas => ventas.where((v) => v.liquidada).length;

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
                MaterialPageRoute(builder: (_) => ProductsScreen()), // ❌ quitar const si da error
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
            MaterialPageRoute(builder: (_) => NewSaleScreen()), // ❌ quitar const si da error
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
                        child: _InfoCard(
                          title: 'Pendientes',
                          value: pendientes.toString(),
                          color: Colors.orange,
                          icon: Icons.schedule,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Liquidadas',
                          value: liquidadas.toString(),
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

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
                    child: ventas.isEmpty
                        ? const Center(child: Text('No hay ventas registradas'))
                        : ListView.builder(
                            itemCount: ventas.length,
                            itemBuilder: (_, i) {
                              final v = ventas[i];

                              return Card(
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
                                  subtitle: Text(
                                    '${v.productoNombre}\n\$${v.total}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Text(
                                    v.liquidada
                                        ? 'Liquidada'
                                        : 'Pendiente',
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
                                        builder: (_) =>
                                            SaleDetailScreen(venta: v),
                                      ),
                                    );
                                    cargarVentas();
                                  },
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

  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
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
