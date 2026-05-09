import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/inventory/presentation/providers/movement_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/database/database_helper.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/fuel_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  final Producto producto;

  const ProductDetailScreen({super.key, required this.producto});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Map<String, dynamic>> _inventoryDetails = [];
  bool _isLoadingInventory = true;
  double? _capacidadMaxima;

  @override
  void initState() {
    super.initState();
    _capacidadMaxima = widget.producto.capacidadMaxima;
    _fetchInventoryDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovementProvider>().fetchMovimientos();
    });
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

  bool get _isFuelProduct {
    return isFuelProduct(widget.producto);
  }

  @override
  Widget build(BuildContext context) {
    final bool lowStock =
        widget.producto.stockActual <= widget.producto.alertaStockMinimo;
    final Color statusColor = lowStock ? Colors.redAccent : Colors.greenAccent;
    final String statusLabel = lowStock ? 'BAJO' : 'DISPONIBLE';

    return DefaultTabController(
      length: 2,
      child: SemanurScaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundDark,
          title: const Text('Item Details'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: Colors.white.withOpacity(0.1), height: 1.0),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Future options menu
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // 2. Hero Product Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      border: Border.all(color: statusColor.withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'ESTADO STOCK: $statusLabel',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  Text(
                    widget.producto.nombre,
                    textAlign: TextAlign.center,
                    style: AppTheme.darkTheme.textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SKU: ',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        widget.producto.sku,
                        style: const TextStyle(
                          fontFamily:
                              'RobotoMono', // Asumiendo monospace default
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: 1,
                          height: 12,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: AppTheme.primaryYellow,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.producto.ubicacion?.isNotEmpty == true
                            ? widget.producto.ubicacion!.toUpperCase()
                            : 'BODEGA PRINCIPAL',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Tab Navigation
            Container(
              color: AppTheme.backgroundDark,
              child: const TabBar(
                indicatorColor: AppTheme.primaryYellow,
                indicatorWeight: 2,
                labelColor: AppTheme.primaryYellow,
                unselectedLabelColor: AppTheme.textGray,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors
                    .transparent, // Lo manejaremos con un contenedor bordeado
                tabs: [
                  Tab(text: 'GENERAL'),
                  Tab(text: 'BODEGAS'),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.1)),

            // 4. Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: GENERAL
                  _buildGeneralTab(lowStock),
                  // Tab 2: BODEGAS
                  _buildBodegasTab(),
                ],
              ),
            ),
          ],
        ),
        // Integrar FAB (Floating Action Button amarillo Contextual)
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 24.0, right: 8.0),
          child: FloatingActionButton(
            onPressed: () => _showAddMovementOptions(context),
            backgroundColor: AppTheme.primaryYellow,
            foregroundColor: Colors.black,
            elevation: 8.0,
            child: const Icon(Icons.add, size: 28, weight: 600),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // --- TAB: GENERAL ---
  Widget _buildGeneralTab(bool lowStock) {
    // Cálculo de stock recuperado
    double stockRecuperado = 0;
    for (var item in _inventoryDetails) {
      if (item['bodega_tipo'] == 'recuperacion') {
        stockRecuperado += (item['cantidad'] is num
            ? item['cantidad']
            : double.tryParse(item['cantidad'].toString()) ?? 0.0);
      }
    }

    final double precioUnitario = widget.producto.precioCosto ?? 0;
    final double precioTotal = precioUnitario * widget.producto.stockActual;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Stock Stats Grid (1px gap)
          Container(
            color: Colors.white.withOpacity(0.1), // Color del borde fino (gap)
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 1, right: 1), // gap
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.backgroundDark,
                    child: Column(
                      children: [
                        Text(
                          'ESTADO DE STOCK',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${widget.producto.stockActual}',
                              style: AppTheme.darkTheme.textTheme.displayLarge
                                  ?.copyWith(
                                    color: AppTheme.primaryYellow,
                                    fontSize: 32,
                                    height: 1.0,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                widget.producto.unidadMedida ?? 'Units',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 1), // gap
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.backgroundDark,
                    child: Column(
                      children: [
                        Text(
                          'STOCK MÍNIMO',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${widget.producto.alertaStockMinimo.toInt()}',
                              style: AppTheme.darkTheme.textTheme.displayLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 32,
                                    height: 1.0,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                widget.producto.unidadMedida ?? 'Units',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isFuelProduct) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: _buildFuelCapacityCard(context),
            ),
          ],

          // 2. Product Details Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              'DETALLES DEL PRODUCTO',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  'Categoría',
                  widget.producto.categoria?.nombre ?? 'Sin Categoría',
                  isStatus: false,
                  isAlert: false,
                ),
              ],
            ),
          ),
          _buildMovementTable(context),
          const SizedBox(height: 100), // Spacing para el FAB
        ],
      ),
    );
  }

  Widget _buildFuelCapacityCard(BuildContext context) {
    final unidad = widget.producto.unidadMedida ?? 'GAL';
    final double capacidad = _capacidadMaxima ?? 0;
    final String display = capacidad > 0
        ? '${capacidad.toStringAsFixed(1)} $unidad'
        : 'Sin definir';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_gas_station,
              color: AppTheme.primaryYellow,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAPACIDAD TANQUE',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  display,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _editFuelCapacity(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryYellow,
              side: const BorderSide(color: AppTheme.primaryYellow),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Configurar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _editFuelCapacity(BuildContext context) {
    final current = (_capacidadMaxima != null && _capacidadMaxima! > 0)
        ? _capacidadMaxima!.toStringAsFixed(1)
        : '';
    final ctrl = TextEditingController(text: current);
    final unidad = (widget.producto.unidadMedida ?? 'GAL').toUpperCase();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar Capacidad'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Capacidad maxima ($unidad)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = ctrl.text.trim();
              final parsed = raw.isEmpty
                  ? 0.0
                  : double.tryParse(raw.replaceAll(',', '.'));
              if (parsed == null || parsed < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Capacidad invalida')),
                );
                return;
              }
              Navigator.pop(ctx);
              final provider = context.read<InventoryProvider>();
              final success = await provider.updateProducto(
                widget.producto.id,
                {
                  'capacidad_maxima': parsed,
                },
              );
              if (!mounted) return;
              if (success) {
                setState(() => _capacidadMaxima = parsed);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Capacidad actualizada' : 'Error al actualizar',
                  ),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  Widget _buildDetailRow(
    String label,
    String value, {
    required bool isStatus,
    required bool isAlert,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          isStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAlert
                        ? Colors.redAccent.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAlert
                          ? Colors.redAccent.withOpacity(0.5)
                          : Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAlert ? Colors.redAccent : Colors.greenAccent,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: AppTheme.darkTheme.textTheme.displayLarge?.copyWith(
                    fontSize: 16,
                    color: AppTheme.primaryYellow,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMovementTable(BuildContext context) {
    final movementProvider = context.watch<MovementProvider>();
    final productMovements = movementProvider.movimientos
        .where((m) => m.productoId == widget.producto.id)
        .take(10)
        .toList();

    if (movementProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryYellow),
        ),
      );
    }

    if (productMovements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No hay movimientos recientes.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'MOVIMIENTOS RECIENTES',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Column(
            children: productMovements.map((movimiento) {
              final isIngreso = movimiento.tipo == 'ingreso';
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isIngreso
                              ? Colors.green.withOpacity(0.15)
                              : Colors.redAccent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIngreso
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${movimiento.motivo.toUpperCase()} • ${movimiento.usuarioNombre ?? 'Sistema'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(movimiento.createdAt),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIngreso ? '+' : '-'}${movimiento.cantidad}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isIngreso
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAddMovementOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Registrar Movimiento',
                style: AppTheme.darkTheme.textTheme.displayLarge?.copyWith(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    color: Colors.greenAccent,
                  ),
                ),
                title: const Text(
                  'Entrada de Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Registrar nuevo ingreso a bodega',
                  style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar Entrada
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formulario de Entrada en desarrollo'),
                    ),
                  );
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.redAccent,
                  ),
                ),
                title: const Text(
                  'Salida de Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Registrar consumo o despacho exterior',
                  style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar Salida
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formulario de Salida en desarrollo'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB: BODEGAS ---
  Widget _buildBodegasTab() {
    if (_isLoadingInventory) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryYellow),
      );
    }

    if (_inventoryDetails.isEmpty) {
      return Center(
        child: Text(
          'No hay stock en bodegas locales.',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STOCK DISTRIBUTION',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._inventoryDetails.map((item) => _buildBodegaLogItem(item)),
            const SizedBox(height: 100), // Spacing para el FAB
          ],
        ),
      ),
    );
  }

  Widget _buildBodegaLogItem(Map<String, dynamic> item) {
    final isRecovery = item['bodega_tipo'] == 'recuperacion';
    final Color badgeColor = isRecovery
        ? Colors.amber.shade700
        : AppTheme.primaryYellow;
    final MaterialColor accentBorder = isRecovery
        ? Colors.orange
        : Colors.blueGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          left: BorderSide(color: accentBorder.shade400, width: 4.0),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  (item['bodega_nombre'] ?? 'BODEGA DESCONOCIDA')
                      .toString()
                      .toUpperCase(),
                  style: AppTheme.darkTheme.textTheme.displayLarge?.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isRecovery ? 'RECOVERY' : 'STANDARD',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Units:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isRecovery ? 'REUSED' : 'NEW',
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item['cantidad']} units',
                    style: AppTheme.darkTheme.textTheme.displayLarge?.copyWith(
                      fontSize: 16,
                      color: isRecovery ? Colors.white : AppTheme.primaryYellow,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editProduct(BuildContext context) {
    final p = widget.producto;
    final nameCtrl = TextEditingController(text: p.nombre);
    final skuCtrl = TextEditingController(text: p.sku);
    final ubicCtrl = TextEditingController(text: p.ubicacion ?? '');
    final alertCtrl = TextEditingController(text: '${p.alertaStockMinimo}');
    final precioCtrl = TextEditingController(text: '${p.precioCosto ?? 0}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: skuCtrl,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ubicCtrl,
                decoration: const InputDecoration(labelText: 'Ubicación'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: alertCtrl,
                decoration: const InputDecoration(labelText: 'Alerta Mínima'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: precioCtrl,
                decoration: const InputDecoration(labelText: 'Precio Costo'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<InventoryProvider>();
              final success = await provider.updateProducto(p.id, {
                'producto_nombre': nameCtrl.text,
                'producto_sku': skuCtrl.text,
                'producto_ubicacion': ubicCtrl.text,
                'producto_alerta_stock_minimo':
                    double.tryParse(alertCtrl.text) ?? 5,
                'producto_precio_costo': double.tryParse(precioCtrl.text) ?? 0,
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Producto actualizado' : 'Error al actualizar',
                    ),
                  ),
                );
                if (success) Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de eliminar "${widget.producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<InventoryProvider>();
              final result = await provider.deleteProducto(widget.producto.id);
              if (mounted) {
                final msg =
                    result['message']?.toString() ?? 'Producto eliminado';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
                if (!msg.contains('No se puede')) Navigator.pop(context);
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
