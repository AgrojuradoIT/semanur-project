<template>
  <div class="preoperacionales-page">
    <!-- Page Header (Standard) -->
    <div class="table-header" style="border-radius: var(--radius-lg); margin-bottom: 0;">
      <div style="display: flex; align-items: center; gap: var(--sp-md); flex-wrap: wrap">
        <h3 class="table-title">INSPECCIONES PREOPERACIONALES</h3>
        <div class="filter-chips">
          <button
            v-for="chip in statusOptions"
            :key="chip.value"
            class="chip"
            :class="{ active: selectedStatus === chip.value }"
            @click="selectedStatus = chip.value"
          >
            {{ chip.label }}
          </button>
        </div>
      </div>

      <div class="table-actions">
        <select v-model="selectedWeek" class="filter-select">
          <option value="all">Todas las semanas</option>
          <option v-for="w in weekOptions" :key="w.value" :value="w.value">
            {{ w.label }}
          </option>
        </select>
        
        <div class="table-search">
          <span class="material-icons-round">search</span>
          <input v-model="searchQuery" type="text" placeholder="Buscar placa..." />
        </div>
      </div>
    </div>

    <!-- Info Banner (Strict Mode) -->
    <div class="info-banner">
      <span class="material-icons-round">info</span>
      <div class="banner-text">
        <strong>Modo Auditoría:</strong> El diligenciamiento diario de los preoperacionales se realiza exclusivamente desde la App Móvil por los operadores. Este panel web es únicamente para revisión y control.
      </div>
    </div>

    <!-- Loading / Error -->
    <div v-if="loading" class="page-loading">
      <span class="spinner"></span>
      Cargando inspecciones...
    </div>

    <div v-else-if="error" class="empty-state">
      <span class="material-icons-round">cloud_off</span>
      <p>{{ error }}</p>
    </div>

    <template v-else>
      <!-- Summary Cards -->
      <div class="summary-cards">
        <div class="summary-card">
          <span class="card-value">{{ completadas }}</span>
          <span class="card-label">Completadas</span>
          <span class="card-icon material-icons-round" style="color: var(--success)">check_circle</span>
        </div>
        <div class="summary-card">
          <span class="card-value">{{ enProgreso }}</span>
          <span class="card-label">En Progreso</span>
          <span class="card-icon material-icons-round" style="color: var(--warning)">pending</span>
        </div>
        <div class="summary-card">
          <span class="card-value">{{ pendientes }}</span>
          <span class="card-label">Pendientes</span>
          <span class="card-icon material-icons-round" style="color: var(--text-muted)">radio_button_unchecked</span>
        </div>
        <div class="summary-card">
          <span class="card-value">{{ fueraServicio }}</span>
          <span class="card-label">Fuera Servicio</span>
          <span class="card-icon material-icons-round" style="color: var(--danger)">block</span>
        </div>
        <div class="summary-card">
          <span class="card-value">{{ vencidas }}</span>
          <span class="card-label">Vencidas</span>
          <span class="card-icon material-icons-round" style="color: var(--danger)">error</span>
        </div>
      </div>

      <!-- Alerts Panel -->
      <AlertsPanel :semanas="semanas" @view-semana="openDetailModal" />

      <!-- Weekly Grid -->
      <WeeklyGrid :semanas="filteredSemanas" :templates="templates" @row-click="openDetailModal" />

      <!-- Footer -->
      <div class="table-footer">
        Mostrando {{ filteredSemanas.length }} semana(s)
      </div>
    </template>

    <!-- Detail Modal -->
    <SemanaDetailModal
      v-model="showDetail"
      :semana="selectedSemana"
      :template="selectedTemplate"
      @fuera-servicio="handleFueraServicio"
    />


  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import { useCatalogsStore } from '../../../shared/stores/catalogs';
import { useDynamicIsland } from '../../../shared/composables/useDynamicIsland';
import SearchableSelect from '../../../shared/components/SearchableSelect.vue';
import WeeklyGrid from '../components/WeeklyGrid.vue';
import AlertsPanel from '../components/AlertsPanel.vue';
import SemanaDetailModal from '../components/SemanaDetailModal.vue';
import {
  fetchTemplates,
  fetchSemanas,
  fetchSemana,
  markFueraServicio,
} from '../api/preoperacionalesService';

const { loading, error, run } = useAsyncState('');
const { notify: islandNotify } = useDynamicIsland();
const catalogsStore = useCatalogsStore();

const semanas = ref([]);
const templates = ref([]);
const vehicles = ref([]);
const employees = ref([]);

// Filters
const selectedWeek = ref('all');
const searchQuery = ref('');
const selectedStatus = ref('all');

// Modals
const showDetail = ref(false);
const selectedSemana = ref(null);
const selectedTemplate = ref(null);

const statusOptions = [
  { label: 'Todos', value: 'all' },
  { label: 'Pendientes', value: 'pendiente' },
  { label: 'En Progreso', value: 'en_progreso' },
  { label: 'Completados', value: 'completado' },
  { label: 'Fuera Servicio', value: 'fuera_servicio' }
];

onMounted(async () => {
  await loadData();
});

async function loadData() {
  try {
    await run(async () => {
      await catalogsStore.fetchEssentialCatalogs();

      const [templatesData, semanasData] = await Promise.all([
        fetchTemplates(),
        fetchSemanas(),
      ]);

      console.log('[Preop] Templates loaded:', templatesData);
      console.log('[Preop] Semanas loaded:', semanasData);

      templates.value = templatesData;
      semanas.value = semanasData?.data || semanasData || [];
      console.log('[Preop] semanas.value:', semanas.value);
      vehicles.value = catalogsStore.vehiculos;
      employees.value = catalogsStore.empleados.filter((e) => {
        const c = (e.cargo || '').toLowerCase();
        return c.includes('operador') || c.includes('conductor') || c.includes('inspector') || c.includes('supervisor') || c.includes('jefe') || c.includes('coordinador');
      });
    }, 'Error al cargar inspecciones');
  } catch (e) {
    console.error('[Preoperacional] Error en loadData:', e);
  }
}

const filteredSemanas = computed(() => {
  let result = semanas.value;

  if (selectedWeek.value !== 'all') {
    result = result.filter((s) => s.semana_inicio === selectedWeek.value);
  }

  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase();
    result = result.filter((s) => {
      const placa = (s.vehiculo_placa || s.vehiculo?.placa || '').toLowerCase();
      return placa.includes(q);
    });
  }

  if (selectedStatus.value !== 'all') {
    result = result.filter((s) => s.estado === selectedStatus.value);
  }

  return result;
});

const completadas = computed(() => semanas.value.filter((s) => s.estado === 'completado').length);
const enProgreso = computed(() => semanas.value.filter((s) => s.estado === 'en_progreso').length);
const pendientes = computed(() => semanas.value.filter((s) => !s.estado || s.estado === 'pendiente').length);
const fueraServicio = computed(() => semanas.value.filter((s) => s.estado === 'fuera_servicio').length);
const vencidas = computed(() => semanas.value.filter((s) => s.estado === 'vencida').length);

function formatWeekLabel(dateStr) {
  if (!dateStr) return 'Semana Desconocida';
  const d = new Date(dateStr);
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay()||7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1));
  const weekNo = Math.ceil((((d - yearStart) / 86400000) + 1)/7);
  return `Semana ${weekNo}`;
}

const weekOptions = computed(() => {
  const weeks = [...new Set(semanas.value.map((s) => s.semana_inicio).filter(Boolean))];
  return weeks.map((w) => ({
    value: w,
    label: formatWeekLabel(w),
  }));
});

const vehiclesWithAll = computed(() => {
  return [
    { id: 'all', placa: 'Todos los vehículos', tipo: '' },
    ...vehicles.value,
  ];
});



async function openDetailModal(semana) {
  try {
    islandNotify({ type: 'info', message: 'Cargando detalles...', duration: 2000 });
    const response = await fetchSemana(semana.id);
    const fullSemana = response?.data || response;
    
    selectedSemana.value = fullSemana;
    selectedTemplate.value = fullSemana.template || templates.value.find((t) => t.id === fullSemana.template_id) || null;
    showDetail.value = true;
  } catch (e) {
    islandNotify({ type: 'error', message: 'Error cargando detalles', duration: 4000 });
    console.error(e);
  }
}

async function handleFueraServicio(semanaId) {
  const motivo = prompt('Motivo para marcar fuera de servicio:');
  if (!motivo) return;

  try {
    await markFueraServicio(semanaId, motivo);
    showDetail.value = false;
    await loadData();
    islandNotify({ type: 'success', title: 'Fuera de servicio', message: 'El vehiculo fue marcado fuera de servicio', duration: 15000 });
  } catch (e) {
    const msg = e?.response?.data?.message || e?.message || 'Error al marcar fuera de servicio';
    islandNotify({ type: 'error', title: 'Error', message: msg, duration: 60000 });
  }
}

function vehicleId(vehicle) {
  return vehicle?.vehiculo_id ?? vehicle?.id ?? '';
}

function vehicleLabel(vehicle) {
  if (!vehicle) return '';
  if (vehicle.id === 'all' || vehicle.vehiculo_id === 'all' || vehicle.placa === 'Todos los vehículos') {
    return 'Todos los vehículos';
  }
  return `${vehicle.placa || 'Sin placa'} - ${vehicle.tipo || vehicle.modelo || ''}`.trim();
}

function formatDate(value) {
  if (!value) return '';
  const d = new Date(value + 'T00:00:00');
  return d.toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' });
}
</script>

<style scoped>
.preoperacionales-page {
  display: flex;
  flex-direction: column;
  gap: var(--sp-lg);
}

.filter-select {
  padding: 6px 30px 6px 12px;
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-sm);
  background: var(--surface-1);
  color: var(--text-primary);
  font-size: 0.8rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  appearance: none;
  background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6 9 12 15 18 9'%3e%3c/polyline%3e%3c/svg%3e");
  background-repeat: no-repeat;
  background-position: right 8px center;
  background-size: 14px;
}

.filter-select:hover {
  border-color: var(--primary-light);
  background-color: var(--surface-2);
}

.filter-select:focus {
  outline: none;
  border-color: var(--primary);
  background-color: var(--surface);
}
/* Removed unused vehicle search select CSS */

/* Info Banner */
.info-banner {
  display: flex;
  align-items: center;
  gap: var(--sp-md);
  background-color: var(--surface-1);
  border: 1px solid var(--surface-2);
  border-left: 4px solid var(--primary);
  padding: var(--sp-md);
  border-radius: var(--radius-sm);
  margin-top: -8px;
}

.info-banner .material-icons-round {
  color: var(--primary);
  font-size: 24px;
}

.info-banner .banner-text {
  font-size: 0.85rem;
  color: var(--text-secondary);
  line-height: 1.4;
}

.info-banner .banner-text strong {
  color: var(--text-main);
}

/* Summary Cards */
.summary-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: var(--sp-md);
}

.summary-card {
  display: flex;
  flex-direction: column;
  position: relative;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.01) 100%);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 1.5rem 1.25rem;
  border-radius: var(--radius-xl);
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.05);
}

.summary-card:hover {
  transform: translateY(-4px) scale(1.02);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.15);
  border-color: rgba(255, 255, 255, 0.2);
}

.card-value {
  font-size: 2.25rem;
  font-weight: 800;
  color: var(--text-primary);
  line-height: 1;
  margin-bottom: 0.5rem;
  z-index: 2;
}

.card-label {
  font-size: 0.85rem;
  color: var(--text-muted);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  z-index: 2;
}

.card-icon {
  position: absolute;
  right: -10px;
  bottom: -15px;
  font-size: 80px;
  opacity: 0.1;
  transform: rotate(-15deg);
  transition: all 0.3s ease;
  z-index: 1;
}

.summary-card:hover .card-icon {
  transform: rotate(0) scale(1.1);
  opacity: 0.15;
}

/* Table footer standalone */
.table-footer {
  padding: var(--sp-sm) var(--sp-md);
  font-size: 0.78rem;
  color: var(--text-gray);
  text-align: center;
}

/* Create modal form */
.input-hint {
  display: block;
  margin-top: 4px;
  font-size: 0.72rem;
  color: var(--text-muted);
}

/* Responsive */
@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .page-actions {
    width: 100%;
    flex-wrap: wrap;
  }

  .filter-select,
  .vehicle-search-select {
    flex: 1;
    min-width: 0;
  }

  .summary-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
