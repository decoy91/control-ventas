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
    return Scaffold(
      appBar: AppBar(title: Text(nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 📷 Imagen correcta
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagenPath != null
                ? Image.file(
                    File(imagenPath!),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 80),
                  ),
          ),

          const SizedBox(height: 16),

          Text(
            nombre,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '\$$precio',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            descripcion,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
