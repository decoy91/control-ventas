import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/producto.dart';
import '../repositories/producto_repository.dart';
import '../screens/product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repo = ProductoRepository();
  final _picker = ImagePicker();
  final _searchCtrl = TextEditingController();
  
  List<Producto> _todosLosProductos = [];
  List<Producto> _productosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    final data = await _repo.obtenerProductos();
    setState(() {
      _todosLosProductos = data;
      _productosFiltrados = data;
    });
  }

  void _filtrarProductos(String query) {
    setState(() {
      _productosFiltrados = _todosLosProductos
          .where((p) =>
              p.nombre.toLowerCase().contains(query.toLowerCase()) ||
              (p.descripcion ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Lógica para eliminar desde el formulario o lista
  Future<void> _eliminarProducto(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _repo.eliminarProducto(id);
      _cargarProductos();
      if (mounted) Navigator.pop(context); // Cierra el modal de edición
    }
  }

  void _mostrarFormularioProducto({Producto? producto}) {
    final nombreCtrl = TextEditingController(text: producto?.nombre ?? '');
    final precioCtrl = TextEditingController(text: producto?.precio.toString() ?? '');
    String? imagenPath = producto?.imagenPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 12
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4, 
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    producto == null ? 'Nuevo Producto' : 'Editar Producto',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  // BOTÓN ELIMINAR (Solo si existe el producto)
                  if (producto != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _eliminarProducto(producto.id!),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (img != null) modalSetState(() => imagenPath = img.path);
                },
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    image: imagenPath != null && File(imagenPath!).existsSync()
                        ? DecorationImage(image: FileImage(File(imagenPath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imagenPath == null || !File(imagenPath!).existsSync()
                      ? const Center(child: Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey))
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 12),
              TextField(controller: precioCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio', prefixIcon: Icon(Icons.attach_money))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nombreCtrl.text.isEmpty || precioCtrl.text.isEmpty) return;
                    final p = Producto(
                      id: producto?.id,
                      nombre: nombreCtrl.text.trim(),
                      precio: int.parse(precioCtrl.text),
                      imagenPath: imagenPath,
                    );
                    producto != null ? await _repo.actualizarProducto(p) : await _repo.insertarProducto(p);
                    _cargarProductos();
                    // ignore: use_build_context_synchronously
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Inventario'),
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioProducto(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filtrarProductos,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _filtrarProductos(''); }) 
                  : null,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          Expanded(
            child: _productosFiltrados.isEmpty
                ? const Center(child: Text('No hay productos que coincidan'))
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _productosFiltrados.length,
                    itemBuilder: (_, i) {
                      final p = _productosFiltrados[i];
                      final bool existeImg = p.imagenPath != null && File(p.imagenPath!).existsSync();

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(
                                nombre: p.nombre, precio: p.precio, descripcion: p.descripcion ?? '', imagenPath: p.imagenPath,
                              ))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      color: Colors.grey.shade100,
                                      child: existeImg
                                          ? Image.file(File(p.imagenPath!), fit: BoxFit.cover)
                                          : const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('\$${p.precio}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white.withValues(alpha: 0.9),
                                child: IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.black87),
                                  onPressed: () => _mostrarFormularioProducto(producto: p),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}