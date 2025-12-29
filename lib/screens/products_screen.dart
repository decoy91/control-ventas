import 'dart:io';

import 'package:control_ventapps/models/producto.dart';
import 'package:control_ventapps/repositories/producto_repository.dart';
import 'package:control_ventapps/screens/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductoRepository _repo = ProductoRepository();
  List<Producto> productos = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final data = await _repo.obtenerProductos();
    setState(() => productos = data);
  }

  // ─────────────────────────────────────────────
  // FORMULARIO (CREAR / EDITAR)
  // ─────────────────────────────────────────────
  void _mostrarFormularioProducto({
    Producto? producto,
    int? index,
  }) {
    final nombreCtrl =
        TextEditingController(text: producto?.nombre ?? '');
    final precioCtrl = TextEditingController(
        text: producto != null ? producto.precio.toString() : '');

    String? imagenPath = producto?.imagenPath;
    final bool esEdicion = producto != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        esEdicion ? 'Editar producto' : 'Nuevo producto',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 📷 Imagen
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (img != null) {
                            modalSetState(() {
                              imagenPath = img.path;
                            });
                          }
                        },
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: imagenPath != null
                              ? Image.file(
                                  File(imagenPath!),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.add_a_photo, size: 40),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: precioCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label:
                            Text(esEdicion ? 'Guardar cambios' : 'Agregar'),
                        onPressed: () async {
                          if (nombreCtrl.text.isEmpty ||
                              precioCtrl.text.isEmpty) {
                            return;
                          }

                          if (esEdicion) {
                            final actualizado = Producto(
                              id: producto.id,
                              nombre: nombreCtrl.text,
                              precio: int.parse(precioCtrl.text),
                              imagenPath: imagenPath,
                            );

                            await _repo.actualizarProducto(actualizado);

                            setState(() {
                              productos[index!] = actualizado;
                            });
                          } else {
                            final nuevo = Producto(
                              nombre: nombreCtrl.text,
                              precio: int.parse(precioCtrl.text),
                              imagenPath: imagenPath,
                            );

                            final id =
                                await _repo.insertarProducto(nuevo);
                            nuevo.id = id;

                            setState(() {
                              productos.insert(0, nuevo);
                            });
                          }

                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // OPCIONES ⋮
  // ─────────────────────────────────────────────
  void _opcionesProducto(Producto producto, int index) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarFormularioProducto(
                    producto: producto,
                    index: index,
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarEliminarProducto(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmarEliminarProducto(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este producto?\n'
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
              await _repo.eliminarProducto(productos[index].id!);
              setState(() => productos.removeAt(index));
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioProducto(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: productos.isEmpty
            ? const Center(child: Text('No hay productos'))
            : GridView.builder(
                itemCount: productos.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final p = productos[index];

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              nombre: p.nombre,
                              precio: p.precio,
                              descripcion:
                                  p.descripcion ?? 'Producto',
                              imagenPath: p.imagenPath,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: p.imagenPath != null
                                ? Image.file(
                                    File(p.imagenPath!),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.image,
                                      size: 60,
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                12, 8, 4, 8),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '\$${p.precio}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.green,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () =>
                                      _opcionesProducto(p, index),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
