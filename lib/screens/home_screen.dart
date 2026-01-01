import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 Importado
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Importado
import '../models/venta.dart';
import '../repositories/venta_repository.dart';
import '../repositories/cliente_repository.dart';
import '../screens/sales/new_sale_screen.dart';
import '../screens/sales/sale_detail_screen.dart';
import 'clients_screen.dart';
import 'products_screen.dart';
import 'activation_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ventaRepo = VentaRepository();
  final _clienteRepo = ClienteRepository();
  List<Venta> ventas = [];
  List<Venta> ventasFiltradas = [];
  bool cargando = true;
  String filtro = 'todas';
  String busqueda = '';
  
  // Variable para la licencia
  String diasRestantesMsg = "Cargando..."; 

  @override
  void initState() {
    super.initState();
    cargarVentas();
    _obtenerDiasRestantes(); // 🔥 Llamada al iniciar
  }

  // 🔥 Lógica para calcular días restantes desde Firebase
  Future<void> _obtenerDiasRestantes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final codigo = prefs.getString('codigo_licencia');

      if (codigo != null) {
        final doc = await FirebaseFirestore.instance
            .collection('licencias')
            .doc(codigo)
            .get();

        if (doc.exists) {
          final Timestamp? fechaExp = doc.data()?['fecha_expiracion'];
          if (fechaExp != null) {
            final ahora = DateTime.now();
            final diferencia = fechaExp.toDate().difference(ahora).inDays;
            
            if (mounted) {
              setState(() {
                if (diferencia <= 0) {
                  diasRestantesMsg = "Licencia expirada ⚠️";
                } else if (diferencia <= 5) {
                  diasRestantesMsg = "Vence en $diferencia días ⏳";
                } else {
                  diasRestantesMsg = "Días de licencia: $diferencia";
                }
              });
            }
            return;
          }
        }
      }
      if (mounted) setState(() => diasRestantesMsg = "Sin licencia activa");
    } catch (e) {
      if (mounted) setState(() => diasRestantesMsg = "Licencia activa");
    }
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
  
  Future<bool> _confirmarSalidaApp() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("¿Salir de la aplicación?"),
        content: const Text("Se cerrará Mis Ventas."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("SALIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  void _contactarCliente(Venta v) async {
    final saldoPendiente = v.total - v.pagado;
    final cliente = await _clienteRepo.obtenerClientePorId(v.clienteId);
    
    if (cliente == null || cliente.telefono.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("El cliente no tiene teléfono registrado"))
        );
      }
      return;
    }

    String mensaje = v.liquidada
        ? "👋 Hola ${v.clienteNombre}, gracias por liquidar tu compra de ${v.productoNombre}. ¡Espero que lo disfrutes!😎"
        : "👋 Hola ${v.clienteNombre}, te contacto para recordarte el saldo pendiente de 💸 \$$saldoPendiente por tu compra de ${v.productoNombre}.";

    final url = "https://wa.me/${cliente.telefono}?text=${Uri.encodeComponent(mensaje)}";
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _eliminarVenta(int id) async {
    await _ventaRepo.eliminarVenta(id);
    cargarVentas();
  }

  Future<bool?> _confirmarEliminacion(Venta v) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Eliminar Venta"),
        content: Text("¿Deseas borrar la venta de ${v.clienteNombre}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCerrarSesion() async {
  final bool? salir = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text("Cerrar Sesión"),
      content: const Text("¿Estás seguro de que deseas salir?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text("CANCELAR")),
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  // 🔥 Verificamos si 'salir' es true Y si el widget sigue montado
  if (salir == true && mounted) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('activado', false);

    // 🔥 Volvemos a verificar 'mounted' después del segundo await
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ActivationScreen()),
      (route) => false,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final quiereSalir = await _confirmarSalidaApp();
        if (quiereSalir) {
          await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
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
                _buildStats(),
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
            final recargar = await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewSaleScreen()));
            if (recargar == true) cargarVentas();
          },
          icon: const Icon(Icons.add),
          label: const Text('Nueva Venta'),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 Mostramos los días restantes aquí
            Text(
              diasRestantesMsg, 
              style: TextStyle(
                color: diasRestantesMsg.contains('expirada') ? Colors.red : Colors.grey.shade600, 
                fontSize: 13,
                fontWeight: FontWeight.w500
              )
            ),
            const Text(
              "Mis Ventas", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        Row(
          children: [
            _CircleIconButton(icon: Icons.people_outline, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen()))),
            const SizedBox(width: 8),
            _CircleIconButton(icon: Icons.inventory_2_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))),
            const SizedBox(width: 8),
            _CircleIconButton(icon: Icons.logout_rounded, onTap: _confirmarCerrarSesion),
          ],
        )
      ],
    );
  }

  Widget _buildStats() {
    int pendientes = ventas.where((v) => !v.liquidada).length;
    int liquidadas = ventas.where((v) => v.liquidada).length;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Pendientes', 
            count: pendientes, 
            color: Colors.orange, 
            isActive: filtro == 'pendientes', 
            onTap: () => filtrarVentas('pendientes')
          )
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _StatCard(
            label: 'Pagadas', 
            count: liquidadas, 
            color: Colors.green, 
            isActive: filtro == 'liquidadas', 
            onTap: () => filtrarVentas('liquidadas')
          )
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) { 
          busqueda = v; 
          _aplicarFiltros(); 
        },
        decoration: InputDecoration(
          hintText: 'Buscar cliente o producto...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSalesList() {
    if (ventasFiltradas.isEmpty) return const Center(child: Text("Sin ventas registradas", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      itemCount: ventasFiltradas.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (_, i) {
        final v = ventasFiltradas[i];
        return Dismissible(
          key: Key(v.id.toString()),
          background: Container(
            color: Colors.redAccent, 
            alignment: Alignment.centerLeft, 
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.green, 
            alignment: Alignment.centerRight, 
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.wechat, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              return await _confirmarEliminacion(v);
            } else {
              _contactarCliente(v);
              return false;
            }
          },
          onDismissed: (direction) => _eliminarVenta(v.id!),
          child: _SaleCard(
            venta: v,
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => SaleDetailScreen(venta: v)));
              cargarVentas();
            },
          ),
        );
      },
    );
  }
}

// ==========================================
// WIDGETS DE APOYO
// ==========================================

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _StatCard({
    required this.label, 
    required this.count, 
    required this.color, 
    required this.isActive, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label, 
              style: TextStyle(
                color: isActive ? Colors.white : color, 
                fontWeight: FontWeight.bold, 
                fontSize: 13
              )
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(), 
              style: TextStyle(
                color: isActive ? Colors.white : color, 
                fontSize: 24, 
                fontWeight: FontWeight.bold
              )
            ),
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
    final int restante = venta.total - venta.pagado;
    final double progreso = venta.total > 0 ? (venta.pagado / venta.total) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: (venta.liquidada ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    child: Icon(
                      venta.liquidada ? Icons.check_circle_rounded : Icons.schedule_rounded, 
                      color: venta.liquidada ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venta.clienteNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(venta.productoNombre, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${venta.total}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(venta.liquidada ? "Liquidada" : "Pendiente", 
                           style: TextStyle(color: venta.liquidada ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progreso,
                  backgroundColor: Colors.grey.shade100,
                  color: venta.liquidada ? Colors.green : Colors.blue,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniInfo("Abonado", "\$${venta.pagado}", Colors.blueGrey),
                  if (!venta.liquidada)
                    _miniInfo("Restante", "\$$restante", Colors.redAccent)
                  else
                    const Icon(Icons.verified_rounded, color: Colors.green, size: 16),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String monto, Color color) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(monto, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)]
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 20), 
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}