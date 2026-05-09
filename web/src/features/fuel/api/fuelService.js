import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

export async function fetchFuelRecords(params = {}) {
  const { data } = await http.get('/combustible', { params });
  return data; // { data: [...], meta: {...} }
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

export async function fetchVehiclesForFuel() {
  const { data } = await http.get('/vehiculos');
  return extractList(data);
}

export async function fetchEmployeesForFuel() {
  const { data } = await http.get('/empleados');
  return extractList(data);
}

export async function fetchUsersForFuel() {
  const { data } = await http.get('/empleados');
  return extractList(data);
}

export async function fetchProductsForFuel() {
  const { data } = await http.get('/productos');
  // Handle paginated response
  return Array.isArray(data) ? data : (data.data || []);
}
