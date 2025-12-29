import 'package:flutter/material.dart';

class ClientDetailScreen extends StatelessWidget {
  final String nombre;

  const ClientDetailScreen({
    super.key,
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    // 🔸 Ventas simuladas del cliente
    final ventas = [
      {
        "producto": "TV Samsung 55\"",
        "total": 8000,
        "pagado": 5000,
        "pendiente": true,
      },
      {
        "producto": "Celular Xiaomi",
        "total": 4500,
        "pagado": 4500,
        "pendiente": false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Info del cliente
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(nombre),
                subtitle: const Text('Cliente registrado'),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Compras',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // 📋 Lista de ventas
            Expanded(
              child: ListView.builder(
                itemCount: ventas.length,
                itemBuilder: (context, index) {
                  final venta = ventas[index];

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        venta["pendiente"] as bool
                            ? Icons.schedule
                            : Icons.check_circle,
                        color: venta["pendiente"] as bool
                            ? Colors.orange
                            : Colors.green,
                      ),
                      title: Text(venta["producto"].toString()),
                      subtitle: Text(
                        'Pagado: \$${venta["pagado"]} / \$${venta["total"]}',
                      ),
                      trailing: Text(
                        venta["pendiente"] as bool
                            ? 'Pendiente'
                            : 'Liquidado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: venta["pendiente"] as bool
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                      onTap: () {
                        // 👉 luego: detalle de venta
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