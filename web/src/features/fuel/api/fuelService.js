import http from '../../../shared/api/http';

export async function fetchFuelRecords(params = {}) {
  const { data } = await http.get('/combustible', { params });
  return data;
}

export async function fetchFuelSummary(params = {}) {
  const { data } = await http.get('/combustible/resumen', { params });
  return data;
}

export async function createFuelRecord(payload) {
  const { data } = await http.post('/combustible', payload);
  return data;
}

export async function updateFuelRecord(id, payload) {
  const { data } = await http.put(`/combustible/${id}`, payload);
  return data;
}

export async function deleteFuelRecord(id) {
  const { data } = await http.delete(`/combustible/${id}`);
  return data;
}
