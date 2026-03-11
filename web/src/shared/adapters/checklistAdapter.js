import { textOrFallback } from '../utils/formatters';

export function checklistId(item) {
  return item?.checklist_id ?? item?.id ?? `${item?.fecha || ''}-${item?.vehiculo_id || ''}`;
}

export function checklistVehicle(item) {
  return textOrFallback(item?.vehiculo?.placa || item?.placa);
}

export function checklistOperator(item) {
  return textOrFallback(item?.operador?.name || item?.usuario?.name || item?.usuario_nombre);
}

export function checklistStatusLabel(status) {
  if (status === 'aprobado') return 'Aprobado';
  if (status === 'reprobado') return 'Rechazado';
  return textOrFallback(status);
}
