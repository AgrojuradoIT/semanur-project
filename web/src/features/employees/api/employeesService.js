import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

export async function fetchEmployees(params = {}) {
  const { data } = await http.get('/empleados', { params });
  return extractList(data);
}

export async function fetchEmployeeDetail(id) {
  const { data } = await http.get(`/empleados/${id}`);
  return data;
}

export async function createEmployee(payload) {
  const { data } = await http.post('/empleados', payload);
  return data;
}

export async function updateEmployee(id, payload) {
  const { data } = await http.put(`/empleados/${id}`, payload);
  return data;
}
