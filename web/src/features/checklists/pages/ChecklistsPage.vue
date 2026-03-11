<template>
  <div class="table-container">
    <div class="table-header">
      <h3 class="table-title">HISTORIAL DE CHECKLISTS</h3>
      <div class="table-actions">
        <div class="table-search">
          <span class="material-icons-round">search</span>
          <input v-model="search" type="text" placeholder="Buscar placa, operador..." />
        </div>
        <button class="btn btn-primary btn-sm" @click="openCreateModal">
          <span class="material-icons-round" style="font-size: 18px">playlist_add_check</span>
          NUEVO CHECKLIST
        </button>
      </div>
    </div>

    <div class="table-scroll">
      <table v-if="!loading && !error && filteredHistory.length > 0">
        <thead>
          <tr>
            <th>VEHICULO</th>
            <th>OPERADOR</th>
            <th>FECHA</th>
            <th>HOR/KM</th>
            <th>ESTADO</th>
            <th>OBSERVACIONES</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in filteredHistory" :key="checklistId(item)">
            <td style="color: var(--primary); font-weight: 700">{{ checklistVehicle(item) }}</td>
            <td>{{ checklistOperator(item) }}</td>
            <td>{{ formatDateTime(item.fecha || item.created_at) }}</td>
            <td style="font-family: 'Oswald', sans-serif">{{ formatHorometer(item.horometro_actual) }}</td>
            <td>
              <span class="badge" :class="statusClass(item.estado)">{{ statusLabel(item.estado) }}</span>
            </td>
            <td style="max-width: 260px; white-space: normal">
              {{ item.observaciones_generales || item.observaciones || '-' }}
            </td>
          </tr>
        </tbody>
      </table>

      <div v-else-if="loading" class="page-loading">
        <span class="spinner"></span>
        Cargando historial...
      </div>

      <div v-else-if="error" class="empty-state">
        <span class="material-icons-round">cloud_off</span>
        <p>{{ error }}</p>
      </div>

      <div v-else class="empty-state">
        <span class="material-icons-round">playlist_add_check</span>
        <p>No hay checklists registrados</p>
      </div>
    </div>

    <div class="table-footer">
      Mostrando {{ filteredHistory.length }} checklist{{ filteredHistory.length === 1 ? '' : 's' }}
    </div>
  </div>

  <div v-if="showCreate" class="modal-overlay" @click.self="closeCreateModal">
    <div class="modal modal-wide">
      <div class="modal-header">
        <h3>NUEVO CHECKLIST PREOPERACIONAL</h3>
        <button class="modal-close" @click="closeCreateModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>

      <div class="modal-body">
        <div class="form-grid" style="margin-bottom: var(--sp-md)">
          <div class="input-group full-width">
            <label>Vehiculo</label>
            <select v-model="createForm.vehiculo_id" class="input" required @change="onVehicleChange">
              <option value="">Seleccionar...</option>
              <option v-for="vehicle in vehicles" :key="vehicleId(vehicle)" :value="vehicleId(vehicle)">
                {{ vehicleLabel(vehicle) }}
              </option>
            </select>
          </div>
        </div>

        <div v-if="templateLoading" class="page-loading" style="height: 160px">
          <span class="spinner"></span>
          Cargando plantilla...
        </div>

        <div v-else-if="createForm.vehiculo_id && !selectedTemplate" class="empty-state" style="padding: var(--sp-lg)">
          <span class="material-icons-round">error_outline</span>
          <p>No hay plantillas activas para este tipo de vehiculo.</p>
        </div>

        <form v-else-if="selectedTemplate" class="form-grid" @submit.prevent="submitChecklist">
          <div class="input-group">
            <label>Operador / Conductor</label>
            <select v-model="createForm.operador_id" class="input" required>
              <option value="">Seleccionar...</option>
              <option v-for="emp in employees" :key="emp.id" :value="emp.id">
                {{ emp.nombres }} {{ emp.apellidos || '' }}
              </option>
            </select>
          </div>

          <div v-if="!isAerialVehicle" class="input-group">
            <label>Horometro / Kilometraje</label>
            <input v-model.number="createForm.horometro_actual" class="input" type="number" min="0" required />
          </div>

          <div class="input-group full-width">
            <label style="margin-bottom: 4px">Items de inspeccion: {{ selectedTemplate.nombre }}</label>
            <div style="display: flex; flex-direction: column; gap: 8px">
              <div
                v-for="item in checklistItems"
                :key="item.id"
                style="display: flex; align-items: center; justify-content: space-between; gap: 12px; background: var(--bg-dark); border: 1px solid var(--surface-2); border-radius: var(--radius-sm); padding: 10px"
              >
                <div style="min-width: 0">
                  <p style="font-weight: 600; color: var(--text-main)">{{ item.pregunta || item.nombre || 'Item' }}</p>
                  <p v-if="item.es_critico" style="font-size: 0.75rem; color: var(--danger)">Item critico</p>
                </div>
                <select v-model="createForm.respuestas[item.id]" class="input" style="max-width: 140px">
                  <option value="aprobado">OK</option>
                  <option value="falla">Falla</option>
                </select>
              </div>
            </div>
          </div>

          <div class="input-group full-width">
            <label>Observaciones Generales</label>
            <textarea
              v-model.trim="createForm.observaciones_generales"
              class="input"
              rows="3"
              placeholder="Describa anomalias o notas..."
            ></textarea>
          </div>
        </form>
      </div>

      <div class="modal-footer">
        <button class="btn btn-secondary" @click="closeCreateModal">Cancelar</button>
        <button class="btn btn-primary" :disabled="saving || !selectedTemplate" @click="submitChecklist">
          <span class="material-icons-round" style="font-size: 18px">save</span>
          {{ saving ? 'GUARDANDO...' : 'CONFIRMAR CHECKLIST' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { formatDateTimeCO } from '../../../shared/utils/formatters';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import {
  checklistId as mapChecklistId,
  checklistOperator as mapChecklistOperator,
  checklistStatusLabel,
  checklistVehicle as mapChecklistVehicle,
} from '../../../shared/adapters/checklistAdapter';
import {
  createChecklist,
  createHorometerRecord,
  fetchChecklistHistory,
  fetchChecklistTemplates,
  fetchEmployeesForChecklist,
  fetchVehiclesForChecklist,
  updateChecklistVehicle,
} from '../api/checklistsService';

const { loading, error, run, clearError } = useAsyncState('');
const route = useRoute();
const history = ref([]);
const vehicles = ref([]);
const employees = ref([]);

const search = ref('');

const showCreate = ref(false);
const templateLoading = ref(false);
const templates = ref([]);
const selectedTemplate = ref(null);
const saving = ref(false);

const createForm = ref(defaultCreateForm());

onMounted(async () => {
  await loadData();
  
  if (route.query.action === 'new' && route.query.vehiculo_id) {
    showCreate.value = true;
    createForm.value.vehiculo_id = route.query.vehiculo_id;
    await onVehicleChange();
  }
});

async function loadData() {
  try {
    await run(async () => {
    const [historyData, vehiclesData, employeeData] = await Promise.all([
      fetchChecklistHistory(),
      fetchVehiclesForChecklist(),
      fetchEmployeesForChecklist(),
    ]);

    history.value = historyData;
    vehicles.value = vehiclesData;
    employees.value = employeeData;
    }, 'Error al cargar checklists');
  } catch {
    // handled by composable
  }
}

const filteredHistory = computed(() => {
  const q = search.value.trim().toLowerCase();
  if (!q) return history.value;

  return history.value.filter((item) => {
    const target = `${checklistVehicle(item)} ${checklistOperator(item)}`.toLowerCase();
    return target.includes(q);
  });
});

const checklistItems = computed(() => selectedTemplate.value?.items || []);

const selectedVehicle = computed(() =>
  vehicles.value.find((vehicle) => String(vehicleId(vehicle)) === String(createForm.value.vehiculo_id)),
);

const isAerialVehicle = computed(() =>
  String(selectedVehicle.value?.tipo || '')
    .toLowerCase()
    .includes('aereo'),
);

function openCreateModal() {
  showCreate.value = true;
}

function closeCreateModal() {
  showCreate.value = false;
  templates.value = [];
  selectedTemplate.value = null;
  createForm.value = defaultCreateForm();
}

async function onVehicleChange() {
  selectedTemplate.value = null;
  templates.value = [];
  createForm.value.lista_chequeo_id = '';
  createForm.value.respuestas = {};

  if (!createForm.value.vehiculo_id) return;

  templateLoading.value = true;
  try {
    const vehicleType = selectedVehicle.value?.tipo || '';
    templates.value = await fetchChecklistTemplates(vehicleType);
    selectedTemplate.value = templates.value[0] || null;
    createForm.value.lista_chequeo_id = selectedTemplate.value?.id || '';
    initializeResponses();
  } catch (e) {
    selectedTemplate.value = null;
    error.value = e?.response?.data?.message || e?.message || 'Error al cargar plantilla';
  } finally {
    templateLoading.value = false;
  }
}

function initializeResponses() {
  const responses = {};
  for (const item of checklistItems.value) {
    responses[item.id] = 'aprobado';
  }
  createForm.value.respuestas = responses;
}

async function submitChecklist() {
  if (saving.value || !selectedTemplate.value) return;
  if (!createForm.value.vehiculo_id || !createForm.value.operador_id || !createForm.value.lista_chequeo_id) return;
  if (!isAerialVehicle.value && !createForm.value.horometro_actual) return;

  saving.value = true;
  clearError();

  try {
    const payload = {
      lista_chequeo_id: Number(createForm.value.lista_chequeo_id),
      vehiculo_id: Number(createForm.value.vehiculo_id),
      operador_id: createForm.value.operador_id ? Number(createForm.value.operador_id) : null,
      observaciones_generales: createForm.value.observaciones_generales || null,
      respuestas: createForm.value.respuestas,
    };

    await createChecklist(payload);
    await updateAuxiliaryRecords();
    closeCreateModal();
    await loadData();
  } catch (e) {
    error.value = e?.response?.data?.message || e?.message || 'Error al crear checklist';
  } finally {
    saving.value = false;
  }
}

async function updateAuxiliaryRecords() {
  const vehicleIdValue = Number(createForm.value.vehiculo_id);
  const operatorIdValue = Number(createForm.value.operador_id);
  const horometer = Number(createForm.value.horometro_actual || 0);
  const hasFailure = Object.values(createForm.value.respuestas).some((value) => value === 'falla');

  const promises = [];

  if (operatorIdValue) {
    promises.push(
      updateChecklistVehicle(vehicleIdValue, { operador_asignado_id: operatorIdValue }).catch(() => null),
    );
  }

  if (!isAerialVehicle.value && horometer > 0) {
    promises.push(
      createHorometerRecord({
        vehiculo_id: vehicleIdValue,
        valor_nuevo: horometer,
        notas: `Checklist Preoperacional: ${hasFailure ? 'Rechazado' : 'Aprobado'}`,
      }).catch(() => null),
    );
  }

  await Promise.all(promises);
}

function defaultCreateForm() {
  return {
    vehiculo_id: '',
    lista_chequeo_id: '',
    operador_id: '',
    horometro_actual: null,
    observaciones_generales: '',
    respuestas: {},
  };
}

function checklistId(item) {
  return mapChecklistId(item);
}

function checklistVehicle(item) {
  return mapChecklistVehicle(item);
}

function checklistOperator(item) {
  return mapChecklistOperator(item);
}

function statusLabel(status) {
  return checklistStatusLabel(status);
}

function statusClass(status) {
  if (status === 'aprobado') return 'badge-success';
  return 'badge-danger';
}

function formatDateTime(value) {
  return formatDateTimeCO(value);
}

function formatHorometer(value) {
  if (value === null || value === undefined || value === '') return '-';
  return `${Number(value).toLocaleString('es-CO')} h`;
}

function vehicleId(vehicle) {
  return vehicle?.vehiculo_id ?? vehicle?.id ?? '';
}

function vehicleLabel(vehicle) {
  return `${vehicle?.placa || 'Sin placa'} - ${vehicle?.tipo || vehicle?.modelo || ''}`.trim();
}
</script>

