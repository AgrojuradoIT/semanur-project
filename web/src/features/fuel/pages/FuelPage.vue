<template>
  <div class="table-container">
    <div class="table-header">
      <h3 class="table-title">REGISTROS DE COMBUSTIBLE</h3>
      <div class="table-actions">
        <div class="table-search">
          <span class="material-icons-round">search</span>
          <input v-model="search" type="text" placeholder="Buscar por placa o estacion..." />
        </div>
        <button v-if="canCreate" class="btn btn-primary btn-sm" @click="openCreateModal">
          <span class="material-icons-round" style="font-size: 18px">local_gas_station</span>
          REGISTRAR TANQUEO
        </button>
      </div>
    </div>

    <!-- Filtros -->
    <div class="filters-row">
      <div class="filter-group">
        <label>Desde</label>
        <input v-model="filterDesde" type="date" class="input input-sm" @change="applyFilters" />
      </div>
      <div class="filter-group">
        <label>Hasta</label>
        <input v-model="filterHasta" type="date" class="input input-sm" @change="applyFilters" />
      </div>
      <div class="filter-group">
        <label>Tipo Comb.</label>
        <select v-model="filterTipoCombustible" class="input input-sm" @change="applyFilters">
          <option value="">Todos</option>
          <option value="gasolina">Gasolina</option>
          <option value="acpm">ACPM</option>
        </select>
      </div>
      <div class="filter-group">
        <label>Tipo Dest.</label>
        <select v-model="filterTipoDestino" class="input input-sm" @change="applyFilters">
          <option value="">Todos</option>
          <option value="vehiculo">Vehículo</option>
          <option value="empleado">Empleado</option>
          <option value="tercero">Tercero</option>
        </select>
      </div>
    </div>

    <!-- Métricas -->
    <div class="metrics-row" v-if="summary">
      <div class="metric-card">
        <span class="material-icons-round metric-icon" style="color: var(--info)">local_gas_station</span>
        <div class="metric-info">
          <span class="metric-value">{{ formatGallons(summary.gasolina_galones) }}</span>
          <span class="metric-label">Gasolina (gal)</span>
        </div>
      </div>
      <div class="metric-card">
        <span class="material-icons-round metric-icon" style="color: var(--warning)">local_gas_station</span>
        <div class="metric-info">
          <span class="metric-value">{{ formatGallons(summary.acpm_galones) }}</span>
          <span class="metric-label">ACPM (gal)</span>
        </div>
      </div>
      <div class="metric-card">
        <span class="material-icons-round metric-icon" style="color: var(--primary)">receipt_long</span>
        <div class="metric-info">
          <span class="metric-value">{{ summary.total_registros }}</span>
          <span class="metric-label">Registros</span>
        </div>
      </div>
    </div>

    <div class="table-scroll">
      <table v-if="!loading && !error && filteredRecords.length > 0">
        <thead>
          <tr>
            <th>FECHA</th>
            <th>TIPO COMB.</th>
            <th>TIPO DEST.</th>
            <th>DESTINO</th>
            <th>GALONES</th>
            <th>HOROMETRO</th>
            <th>KM</th>
            <th>REGISTRO</th>
            <th v-if="isAdmin">ACCIONES</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in filteredRecords" :key="fuelId(item)">
            <td>{{ formatDate(item.fecha || item.created_at) }}</td>
            <td>
              <span class="badge" :class="item.tipo_combustible === 'acpm' ? 'badge-warning' : 'badge-info'">
                {{ (item.tipo_combustible || 'gasolina').toUpperCase() }}
              </span>
            </td>
            <td>
              <span class="badge" :class="destinationTypeClass(item.tipo_destino)">
                {{ destinationTypeLabel(item.tipo_destino) }}
              </span>
            </td>
            <td style="color: var(--text-main); font-weight: 600">
              {{ destinationLabel(item) }}
              <div v-if="item.labor" style="font-size: 0.75rem; color: var(--text-gray); font-weight: normal;">
                Labor: {{ item.labor }}
              </div>
            </td>
            <td style="font-family: 'Oswald', sans-serif">{{ formatGallons(item.cantidad_galones) }}</td>
            <td>{{ item.horometro_actual ?? '-' }}</td>
            <td>{{ item.kilometraje_actual ?? '-' }}</td>
            <td>{{ item.usuario?.name || item.registrado_por?.name || '-' }}</td>
            <td v-if="isAdmin">
              <div style="display: flex; gap: 4px;">
                <button class="btn-icon" title="Editar" @click.stop="openEditModal(item)">
                  <span class="material-icons-round" style="font-size: 16px; color: var(--warning)">edit</span>
                </button>
                <button class="btn-icon" title="Eliminar" @click.stop="confirmDelete(item)">
                  <span class="material-icons-round" style="font-size: 16px; color: var(--danger)">delete</span>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <div v-else-if="loading" class="page-loading">
        <span class="spinner"></span>
        Cargando registros...
      </div>

      <div v-else-if="error" class="empty-state">
        <span class="material-icons-round">cloud_off</span>
        <p>{{ error }}</p>
      </div>

      <div v-else class="empty-state">
        <span class="material-icons-round">local_gas_station</span>
        <p>No se encontraron registros de combustible</p>
      </div>
    </div>

    <div class="table-footer">
      <span>Página {{ currentPage }} de {{ totalPages }} — {{ totalItems }} registro{{ totalItems === 1 ? '' : 's' }}</span>
      <div class="pagination-controls">
        <button class="btn btn-secondary btn-sm" :disabled="currentPage <= 1" @click="goPage(currentPage - 1)">
          <span class="material-icons-round" style="font-size: 16px">chevron_left</span>
        </button>
        <button class="btn btn-secondary btn-sm" :disabled="currentPage >= totalPages" @click="goPage(currentPage + 1)">
          <span class="material-icons-round" style="font-size: 16px">chevron_right</span>
        </button>
      </div>
    </div>
  </div>

  <div v-if="showCreate" class="modal-overlay" @click.self="closeCreateModal">
    <div class="modal modal-wide">
      <div class="modal-header">
        <h3>REGISTRAR COMBUSTIBLE</h3>
        <button class="modal-close" @click="closeCreateModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>

      <div class="modal-body">
        <div v-if="formError" class="alert-danger" style="margin-bottom: 1rem; padding: 0.75rem; border-radius: 4px; background: rgba(239, 68, 68, 0.1); color: var(--danger);">
          {{ formError }}
        </div>
        <form class="form-grid" @submit.prevent="submitCreate">
          <div class="input-group">
            <label>Tipo de Destino</label>
            <select v-model="form.tipo_destino" class="input" required>
              <option value="vehiculo">Vehiculo</option>
              <option value="empleado">Empleado</option>
              <option value="tercero">Tercero</option>
            </select>
          </div>

          <div class="input-group">
            <label>Tipo de Combustible</label>
            <select v-model="form.tipo_combustible" class="input" required>
              <option value="gasolina">Gasolina</option>
              <option value="acpm">ACPM</option>
            </select>
          </div>

          <div v-if="form.tipo_destino === 'vehiculo'" class="input-group">
            <label>Vehiculo</label>
            <select v-model="form.vehiculo_id" class="input" required>
              <option value="">Seleccionar...</option>
              <option v-for="vehicle in vehicles" :key="vehicleId(vehicle)" :value="vehicleId(vehicle)">
                {{ vehicleLabel(vehicle) }}
              </option>
            </select>
          </div>

          <div v-if="form.tipo_destino === 'vehiculo'" class="input-group">
            <label>A quien se le entrega (Empleado)</label>
            <select v-model="form.empleado_id" class="input" required>
              <option value="">Seleccionar...</option>
              <option v-for="user in users" :key="user.id" :value="user.id">{{ employeeLabel(user) }}</option>
            </select>
          </div>

          <div v-else-if="form.tipo_destino === 'empleado'" class="input-group">
            <label>Nombre del Empleado</label>
            <input v-model.trim="form.tercero_nombre" class="input" type="text" required placeholder="Nombre completo" />
          </div>

          <div v-else class="input-group">
            <label>Nombre del Tercero</label>
            <input v-model.trim="form.tercero_nombre" class="input" type="text" required placeholder="Nombre completo" />
          </div>

          <div class="input-group">
            <label>Cantidad (Galones)</label>
            <input v-model.number="form.cantidad_galones" class="input" type="number" min="0.1" step="0.1" required />
          </div>

          <div v-if="form.tipo_destino === 'vehiculo' && isSelectedVehicleMachinery" class="input-group">
            <label>Horometro Actual</label>
            <input v-model.number="form.horometro_actual" class="input" type="number" min="0" />
          </div>

          <div v-if="form.tipo_destino === 'vehiculo' && !isSelectedVehicleMachinery" class="input-group">
            <label>Kilometraje Actual</label>
            <input v-model.number="form.kilometraje_actual" class="input" type="number" min="0" />
          </div>

          <div class="input-group full-width">
            <label>Destino o Labor</label>
            <input v-model.trim="form.labor" class="input" type="text" placeholder="Ej. Guadañar lote 5, viaje a finca..." />
          </div>

          <div class="input-group full-width">
            <label>Notas</label>
            <textarea v-model.trim="form.notas" class="input" rows="3" placeholder="Observaciones del tanqueo..."></textarea>
          </div>
        </form>
      </div>

      <div class="modal-footer">
        <button class="btn btn-secondary" @click="closeCreateModal">Cancelar</button>
        <button class="btn btn-primary" :disabled="saving" @click="submitCreate">
          <span v-if="saving" class="spinner" style="width: 16px; height: 16px; border-width: 2px;"></span>
          <span v-else class="material-icons-round" style="font-size: 18px">save</span>
          {{ saving ? 'REGISTRANDO...' : 'REGISTRAR TANQUEO' }}
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Editar Registro -->
  <div v-if="showEdit" class="modal-overlay" @click.self="closeEditModal">
    <div class="modal modal-wide">
      <div class="modal-header">
        <h3>EDITAR REGISTRO</h3>
        <button class="modal-close" @click="closeEditModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>
      <div class="modal-body">
        <div v-if="formError" class="alert-danger" style="margin-bottom: 1rem; padding: 0.75rem; border-radius: 4px; background: rgba(239, 68, 68, 0.1); color: var(--danger);">
          {{ formError }}
        </div>
        <form class="form-grid" @submit.prevent="submitEdit">
          <div class="input-group">
            <label>Tipo de Combustible</label>
            <select v-model="editForm.tipo_combustible" class="input">
              <option value="gasolina">Gasolina</option>
              <option value="acpm">ACPM</option>
            </select>
          </div>
          <div class="input-group">
            <label>Cantidad (Galones)</label>
            <input v-model.number="editForm.cantidad_galones" class="input" type="number" min="0.1" step="0.1" />
          </div>
          <div class="input-group">
            <label>Horometro Actual</label>
            <input v-model.number="editForm.horometro_actual" class="input" type="number" min="0" />
          </div>
          <div class="input-group">
            <label>Kilometraje Actual</label>
            <input v-model.number="editForm.kilometraje_actual" class="input" type="number" min="0" />
          </div>
          <div class="input-group full-width">
            <label>Notas</label>
            <textarea v-model.trim="editForm.notas" class="input" rows="3"></textarea>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" @click="closeEditModal">Cancelar</button>
        <button class="btn btn-primary" :disabled="saving" @click="submitEdit">
          <span v-if="saving" class="spinner" style="width: 16px; height: 16px; border-width: 2px;"></span>
          <span v-else class="material-icons-round" style="font-size: 18px">save</span>
          {{ saving ? 'GUARDANDO...' : 'ACTUALIZAR' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { formatCurrencyCO, formatDateCO } from '../../../shared/utils/formatters';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import { useRefresh } from '../../../shared/composables/useRefresh';
import { fuelDestinationLabel, fuelId as mapFuelId } from '../../../shared/adapters/fuelAdapter';
import {
  productId as mapProductId,
  productLabelWithStock,
  productName as mapProductName,
  productStock as mapProductStock,
} from '../../../shared/adapters/productAdapter';
import {
  createFuelRecord,
  updateFuelRecord,
  deleteFuelRecord,
  fetchFuelRecords,
  fetchFuelSummary,
  fetchProductsForFuel,
  fetchUsersForFuel,
  fetchVehiclesForFuel,
} from '../api/fuelService';
import { useAuthStore } from '../../../shared/stores/auth';

const auth = useAuthStore();
const userRole = computed(() => auth.user?.role || 'visualizador');
const isAdmin = computed(() => userRole.value === 'admin');
const canCreate = computed(() => ['admin', 'jefe_taller', 'auxiliar_bodega'].includes(userRole.value));

const { loading, error, run, clearError } = useAsyncState('');
const { onRefresh } = useRefresh();
const route = useRoute();
const records = ref([]);
const vehicles = ref([]);
const users = ref([]);
const products = ref([]);

const search = ref('');

const showCreate = ref(false);
const showEdit = ref(false);
const saving = ref(false);
const formError = ref('');
const form = ref(defaultForm());
const editForm = ref({});
const editingId = ref(null);

// Pagination & Filters
const currentPage = ref(1);
const totalPages = ref(1);
const totalItems = ref(0);
const summary = ref(null);
const filterDesde = ref('');
const filterHasta = ref('');
const filterTipoCombustible = ref('');
const filterTipoDestino = ref('');

const isSelectedVehicleMachinery = computed(() => {
  if (form.value.tipo_destino !== 'vehiculo' || !form.value.vehiculo_id) return false;
  const v = vehicles.value.find(v => vehicleId(v) == form.value.vehiculo_id);
  if (!v) return false;
  const t = (v.tipo || '').toLowerCase();
  return t.includes('tractor') || t.includes('maquinaria') || t.includes('pesada') || t.includes('volqueta');
});

onMounted(async () => {
  await loadData();
  
  if (route.query.action === 'new' && route.query.vehiculo_id) {
    showCreate.value = true;
    form.value.tipo_destino = 'vehiculo';
    form.value.vehiculo_id = route.query.vehiculo_id;
  }
});

function buildFilterParams() {
  const params = { page: currentPage.value, per_page: 25 };
  if (filterDesde.value) params.fecha_desde = filterDesde.value;
  if (filterHasta.value) params.fecha_hasta = filterHasta.value;
  if (filterTipoCombustible.value) params.tipo_combustible = filterTipoCombustible.value;
  if (filterTipoDestino.value) params.tipo_destino = filterTipoDestino.value;
  return params;
}

async function applyFilters() {
  currentPage.value = 1;
  await loadData();
}

function goPage(page) {
  if (page < 1 || page > totalPages.value) return;
  currentPage.value = page;
  loadData();
}

async function loadData() {
  try {
    await run(async () => {
    const params = buildFilterParams();
    const [recordsRes, vehiclesData, usersData, productsData, summaryData] = await Promise.all([
      fetchFuelRecords(params),
      fetchVehiclesForFuel(),
      fetchUsersForFuel(),
      fetchProductsForFuel(),
      fetchFuelSummary({ fecha_desde: filterDesde.value || undefined, fecha_hasta: filterHasta.value || undefined }),
    ]);

    records.value = recordsRes.data || [];
    totalPages.value = recordsRes.meta?.last_page || 1;
    totalItems.value = recordsRes.meta?.total || 0;
    currentPage.value = recordsRes.meta?.current_page || 1;
    vehicles.value = vehiclesData;
    users.value = usersData;
    products.value = productsData;
    summary.value = summaryData;
    }, 'Error al cargar combustible');
  } catch {
    // handled by composable
  }
}

onRefresh(() => {
  loadData();
});

const filteredRecords = computed(() => {
  const q = search.value.trim().toLowerCase();
  if (!q) return records.value;

  return records.value.filter((item) => {
    const target = [
      destinationLabel(item),
      item.estacion_servicio || '',
      item.placa_manual || '',
    ]
      .join(' ')
      .toLowerCase();
    return target.includes(q);
  });
});

const fuelProducts = computed(() =>
  products.value.filter((product) => {
    const name = String(productName(product)).toLowerCase();
    const category = String(productCategory(product)).toLowerCase();
    return (
      name.includes('combustible') ||
      name.includes('gasolina') ||
      name.includes('acpm') ||
      name.includes('diesel') ||
      category.includes('combustible')
    );
  }),
);

function openCreateModal() {
  formError.value = '';
  showCreate.value = true;
}

function closeCreateModal() {
  showCreate.value = false;
  form.value = defaultForm();
  formError.value = '';
}

async function submitCreate() {
  if (saving.value) return;
  if (!isCreateValid()) return;

  saving.value = true;
  formError.value = '';

  try {
    const payload = buildCreatePayload();
    await createFuelRecord(payload);
    closeCreateModal();
    await loadData();
  } catch (e) {
    formError.value = e?.response?.data?.message || e?.message || 'Error al registrar combustible';
  } finally {
    saving.value = false;
  }
}

function isCreateValid() {
  if (!form.value.tipo_destino) return false;
  if (!form.value.tipo_combustible) return false;
  if (!form.value.cantidad_galones) return false;
  if (form.value.tipo_destino === 'vehiculo' && (!form.value.vehiculo_id || !form.value.empleado_id)) return false;
  if (form.value.tipo_destino === 'empleado' && !form.value.tercero_nombre) return false;
  if (form.value.tipo_destino === 'tercero' && !form.value.tercero_nombre) return false;
  return true;
}

function buildCreatePayload() {
  const payload = {
    tipo_destino: form.value.tipo_destino,
    tipo_combustible: form.value.tipo_combustible,
    cantidad_galones: Number(form.value.cantidad_galones),
    valor_total: 0,
    notas: form.value.notas || null,
  };

  if (form.value.horometro_actual) payload.horometro_actual = Number(form.value.horometro_actual);
  if (form.value.kilometraje_actual) payload.kilometraje_actual = Number(form.value.kilometraje_actual);
  if (form.value.labor) payload.labor = form.value.labor;

  if (form.value.tipo_destino === 'vehiculo') {
    payload.vehiculo_id = Number(form.value.vehiculo_id);
    payload.empleado_id = Number(form.value.empleado_id);
  }
  if (form.value.tipo_destino === 'empleado') payload.tercero_nombre = form.value.tercero_nombre;
  if (form.value.tipo_destino === 'tercero') payload.tercero_nombre = form.value.tercero_nombre;

  return payload;
}

function defaultForm() {
  return {
    tipo_destino: 'vehiculo',
    tipo_combustible: 'gasolina',
    vehiculo_id: '',
    empleado_id: '',
    tercero_nombre: '',
    cantidad_galones: null,
    horometro_actual: null,
    kilometraje_actual: null,
    labor: '',
    notas: '',
  };
}

function openEditModal(item) {
  editingId.value = fuelId(item);
  formError.value = '';
  editForm.value = {
    tipo_combustible: item.tipo_combustible || 'gasolina',
    cantidad_galones: item.cantidad_galones,
    horometro_actual: item.horometro_actual,
    kilometraje_actual: item.kilometraje_actual,
    notas: item.notas || '',
  };
  showEdit.value = true;
}

function closeEditModal() {
  showEdit.value = false;
  editingId.value = null;
  formError.value = '';
}

async function submitEdit() {
  if (saving.value) return;
  saving.value = true;
  formError.value = '';
  try {
    await updateFuelRecord(editingId.value, editForm.value);
    closeEditModal();
    await loadData();
  } catch (e) {
    formError.value = e?.response?.data?.message || e?.message || 'Error al actualizar';
  } finally {
    saving.value = false;
  }
}

async function confirmDelete(item) {
  const label = destinationLabel(item);
  if (!confirm(`¿Eliminar registro de ${formatGallons(item.cantidad_galones)} para "${label}"?`)) return;
  try {
    saving.value = true;
    await deleteFuelRecord(fuelId(item));
    await loadData();
  } catch (e) {
    error.value = e?.response?.data?.message || e?.message || 'Error al eliminar';
  } finally {
    saving.value = false;
  }
}

function fuelId(item) {
  return mapFuelId(item);
}

function destinationTypeClass(type) {
  if (type === 'vehiculo') return 'badge-info';
  if (type === 'empleado') return 'badge-warning';
  return 'badge-neutral';
}

function destinationTypeLabel(type) {
  if (type === 'vehiculo') return 'Vehiculo';
  if (type === 'empleado') return 'Empleado';
  return 'Tercero';
}

function destinationLabel(item) {
  return fuelDestinationLabel(item);
}

function formatDate(value) {
  return formatDateCO(value);
}

function formatGallons(value) {
  const n = Number(value || 0);
  return `${n.toFixed(1)} gal`;
}

function formatCurrency(value) {
  return formatCurrencyCO(value);
}

function vehicleId(vehicle) {
  return vehicle?.vehiculo_id ?? vehicle?.id ?? '';
}

function vehicleLabel(vehicle) {
  return `${vehicle?.placa || 'Sin placa'} - ${vehicle?.marca || ''} ${vehicle?.modelo || ''}`.trim();
}

function employeeLabel(employee) {
  const fullName = `${employee?.nombres || ''} ${employee?.apellidos || ''}`.trim();
  if (fullName) return fullName;
  return employee?.name || employee?.email || 'Sin nombre';
}

function productId(product) {
  return mapProductId(product);
}

function productName(product) {
  return mapProductName(product);
}

function productCategory(product) {
  return product?.categoria?.categoria_nombre ?? product?.categoria ?? '';
}

function productStock(product) {
  return mapProductStock(product);
}

function productLabel(product) {
  return productLabelWithStock(product);
}
</script>

<style scoped>
/* Filters */
.filters-row {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-sm);
  margin-bottom: var(--sp-md);
}
.filter-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.filter-group label {
  font-size: 0.7rem;
  color: var(--text-gray);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.input-sm {
  padding: 4px 8px;
  font-size: 0.8rem;
  min-width: 120px;
}

/* Pagination */
.pagination-controls {
  display: flex;
  gap: 4px;
}
.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* Metrics */
.metrics-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: var(--sp-md);
  margin-bottom: var(--sp-md);
}
.metric-card {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  padding: var(--sp-md);
}
.metric-icon {
  font-size: 28px;
  opacity: 0.8;
}
.metric-info {
  display: flex;
  flex-direction: column;
}
.metric-value {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--text-main);
  font-family: 'Oswald', sans-serif;
}
.metric-label {
  font-size: 0.7rem;
  color: var(--text-gray);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
</style>
