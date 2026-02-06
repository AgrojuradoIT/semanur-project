import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:frontend/core/widgets/custom_loader.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/inventory/presentation/screens/add_movement_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/features/inventory/presentation/screens/movement_list_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();

  Widget buildMiniButton(String label, IconData icon, VoidCallback onTap) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textGray),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchProductos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, inventoryProvider),
                _buildSearchBar(inventoryProvider),
                _buildCategoryFilters(),
                Expanded(child: _buildBody(inventoryProvider)),
              ],
            ),
          ),
          _buildBottomActionPanel(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InventoryProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: AppTheme.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                width: 35,
                height: 35,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryYellow),
                ),
                child: CachedNetworkImage(
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDdniVoAwXdAaZ8_1i3-86JjnO2RVHHvuOMTexBpN44I65icwgSaVFaQIbCu4l5jOTCm7Omfz5WanVHeEhNbgjIf7pniPtW5N9zJArd9inzYp2UUNBFh3abGbT2uAUKRN4x0NvBFdKDa9HPY7Q7__HR7SJeFzvBw0RNdAIlDg3UbpWPSHLW9D7E6a__qpTGHPNj5bMl23YMDcYdb4czEALeNsbyaOlZKxr-Lnx7caoHeZ0S56oc9vBtgJs4N-a9cDYkDBiu_emQYz8',
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'GESTIÓN DE INVENTARIO',
            style: GoogleFonts.oswald(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          Text(
            'SEMANUR ZOMAC S.A.S.',
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
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
          onChanged: (value) => provider.searchProductos(value),
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
      'Repuestos',
      'Tornillería',
      'Lubricantes',
      'Combustible',
      'Herramientas',
    ];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _buildFilterChip(cat, _selectedCategory == cat);
        },
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

  Widget _buildBottomActionPanel(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark.withValues(alpha: 0),
              AppTheme.backgroundDark,
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceDark2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildPanelButton(
                  'Ingreso',
                  Icons.arrow_downward,
                  Colors.green,
                  () {
                    final provider = context.read<InventoryProvider>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddMovementScreen(),
                      ),
                    ).then((_) {
                      if (!mounted) return;
                      provider.fetchProductos();
                    });
                  },
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.surfaceDark2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Expanded(
                child: _buildPanelButton(
                  'Salida',
                  Icons.arrow_upward,
                  Colors.red,
                  () {
                    final provider = context.read<InventoryProvider>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddMovementScreen(),
                      ),
                    ).then((_) {
                      if (!mounted) return;
                      provider.fetchProductos();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.oswald(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(InventoryProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CustomLoader(message: 'Cargando inventario...'),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchProductos(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

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
      // En caso de error, mostramos lista vacía o lista completa, mejor completa para no bloquear
      // Pero si el filtro falla, mejor no filtrar
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
              'No hay productos en esta categoría',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            if (_selectedCategory != 'Todos')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton(
                  onPressed: () => setState(() => _selectedCategory = 'Todos'),
                  child: const Text('Ver todos'),
                ),
              ),
            // Botón de reintentar removido porque el filtro está vacío, no la carga
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchProductos(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          try {
            final producto = filteredProducts[index];
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
                                  _getCategoryIcon(producto.categoria?.nombre),
                                  color: AppTheme.textGray,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryYellow
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
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
                                      widthFactor: 0.75, // Placeholder level
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: widget.buildMiniButton(
                                  'Historial',
                                  Icons.history,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MovementListScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: widget.buildMiniButton(
                                  'Reordenar',
                                  Icons.refresh,
                                  () {
                                    final provider = context
                                        .read<InventoryProvider>();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddMovementScreen(),
                                      ),
                                    ).then((_) {
                                      if (!mounted) return;
                                      provider.fetchProductos();
                                    });
                                  },
                                ),
                              ),
                            ],
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
