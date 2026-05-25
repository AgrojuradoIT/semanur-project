// DEPRECATED: This legacy checklists service will be replaced by the new
// preoperacionales system (v2). Use preoperacionalesService.js for the new
// weekly inspection workflow. See /preoperacionales route.
import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

export async function fetchChecklistHistory() {
  const { data } = await http.get('/checklists/history');
  return extractList(data);
}

export async function fetchChecklistTemplates(vehicleType = '') {
  const { data } = await http.get('/checklists', {
    params: vehicleType ? { tipo_vehiculo: vehicleType } : undefined,
  });
  return extractList(data);
}

export async function createChecklist(payload) {
  try {
    const { data } = await http.post('/checklists', payload);
    return data;
  } catch (error) {
    throw error;
  }
}

export async function fetchVehiclesForChecklist() {
  const { data } = await http.get('/vehiculos');
  return extractList(data);
}

export async function fetchEmployeesForChecklist() {
  const { data } = await http.get('/empleados?cargo=operador');
  return extractList(data);
}

export async function updateChecklistVehicle(vehicleId, payload) {
  const { data } = await http.put(`/vehiculos/${vehicleId}`, payload);
  return data;
}

export async function createHorometerRecord(payload) {
  const { data } = await http.post('/horometro', payload);
  return data;
}
