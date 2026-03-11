import { FALLBACK_TEXT, textOrFallback } from '../utils/formatters';

export function loanId(loan) {
  return loan?.prestamo_id ?? loan?.id ?? 0;
}

export function loanProductName(loan) {
  return textOrFallback(loan?.producto?.producto_nombre ?? loan?.producto?.nombre);
}

export function loanMechanicName(loan) {
  return textOrFallback(loan?.mecanico?.name ?? loan?.mecanico_nombre);
}

export function loanQuantity(loan) {
  return loan?.prestamo_cantidad ?? loan?.cantidad ?? FALLBACK_TEXT;
}
