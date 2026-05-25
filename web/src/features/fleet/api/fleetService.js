import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

export async function fetchFleetVehicles() {
  const { data } = await http.get('/vehiculos');
  return extractList(data);
}

export async function getVehicleDetails(vehicleId) {
  const { data } = await http.get(`/vehiculos/${vehicleId}`);
  return data;
}

export async function createVehicle(vehicleData) {
  const { data } = await http.post('/vehiculos', vehicleData);
  return data;
}

export async function updateVehicle(vehicleId, vehicleData) {
  const { data } = await http.put(`/vehiculos/${vehicleId}`, vehicleData);
  return data;
}

export async function getVehicleFuelHistory(vehicleId) {
  const { data } = await http.get(`/combustible?vehiculo_id=${vehicleId}`);
  return data.data || [];
}

export async function getVehicleHourMeters(vehicleId) {
  const { data } = await http.get(`/vehiculos/${vehicleId}/horometro`);
  return data;
}


export async function getVehicleDocuments(vehicleId) {
  const { data } = await http.get(`/vehiculos/${vehicleId}/documentos`);
  return extractList(data);
}

export async function createVehicleDocument(vehicleId, documentData) {
  const formData = new FormData();
  formData.append('tipo', documentData.tipo);
  formData.append('fecha_inicio', documentData.fecha_inicio);
  formData.append('fecha_vencimiento', documentData.fecha_vencimiento);
  formData.append('compania', documentData.compania || '');
  if (documentData.certificado_pdf) {
    formData.append('certificado_pdf', documentData.certificado_pdf);
  }

  const { data } = await http.post(`/vehiculos/${vehicleId}/documentos`, formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return data;
}

export async function fetchMechanics() {
  const { data } = await http.get('/empleados?cargo=mecanico');
  return extractList(data);
}

export async function fetchOperators() {
  const { data } = await http.get('/empleados?cargo=operador');
  return extractList(data);
}

export async function uploadVehicleImage(vehicleId, file) {
  const formData = new FormData();
  formData.append('imagen', file);
  formData.append('vehiculo_id', vehicleId);

  const { data } = await http.post('/vehiculos/imagen', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return data;
}
