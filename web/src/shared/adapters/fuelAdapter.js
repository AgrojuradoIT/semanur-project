import { textOrFallback } from '../utils/formatters';

export function fuelId(item) {
  return item?.combustible_id ?? item?.id ?? `${item?.fecha || ''}-${item?.valor_total || ''}`;
}

export function fuelDestinationLabel(item) {
  if (item?.tipo_destino === 'vehiculo') {
    return textOrFallback(item?.vehiculo?.placa || item?.placa_manual);
  }
  if (item?.tipo_destino === 'empleado') {
    return textOrFallback(item?.empleado?.name || item?.usuario?.name);
  }
  return textOrFallback(item?.tercero_nombre);
}
