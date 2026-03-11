import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

async function safeGet(path) {
  try {
    const { data } = await http.get(path);
    return extractList(data);
  } catch {
    return [];
  }
}

export async function fetchHistorySources() {
  const [movimientos, ordenes, combustible, prestamos, checklists] = await Promise.all([
    safeGet('/movimientos'),
    safeGet('/ordenes-trabajo'),
    safeGet('/combustible'),
    safeGet('/prestamos'),
    safeGet('/checklists/history'),
  ]);

  return { movimientos, ordenes, combustible, prestamos, checklists };
}
