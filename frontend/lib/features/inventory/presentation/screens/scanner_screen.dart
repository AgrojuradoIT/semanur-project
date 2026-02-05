import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/inventory/presentation/screens/product_detail_screen.dart';
import 'package:frontend/core/widgets/custom_loader.dart';
import 'package:frontend/core/theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  // ... (rest of class)

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    _handleScannedCode(code);
  }

  Future<void> _handleScannedCode(String code) async {
    final inventoryProvider = context.read<InventoryProvider>();

    try {
      // 1. Buscar en memoria local primero (si ya se cargaron prodcutos)
      // Ajusta 'codigo' o 'sku' según tus modelos. Asumo que el modelo Producto tiene 'codigo' o 'referencia'.
      // Vamos a intentar buscar en la lista cargada.

      // Si la lista está vacía o no se encuentra, quizás se deba hacer searchProductos(code)
      // Pero primero intentemos búsqueda local exacta

      var product = inventoryProvider.productos.cast<dynamic>().firstWhere(
        (p) =>
            p.codigo == code || p.referencia == code || p.id.toString() == code,
        orElse: () => null,
      );

      if (product == null) {
        // 2. Si no está en memoria local, intentar buscar en API
        await inventoryProvider.searchProductos(code);
        if (inventoryProvider.productos.isNotEmpty) {
          // Asumimos que la búsqueda devuelve coincidencias. Filtramos exacto si es posible.
          product = inventoryProvider.productos.cast<dynamic>().firstWhere(
            (p) => p.codigo == code || p.referencia == code,
            orElse: () => inventoryProvider
                .productos
                .first, // Fallback al primero encontrado
          );
        }
      }

      if (!mounted) return;

      if (product != null) {
        // Encontrado: Navegar al detalle
        Navigator.pop(context); // Cerrar scanner
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(producto: product),
          ),
        );
      } else {
        // No encontrado
        _showErrorDialog('Producto no encontrado: $code');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al buscar producto: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Código')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Overlay para guiar encuadre
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CustomLoader(
                  message: 'Buscando producto...',
                  color: AppTheme.primaryYellow,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
