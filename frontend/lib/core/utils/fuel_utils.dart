import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';

class FuelProducts {
  final Producto? gasolina;
  final Producto? acpm;

  const FuelProducts({this.gasolina, this.acpm});
}

FuelProducts resolveFuelProducts(List<Producto> productos) {
  final String skuGasolina = _envSku('FUEL_SKU_GASOLINA');
  final String skuAcpm = _envSku('FUEL_SKU_ACPM');

  final bool hasSkuGasolina = skuGasolina.isNotEmpty;
  final bool hasSkuAcpm = skuAcpm.isNotEmpty;

  final Producto? gasBySku =
      hasSkuGasolina ? _findBySku(productos, skuGasolina) : null;
  final Producto? acpmBySku =
      hasSkuAcpm ? _findBySku(productos, skuAcpm) : null;

  final List<Producto> combustibles = productos
      .where((p) => _isFuelCandidate(p))
      .toList();

  Producto? gas;
  if (hasSkuGasolina && gasBySku != null) {
    gas = gasBySku;
  } else {
    gas = _findByNamePreferCategoria(
      productos,
      ['gasolina'],
      categoriaKeyword: 'combustible',
    );
  }

  Producto? acpm;
  if (hasSkuAcpm && acpmBySku != null) {
    acpm = acpmBySku;
  } else {
    acpm = _findByNamePreferCategoria(
      productos,
      ['acpm', 'diesel'],
      categoriaKeyword: 'combustible',
    );
  }

  if (gas != null && acpm != null && gas.id == acpm.id) {
    acpm = combustibles.firstWhere(
      (p) => p.id != gas!.id,
      orElse: () => acpm!,
    );
  }

  return FuelProducts(gasolina: gas, acpm: acpm);
}

bool isFuelProduct(Producto producto) {
  final String skuGasolina = _envSku('FUEL_SKU_GASOLINA');
  final String skuAcpm = _envSku('FUEL_SKU_ACPM');
  final String sku = producto.sku.toLowerCase().trim();

  if (skuGasolina.isNotEmpty && sku == skuGasolina.toLowerCase()) {
    return true;
  }
  if (skuAcpm.isNotEmpty && sku == skuAcpm.toLowerCase()) {
    return true;
  }
  return _isFuelCandidate(producto);
}

String _envSku(String key) {
  return (dotenv.env[key] ?? '').trim();
}

Producto? _findBySku(List<Producto> productos, String sku) {
  final String skuLower = sku.toLowerCase();
  for (final p in productos) {
    if (p.sku.toLowerCase() == skuLower) {
      return p;
    }
  }
  return null;
}

Producto? _findByNamePreferCategoria(
  List<Producto> productos,
  List<String> keywords, {
  required String categoriaKeyword,
}) {
  final matches = productos.where((p) {
    final nombre = p.nombre.toLowerCase().trim();
    return keywords.any((k) => nombre.contains(k));
  }).toList();

  if (matches.isEmpty) return null;

  final withCategoria = matches.where((p) {
    final categoria = (p.categoria?.nombre ?? '').toLowerCase().trim();
    return categoria.contains(categoriaKeyword);
  }).toList();

  final candidates = withCategoria.isNotEmpty ? withCategoria : matches;
  candidates.sort((a, b) => b.stockActual.compareTo(a.stockActual));
  return candidates.first;
}

bool _isFuelCandidate(Producto p) {
  final nombre = p.nombre.toLowerCase().trim();
  final categoria = (p.categoria?.nombre ?? '').toLowerCase().trim();
  if (categoria.contains('combustible')) {
    return true;
  }
  return nombre.contains('gasolina') ||
      nombre.contains('acpm') ||
      nombre.contains('diesel');
}
