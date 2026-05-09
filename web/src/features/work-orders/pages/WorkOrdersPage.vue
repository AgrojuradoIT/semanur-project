<template>
  <div class="table-container">
    <div class="table-header">
      <div style="display: flex; align-items: center; gap: var(--sp-md); flex-wrap: wrap">
        <h3 class="table-title">ORDENES DE TRABAJO</h3>
        <div class="filter-chips">
          <button
            v-for="chip in statusFilters"
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
        <div class="table-search">
          <span class="material-icons-round">search</span>
          <input v-model="search" type="text" placeholder="Buscar por descripcion o vehiculo..." />
        </div>
        <button class="btn btn-primary btn-sm" @click="openCreateModal">
          <span class="material-icons-round" style="font-size: 18px">add_circle</span>
          NUEVA ORDEN
        </button>
      </div>
    </div>

    <div class="table-scroll">
      <table v-if="!loading && !error && filteredOrders.length > 0">
        <thead>
          <tr>
            <th>ID</th>
            <th>VEHICULO</th>
            <th>DESCRIPCION</th>
            <th>ESTADO</th>
            <th>PRIORIDAD</th>
            <th>MECANICO</th>
            <th>INICIO</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="order in filteredOrders" :key="orderId(order)" @click="openDetailModal(order)" style="cursor: pointer;">
            <td style="color: var(--primary); font-weight: 700">#{{ orderId(order) }}</td>
            <td style="color: var(--text-main); font-weight: 600">{{ orderVehicle(order) }}</td>
            <td style="max-width: 300px; white-space: normal; line-height: 1.4">{{ orderDescription(order) }}</td>
            <td>
              <span class="badge" :class="statusBadgeClass(orderStatus(order))">{{ orderStatus(order) }}</span>
            </td>
            <td>
              <span class="badge" :class="priorityBadgeClass(orderPriority(order))">{{ orderPriority(order) }}</span>
            </td>
            <td>{{ orderMechanic(order) }}</td>
            <td>{{ orderStartDate(order) }}</td>
          </tr>
        </tbody>
      </table>

      <div v-else-if="loading" class="page-loading">
        <span class="spinner"></span>
        Cargando ordenes...
      </div>

      <div v-else-if="error" class="empty-state">
        <span class="material-icons-round">cloud_off</span>
        <p>{{ error }}</p>
      </div>

      <div v-else class="empty-state">
        <span class="material-icons-round">build_circle</span>
        <p>No se encontraron ordenes de trabajo</p>
      </div>
    </div>

    <div class="table-footer">
      Mostrando {{ filteredOrders.length }} orden{{ filteredOrders.length === 1 ? '' : 'es' }}
    </div>
  </div>

  <div v-if="showCreate" class="modal-overlay" @click.self="closeCreateModal">
    <div class="modal modal-wide">
      <div class="modal-header">
        <h3>NUEVA ORDEN DE TRABAJO</h3>
        <button class="modal-close" @click="closeCreateModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>
      <div class="modal-body">
        <form class="form-grid" @submit.prevent="submitCreate">
          <div class="input-group">
            <label>Vehiculo</label>
            <select v-model="createForm.vehiculo_id" class="input" required>
              <option value="">Seleccionar...</option>
              <option v-for="vehicle in fleetOptions" :key="vehicleOptionId(vehicle)" :value="vehicleOptionId(vehicle)">
                {{ vehicleOptionLabel(vehicle) }}
              </option>
            </select>
          </div>

          <div class="input-group">
            <label>Mecánico Asignado</label>
            <select v-model="createForm.mecanico_asignado_id" class="input">
              <option value="">(Sin asignar)</option>
              <option v-for="emp in employeeOptions" :key="emp.id" :value="emp.id">
                {{ emp.nombres }} {{ emp.apellidos || '' }}
              </option>
            </select>
          </div>

          <div class="input-group">
            <label>Prioridad</label>
            <select v-model="createForm.prioridad" class="input" required>
              <option value="Alta">Alta</option>
              <option value="Media">Media</option>
              <option value="Baja">Baja</option>
            </select>
          </div>

          <div class="input-group"></div>

          <div class="input-group full-width">
            <label>Descripcion del trabajo</label>
            <textarea v-model="createForm.descripcion" class="input" rows="4" required placeholder="Describe el trabajo a realizar..."></textarea>
          </div>

          <div class="input-group full-width">
            <label>Evidencia (Foto Opcional)</label>
            <input type="file" @change="onFileChange" accept="image/*" class="input" />
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" @click="closeCreateModal">Cancelar</button>
        <button class="btn btn-primary" :disabled="savingCreate" @click="submitCreate">
          <span class="material-icons-round" style="font-size: 18px">save</span>
          {{ savingCreate ? 'CREANDO...' : 'CREAR ORDEN' }}
        </button>
      </div>
    </div>
  </div>

  <!-- Status change moved to detail modal -->

  <!-- Detail Modal -->
  <div v-if="showDetailModal && selectedOrder" class="modal-overlay" @click.self="closeDetailModal">
    <div class="modal modal-wide" style="max-width: 800px;">
      <div class="modal-header">
        <h3>DETALLE ORDEN #{{ orderId(selectedOrder) }}</h3>
        <button class="modal-close" @click="closeDetailModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>
      
      <!-- Action Banner -->
      <div style="background: var(--surface-2); padding: 12px 24px; border-bottom: 1px solid var(--surface-3); display: flex; align-items: center; justify-content: space-between;">
        <div style="display: flex; gap: 8px; align-items: center;">
          <span class="badge" :class="statusBadgeClass(orderStatus(selectedOrder))" style="font-size: 0.85rem; padding: 4px 10px;">{{ orderStatus(selectedOrder).toUpperCase() }}</span>
          <span class="badge" :class="priorityBadgeClass(orderPriority(selectedOrder))" style="font-size: 0.85rem; padding: 4px 10px;">{{ orderPriority(selectedOrder).toUpperCase() }}</span>
        </div>
        
        <div style="display: flex; gap: 8px;" v-if="orderStatus(selectedOrder) !== 'Cerrada'">
          <button 
            v-if="orderStatus(selectedOrder) === 'Abierta'"
            class="btn btn-warning btn-sm"
            @click="submitStatusChange('En Progreso')"
            :disabled="savingStatus || savingSession"
          >
            <span class="material-icons-round" style="font-size: 16px;">play_arrow</span>
            INICIAR TRABAJO
          </button>
          
          <template v-else-if="orderStatus(selectedOrder) === 'En Progreso'">
            <button 
              v-if="activeSession"
              class="btn btn-danger btn-sm"
              @click="handleStopSession"
              :disabled="savingSession || savingStatus"
            >
              <span class="material-icons-round" style="font-size: 16px;">pause</span>
              PAUSAR TRABAJO
            </button>
            <button 
              v-else
              class="btn btn-warning btn-sm"
              @click="handleStartSession"
              :disabled="savingSession || savingStatus"
            >
              <span class="material-icons-round" style="font-size: 16px;">play_arrow</span>
              REANUDAR TRABAJO
            </button>
          </template>
          
          <button 
            class="btn btn-success btn-sm"
            @click="submitStatusChange('Cerrada')"
            :disabled="savingStatus || savingSession"
          >
            <span class="material-icons-round" style="font-size: 16px;">check_circle</span>
            FINALIZAR ORDEN
          </button>
        </div>
      </div>

      <div class="modal-body" style="padding: 24px;">
        
        <h4 style="color: var(--text-main); margin-bottom: 16px; font-size: 1rem; border-bottom: 1px solid var(--surface-2); padding-bottom: 8px;">1. Información General</h4>
        
        <div class="form-grid" style="margin-bottom: 32px;">
          <div class="input-group">
            <label>Vehículo</label>
            <div class="input" style="background: var(--surface-2); color: var(--text-main); font-weight: 600; display: flex; align-items: center; gap: 8px;">
              <span class="material-icons-round" style="font-size: 16px; color: var(--primary);">directions_car</span>
              {{ orderVehicle(selectedOrder) }}
            </div>
          </div>

          <div class="input-group">
            <label>Mecánico Asignado</label>
            <div class="input" style="background: var(--surface-2); color: var(--text-main); font-weight: 600; display: flex; align-items: center; gap: 8px;">
              <span class="material-icons-round" style="font-size: 16px; color: var(--primary);">engineering</span>
              {{ orderMechanic(selectedOrder) }}
            </div>
          </div>
          
          <div class="input-group full-width">
            <label>Descripción del Problema</label>
            <div class="input" style="background: var(--surface-2); height: auto; min-height: 60px; white-space: pre-wrap; color: var(--text-secondary); line-height: 1.5;">
              {{ selectedOrder.descripcion }}
            </div>
          </div>
          
          <div class="input-group">
            <label>Fecha de Inicio</label>
            <div class="input" style="background: var(--surface-2); color: var(--text-main);">
               {{ formatDate(selectedOrder.fecha_inicio) }}
            </div>
          </div>
        </div>

        <h4 style="color: var(--text-main); margin-bottom: 16px; font-size: 1rem; border-bottom: 1px solid var(--surface-2); padding-bottom: 8px; display: flex; align-items: center; gap: 8px;">
          2. Sesiones de Trabajo
        </h4>
        
        <div v-if="!selectedOrder.sesiones?.length" class="empty-state" style="padding: 16px; min-height: auto; margin-bottom: 32px;">
          <p>No hay sesiones de trabajo registradas.</p>
        </div>
        <div v-else style="margin-bottom: 32px; overflow-x: auto;">
          <table style="width: 100%; border-collapse: collapse; text-align: left; font-size: 0.9rem;">
            <thead>
              <tr style="border-bottom: 2px solid var(--surface-2);">
                <th style="padding: 10px 8px; color: var(--text-gray);">Mecánico</th>
                <th style="padding: 10px 8px; color: var(--text-gray);">Inicio</th>
                <th style="padding: 10px 8px; color: var(--text-gray);">Fin</th>
                <th style="padding: 10px 8px; color: var(--text-gray); text-align: right;">Duración</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="sesion in selectedOrder.sesiones" :key="sesion.id" style="border-bottom: 1px solid var(--surface-2);">
                <td style="padding: 10px 8px; color: var(--primary); font-weight: 500;">{{ sesion.empleado?.name || 'Empleado' }}</td>
                <td style="padding: 10px 8px;">{{ formatDate(sesion.fecha_inicio) }}</td>
                <td style="padding: 10px 8px;">{{ sesion.fecha_fin ? formatDate(sesion.fecha_fin) : 'En proceso...' }}</td>
                <td style="padding: 10px 8px; text-align: right; font-family: monospace; font-weight: bold; font-size: 1rem;">{{ formatDuration(sesion.duracion_microsegundos) }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <h4 style="color: var(--text-main); margin-bottom: 16px; font-size: 1rem; border-bottom: 1px solid var(--surface-2); padding-bottom: 8px; display: flex; align-items: center; gap: 8px;">
          3. Repuestos y Materiales
        </h4>
        
        <div v-if="!selectedOrder.movimientos_inventario?.length" class="empty-state" style="padding: 16px; min-height: auto;">
          <p>No hay repuestos descontados en esta orden.</p>
        </div>
        <div v-else style="overflow-x: auto;">
          <table style="width: 100%; border-collapse: collapse; text-align: left; font-size: 0.9rem;">
            <thead>
              <tr style="border-bottom: 2px solid var(--surface-2);">
                <th style="padding: 10px 8px; color: var(--text-gray);">Fecha de cargo</th>
                <th style="padding: 10px 8px; color: var(--text-gray);">Producto</th>
                <th style="padding: 10px 8px; color: var(--text-gray); text-align: right;">Cantidad</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="mov in selectedOrder.movimientos_inventario" :key="mov.transaccion_id" style="border-bottom: 1px solid var(--surface-2);">
                <td style="padding: 10px 8px;">{{ formatDate(mov.created_at) }}</td>
                <td style="padding: 10px 8px; font-weight: 500; color: var(--text-main);">{{ mov.producto?.producto_nombre || 'Repuesto' }}</td>
                <td style="padding: 10px 8px; text-align: right;">
                  <span style="color: var(--danger); font-weight: bold; font-family: monospace; font-size: 1rem;">-{{ Number(mov.transaccion_cantidad) }} {{ mov.producto?.producto_unidad_medida || 'UNID' }}</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import {
  createWorkOrder,
  fetchWorkOrders,
  updateWorkOrderStatus,
  startWorkSession,
  stopWorkSession
} from '../api/workOrdersService';
import { useCatalogsStore } from '../../../shared/stores/catalogs';
import { useRefresh } from '../../../shared/composables/useRefresh';

const { refreshTrigger } = useRefresh();

const { loading, error, run, clearError } = useAsyncState('');
const route = useRoute();
const search = ref('');
const selectedStatus = ref('all');
const orders = ref([]);
const fleetOptions = ref([]);
const employeeOptions = ref([]);

const showCreate = ref(false);
const savingCreate = ref(false);
const createForm = ref({
  vehiculo_id: '',
  mecanico_asignado_id: '',
  prioridad: 'Media',
  descripcion: '',
  foto_evidencia: null,
});

function onFileChange(event) {
  const file = event.target.files[0];
  if (file) {
    createForm.value.foto_evidencia = file;
  }
}

const savingStatus = ref(false);
const savingSession = ref(false);
const selectedOrder = ref(null);

const activeSession = computed(() => {
  if (!selectedOrder.value?.sesiones) return null;
  return selectedOrder.value.sesiones.find(s => !s.fecha_fin);
});

const showDetailModal = ref(false);

const statusFilters = [
  { value: 'all', label: 'Todas' },
  { value: 'Abierta', label: 'Abiertas' },
  { value: 'En Progreso', label: 'En Progreso' },
  { value: 'Cerrada', label: 'Cerradas' },
];

onMounted(async () => {
  await loadData();

  if (route.query.action === 'new' && route.query.vehiculo_id) {
    showCreate.value = true;
    createForm.value.vehiculo_id = route.query.vehiculo_id;
  }
});

watch(refreshTrigger, loadData);

async function loadData() {
  try {
    await run(async () => {
      const catalogsStore = useCatalogsStore();
      await catalogsStore.fetchEssentialCatalogs();

      const [ordersData] = await Promise.all([
        fetchWorkOrders(),
      ]);
      
      orders.value = ordersData;
      fleetOptions.value = catalogsStore.vehiculos;
      employeeOptions.value = catalogsStore.empleados.filter(e => {
        const c = (e.cargo || '').toLowerCase();
        return c.includes('mecanico') || c.includes('mecánico');
      });
    }, 'Error al cargar ordenes');
  } catch {
    // handled by composable
  }
}

const filteredOrders = computed(() => {
  const q = search.value.trim().toLowerCase();
  return orders.value.filter((order) => {
    const statusMatch =
      selectedStatus.value === 'all' || orderStatus(order) === selectedStatus.value;

    const searchMatch =
      !q ||
      orderDescription(order).toLowerCase().includes(q) ||
      orderVehicle(order).toLowerCase().includes(q);

    return statusMatch && searchMatch;
  });
});

function openDetailModal(order) {
  selectedOrder.value = order;
  showDetailModal.value = true;
}

function closeDetailModal() {
  showDetailModal.value = false;
  selectedOrder.value = null;
}

function openCreateModal() {
  showCreate.value = true;
}

function closeCreateModal() {
  showCreate.value = false;
  createForm.value = {
    vehiculo_id: '',
    mecanico_asignado_id: '',
    prioridad: 'Media',
    descripcion: '',
    foto_evidencia: null,
  };
}

async function submitCreate() {
  if (savingCreate.value) return;
  if (!createForm.value.vehiculo_id || !createForm.value.prioridad || !createForm.value.descripcion) {
    return;
  }

  savingCreate.value = true;
  clearError();
  try {
    const payload = new FormData();
    payload.append('vehiculo_id', createForm.value.vehiculo_id);
    if (createForm.value.mecanico_asignado_id) {
      payload.append('mecanico_asignado_id', createForm.value.mecanico_asignado_id);
    }
    payload.append('prioridad', createForm.value.prioridad);
    payload.append('descripcion', createForm.value.descripcion.trim());
    if (createForm.value.foto_evidencia) {
      payload.append('foto_evidencia', createForm.value.foto_evidencia);
    }

    await createWorkOrder(payload);
    closeCreateModal();
    await loadData();
  } catch (e) {
    error.value = e?.response?.data?.message || e?.message || 'Error al crear la orden';
  } finally {
    savingCreate.value = false;
  }
}

async function submitStatusChange(newState) {
  if (savingStatus.value || !selectedOrder.value) return;

  savingStatus.value = true;
  clearError();
  try {
    await updateWorkOrderStatus(orderId(selectedOrder.value), newState);
    
    // Auto-start session if it's new
    if (newState === 'En Progreso' && !activeSession.value) {
      await startWorkSession(orderId(selectedOrder.value));
    }
    
    // Auto-stop session if closing order
    if (newState === 'Cerrada' && activeSession.value) {
      await stopWorkSession(activeSession.value.id, 'Orden Cerrada');
    }

    await loadData();
    // Update local selection to reflect changes quickly without closing modal
    const updatedOrder = orders.value.find(o => orderId(o) === orderId(selectedOrder.value));
    if (updatedOrder) {
      selectedOrder.value = updatedOrder;
    }
  } catch (e) {
    error.value = e?.response?.data?.message || e?.message || 'Error al actualizar estado';
  } finally {
    savingStatus.value = false;
  }
}

async function handleStartSession() {
  if (savingSession.value || !selectedOrder.value) return;
  savingSession.value = true;
  clearError();
  try {
    await startWorkSession(orderId(selectedOrder.value));
    await loadData();
    const updatedOrder = orders.value.find(o => orderId(o) === orderId(selectedOrder.value));
    if (updatedOrder) selectedOrder.value = updatedOrder;
  } catch (e) {
    error.value = e?.response?.data?.message || 'Error al iniciar sesión';
  } finally {
    savingSession.value = false;
  }
}

async function handleStopSession() {
  if (savingSession.value || !activeSession.value) return;
  savingSession.value = true;
  clearError();
  try {
    await stopWorkSession(activeSession.value.id, '');
    await loadData();
    const updatedOrder = orders.value.find(o => orderId(o) === orderId(selectedOrder.value));
    if (updatedOrder) selectedOrder.value = updatedOrder;
  } catch (e) {
    error.value = e?.response?.data?.message || 'Error al pausar sesión';
  } finally {
    savingSession.value = false;
  }
}

function orderId(order) {
  return order?.orden_trabajo_id ?? order?.id ?? 0;
}

function orderVehicle(order) {
  return order?.vehiculo?.placa ?? '—';
}

function orderDescription(order) {
  return order?.descripcion ?? '—';
}

function orderStatus(order) {
  return order?.estado ?? 'Abierta';
}

function orderPriority(order) {
  return order?.prioridad ?? 'Media';
}

function orderMechanic(order) {
  return order?.mecanico?.name ?? order?.mecanico_asignado?.name ?? '—';
}

function orderStartDate(order) {
  const raw = order?.fecha_inicio;
  if (!raw) return '—';
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString('es-CO');
}

function statusBadgeClass(status) {
  if (status === 'Cerrada') return 'badge-success';
  if (status === 'En Progreso') return 'badge-warning';
  return 'badge-neutral';
}

function priorityBadgeClass(priority) {
  if (priority === 'Alta') return 'badge-danger';
  if (priority === 'Media') return 'badge-warning';
  return 'badge-info';
}

function vehicleOptionId(vehicle) {
  return vehicle?.vehiculo_id ?? vehicle?.id ?? 0;
}

function vehicleOptionLabel(vehicle) {
  return `${vehicle?.placa ?? 'Sin placa'} - ${vehicle?.tipo ?? vehicle?.modelo ?? ''}`.trim();
}

function formatDuration(microseconds) {
  if (!microseconds) return '00:00:00';
  const totalSeconds = Math.floor(microseconds / 1000000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

function formatDate(dateString) {
  if (!dateString) return '—';
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return '—';
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  return `${day}/${month}/${year} ${hours}:${minutes}`;
}
</script>
