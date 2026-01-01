import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart'; // Asegúrate de agregar esta dependencia en pubspec.yaml
import 'activation_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _busqueda = "";
  final TextEditingController _searchCtrl = TextEditingController();

  // Generador de códigos aleatorios (Ej: 4A7K-9P2Z)
  String _generarCodigoAleatorio() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    Random rnd = Random();
    String r(int len) => List.generate(len, (index) => chars[rnd.nextInt(chars.length)]).join();
    return "${r(4)}-${r(4)}";
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ActivationScreen()));
    }
  }

  int _calcularDiasRestantes(Timestamp? fecha) {
    if (fecha == null) return 0;
    final exp = fecha.toDate();
    final diff = exp.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  // 🔥 Función para compartir el código
  void _compartirCodigo(String codigo, int dias) {
    String mensaje = "¡Hola! Aquí tienes tu código de activación:\n\n"
        "🔑 Código: $codigo\n"
        "⏳ Duración: $dias días\n\n"
        "Espero disfrutes la App.";
    SharePlus.instance.share(ShareParams(text: mensaje));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Licencias"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => _cerrarSesion(context)
          )
        ],
      ),
      body: Column(
        children: [
          // 🔥 BUSCADOR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) {
                setState(() => _busqueda = value.trim().toUpperCase());
              },
              decoration: InputDecoration(
                hintText: "Buscar por código...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _busqueda = "");
                    })
                  : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('licencias').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Filtrar por código y excluir administradores
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final codigo = (data['codigo_activacion'] ?? "").toString().toUpperCase();
                  return data['is_admin'] != true && codigo.contains(_busqueda);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No se encontraron licencias."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    int dias = _calcularDiasRestantes(data['fecha_expiracion']);
                    bool tieneDevice = data['device_id'] != null && data['device_id'] != "";
                    String codigo = data['codigo_activacion'] ?? "";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        onTap: () => _mostrarDialogoEditar(context, doc),
                        leading: CircleAvatar(
                          backgroundColor: dias > 0 ? (dias > 5 ? Colors.green : Colors.orange) : Colors.red,
                          child: Text("$dias", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        title: Text(codigo, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        subtitle: Text(tieneDevice ? "📱 Vinculado" : "🔓 Disponible"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🔥 BOTÓN COMPARTIR
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.blue),
                              onPressed: () => _compartirCodigo(codigo, dias),
                              tooltip: "Compartir código",
                            ),
                            if (tieneDevice)
                              IconButton(
                                icon: const Icon(Icons.phonelink_erase, color: Colors.orange),
                                onPressed: () => _liberarDevice(context, doc.reference),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmarEliminacion(context, doc.reference),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCrear(context),
        label: const Text("Nueva Licencia"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // --- MISMOS DIÁLOGOS DE CREAR Y EDITAR ANTERIORES ---

  void _mostrarDialogoCrear(BuildContext context) {
    final codeCtrl = TextEditingController(text: _generarCodigoAleatorio());
    final daysCtrl = TextEditingController(text: "30");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Nueva Licencia"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: InputDecoration(
                  labelText: "Código",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.casino_outlined),
                    onPressed: () => setState(() => codeCtrl.text = _generarCodigoAleatorio()),
                  ),
                ),
              ),
              TextField(controller: daysCtrl, decoration: const InputDecoration(labelText: "Días"), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
            ElevatedButton(
              onPressed: () async {
                int dias = int.tryParse(daysCtrl.text) ?? 30;
                await FirebaseFirestore.instance.collection('licencias').add({
                  'codigo_activacion': codeCtrl.text.trim().toUpperCase(),
                  'device_id': '',
                  'is_admin': false,
                  'fecha_expiracion': Timestamp.fromDate(DateTime.now().add(Duration(days: dias))),
                });
                // ignore: use_build_context_synchronously
                if (mounted) Navigator.pop(context);
              },
              child: const Text("CREAR"),
            )
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditar(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final daysCtrl = TextEditingController(text: _calcularDiasRestantes(data['fecha_expiracion']).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar: ${data['codigo_activacion']}"),
        content: TextField(
          controller: daysCtrl, 
          decoration: const InputDecoration(labelText: "Nuevos días totales desde hoy"), 
          keyboardType: TextInputType.number
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              int dias = int.tryParse(daysCtrl.text) ?? 0;
              await doc.reference.update({
                'fecha_expiracion': Timestamp.fromDate(DateTime.now().add(Duration(days: dias))),
              });
              // ignore: use_build_context_synchronously
              if (mounted) Navigator.pop(context);
            },
            child: const Text("GUARDAR"),
          )
        ],
      ),
    );
  }

  void _liberarDevice(BuildContext context, DocumentReference ref) {
    ref.update({'device_id': ''});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dispositivo desvinculado")));
  }

  void _confirmarEliminacion(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar"),
        content: const Text("¿Borrar permanentemente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(onPressed: () { ref.delete(); Navigator.pop(context); }, child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}