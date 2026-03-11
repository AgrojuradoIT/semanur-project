import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

export async function fetchScheduleRange(startDate, endDate) {
  const { data } = await http.get('/programacion', {
    params: {
      fecha_inicio: startDate,
      fecha_fin: endDate,
    },
  });
  return extractList(data);
}

export async function createSchedule(payload) {
  const { data } = await http.post('/programacion', payload);
  return data;
}

export async function updateSchedule(scheduleId, payload) {
  const { data } = await http.put(`/programacion/${scheduleId}`, payload);
  return data;
}

export async function deleteSchedule(scheduleId) {
  const { data } = await http.delete(`/programacion/${scheduleId}`);
  return data;
}

export async function reportScheduleIssue(payload) {
  const { data } = await http.post('/programacion/novedad', payload);
  return data;
}

export async function fetchEmployeesForSchedule() {
  const { data } = await http.get('/empleados');
  return extractList(data);
}

export async function fetchVehiclesForSchedule() {
  const { data } = await http.get('/vehiculos');
  return extractList(data);
}
