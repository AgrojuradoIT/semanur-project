<template>
  <div class="table-container">
    <!-- Deprecation Banner -->
    <div class="deprecation-banner">
      <span class="material-icons-round">warning</span>
      <div>
        <strong>Esta funcion sera reemplazada proximaente.</strong>
        Use el nuevo modulo de <router-link to="/preoperacionales">Inspecciones Preoperacionales</router-link> para el sistema semanal.
      </div>
    </div>

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

  <!-- Toast Notification -->
  <Teleport to="body">
    <Transition name="toast-slide">
      <div v-if="toast.show" class="app-toast" :class="'app-toast--' + toast.type" @click="toast.show = false">
        <span class="material-icons-round app-toast-icon">{{ toastIcon }}</span>
        <div class="app-toast-body">
          <p class="app-toast-title">{{ toast.title }}</p>
          <p v-if="toast.message" class="app-toast-msg">{{ toast.message }}</p>
        </div>
        <span class="material-icons-round app-toast-close">close</span>
      </div>
    </Transition>
  </Teleport>

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
            <SearchableSelect
              v-model="createForm.vehiculo_id"
              :items="vehicles"
              :label-fn="vehicleLabel"
              :value-fn="vehicleId"
              placeholder="Seleccionar vehiculo..."
              @select="onVehicleChange"
            />
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
            <SearchableSelect
              v-model="createForm.operador_id"
              :items="employees"
              :label-fn="(e) => `${e.nombres} ${e.apellidos || ''}`.trim()"
              placeholder="Seleccionar operador..."
            />
          </div>

          <div v-if="!isAerialVehicle" class="input-group">
            <label>Horometro / Kilometraje</label>
            <input v-model.number="createForm.horometro_actual" class="input" type="number" min="0" required />
          </div>

          <div class="input-group full-width">
            <label style="margin-bottom: 4px">Items de inspeccion: {{ selectedTemplate.nombre }}</label>
            <div class="checklist-items-container">
              <div
                v-for="item in checklistItems"
                :key="item.id"
                class="checklist-item"
                :class="{ 'checklist-item--critical': item.es_critico }"
              >
                <div class="checklist-item-content">
                  <p class="checklist-item-pregunta">{{ item.pregunta || item.nombre || 'Item' }}</p>
                  <p v-if="item.es_critico" class="checklist-item-critical">
                    <span class="material-icons-round">warning</span>
                    Item crítico
                  </p>
                </div>
                <div class="checklist-toggle">
                  <button
                    type="button"
                    class="toggle-btn toggle-btn--ok"
                    :class="{ 'toggle-btn--active': createForm.respuestas[item.id] === 'aprobado' }"
                    @click="createForm.respuestas[item.id] = 'aprobado'"
                  >
                    <span class="material-icons-round">check_circle</span>
                    <span>OK</span>
                  </button>
                  <button
                    type="button"
                    class="toggle-btn toggle-btn--falla"
                    :class="{ 'toggle-btn--active': createForm.respuestas[item.id] === 'falla' }"
                    @click="createForm.respuestas[item.id] = 'falla'"
                  >
                    <span class="material-icons-round">error</span>
                    <span>Falla</span>
                  </button>
                </div>
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
  updateChecklistVehicle,
} from '../api/checklistsService';
import { useCatalogsStore } from '../../../shared/stores/catalogs';
import SearchableSelect from '../../../shared/components/SearchableSelect.vue';
import { useDynamicIsland } from '../../../shared/composables/useDynamicIsland';

const { loading, error, run, clearError } = useAsyncState('');
const route = useRoute();
const history = ref([]);
const vehicles = ref([]);
const employees = ref([]);
const { notify: islandNotify } = useDynamicIsland();

const search = ref('');

const showCreate = ref(false);
const templateLoading = ref(false);
const templates = ref([]);
const selectedTemplate = ref(null);
const saving = ref(false);

// Toast system
const toast = ref({ show: false, type: 'info', title: '', message: '' });
let toastTimer = null;
const toastIcon = computed(() => {
  const icons = { success: 'check_circle', error: 'error', warning: 'warning', info: 'info' };
  return icons[toast.value.type] || 'info';
});
function showToast(type, title, message = '') {
  if (toastTimer) clearTimeout(toastTimer);
  toast.value = { show: true, type, title, message };
  const duration = type === 'error' ? 60000 : 30000;
  toastTimer = setTimeout(() => { toast.value.show = false; }, duration);
}

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
      const catalogsStore = useCatalogsStore();
      await catalogsStore.fetchEssentialCatalogs();
      
      const [historyData] = await Promise.all([
        fetchChecklistHistory(),
      ]);

      history.value = historyData;
      vehicles.value = catalogsStore.vehiculos;
      employees.value = catalogsStore.empleados.filter(e => {
        const c = (e.cargo || '').toLowerCase();
        return c.includes('operador') || c.includes('conductor');
      });
    }, 'Error al cargar checklists');
  } catch (e) {
    console.error('[Checklist] Error en loadData:', e);
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
  // Validar campos uno por uno con mensajes específicos
  if (saving.value) {
    islandNotify({ type: 'warning', title: 'Operación en curso', message: 'Por favor espere a que termine la operación anterior', duration: 15000 });
    return;
  }

  if (!selectedTemplate.value) {
    islandNotify({ type: 'warning', title: 'Plantilla no cargada', message: 'No hay una plantilla de checklist disponible para este vehículo', duration: 15000 });
    return;
  }

  if (!createForm.value.vehiculo_id) {
    islandNotify({ type: 'warning', title: 'Falta vehículo', message: 'Seleccione el vehículo a inspeccionar', duration: 15000 });
    return;
  }

  if (!createForm.value.operador_id) {
    islandNotify({ type: 'warning', title: 'Falta operador', message: 'Seleccione el operador o conductor del vehículo', duration: 15000 });
    return;
  }

  if (!createForm.value.lista_chequeo_id) {
    islandNotify({ type: 'warning', title: 'Plantilla no seleccionada', message: 'Seleccione la plantilla de checklist a utilizar', duration: 15000 });
    return;
  }

  if (!isAerialVehicle.value && !createForm.value.horometro_actual) {
    islandNotify({ type: 'warning', title: 'Falta horómetro', message: 'Ingrese el horómetro o kilometraje actual del vehículo', duration: 15000 });
    return;
  }

  // Validar que todos los items tengan respuesta
  const itemsSinRespuesta = checklistItems.value.filter(
    (item) => !createForm.value.respuestas[item.id]
  );

  if (itemsSinRespuesta.length > 0) {
    const primerosItems = itemsSinRespuesta.slice(0, 3).map((i) => i.pregunta).join(', ');
    const mensajeCompletar = itemsSinRespuesta.length > 3
      ? `${primerosItems}... y ${itemsSinRespuesta.length - 3} más`
      : primerosItems;
    islandNotify({
      type: 'warning',
      title: `Faltan ${itemsSinRespuesta.length} ítems por responder`,
      message: `Complete: ${mensajeCompletar}`,
      duration: 15000,
    });
    return;
  }

  saving.value = true;
  clearError();

  try {
    const payload = {
      lista_chequeo_id: Number(createForm.value.lista_chequeo_id),
      vehiculo_id: Number(createForm.value.vehiculo_id),
      empleado_id: Number(createForm.value.operador_id),
      checklist_data: createForm.value.respuestas,
      estado: 'aprobado',
      observaciones: createForm.value.observaciones_generales || null,
    };

    await createChecklist(payload);
    await updateAuxiliaryRecords();
    closeCreateModal();
    await loadData();
    islandNotify({ type: 'success', title: 'Checklist guardado', message: 'La inspección se registró correctamente', duration: 15000 });
  } catch (e) {
    const errorMessage = e?.response?.data?.message || e?.message || 'Error al crear checklist';
    islandNotify({ type: 'error', title: 'Error al guardar', message: errorMessage, duration: 60000 });
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

<style scoped>
/* --- App Toast --- */
.app-toast {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 9999;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  background: var(--surface-2);
  border-radius: var(--radius-md);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  border-left: 4px solid var(--primary);
  cursor: pointer;
  max-width: 420px;
  animation: toastSlideIn 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}

.app-toast-icon {
  font-size: 22px;
  color: var(--primary);
  flex-shrink: 0;
}

.app-toast-body {
  flex: 1;
  min-width: 0;
}

.app-toast-title {
  font-weight: 700;
  font-size: 0.95rem;
  color: var(--text-main);
  margin: 0 0 2px 0;
}

.app-toast-msg {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin: 0;
  line-height: 1.3;
}

.app-toast-close {
  font-size: 18px;
  color: var(--text-muted);
  opacity: 0;
  transition: opacity 0.2s;
  flex-shrink: 0;
}

.app-toast:hover .app-toast-close {
  opacity: 1;
}

/* Toast types */
.app-toast--success {
  border-left-color: var(--success);
}

.app-toast--success .app-toast-icon {
  color: var(--success);
}

.app-toast--error {
  border-left-color: var(--danger);
}

.app-toast--error .app-toast-icon {
  color: var(--danger);
}

.app-toast--warning {
  border-left-color: var(--warning);
}

.app-toast--warning .app-toast-icon {
  color: var(--warning);
}

.app-toast--info {
  border-left-color: var(--primary);
}

.app-toast--info .app-toast-icon {
  color: var(--primary);
}

/* Toast transition */
.toast-slide-enter-active {
  animation: toastSlideIn 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}

.toast-slide-leave-active {
  animation: toastSlideOut 0.25s ease forwards;
}

@keyframes toastSlideIn {
  from {
    transform: translateX(calc(100% + 40px));
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes toastSlideOut {
  from {
    transform: translateX(0);
    opacity: 1;
  }
  to {
    transform: translateX(calc(100% + 40px));
    opacity: 0;
  }
}

/* --- Checklist Items Toggle --- */
.checklist-items-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.checklist-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 16px;
  background: var(--surface-1);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  transition: all 0.2s ease;
}

.checklist-item:hover {
  border-color: var(--primary);
  background: var(--surface-2);
}

.checklist-item--critical {
  border-left: 3px solid var(--warning);
  background: linear-gradient(90deg, rgba(255, 193, 7, 0.05) 0%, var(--surface-1) 100%);
}

.checklist-item--critical:hover {
  background: linear-gradient(90deg, rgba(255, 193, 7, 0.1) 0%, var(--surface-2) 100%);
}

.checklist-item-content {
  flex: 1;
  min-width: 0;
}

.checklist-item-pregunta {
  font-weight: 600;
  color: var(--text-main);
  margin: 0 0 4px 0;
  font-size: 0.95rem;
  line-height: 1.4;
}

.checklist-item-critical {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 0.75rem;
  color: var(--warning);
  font-weight: 600;
  margin: 0;
}

.checklist-item-critical .material-icons-round {
  font-size: 14px;
}

.checklist-toggle {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}

.toggle-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  border: 2px solid var(--surface-3);
  border-radius: var(--radius-md);
  background: var(--surface-1);
  color: var(--text-muted);
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 70px;
  justify-content: center;
}

.toggle-btn .material-icons-round {
  font-size: 18px;
}

.toggle-btn:hover {
  border-color: var(--surface-3);
  background: var(--surface-2);
}

.toggle-btn--ok.toggle-btn--active {
  border-color: var(--success);
  background: rgba(76, 175, 80, 0.15);
  color: var(--success);
}

.toggle-btn--ok.toggle-btn--active .material-icons-round {
  animation: checkBounce 0.4s ease;
}

.toggle-btn--falla.toggle-btn--active {
  border-color: var(--danger);
  background: rgba(244, 67, 54, 0.15);
  color: var(--danger);
}

.toggle-btn--falla.toggle-btn--active .material-icons-round {
  animation: errorShake 0.4s ease;
}

@keyframes checkBounce {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.2); }
}

@keyframes errorShake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-4px); }
  75% { transform: translateX(4px); }
}

/* Responsive */
@media (max-width: 768px) {
  .checklist-item {
    flex-direction: column;
    align-items: flex-start;
  }

  .checklist-toggle {
    width: 100%;
    justify-content: stretch;
  }

  .toggle-btn {
    flex: 1;
  }
}

/* Deprecation Banner */
.deprecation-banner {
  display: flex;
  align-items: flex-start;
  gap: var(--sp-sm);
  padding: var(--sp-sm) var(--sp-md);
  margin-bottom: var(--sp-md);
  background: rgba(255, 152, 0, 0.1);
  border: 1px solid rgba(255, 152, 0, 0.3);
  border-left: 4px solid var(--warning);
  border-radius: var(--radius-md);
  color: var(--warning);
  font-size: 0.85rem;
  line-height: 1.5;
}

.deprecation-banner .material-icons-round {
  font-size: 20px;
  flex-shrink: 0;
  margin-top: 2px;
}

.deprecation-banner strong {
  display: block;
  margin-bottom: 2px;
}

.deprecation-banner a {
  color: var(--primary);
  text-decoration: underline;
  font-weight: 600;
}

.deprecation-banner a:hover {
  color: var(--primary-light, var(--primary));
}
</style>

