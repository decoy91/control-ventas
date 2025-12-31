import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/cliente.dart';
import '../repositories/cliente_repository.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _repo = ClienteRepository();
  List<Cliente> _todosLosClientes = [];
  List<Cliente> _clientesFiltrados = [];
  
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    final data = await _repo.obtenerClientes();
    setState(() {
      _todosLosClientes = data;
      _clientesFiltrados = data;
    });
  }

  void _filtrarClientes(String query) {
    setState(() {
      _clientesFiltrados = _todosLosClientes
          .where((c) =>
              c.nombre.toLowerCase().contains(query.toLowerCase()) ||
              c.telefono.contains(query))
          .toList();
    });
  }

  Future<void> _agregarDesdeContactos() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      try {
        final contacto = await ContactsService.openDeviceContactPicker();
        if (contacto != null) {
          final nombre = contacto.displayName ?? '';
          String telefono = '';
          if (contacto.phones != null && contacto.phones!.isNotEmpty) {
            telefono = contacto.phones!.first.value?.replaceAll(RegExp(r'\s+'), '') ?? '';
          }
          setState(() {
            _nombreCtrl.text = nombre;
            _telefonoCtrl.text = telefono;
          });
          _abrirFormulario();
        }
      } catch (e) {
        _notificar('Error al acceder a contactos: $e');
      }
    }
  }

  void _abrirWhatsApp(String tel) async {
    final num = tel.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse("https://wa.me/$num");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Lógica para eliminar cliente
  Future<void> _eliminarCliente(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: const Text('Esto no borrará sus ventas, pero ya no aparecerá en esta lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ELIMINAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      await _repo.eliminarCliente(id);
      _cargarClientes();
      if (mounted) Navigator.pop(context); // Cierra el modal de edición
    }
  }

  void _abrirFormulario([Cliente? cliente]) {
    if (cliente != null) {
      _nombreCtrl.text = cliente.nombre;
      _telefonoCtrl.text = cliente.telefono;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(cliente == null ? 'Nuevo Cliente' : 'Editar Cliente', 
                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (cliente != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminarCliente(cliente.id!),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: _telefonoCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nombreCtrl.text.trim().isEmpty) return;
                  if (cliente != null) {
                    cliente.nombre = _nombreCtrl.text.trim();
                    cliente.telefono = _telefonoCtrl.text.trim();
                    await _repo.actualizarCliente(cliente);
                  } else {
                    await _repo.insertarCliente(Cliente(nombre: _nombreCtrl.text.trim(), telefono: _telefonoCtrl.text.trim()));
                  }
                  _cargarClientes();
                  // ignore: use_build_context_synchronously
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            )
          ],
        ),
      ),
    ).then((_) {
      _nombreCtrl.clear();
      _telefonoCtrl.clear();
    });
  }

  void _notificar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Clientes'),
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarMenuOpciones(),
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filtrarClientes,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o número...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _filtrarClientes(''); }) 
                  : null,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          Expanded(
            child: _clientesFiltrados.isEmpty
                ? const Center(child: Text('No se encontraron clientes'))
                : ListView.builder(
                    // ✅ EL CAMBIO IMPORTANTE: Padding inferior de 80 para que el FAB no tape nada
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                    itemCount: _clientesFiltrados.length,
                    itemBuilder: (_, i) {
                      final c = _clientesFiltrados[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            child: Text(c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?'),
                          ),
                          title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(c.telefono),
                          trailing: c.telefono.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.wechat_rounded, color: Colors.green), onPressed: () => _abrirWhatsApp(c.telefono))
                            : null,
                          onTap: () => _abrirFormulario(c),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _mostrarMenuOpciones() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Ingreso manual'),
              onTap: () { Navigator.pop(context); _abrirFormulario(); },
            ),
            ListTile(
              leading: const Icon(Icons.contact_phone_outlined),
              title: const Text('Desde contactos del teléfono'),
              onTap: () { Navigator.pop(context); _agregarDesdeContactos(); },
            ),
          ],
        ),
      ),
    );
  }
}