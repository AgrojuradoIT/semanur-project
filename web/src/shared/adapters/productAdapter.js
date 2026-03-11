import { FALLBACK_TEXT, textOrFallback } from '../utils/formatters';

export function productId(product) {
  return product?.producto_id ?? product?.id ?? `${productSku(product)}-${productName(product)}`;
}

export function productSku(product) {
  return textOrFallback(product?.producto_sku ?? product?.sku);
}

export function productRef(product) {
  const ref = product?.referencia_fabrica ?? product?.referencia;
  return ref ? textOrFallback(ref) : null;
}

export function productName(product) {
  return textOrFallback(product?.producto_nombre ?? product?.nombre);
}

export function productCategory(product) {
  const nested = product?.categoria?.categoria_nombre ?? product?.categoria?.nombre;
  return textOrFallback(nested ?? product?.categoria_nombre ?? 'Sin categoria');
}

export function productStock(product) {
  const raw = product?.producto_stock_actual ?? product?.stock_actual ?? 0;
  return Number(raw);
}

export function productAlert(product) {
  const raw = product?.producto_alerta_stock_minimo ?? product?.stock_minimo ?? 0;
  return Number(raw);
}

export function productUnit(product) {
  return textOrFallback(product?.producto_unidad_medida ?? product?.unidad_medida ?? 'und');
}

export function productCost(product) {
  const raw = product?.producto_precio_costo ?? product?.precio_costo;
  if (raw == null || raw === '') return null;
  const value = Number(raw);
  return Number.isNaN(value) ? null : value;
}

export function productLocation(product) {
  return textOrFallback(product?.producto_ubicacion ?? product?.ubicacion);
}

export function productLabelWithStock(product) {
  return `${productName(product)} (Stock: ${productStock(product) || 0})`;
}

export function productCategoryToken(product) {
  return (productCategory(product) || FALLBACK_TEXT).toLowerCase();
}
