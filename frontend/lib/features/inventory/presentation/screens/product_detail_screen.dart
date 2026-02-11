import 'package:flutter/material.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/core/database/database_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final Producto producto;

  const ProductDetailScreen({super.key, required this.producto});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Map<String, dynamic>> _inventoryDetails = [];
  bool _isLoadingInventory = true;

  @override
  void initState() {
    super.initState();
    _fetchInventoryDetails();
  }

  Future<void> _fetchInventoryDetails() async {
    try {
      final details = await DatabaseHelper().getInventarioProducto(
        widget.producto.id,
      );
      if (mounted) {
        setState(() {
          _inventoryDetails = details;
          _isLoadingInventory = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching inventory details: $e');
      if (mounted) {
        setState(() => _isLoadingInventory = false);
      }
    }
  }

  bool get _hasReusedParts {
    // Check if any inventory item comes from a recovery warehouse
    return _inventoryDetails.any(
      (item) =>
          item['bodega_tipo'] == 'recuperacion' && (item['cantidad'] ?? 0) > 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool lowStock =
        widget.producto.stockActual <= widget.producto.alertaStockMinimo;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto.nombre),
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
                    widget.producto.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.producto.categoria?.nombre ?? 'Sin Categoría',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_hasReusedParts) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'REPUESTO RECUPERADO DISPONIBLE',
                            style: TextStyle(
                              color: Colors.deepOrange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    _buildInfoRow('SKU', widget.producto.sku),
                    _buildInfoRow(
                      'Unidad',
                      widget.producto.unidadMedida ?? 'No especificada',
                    ),
                    _buildInfoRow(
                      'Stock Total',
                      '${widget.producto.stockActual}',
                      valueColor: lowStock ? Colors.red : Colors.green,
                      isBold: true,
                    ),
                    _buildInfoRow(
                      'Mínimo Alerta',
                      '${widget.producto.alertaStockMinimo}',
                    ),
                  ]),

                  // Detailed Breakdown by Warehouse if available
                  if (!_isLoadingInventory && _inventoryDetails.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Distribución por Bodega'),
                    ..._inventoryDetails.map((item) {
                      final isRecovery = item['bodega_tipo'] == 'recuperacion';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isRecovery ? Colors.orange.shade50 : null,
                        child: ListTile(
                          leading: Icon(
                            isRecovery ? Icons.recycling : Icons.store,
                            color: isRecovery ? Colors.orange : Colors.blue,
                          ),
                          title: Text(item['bodega_nombre'] ?? 'Bodega'),
                          subtitle: Text(
                            isRecovery
                                ? 'Segunda Mano / Recuperado'
                                : 'Estándar',
                          ),
                          trailing: Text(
                            '${item['cantidad']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                  _buildSectionTitle('Ubicación y Costo'),
                  _buildInfoCard([
                    _buildInfoRow(
                      'Ubicación',
                      widget.producto.ubicacion ?? 'Bodega Principal',
                    ),
                    _buildInfoRow(
                      'Precio Costo',
                      widget.producto.precioCosto != null
                          ? '\$${widget.producto.precioCosto}'
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
