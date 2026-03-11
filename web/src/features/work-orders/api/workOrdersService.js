import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

export async function fetchWorkOrders() {
  const { data } = await http.get('/ordenes-trabajo');
  return extractList(data);
}

export async function createWorkOrder(payload) {
  const { data } = await http.post('/ordenes-trabajo', payload);
  return data;
}

export async function updateWorkOrderStatus(id, estado) {
  const { data } = await http.patch(`/ordenes-trabajo/${id}/estado`, { estado });
  return data;
}

export async function startWorkSession(ordenTrabajoId) {
  const { data } = await http.post('/sesiones-trabajo/start', { orden_trabajo_id: ordenTrabajoId });
  return data;
}

export async function stopWorkSession(sessionId, notas = '') {
  const { data } = await http.post(`/sesiones-trabajo/${sessionId}/stop`, { notas });
  return data;
}

export async function fetchFleetOptions() {
  const { data } = await http.get('/vehiculos');
  return extractList(data);
}

export async function fetchEmployees() {
  const { data } = await http.get('/empleados?cargo=mecanico');
  return extractList(data);
}
