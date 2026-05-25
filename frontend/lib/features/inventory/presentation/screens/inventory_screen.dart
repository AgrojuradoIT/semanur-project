import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:frontend/core/widgets/custom_loader.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/inventory/presentation/screens/add_movement_screen.dart';
import 'package:frontend/features/notifications/presentation/screens/notification_list_screen.dart';
import 'package:frontend/core/utils/debounce_util.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);
  String _selectedCategory = 'Todos';
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchProductos(lowStock: _lowStockOnly);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();

    return SemanurScaffold(
      backgroundColor: AppTheme.backgroundDark,
      showCenterGap: true,
      floatingActionButton: GestureDetector(
        onTap: () => _showQuickActions(context),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryYellow,
            border: Border.all(color: const Color(0xFF0A0A0A), width: 6),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.black, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, inventoryProvider),
            _buildSearchBar(inventoryProvider),
            _buildCategoryFilters(),
            Expanded(child: _buildBody(inventoryProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InventoryProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppTheme.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GESTIÓN DE INVENTARIO',
                    style: GoogleFonts.oswald(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationListScreen(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              'SEMANUR ZOMAC S.A.S.',
              style: GoogleFonts.roboto(
                fontSize: 9,
                color: AppTheme.textGray,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(InventoryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (value) {
            // Usar debounce para evitar llamadas API en cada tecla
            _debouncer.run(() {
              provider.searchProductosWithLowStock(value, lowStock: _lowStockOnly);
            });
          },
          decoration: InputDecoration(
            hintText: 'Buscar repuesto, código o SKU...',
            hintStyle: const TextStyle(color: AppTheme.textGray, fontSize: 13),
            prefixIcon: const Icon(
              Icons.search,
              color: AppTheme.textGray,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune, color: AppTheme.textGray, size: 18),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Filtros avanzados próximamente'),
                  ),
                );
              },
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryYellow),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      'Todos',
      'Stock bajo',
      'Repuestos',
      'Tornillería',
      'Lubricantes',
      'Combustible',
      'Herramientas',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            if (cat == 'Stock bajo') {
              return _buildLowStockChip();
            }
            return _buildFilterChip(cat, _selectedCategory == cat);
          },
        ),
      ),
    );
  }

  Widget _buildLowStockChip() {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () async {
          setState(() => _lowStockOnly = !_lowStockOnly);
          if (_searchController.text.trim().isNotEmpty) {
            await context.read<InventoryProvider>().searchProductosWithLowStock(
                  _searchController.text,
                  lowStock: _lowStockOnly,
                );
          } else {
            await context
                .read<InventoryProvider>()
                .fetchProductos(lowStock: _lowStockOnly);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _lowStockOnly ? Colors.redAccent : AppTheme.surfaceDark,
          foregroundColor: _lowStockOnly ? Colors.white : Colors.white70,
          elevation: _lowStockOnly ? 4 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _lowStockOnly ? Colors.redAccent : AppTheme.surfaceDark2,
            ),
          ),
        ),
        child: Text(
          'Stock bajo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: _lowStockOnly ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedCategory = label;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? AppTheme.primaryYellow
              : AppTheme.surfaceDark,
          foregroundColor: isSelected ? Colors.black : Colors.white70,
          elevation: isSelected ? 4 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isSelected
                ? BorderSide.none
                : const BorderSide(color: AppTheme.surfaceDark2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuickActionTile(
                  context,
                  label: 'Ingreso',
                  icon: Icons.arrow_downward,
                  color: Colors.green,
                  onTap: () => _openMovementForm(parentContext),
                ),
                const SizedBox(height: 8),
                _buildQuickActionTile(
                  context,
                  label: 'Salida',
                  icon: Icons.arrow_upward,
                  color: Colors.red,
                  onTap: () => _openMovementForm(parentContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionTile(
    BuildContext sheetContext, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(sheetContext);
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceDark),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMovementForm(BuildContext context) async {
    final provider = context.read<InventoryProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMovementScreen()),
    );
    if (!mounted) return;
    provider.fetchProductos(lowStock: _lowStockOnly);
  }

  Widget _buildBody(InventoryProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CustomLoader(message: 'Cargando inventario...'),
      );
    }

    // Mostrar error SOLO si no hay productos
    if (provider.error != null && provider.productos.isEmpty) {
      final bool isCachedData = provider.error!.contains('caché');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCachedData ? Icons.cloud_off_outlined : Icons.error_outline,
                size: 48,
                color: isCachedData ? Colors.orange : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCachedData ? Colors.orange : Colors.red,
                  fontSize: 16,
                ),
              ),
              if (!isCachedData) ...[
                const SizedBox(height: 8),
                Text(
                  'URL: ${provider.repositoryUrl}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.fetchProductos(lowStock: _lowStockOnly),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filtrar productos (sin modificar la lista original para pagination)
    var filteredProducts = provider.productos;
    try {
      if (_selectedCategory != 'Todos') {
        filteredProducts = filteredProducts
            .where(
              (p) =>
                  (p.categoria?.nombre ?? '').toLowerCase() ==
                  _selectedCategory.toLowerCase(),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error filtrando productos: $e');
    }

    if (_lowStockOnly) {
      filteredProducts = filteredProducts
          .where((p) => p.stockActual <= p.alertaStockMinimo)
          .toList();
    }

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _lowStockOnly
                  ? 'No hay productos con stock bajo'
                  : 'No hay productos en esta categoría',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            if (_selectedCategory != 'Todos' && !_lowStockOnly)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton(
                  onPressed: () => setState(() => _selectedCategory = 'Todos'),
                  child: const Text('Ver todos'),
                ),
              ),
          ],
        ),
      );
    }

    // Usar productos paginados para lazy loading
    final paginatedProducts = provider.productosPaginados;

    return RefreshIndicator(
      onRefresh: () async {
        provider.resetPagination();
        await provider.fetchProductos(lowStock: _lowStockOnly);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Cargar más productos cuando el usuario llega al final
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
            provider.loadMoreProductos();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          // Usar la longitud paginada + 1 para el indicador de carga
          itemCount: paginatedProducts.length + (provider.hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            // Indicador de carga al final
            if (index == paginatedProducts.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: provider.isLoadingMore
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryYellow,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }

            try {
              final producto = paginatedProducts[index];
              final bool lowStock =
                  producto.stockActual <= producto.alertaStockMinimo;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(producto: producto),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceDark2),
                  ),
                  child: Stack(
                    children: [
                      if (lowStock)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 4,
                          child: Container(color: AppTheme.primaryYellow),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundDark,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(
                                      producto.categoria?.nombre,
                                    ),
                                    color: AppTheme.textGray,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        producto.nombre.toUpperCase(),
                                        style: GoogleFonts.oswald(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'SKU: ${producto.sku} • ${producto.categoria?.nombre ?? 'General'}',
                                        style: const TextStyle(
                                          color: AppTheme.textGray,
                                          fontSize: 10,
                                        ),
                                      ),
                                      if (lowStock)
                                        Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryYellow
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration:
                                                    const BoxDecoration(
                                                  color: AppTheme.primaryYellow,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'STOCK BAJO',
                                                style: TextStyle(
                                                  color: AppTheme.primaryYellow,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      producto.stockActual.toString(),
                                      style: GoogleFonts.oswald(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: lowStock
                                            ? AppTheme.primaryYellow
                                            : Colors.white,
                                      ),
                                    ),
                                    Text(
                                      producto.unidadMedida ?? 'UNID',
                                      style: const TextStyle(
                                        color: AppTheme.textGray,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (producto.categoria?.nombre.toLowerCase() ==
                                'combustible')
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark2,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: 0.75,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                    ],
                  ),
                ),
              );
            } catch (e) {
              return Container(
                height: 80,
                color: Colors.red.withValues(alpha: 0.1),
                alignment: Alignment.center,
                child: Text(
                  'Error item: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'repuestos':
        return Icons.settings;
      case 'tornillería':
        return Icons.hardware;
      case 'combustible':
        return Icons.local_gas_station;
      case 'lubricantes':
        return Icons.oil_barrel;
      default:
        return Icons.inventory_2;
    }
  }
}
