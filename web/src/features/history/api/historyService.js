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
  const fallback = { movimientos: [], ordenes: [], combustible: [], prestamos: [] };
  
  try {
    const { data } = await http.get('/history/all');
    const result = data || fallback;
    
    return {
      movimientos: extractList(result.movimientos),
      ordenes: extractList(result.ordenes),
      combustible: extractList(result.combustible),
      prestamos: extractList(result.prestamos),
    };
  } catch {
    return fallback;
  }
}
