import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cliente.dart';
import '../repositories/cliente_repository.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _repo = ClienteRepository();

  List<Cliente> clientes = [];

  bool mostrarFormulario = false;
  Cliente? clienteEditando;

  final nombreCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final notasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    final data = await _repo.obtenerClientes();
    setState(() => clientes = data);
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    telefonoCtrl.dispose();
    notasCtrl.dispose();
    super.dispose();
  }

  // =========================
  // WhatsApp
  // =========================
  void abrirWhatsApp(String telefono) async {
    final numero = telefono.replaceAll(RegExp(r'\D'), '');
    final appUri = Uri.parse("whatsapp://send?phone=$numero&text=Hola");
    final webUri = Uri.parse("https://wa.me/$numero?text=Hola");

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  // =========================
  // Formulario
  // =========================
  void abrirFormulario([Cliente? cliente]) {
    clienteEditando = cliente;

    if (cliente != null) {
      nombreCtrl.text = cliente.nombre;
      telefonoCtrl.text = cliente.telefono;
      notasCtrl.text = cliente.notas ?? '';
    } else {
      nombreCtrl.clear();
      telefonoCtrl.clear();
      notasCtrl.clear();
    }

    setState(() => mostrarFormulario = true);
  }

  void cerrarFormulario() {
    setState(() {
      mostrarFormulario = false;
      clienteEditando = null;
    });
  }

  Future<void> guardarCliente() async {
    if (nombreCtrl.text.trim().isEmpty) return;

    if (clienteEditando != null) {
      clienteEditando!
        ..nombre = nombreCtrl.text.trim()
        ..telefono = telefonoCtrl.text.trim()
        ..notas = notasCtrl.text.trim();

      await _repo.actualizarCliente(clienteEditando!);
    } else {
      final nuevo = Cliente(
        nombre: nombreCtrl.text.trim(),
        telefono: telefonoCtrl.text.trim(),
        notas: notasCtrl.text.trim(),
      );

      await _repo.insertarCliente(nuevo);
    }

    cerrarFormulario();
    _cargarClientes();
  }

  void confirmarEliminarCliente(Cliente cliente) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar cliente'),
          content: Text(
            '¿Estás seguro de que deseas eliminar a "${cliente.nombre}"?\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await _repo.eliminarCliente(cliente.id!);
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _cargarClientes();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // Modal de opciones del cliente
  // =========================
  void mostrarOpcionesCliente(Cliente cliente) {
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
                abrirFormulario(cliente);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar'),
              onTap: () {
                Navigator.pop(context);
                confirmarEliminarCliente(cliente);
              },
            ),
            if (cliente.telefono.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.wechat, color: Colors.green),
                title: const Text('Abrir WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  abrirWhatsApp(cliente.telefono);
                },
              ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Detalle cliente
  // =========================
  void verDetalleCliente(Cliente cliente) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cliente.nombre,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (cliente.telefono.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(cliente.telefono),
                  trailing: IconButton(
                    icon: const Icon(Icons.wechat, color: Colors.green),
                    onPressed: () => abrirWhatsApp(cliente.telefono),
                  ),
                ),
              if ((cliente.notas ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notas',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(cliente.notas!),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          buildLista(),
          if (mostrarFormulario) ...[
            GestureDetector(
              onTap: cerrarFormulario,
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
            Center(child: buildFormulario()),
          ],
        ],
      ),
    );
  }

  Widget buildLista() {
    if (clientes.isEmpty) return const Center(child: Text('No hay clientes'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientes.length,
      itemBuilder: (_, i) {
        final c = clientes[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(c.nombre),
            subtitle: c.telefono.isNotEmpty ? Text(c.telefono) : null,
            onTap: () => verDetalleCliente(c),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => mostrarOpcionesCliente(c),
            ),
          ),
        );
      },
    );
  }

  Widget buildFormulario() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              clienteEditando == null ? 'Nuevo cliente' : 'Editar cliente',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notasCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: cerrarFormulario,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: guardarCliente,
                    child: const Text('Guardar'),
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
