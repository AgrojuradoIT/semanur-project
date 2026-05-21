<template>
  <div class="preoperacionales-page">
    <!-- Page Header -->
    <div class="page-header">
      <h3>INSPECCIONES PREOPERACIONALES</h3>
      <div class="page-actions">
        <select v-model="selectedWeek" class="filter-select">
          <option value="all">Todas las semanas</option>
          <option v-for="w in weekOptions" :key="w.value" :value="w.value">
            {{ w.label }}
          </option>
        </select>
        <select v-model="selectedVehicle" class="filter-select">
          <option value="all">Todos los vehiculos</option>
          <option v-for="v in vehicles" :key="vehicleId(v)" :value="vehicleId(v)">
            {{ v.placa || 'Sin placa' }}
          </option>
        </select>
        <select v-model="selectedStatus" class="filter-select">
          <option value="all">Todos los estados</option>
          <option value="activa">Activa</option>
          <option value="completada">Completada</option>
          <option value="fuera_servicio">Fuera Servicio</option>
          <option value="vencida">Vencida</option>
        </select>
        <button class="btn btn-primary btn-sm" @click="openCreateModal">
          <span class="material-icons-round" style="font-size: 18px">add_circle</span>
          CREAR SEMANA
        </button>
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
          <span class="card-icon">&#128994;</span>
        </div>
        <div class="summary-card">
          <span class="card-value">{{ enProgreso }}</span>
          <span class="card-label">En Progreso</span>
          <span class="card-icon">&#128992;</span>
        </div>
        <div class="summary-card">
          <span class="card-value">{{ pendientes }}</span>
          <span class="card-label">Pendientes</span>
          <span class="card-icon">&#9898;</span>
        </div>
        <div class="summary-card">
          <span class="card-value">{{ fueraServicio }}</span>
          <span class="card-label">Fuera Servicio</span>
          <span class="card-icon">&#128308;</span>
        </div>
        <div class="summary-card">
          <span class="card-value">{{ vencidas }}</span>
          <span class="card-label">Vencidas</span>
          <span class="card-icon">&#9940;</span>
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

    <!-- Create Modal -->
    <div v-if="showCreate" class="modal-overlay" @click.self="closeCreateModal">
      <div class="modal modal-wide">
        <div class="modal-header">
          <h3>CREAR INSPECCION SEMANAL</h3>
          <button class="modal-close" @click="closeCreateModal">
            <span class="material-icons-round" style="font-size: 18px">close</span>
          </button>
        </div>

        <div class="modal-body">
          <div class="form-grid">
            <div class="input-group full-width">
              <label>Vehiculo</label>
              <SearchableSelect
                v-model="createForm.vehiculo_id"
                :items="vehicles"
                :label-fn="vehicleLabel"
                :value-fn="vehicleId"
                placeholder="Seleccionar vehiculo..."
              />
            </div>

            <div class="input-group">
              <label>Inspector</label>
              <SearchableSelect
                v-model="createForm.inspector_id"
                :items="employees"
                :label-fn="(e) => `${e.nombres} ${e.apellidos || ''}`.trim()"
                placeholder="Seleccionar inspector..."
              />
            </div>

            <div class="input-group">
              <label>Semana (inicio)</label>
              <input v-model="createForm.semana_inicio" type="date" class="input" />
              <small class="input-hint">Debe ser un lunes</small>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn btn-secondary" @click="closeCreateModal">Cancelar</button>
          <button class="btn btn-primary" :disabled="saving" @click="handleCreateSemana">
            <span class="material-icons-round" style="font-size: 18px">save</span>
            {{ saving ? 'GUARDANDO...' : 'CREAR SEMANA' }}
          </button>
        </div>
      </div>
    </div>
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
  createSemana,
  markFueraServicio,
} from '../api/preoperacionalesService';

const { loading, error, run } = useAsyncState('');
const { notify: islandNotify } = useDynamicIsland();

const semanas = ref([]);
const templates = ref([]);
const vehicles = ref([]);
const employees = ref([]);

// Filters
const selectedWeek = ref('all');
const selectedVehicle = ref('all');
const selectedStatus = ref('all');

// Modals
const showCreate = ref(false);
const showDetail = ref(false);
const selectedSemana = ref(null);
const selectedTemplate = ref(null);
const saving = ref(false);

const createForm = ref({
  vehiculo_id: '',
  inspector_id: '',
  semana_inicio: '',
});

onMounted(async () => {
  await loadData();
});

async function loadData() {
  try {
    await run(async () => {
      const catalogsStore = useCatalogsStore();
      await catalogsStore.fetchEssentialCatalogs();

      const [templatesData, semanasData] = await Promise.all([
        fetchTemplates(),
        fetchSemanas(),
      ]);

      templates.value = templatesData;
      semanas.value = semanasData.data || semanasData;
      vehicles.value = catalogsStore.vehiculos;
      employees.value = catalogsStore.empleados.filter((e) => {
        const c = (e.cargo || '').toLowerCase();
        return c.includes('operador') || c.includes('conductor') || c.includes('inspector') || c.includes('supervisor');
      });
    }, 'Error al cargar inspecciones');
  } catch (e) {
    console.error('[Preoperacional] Error en loadData:', e);
  }
}

const filteredSemanas = computed(() => {
  let result = semanas.value;

  if (selectedWeek.value !== 'all') {
    result = result.filter((s) => s.fecha_inicio === selectedWeek.value);
  }

  if (selectedVehicle.value !== 'all') {
    result = result.filter((s) => String(s.vehiculoId) === String(selectedVehicle.value));
  }

  if (selectedStatus.value !== 'all') {
    result = result.filter((s) => s.estado === selectedStatus.value);
  }

  return result;
});

const completadas = computed(() => semanas.value.filter((s) => s.estado === 'completada').length);
const enProgreso = computed(() => semanas.value.filter((s) => s.estado === 'activa').length);
const pendientes = computed(() => semanas.value.filter((s) => !s.estado || s.estado === 'pendiente').length);
const fueraServicio = computed(() => semanas.value.filter((s) => s.estado === 'fuera_servicio').length);
const vencidas = computed(() => semanas.value.filter((s) => s.estado === 'vencida').length);

const weekOptions = computed(() => {
  const weeks = [...new Set(semanas.value.map((s) => s.fecha_inicio).filter(Boolean))];
  return weeks.map((w) => ({
    value: w,
    label: formatDate(w),
  }));
});

function openCreateModal() {
  showCreate.value = true;
  createForm.value = { vehiculo_id: '', inspector_id: '', semana_inicio: '' };
}

function closeCreateModal() {
  showCreate.value = false;
  createForm.value = { vehiculo_id: '', inspector_id: '', semana_inicio: '' };
}

async function handleCreateSemana() {
  if (!createForm.value.vehiculo_id) {
    islandNotify({ type: 'warning', title: 'Falta vehiculo', message: 'Seleccione el vehiculo', duration: 15000 });
    return;
  }
  if (!createForm.value.inspector_id) {
    islandNotify({ type: 'warning', title: 'Falta inspector', message: 'Seleccione el inspector', duration: 15000 });
    return;
  }
  if (!createForm.value.semana_inicio) {
    islandNotify({ type: 'warning', title: 'Falta semana', message: 'Seleccione la fecha de inicio', duration: 15000 });
    return;
  }

  const startDate = new Date(createForm.value.semana_inicio + 'T00:00:00');
  if (startDate.getDay() !== 1) {
    islandNotify({ type: 'warning', title: 'Fecha invalida', message: 'La fecha de inicio debe ser un lunes', duration: 15000 });
    return;
  }

  saving.value = true;
  try {
    await createSemana({
      vehiculo_id: Number(createForm.value.vehiculo_id),
      inspector_id: Number(createForm.value.inspector_id),
      semana_inicio: createForm.value.semana_inicio,
    });
    closeCreateModal();
    await loadData();
    islandNotify({ type: 'success', title: 'Semana creada', message: 'La inspeccion semanal se registro correctamente', duration: 15000 });
  } catch (e) {
    const msg = e?.response?.data?.message || e?.message || 'Error al crear semana';
    islandNotify({ type: 'error', title: 'Error al guardar', message: msg, duration: 60000 });
  } finally {
    saving.value = false;
  }
}

function openDetailModal(semana) {
  selectedSemana.value = semana;
  selectedTemplate.value = templates.value.find((t) => t.id === semana.templateId) || {};
  showDetail.value = true;
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
  return `${vehicle?.placa || 'Sin placa'} - ${vehicle?.tipo || vehicle?.modelo || ''}`.trim();
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

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: var(--sp-md);
}

.page-header h3 {
  font-family: 'Oswald', sans-serif;
  font-size: 1.1rem;
  font-weight: 700;
  letter-spacing: 1px;
  margin: 0;
}

.page-actions {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
  flex-wrap: wrap;
}

.filter-select {
  padding: 6px 12px;
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-sm);
  background: var(--surface-1);
  color: var(--text-secondary);
  font-size: 0.82rem;
  cursor: pointer;
}

.filter-select:focus {
  border-color: var(--primary);
  outline: none;
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
  align-items: center;
  gap: 4px;
  padding: var(--sp-md);
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  text-align: center;
}

.summary-card:hover {
  border-color: var(--primary);
}

.card-value {
  font-family: 'Oswald', sans-serif;
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--text-main);
}

.card-label {
  font-size: 0.72rem;
  color: var(--text-gray);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.card-icon {
  font-size: 1rem;
  opacity: 0.6;
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

  .filter-select {
    flex: 1;
    min-width: 0;
  }

  .summary-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
