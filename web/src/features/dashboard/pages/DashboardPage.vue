<template>
  <div class="dash-page">
    <!-- Loading / Error -->
    <div v-if="loading" class="dash-loading">
      <span class="spinner"></span>
      Cargando Command Center...
    </div>

    <div v-else-if="error" class="dash-error">
      <span class="material-icons-round">cloud_off</span>
      <p>{{ error }}</p>
    </div>

    <template v-else>
      <!-- ── HEADER ── -->
      <header class="dash-header">
        <div class="dash-header-left">
          <span class="dash-subtitle">{{ todayFormatted }}</span>
        </div>
      </header>

      <!-- ── 1. TANQUES DE COMBUSTIBLE ── -->
      <section v-if="fuelStock.length" class="dash-fuel-hero">
        <article
          v-for="fuel in fuelStock"
          :key="fuel.producto_id"
          class="fuel-tank-card"
          :class="`fuel-tank-${getFuelLevelStatus(fuel)}`"
        >
          <!-- Background icon -->
          <span class="fuel-tank-bg-icon material-icons-round">{{ fuelIcon(fuel.producto_nombre) }}</span>

          <div class="fuel-tank-body">
            <!-- Top -->
            <div class="fuel-tank-top">
              <div class="fuel-tank-indicator">
                <span
                  class="fuel-dot"
                  :class="`fuel-dot-${getFuelLevelStatus(fuel)}`"
                ></span>
                <span class="fuel-tank-label">
                  {{ getFuelLevelText(fuel) }}
                </span>
              </div>
              <span class="fuel-tank-sku">{{ fuel.producto_sku }}</span>
            </div>

            <!-- Name & Value -->
            <p class="fuel-tank-name">{{ fuel.producto_nombre }}</p>
            <div class="fuel-tank-row">
              <div class="fuel-tank-main">
                <span
                  class="fuel-tank-value"
                  :class="`value-${getFuelLevelStatus(fuel)}`"
                >
                  {{ formatNumber(fuel.producto_stock_actual) }}
                  <span class="fuel-tank-unit">{{ fuel.producto_unidad_medida || 'GAL' }}</span>
                </span>
                <span class="fuel-pct-label" :class="`pct-${getFuelLevelStatus(fuel)}`">
                  {{ fuelBarPercent(fuel).toFixed(0) }}% Capacidad
                </span>
                <!-- Progress bar -->
                <div class="fuel-bar-track">
                  <div
                    class="fuel-bar-fill"
                    :class="`bar-${getFuelLevelStatus(fuel)}`"
                    :style="{ width: fuelBarPercent(fuel) + '%' }"
                  ></div>
                </div>
              </div>

              <!-- Right: Capacity info -->
              <div class="fuel-tank-right" v-if="fuel.capacidad_maxima">
                <p class="fuel-cap-label">CAPACIDAD TOTAL</p>
                <p class="fuel-cap-value">{{ formatNumber(fuel.capacidad_maxima) }}</p>
                <p class="fuel-cap-unit">{{ fuel.producto_unidad_medida || 'GAL' }}</p>
              </div>
            </div>
          </div>
        </article>
      </section>

      <!-- ── 2. KPI CARDS ── -->
      <section class="dash-kpi-grid">
        <!-- Flota -->
        <article class="kpi-card">
          <div class="kpi-icon-wrap kpi-primary">
            <span class="material-icons-round">directions_car</span>
          </div>
          <div class="kpi-body">
            <span class="kpi-label">Estado de Flota</span>
            <span class="kpi-value">{{ summary.vehicle_count }}</span>
            <span class="kpi-sub">Vehículos registrados</span>
          </div>
          <span class="kpi-trend kpi-trend-up">
            <span class="material-icons-round">trending_up</span> Activos
          </span>
        </article>

        <!-- Órdenes -->
        <article class="kpi-card">
          <div class="kpi-icon-wrap kpi-blue">
            <span class="material-icons-round">assignment</span>
          </div>
          <div class="kpi-body">
            <span class="kpi-label">Cola de Taller</span>
            <span class="kpi-value">{{ summary.open_orders }}</span>
            <span class="kpi-sub">OTs abiertas</span>
          </div>
          <div class="kpi-tags">
            <span v-if="oilChangeUrgentCount > 0" class="kpi-tag tag-danger">{{ oilChangeUrgentCount }} Urgente</span>
            <span v-if="oilChangeSoonCount > 0" class="kpi-tag tag-warning">{{ oilChangeSoonCount }} Próximo</span>
            <span v-if="oilChangeUrgentCount === 0 && oilChangeSoonCount === 0" class="kpi-tag tag-ok">Al día</span>
          </div>
        </article>

        <!-- Docs vencidos -->
        <article class="kpi-card">
          <div class="kpi-icon-wrap kpi-danger">
            <span class="material-icons-round">warning</span>
          </div>
          <div class="kpi-body">
            <span class="kpi-label">Alertas Documentales</span>
            <span class="kpi-value">{{ expiredDocumentsCount }}</span>
            <span class="kpi-sub">Docs vencidos</span>
          </div>
          <p class="kpi-hint" v-if="documentsDueSoonCount > 0">+{{ documentsDueSoonCount }} por vencer en 30d</p>
        </article>

        <!-- Costo combustible -->
        <article class="kpi-card">
          <div class="kpi-icon-wrap kpi-neutral">
            <span class="material-icons-round">local_gas_station</span>
          </div>
          <div class="kpi-body">
            <span class="kpi-label">Costo Combustible</span>
            <span class="kpi-value kpi-value-sm">{{ formatCurrency(summary.total_fuel_cost) }}</span>
            <span class="kpi-sub">{{ fuelTrendLabel }}</span>
          </div>
        </article>
      </section>

      <!-- ── 3. ACTIVIDAD + ALERTAS ── -->
      <section class="dash-bottom-grid">

        <!-- Consumo mensual (tabla) -->
        <article class="dash-panel">
          <div class="dash-panel-head">
            <h3>Consumo Mensual de Combustible</h3>
            <span class="badge badge-info">{{ fuelMonthly.length }} meses</span>
          </div>
          <div v-if="fuelMonthly.length" class="activity-list">
            <div
              v-for="row in fuelMonthly.slice().reverse().slice(0, 6)"
              :key="`${row.year}-${row.month}`"
              class="activity-item"
            >
              <div class="activity-icon activity-icon-fuel">
                <span class="material-icons-round">local_gas_station</span>
              </div>
              <div class="activity-content">
                <p class="activity-title">{{ formatMonth(row.year, row.month) }}</p>
                <p class="activity-desc">{{ formatNumber(row.gallons) }} gal · {{ formatCurrency(row.cost) }}</p>
              </div>
              <div class="activity-right">
                <p class="activity-cost">{{ row.gallons > 0 ? formatCurrency(row.cost / row.gallons) : '-' }}/gal</p>
              </div>
            </div>
          </div>
          <div v-else class="dash-empty">Sin registros de combustible.</div>
        </article>

        <!-- Alertas documentales -->
        <article class="dash-panel">
          <div class="dash-panel-head">
            <h3>Alertas Documentales</h3>
            <span class="badge badge-warning">{{ documentAlerts.length }}</span>
          </div>
          <div v-if="documentAlerts.length" class="activity-list">
            <div
              v-for="alert in documentAlerts"
              :key="alert.key"
              class="activity-item"
            >
              <div class="activity-icon" :class="alert.days < 0 ? 'activity-icon-danger' : 'activity-icon-warning'">
                <span class="material-icons-round">{{ alert.days < 0 ? 'report_problem' : 'schedule' }}</span>
              </div>
              <div class="activity-content">
                <p class="activity-title">{{ alert.plate }}</p>
                <p class="activity-desc">{{ alert.type }}</p>
              </div>
              <div class="activity-right">
                <span class="badge" :class="alert.days < 0 ? 'badge-danger' : 'badge-warning'">
                  {{ alert.days < 0 ? `Vencido ${Math.abs(alert.days)}d` : `${alert.days}d` }}
                </span>
              </div>
            </div>
          </div>
          <div v-else class="dash-empty dash-empty-ok">
            <span class="material-icons-round">check_circle</span>
            Sin alertas documentales
          </div>
        </article>

        <!-- Cambios de aceite -->
        <article class="dash-panel">
          <div class="dash-panel-head">
            <h3>Cambios de Aceite</h3>
            <span class="badge badge-danger">{{ oilAlerts.length }}</span>
          </div>
          <div v-if="oilAlerts.length" class="activity-list">
            <div
              v-for="alert in oilAlerts"
              :key="alert.key"
              class="activity-item"
            >
              <div class="activity-icon" :class="alert.remainingKm <= 0 ? 'activity-icon-danger' : 'activity-icon-warning'">
                <span class="material-icons-round">oil_barrel</span>
              </div>
              <div class="activity-content">
                <p class="activity-title">{{ alert.plate }}</p>
                <p class="activity-desc">{{ formatNumber(alert.currentKm) }} / {{ formatNumber(alert.nextKm) }} km</p>
              </div>
              <div class="activity-right">
                <span class="badge" :class="alert.remainingKm <= 0 ? 'badge-danger' : 'badge-warning'">
                  {{ alert.remainingKm <= 0 ? `${formatNumber(Math.abs(alert.remainingKm))} km venc.` : `${formatNumber(alert.remainingKm)} km` }}
                </span>
              </div>
            </div>
          </div>
          <div v-else class="dash-empty dash-empty-ok">
            <span class="material-icons-round">check_circle</span>
            Sin cambios urgentes
          </div>
        </article>

      </section>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import { fetchDashboardSources } from '../api/dashboardService';
import { useRefresh } from '../../../shared/composables/useRefresh';

const OIL_SOON_THRESHOLD_KM = 500;
const DUE_SOON_DAYS = 30;

const { refreshTrigger } = useRefresh();
const { loading, error, run } = useAsyncState('');

const summary = ref({ total_fuel_cost: 0, total_maintenance_cost: 0, vehicle_count: 0, open_orders: 0 });
const fuelMonthly = ref([]);
const maintenanceByVehicle = ref([]);
const vehicles = ref([]);
const fuelStock = ref([]);

const todayFormatted = computed(() =>
  new Date().toLocaleDateString('es-CO', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
);

onMounted(loadDashboard);

async function loadDashboard() {
  try {
    await run(async () => {
      const payload = await fetchDashboardSources();
      summary.value = payload.summary || summary.value;
      fuelMonthly.value = Array.isArray(payload.fuelMonthly) ? payload.fuelMonthly : [];
      maintenanceByVehicle.value = Array.isArray(payload.maintenanceByVehicle) ? payload.maintenanceByVehicle : [];
      vehicles.value = Array.isArray(payload.vehicles) ? payload.vehicles : [];
      fuelStock.value = Array.isArray(payload.fuelStock) ? payload.fuelStock : [];
    }, 'Error al cargar dashboard');
  } catch { /* handled */ }
}

watch(refreshTrigger, loadDashboard);

// --- Vehicle Alerts ---
const parsedVehicleAlerts = computed(() =>
  vehicles.value.map((vehicle, index) => {
    const plate = vehicle?.placa || `Vehiculo-${index + 1}`;
    const soatDays = daysUntil(vehicle?.fecha_vencimiento_soat || vehicle?.soat);
    const technoDays = daysUntil(vehicle?.fecha_vencimiento_tecnomecanica || vehicle?.rtm);
    const currentKm = Number(vehicle?.kilometraje_actual ?? 0);
    const nextKm = Number(vehicle?.kilometraje_proximo_mantenimiento ?? 0);
    const hasOilData = Number.isFinite(currentKm) && Number.isFinite(nextKm) && nextKm > 0;
    const remainingKm = hasOilData ? Math.round(nextKm - currentKm) : null;
    return { key: `${plate}-${index}`, plate, soatDays, technoDays, currentKm, nextKm, remainingKm };
  })
);

const documentAlerts = computed(() => {
  const alerts = [];
  parsedVehicleAlerts.value.forEach((item) => {
    if (item.soatDays !== null && item.soatDays <= DUE_SOON_DAYS)
      alerts.push({ key: `${item.key}-soat`, plate: item.plate, type: 'SOAT', days: item.soatDays });
    if (item.technoDays !== null && item.technoDays <= DUE_SOON_DAYS)
      alerts.push({ key: `${item.key}-tecno`, plate: item.plate, type: 'Tecnomecánica', days: item.technoDays });
  });
  return alerts.sort((a, b) => a.days - b.days).slice(0, 8);
});

const oilAlerts = computed(() =>
  parsedVehicleAlerts.value
    .filter((item) => item.remainingKm !== null && item.remainingKm <= OIL_SOON_THRESHOLD_KM)
    .sort((a, b) => a.remainingKm - b.remainingKm)
    .slice(0, 8)
);

const expiredDocumentsCount = computed(() =>
  parsedVehicleAlerts.value.reduce((c, item) =>
    c + (item.soatDays !== null && item.soatDays < 0 ? 1 : 0)
      + (item.technoDays !== null && item.technoDays < 0 ? 1 : 0), 0)
);

const documentsDueSoonCount = computed(() =>
  parsedVehicleAlerts.value.reduce((c, item) =>
    c + (item.soatDays !== null && item.soatDays >= 0 && item.soatDays <= DUE_SOON_DAYS ? 1 : 0)
      + (item.technoDays !== null && item.technoDays >= 0 && item.technoDays <= DUE_SOON_DAYS ? 1 : 0), 0)
);

const oilChangeUrgentCount = computed(() =>
  parsedVehicleAlerts.value.filter((item) => item.remainingKm !== null && item.remainingKm <= 0).length
);

const oilChangeSoonCount = computed(() =>
  parsedVehicleAlerts.value.filter((item) => item.remainingKm !== null && item.remainingKm > 0 && item.remainingKm <= OIL_SOON_THRESHOLD_KM).length
);

const fuelTrendLabel = computed(() => {
  if (fuelMonthly.value.length < 2) return 'Sin base comparativa';
  const last = Number(fuelMonthly.value[fuelMonthly.value.length - 1]?.gallons ?? 0);
  const prev = Number(fuelMonthly.value[fuelMonthly.value.length - 2]?.gallons ?? 0);
  if (prev <= 0) return 'Sin comparativo';
  const change = ((last - prev) / prev) * 100;
  return `${change >= 0 ? '+' : ''}${change.toFixed(1)}% vs mes anterior`;
});

// --- Utilities ---
function daysUntil(rawDate) {
  if (!rawDate) return null;
  const date = new Date(rawDate);
  if (Number.isNaN(date.getTime())) return null;
  return Math.ceil((date - new Date()) / 864e5);
}

function formatMonth(year, month) {
  const d = new Date(Number(year), Number(month) - 1, 1);
  return Number.isNaN(d.getTime()) ? 'N/D'
    : d.toLocaleDateString('es-CO', { month: 'long', year: 'numeric' });
}

function formatNumber(value) {
  return Number(value || 0).toLocaleString('es-CO', { maximumFractionDigits: 1 });
}

function formatCurrency(value) {
  return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(Number(value || 0));
}

function fuelIcon(name) {
  const n = (name || '').toLowerCase();
  if (n.includes('gasolina')) return 'gas_meter';
  if (n.includes('acpm') || n.includes('diesel')) return 'oil_barrel';
  return 'propane_tank';
}

function fuelBarPercent(fuel) {
  const stock = Number(fuel.producto_stock_actual || 0);
  if (fuel.capacidad_maxima && Number(fuel.capacidad_maxima) > 0)
    return Math.min(Math.max((stock / Number(fuel.capacidad_maxima)) * 100, 0), 100);
  const min = Number(fuel.producto_alerta_stock_minimo || 1);
  return Math.min((stock / Math.max(min * 3, stock)) * 100, 100);
}

function getFuelLevelStatus(fuel) {
  const stock = Number(fuel.producto_stock_actual || 0);
  const min = Number(fuel.producto_alerta_stock_minimo || 0);

  // Critical is 50% of the minimum alert threshold (e.g., if min is 800, critical is 400)
  const criticalThreshold = min / 2;

  if (stock <= criticalThreshold) return 'danger';
  if (stock <= min) return 'warning';
  return 'ok';
}

function getFuelLevelText(fuel) {
  const status = getFuelLevelStatus(fuel);
  if (status === 'danger') return 'Nivel Crítico';
  if (status === 'warning') return 'Nivel Bajo';
  return 'Nivel Óptimo';
}
</script>

<style scoped>
/* ═══ BASE ═══ */
.dash-page {
  display: flex;
  flex-direction: column;
  gap: 28px;
  width: 100%;
  min-width: 0;
}

.dash-loading {
  display: flex;
  align-items: center;
  gap: 12px;
  color: var(--text-gray);
  padding: 40px;
  font-size: 0.9rem;
}

.dash-error {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 60px;
  color: var(--danger);
}

/* ═══ HEADER ═══ */
.dash-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--surface-2);
}

.dash-header-left {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.dash-title {
  font-family: 'Oswald', sans-serif;
  font-size: 1.6rem;
  font-weight: 700;
  letter-spacing: 1px;
  color: var(--text-main);
  text-transform: uppercase;
}

.dash-header-divider {
  width: 1px;
  height: 24px;
  background: var(--surface-2);
}

.dash-subtitle {
  font-size: 0.8rem;
  color: var(--text-gray);
  font-weight: 500;
  text-transform: capitalize;
}

/* ═══ TANQUES DE COMBUSTIBLE ═══ */
.dash-fuel-hero {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 20px;
}

.fuel-tank-card {
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: 20px;
  padding: 32px;
  position: relative;
  overflow: hidden;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.fuel-tank-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 40px rgba(0,0,0,0.4);
}

.fuel-tank-card::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 3px;
  background: linear-gradient(90deg, var(--primary), var(--success));
}

.fuel-tank-danger::before {
  background: linear-gradient(90deg, #f97316, #ef4444);
}

.fuel-tank-danger {
  border-color: rgba(239, 68, 68, 0.4);
}

.fuel-tank-warning::before {
  background: linear-gradient(90deg, #facc15, #f59e0b);
}

.fuel-tank-warning {
  border-color: rgba(245, 158, 11, 0.4);
}

/* Big ghost icon */
.fuel-tank-bg-icon {
  position: absolute;
  top: 12px;
  right: 20px;
  font-size: 120px;
  opacity: 0.07;
  color: var(--text-main);
  pointer-events: none;
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.fuel-tank-card:hover .fuel-tank-bg-icon {
  opacity: 0.12;
  transform: scale(1.08);
}

.fuel-tank-body {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.fuel-tank-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.fuel-tank-indicator {
  display: flex;
  align-items: center;
  gap: 8px;
}

.fuel-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.fuel-dot-ok {
  background: var(--success);
  box-shadow: 0 0 8px var(--success);
}

.fuel-dot-warning {
  background: #f59e0b;
  box-shadow: 0 0 8px #f59e0b;
  animation: pulseDot 2s infinite;
}

.fuel-dot-danger {
  background: #ef4444;
  box-shadow: 0 0 8px #ef4444;
  animation: pulseDot 1.4s infinite;
}

@keyframes pulseDot {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.5; transform: scale(0.8); }
}

.fuel-tank-label {
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--text-gray);
  text-transform: uppercase;
  letter-spacing: 1px;
}

.fuel-tank-sku {
  font-size: 0.72rem;
  color: var(--text-muted);
  font-weight: 600;
  letter-spacing: 0.5px;
}

.fuel-tank-name {
  font-family: 'Oswald', sans-serif;
  font-size: 2.2rem;
  font-weight: 700;
  color: var(--text-main);
  text-transform: uppercase;
  line-height: 1;
}

.fuel-tank-row {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
}

.fuel-tank-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.fuel-tank-value {
  font-family: 'Oswald', sans-serif;
  font-size: 3.5rem;
  font-weight: 900;
  line-height: 1;
}

.fuel-tank-unit {
  font-size: 1rem;
  font-weight: 400;
  color: var(--text-gray);
  margin-left: 6px;
}

.value-ok { color: var(--primary); }
.value-warning { color: #f59e0b; }
.value-danger { color: #ef4444; }

.fuel-pct-label {
  font-size: 0.78rem;
  color: var(--text-gray);
  font-weight: 600;
}

.pct-ok { color: var(--text-gray); }
.pct-warning { color: #f59e0b; font-weight: 700; }
.pct-danger { color: #f97316; font-weight: 700; }

.fuel-bar-track {
  height: 14px;
  background: var(--surface-2);
  border-radius: 7px;
  overflow: hidden;
}

.fuel-bar-fill {
  height: 100%;
  border-radius: 7px;
  transition: width 1.2s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.bar-ok {
  background: linear-gradient(90deg, var(--primary), var(--success));
  box-shadow: 0 0 16px rgba(242, 242, 13, 0.3);
}

.bar-warning {
  background: linear-gradient(90deg, #fde047, #f59e0b);
  box-shadow: 0 0 16px rgba(245, 158, 11, 0.3);
}

.bar-danger {
  background: linear-gradient(90deg, #f97316, #ef4444);
  box-shadow: 0 0 16px rgba(239, 68, 68, 0.3);
}

.fuel-tank-right {
  text-align: right;
  border-left: 1px solid var(--surface-2);
  padding-left: 20px;
  flex-shrink: 0;
}

.fuel-cap-label {
  font-size: 0.65rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  color: var(--text-muted);
  margin-bottom: 4px;
}

.fuel-cap-value {
  font-family: 'Oswald', sans-serif;
  font-size: 2.2rem;
  font-weight: 700;
  color: var(--text-main);
  line-height: 1;
}

.fuel-cap-unit {
  font-size: 0.72rem;
  color: var(--text-muted);
  font-weight: 600;
  margin-top: 2px;
}

/* ═══ KPI GRID ═══ */
.dash-kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.kpi-card {
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: 16px;
  padding: 22px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  transition: all 0.25s ease;
  position: relative;
  overflow: hidden;
}

.kpi-card:hover {
  transform: translateY(-2px);
  border-color: var(--surface-3);
  box-shadow: 0 8px 24px rgba(0,0,0,0.3);
}

.kpi-icon-wrap {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.kpi-icon-wrap .material-icons-round {
  font-size: 22px;
}

.kpi-primary { background: var(--primary-10); color: var(--primary); }
.kpi-blue    { background: var(--info-10); color: #60a5fa; }
.kpi-danger  { background: var(--danger-10);  color: #f87171; }
.kpi-neutral { background: rgba(100, 116, 139, 0.15); color: var(--text-gray); }

.kpi-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.kpi-label {
  font-size: 0.72rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.8px;
  color: var(--text-gray);
}

.kpi-value {
  font-family: 'Oswald', sans-serif;
  font-size: 2.4rem;
  font-weight: 900;
  color: var(--text-main);
  line-height: 1.1;
}

.kpi-value-sm {
  font-size: 1.3rem;
}

.kpi-sub {
  font-size: 0.72rem;
  color: var(--text-muted);
}

.kpi-trend {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 0.72rem;
  font-weight: 700;
}

.kpi-trend .material-icons-round { font-size: 14px; }
.kpi-trend-up { color: var(--success); }

.kpi-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.kpi-tag {
  font-size: 0.65rem;
  font-weight: 800;
  padding: 2px 8px;
  border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.tag-danger  { background: var(--danger-10);  color: #f87171; }
.tag-warning { background: var(--warning-10); color: #fbbf24; }
.tag-ok      { background: var(--success-10);  color: var(--success); }

.kpi-hint {
  font-size: 0.7rem;
  color: #fbbf24;
  font-weight: 600;
  font-style: italic;
}

/* ═══ BOTTOM GRID ═══ */
.dash-bottom-grid {
  display: grid;
  grid-template-columns: 1.3fr 1fr 1fr;
  gap: 20px;
}

.dash-panel {
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: 16px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.dash-panel-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 20px;
  border-bottom: 1px solid var(--surface-2);
}

.dash-panel-head h3 {
  font-family: 'Oswald', sans-serif;
  font-size: 0.95rem;
  font-weight: 600;
  letter-spacing: 0.5px;
  text-transform: uppercase;
  color: var(--text-main);
}

/* Activity list */
.activity-list {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.activity-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 20px;
  border-bottom: 1px solid var(--surface-2);
  transition: background 0.2s ease;
}

.activity-item:last-child {
  border-bottom: none;
}

.activity-item:hover {
  background: var(--primary-10);
}

.activity-icon {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.activity-icon .material-icons-round { font-size: 20px; }

.activity-icon-fuel    { background: var(--primary-10); color: var(--primary); }
.activity-icon-danger  { background: var(--danger-10);  color: #f87171; }
.activity-icon-warning { background: var(--warning-10); color: #fbbf24; }

.activity-content {
  flex: 1;
  min-width: 0;
}

.activity-title {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--text-main);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.activity-desc {
  font-size: 0.75rem;
  color: var(--text-gray);
  margin-top: 2px;
}

.activity-right {
  flex-shrink: 0;
  text-align: right;
}

.activity-cost {
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--text-gray);
}

/* Empty states */
.dash-empty {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 30px 20px;
  font-size: 0.82rem;
  color: var(--text-muted);
  font-style: italic;
  flex: 1;
}

.dash-empty-ok {
  color: var(--success);
  font-style: normal;
  font-weight: 600;
}

.dash-empty-ok .material-icons-round {
  font-size: 20px;
}

/* Badges reutilizables */
.badge {
  font-size: 0.65rem;
  font-weight: 800;
  padding: 3px 10px;
  border-radius: 20px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.badge-info    { background: var(--info-10); color: #60a5fa; }
.badge-warning { background: var(--warning-10); color: #fbbf24; }
.badge-danger  { background: var(--danger-10);  color: #f87171; }
.badge-neutral { background: rgba(100,116,139,0.15); color: var(--text-gray); }

/* Spinner */
.spinner {
  width: 20px;
  height: 20px;
  border: 2px solid var(--surface-2);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

/* ─── Responsive ─── */
@media (max-width: 1200px) {
  .dash-kpi-grid { grid-template-columns: repeat(2, 1fr); }
  .dash-bottom-grid { grid-template-columns: 1fr 1fr; }
}

@media (max-width: 768px) {
  .dash-kpi-grid { grid-template-columns: 1fr 1fr; }
  .dash-bottom-grid { grid-template-columns: 1fr; }
  .fuel-tank-card { padding: 20px; }
  .fuel-tank-name { font-size: 1.6rem; }
  .fuel-tank-value { font-size: 2.4rem; }
}
</style>
