import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

async function safeGet(path, fallback = []) {
  try {
    const { data } = await http.get(path);
    return Array.isArray(fallback) ? extractList(data) : data ?? fallback;
  } catch {
    return fallback;
  }
}

export async function fetchDashboardSources() {
  const [summary, fuelMonthly, maintenanceByVehicle, vehicles, fuelStock] = await Promise.all([
    safeGet('/analytics/summary', {
      total_fuel_cost: 0,
      total_maintenance_cost: 0,
      vehicle_count: 0,
      open_orders: 0,
    }),
    safeGet('/analytics/fuel', []),
    safeGet('/analytics/maintenance', []),
    safeGet('/vehiculos', []),
    safeGet('/analytics/fuel-stock', []),
  ]);

  return {
    summary,
    fuelMonthly,
    maintenanceByVehicle,
    vehicles,
    fuelStock,
  };
}
