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

import { useCatalogsStore } from '../../../shared/stores/catalogs';

export async function fetchDashboardSources() {
  const store = useCatalogsStore();
  
  // Única llamada BFF
  const data = await safeGet('/dashboard/all', {
    summary: { total_fuel_cost: 0, total_maintenance_cost: 0, vehicle_count: 0, open_orders: 0 },
    fuelMonthly: [],
    maintenanceByVehicle: [],
    fuelStock: []
  });

  // Cargar vehículos desde el Caché local
  const vehicles = await store.fetchVehiculos();

  return {
    summary: data.summary || { total_fuel_cost: 0, total_maintenance_cost: 0, vehicle_count: 0, open_orders: 0 },
    fuelMonthly: extractList(data.fuelMonthly),
    maintenanceByVehicle: extractList(data.maintenanceByVehicle),
    vehicles,
    fuelStock: extractList(data.fuelStock),
  };
}
