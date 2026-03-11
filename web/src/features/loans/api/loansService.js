import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

export async function fetchLoans() {
  const { data } = await http.get('/prestamos');
  return extractList(data);
}

export async function createLoan(payload) {
  const { data } = await http.post('/prestamos', payload);
  return data;
}

export async function returnLoan(id, payload) {
  const { data } = await http.post(`/prestamos/${id}/devolver`, payload);
  return data;
}

export async function fetchProductsForLoan() {
  const { data } = await http.get('/productos');
  return extractList(data);
}

export async function fetchEmployeesForLoan() {
  const { data } = await http.get('/empleados');
  return extractList(data);
}
