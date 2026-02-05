import 'package:flutter/material.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Producto producto;

  const ProductDetailScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final bool lowStock = producto.stockActual <= producto.alertaStockMinimo;

    return Scaffold(
      appBar: AppBar(
        title: Text(producto.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Editar producto (próximamente)
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con Icono y Nombre
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: lowStock
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      lowStock
                          ? Icons.warning_amber_rounded
                          : Icons.inventory_2_outlined,
                      size: 40,
                      color: lowStock ? Colors.red : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    producto.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    producto.categoria?.nombre ?? 'Sin Categoría',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Información de Inventario'),
                  _buildInfoCard([
                    _buildInfoRow('SKU', producto.sku),
                    _buildInfoRow(
                      'Unidad',
                      producto.unidadMedida ?? 'No especificada',
                    ),
                    _buildInfoRow(
                      'Stock Actual',
                      '${producto.stockActual}',
                      valueColor: lowStock ? Colors.red : Colors.green,
                      isBold: true,
                    ),
                    _buildInfoRow(
                      'Mínimo Alerta',
                      '${producto.alertaStockMinimo}',
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Ubicación y Costo'),
                  _buildInfoCard([
                    _buildInfoRow(
                      'Ubicación',
                      producto.ubicacion ?? 'Bodega Principal',
                    ),
                    _buildInfoRow(
                      'Precio Costo',
                      producto.precioCosto != null
                          ? '\$${producto.precioCosto}'
                          : 'N/A',
                      valueColor: Colors.blueGrey,
                    ),
                  ]),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Acción de añadir a orden
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Añadir a Orden de Trabajo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
