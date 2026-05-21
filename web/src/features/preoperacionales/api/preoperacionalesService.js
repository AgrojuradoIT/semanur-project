import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

export async function fetchTemplates(tipoVehiculo = '') {
  const params = tipoVehiculo ? { tipo_vehiculo: tipoVehiculo } : {};
  const { data } = await http.get('/v2/preoperacionales/templates', { params });
  return extractList(data);
}

export async function fetchPendientesHoy(fecha = null) {
  const params = fecha ? { fecha } : {};
  const { data } = await http.get('/v2/preoperacionales/pendientes-hoy', { params });
  return extractList(data);
}

export async function fetchSemanas(filters = {}) {
  const { data } = await http.get('/v2/preoperacionales/semanas', { params: filters });
  return data; // paginated
}

export async function fetchSemana(id) {
  const { data } = await http.get(`/v2/preoperacionales/semanas/${id}`);
  return data;
}

export async function createSemana(payload) {
  const { data } = await http.post('/v2/preoperacionales/semanas', payload);
  return data;
}

export async function submitDailyForm(semanaId, diaSemana, payload) {
  const { data } = await http.post(`/v2/preoperacionales/semanas/${semanaId}/dias/${diaSemana}`, payload);
  return data;
}

export async function markFueraServicio(semanaId, motivo) {
  const { data } = await http.put(`/v2/preoperacionales/semanas/${semanaId}/fuera-servicio`, { motivo });
  return data;
}
