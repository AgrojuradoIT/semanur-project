export const FALLBACK_TEXT = '-';

export function textOrFallback(value, fallback = FALLBACK_TEXT) {
  if (value === null || value === undefined) return fallback;
  const text = String(value).trim();
  return text.length ? text : fallback;
}

export function formatDateCO(value, fallback = FALLBACK_TEXT) {
  if (!value) return fallback;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return fallback;
  return date.toLocaleDateString('es-CO');
}

export function formatDateTimeCO(value, fallback = FALLBACK_TEXT) {
  if (!value) return fallback;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return fallback;
  return date.toLocaleString('es-CO');
}

export function formatCurrencyCO(value, fallback = FALLBACK_TEXT) {
  if (value === null || value === undefined || value === '') return fallback;
  const n = Number(value);
  if (Number.isNaN(n)) return fallback;
  return `$${n.toLocaleString('es-CO')}`;
}

export function formatNumber(value, maxFractionDigits = 1) {
  if (value === null || value === undefined || value === '') return FALLBACK_TEXT;
  const n = Number(value);
  if (Number.isNaN(n)) return FALLBACK_TEXT;
  return n.toLocaleString('es-CO', { maximumFractionDigits: maxFractionDigits });
}
