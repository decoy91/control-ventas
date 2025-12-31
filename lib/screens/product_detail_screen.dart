import 'dart:io';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String nombre;
  final int precio;
  final String descripcion;
  final String? imagenPath;

  const ProductDetailScreen({
    super.key,
    required this.nombre,
    required this.precio,
    required this.descripcion,
    this.imagenPath,
  });

  @override
  Widget build(BuildContext context) {
    // Verificamos si la imagen existe físicamente en el dispositivo
    final bool existeImagen = imagenPath != null && File(imagenPath!).existsSync();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // AppBar flotante con imagen (SliverAppBar)
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: existeImagen
                  ? Hero(
                      tag: nombre, // Animación Hero si la usas desde el Grid
                      child: Image.file(
                        File(imagenPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
          ),

          // Contenido de los detalles
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiqueta de Precio
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '\$${precio.toString()}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre del Producto
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Separador sutil
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 24),

                  // Título Descripción
                  // const Text(
                  //   'Descripción',
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  // const SizedBox(height: 12),

                  // Texto Descripción
                  // Text(
                  //   descripcion.isEmpty ? 'Sin descripción disponible.' : descripcion,
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     height: 1.6,
                  //     color: Colors.grey.shade700,
                  //   ),
                  // ),
                  
                  const SizedBox(height: 100), // Espacio para no chocar con el botón inferior
                ],
              ),
            ),
          ),
        ],
      ),
      
      // // Botón de acción principal
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: Container(
      //   padding: const EdgeInsets.symmetric(horizontal: 48),
      //   width: double.infinity,
      //   child: ElevatedButton.icon(
      //     onPressed: () {
      //       // Aquí podrías añadir una función para compartir el producto
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(content: Text('Función de compartir próximamente')),
      //       );
      //     },
      //     icon: const Icon(Icons.share_outlined),
      //     label: const Text('Compartir Producto'),
      //     style: ElevatedButton.styleFrom(
      //       padding: const EdgeInsets.symmetric(vertical: 16),
      //     ),
      //   ),
      // ),
    );
  }
}