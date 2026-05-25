import { textOrFallback } from '../utils/formatters';

export function fuelId(item) {
  return item?.registro_id ?? item?.combustible_id ?? item?.id ?? `${item?.fecha || ''}-${item?.valor_total || ''}`;
}

export function fuelDestinationLabel(item) {
  if (['vehiculo', 'maquinaria', 'equipo_menor'].includes(item?.tipo_destino)) {
    return textOrFallback(item?.vehiculo?.nombre || item?.vehiculo?.placa || item?.placa_manual);
  }
  if (item?.tipo_destino === 'empleado') {
    return textOrFallback(item?.empleado?.name || item?.usuario?.name);
  }
  return textOrFallback(item?.tercero_nombre);
}
