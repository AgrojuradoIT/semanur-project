<template>
  <div class="table-container">
    <div class="table-header">
      <h3 class="table-title">REGISTROS DE COMBUSTIBLE</h3>
      <div class="table-actions">
        <div class="table-search">
          <span class="material-icons-round">search</span>
          <input v-model="search" type="text" placeholder="Buscar por placa, empleado, labor..." />
        </div>
        <button v-if="canCreate" class="btn btn-primary btn-sm" @click="openCreateModal">
          <span class="material-icons-round" style="font-size: 18px">local_gas_station</span>
          REGISTRAR TANQUEO
        </button>
      </div>
    </div>

    <!-- Filtros Mejorados -->
    <div class="filters-section">
      <div class="filters-content">
        <div class="filter-chips">
          <button
            class="chip"
            :class="{ active: selectedPeriod === 'today' }"
            @click="setPeriod('today')"
          >
            Hoy
          </button>
          <button
            class="chip"
            :class="{ active: selectedPeriod === 'week' }"
            @click="setPeriod('week')"
          >
            Esta Semana
          </button>
          <button
            class="chip"
            :class="{ active: selectedPeriod === 'month' }"
            @click="setPeriod('month')"
          >
            Este Mes
          </button>
          <button
            class="chip"
            :class="{ active: selectedPeriod === 'year' }"
            @click="setPeriod('year')"
          >
            Este Año
          </button>
          <button
            class="chip"
            :class="{ active: selectedPeriod === 'all' }"
            @click="setPeriod('all')"
          >
            Todo
          </button>
        </div>

        <!-- Métricas -->
        <div class="metrics-inline" v-if="summary">
          <div class="metric-card metric-card--small">
            <span class="material-icons-round metric-icon" style="color: var(--info)">local_gas_station</span>
            <div class="metric-info">
              <span class="metric-value">{{ formatGallons(summary.gasolina_galones) }}</span>
              <span class="metric-label">Gasolina</span>
            </div>
          </div>
          <div class="metric-card metric-card--small">
            <span class="material-icons-round metric-icon" style="color: var(--warning)">local_gas_station</span>
            <div class="metric-info">
              <span class="metric-value">{{ formatGallons(summary.acpm_galones) }}</span>
              <span class="metric-label">ACPM</span>
            </div>
          </div>
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
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in filteredRecords" :key="fuelId(item)" @click="openViewModal(item)" class="clickable-row" style="cursor: pointer;">
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
              <option value="maquinaria">Maquinaria Pesada</option>
              <option value="equipo_menor">Equipo Menor</option>
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

          <div v-if="['vehiculo', 'maquinaria', 'equipo_menor'].includes(form.tipo_destino)" class="input-group">
            <label>{{ form.tipo_destino === 'vehiculo' ? 'Vehiculo' : form.tipo_destino === 'maquinaria' ? 'Maquinaria Pesada' : 'Equipo Menor' }}</label>
            <SearchableSelect
              v-model="form.vehiculo_id"
              :items="filteredVehiclesList"
              :label-fn="vehicleLabel"
              :value-fn="vehicleId"
              :placeholder="form.tipo_destino === 'vehiculo' ? 'Seleccionar vehiculo...' : form.tipo_destino === 'maquinaria' ? 'Seleccionar maquinaria...' : 'Seleccionar equipo...'"
            />
          </div>

          <div v-if="['vehiculo', 'maquinaria', 'equipo_menor'].includes(form.tipo_destino)" class="input-group">
            <label>{{ form.tipo_destino === 'vehiculo' || form.tipo_destino === 'maquinaria' ? 'A quien se le entrega (Empleado)' : 'Responsable (Empleado o Externo)' }}</label>
            <SearchableSelect
              v-model="form.empleado_id"
              :items="users"
              :label-fn="employeeLabel"
              placeholder="Seleccionar empleado responsable..."
              empty-text="No se encontraron empleados"
              :allow-free-text="form.tipo_destino === 'equipo_menor'"
              @select="onResponsableSelect"
            />
          </div>

          <template v-else-if="form.tipo_destino === 'empleado'">
            <div class="input-group">
              <label>Nombre del Empleado</label>
              <input v-model.trim="form.tercero_nombre" class="input" type="text" required placeholder="Nombre completo" />
            </div>
            <div class="input-group">
              <label>Placa Vehículo (Opcional)</label>
              <input v-model.trim="form.placa_manual" class="input" type="text" placeholder="Ej. ABC-123" />
            </div>
          </template>

          <div v-else class="input-group">
            <label>Nombre del Tercero</label>
            <input v-model.trim="form.tercero_nombre" class="input" type="text" required placeholder="Nombre completo" />
          </div>

          <div class="input-group">
            <label>Cantidad (Galones)</label>
            <input v-model.number="form.cantidad_galones" class="input" type="number" min="0.1" step="0.1" required />
          </div>

          <div v-if="['vehiculo', 'maquinaria', 'equipo_menor'].includes(form.tipo_destino) && isSelectedVehicleMachinery" class="input-group">
            <label>Horometro Actual</label>
            <input v-model.number="form.horometro_actual" class="input" type="number" min="0" />
          </div>

          <div v-if="['vehiculo', 'maquinaria', 'equipo_menor'].includes(form.tipo_destino) && !isSelectedVehicleMachinery" class="input-group">
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
            <label>Tipo de Destino</label>
            <select v-model="editForm.tipo_destino" class="input" required>
              <option value="vehiculo">Vehiculo</option>
              <option value="maquinaria">Maquinaria Pesada</option>
              <option value="equipo_menor">Equipo Menor</option>
              <option value="empleado">Empleado</option>
              <option value="tercero">Tercero</option>
            </select>
          </div>

          <div class="input-group">
            <label>Tipo de Combustible</label>
            <select v-model="editForm.tipo_combustible" class="input" required>
              <option value="gasolina">Gasolina</option>
              <option value="acpm">ACPM</option>
            </select>
          </div>

          <div v-if="['vehiculo', 'maquinaria', 'equipo_menor'].includes(editForm.tipo_destino)" class="input-group">
            <label>{{ editForm.tipo_destino === 'vehiculo' ? 'Vehiculo' : editForm.tipo_destino === 'maquinaria' ? 'Maquinaria Pesada' : 'Equipo Menor' }}</label>
            <SearchableSelect
              v-model="editForm.vehiculo_id"
              :items="filteredEditVehiclesList"
              :label-fn="vehicleLabel"
              :value-fn="vehicleId"
              :placeholder="editForm.tipo_destino === 'vehiculo' ? 'Seleccionar vehiculo...' : editForm.tipo_destino === 'maquinaria' ? 'Seleccionar maquinaria...' : 'Seleccionar equipo...'"
            />
          </div>

          <div v-if="['vehiculo', 'maquinaria', 'equipo_menor'].includes(editForm.tipo_destino)" class="input-group">
            <label>{{ editForm.tipo_destino === 'vehiculo' || editForm.tipo_destino === 'maquinaria' ? 'A quien se le entrega (Empleado)' : 'Responsable (Empleado o Externo)' }}</label>
            <SearchableSelect
              v-model="editForm.empleado_id"
              :items="users"
              :label-fn="employeeLabel"
              placeholder="Seleccionar empleado responsable..."
              empty-text="No se encontraron empleados"
              :allow-free-text="editForm.tipo_destino === 'equipo_menor'"
              @select="onEditResponsableSelect"
            />
          </div>

          <template v-else-if="editForm.tipo_destino === 'empleado'">
            <div class="input-group">
              <label>Nombre del Empleado</label>
              <input v-model.trim="editForm.tercero_nombre" class="input" type="text" required placeholder="Nombre completo" />
            </div>
            <div class="input-group">
              <label>Placa Vehículo (Opcional)</label>
              <input v-model.trim="editForm.placa_manual" class="input" type="text" placeholder="Ej. ABC-123" />
            </div>
          </template>

          <div v-else class="input-group">
            <label>Nombre del Tercero</label>
            <input v-model.trim="editForm.tercero_nombre" class="input" type="text" required placeholder="Nombre completo" />
          </div>

          <div class="input-group">
            <label>Cantidad (Galones)</label>
            <input v-model.number="editForm.cantidad_galones" class="input" type="number" min="0.1" step="0.1" required />
          </div>

          <div v-if="['vehiculo', 'maquinaria', 'equipo_menor'].includes(editForm.tipo_destino) && isEditSelectedVehicleMachinery" class="input-group">
            <label>Horometro Actual</label>
            <input v-model.number="editForm.horometro_actual" class="input" type="number" min="0" />
          </div>

          <div v-if="['vehiculo', 'maquinaria', 'equipo_menor'].includes(editForm.tipo_destino) && !isEditSelectedVehicleMachinery" class="input-group">
            <label>Kilometraje Actual</label>
            <input v-model.number="editForm.kilometraje_actual" class="input" type="number" min="0" />
          </div>

          <div class="input-group full-width">
            <label>Destino o Labor</label>
            <input v-model.trim="editForm.labor" class="input" type="text" placeholder="Ej. Guadañar lote 5, viaje a finca..." />
          </div>

          <div class="input-group full-width">
            <label>Notas</label>
            <textarea v-model.trim="editForm.notas" class="input" rows="3" placeholder="Observaciones del tanqueo..."></textarea>
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

  <div v-if="showView" class="modal-overlay" @click.self="closeViewModal">
    <div class="modal modal-wide fuel-detail-modal">
      
      <!-- HEADER -->
      <div class="modal-header" style="border-bottom: none; padding-bottom: 0;">
        <h3 style="color: var(--text-gray); font-size: 0.8rem; letter-spacing: 0.5px;">DETALLE DE COMBUSTIBLE</h3>
        <button class="modal-close" @click="closeViewModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>

      <div class="modal-body" style="padding-top: 1rem;">
        
        <!-- PROFILE CARD LAYOUT -->
        <div style="display: flex; gap: 20px; margin-bottom: 24px; align-items: flex-start;">
          <!-- IMAGE (Like FleetPage fd-image-container) -->
          <div style="flex-shrink: 0; width: 120px; height: 120px; border-radius: 12px; overflow: hidden; background: var(--surface-light); border: 1px solid var(--border); display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
            <img v-if="viewItem.vehiculo?.imagen_url" :src="viewItem.vehiculo.imagen_url" style="width: 100%; height: 100%; object-fit: cover;" />
            <span v-else class="material-icons-round" style="font-size: 40px; color: var(--text-muted);">local_gas_station</span>
          </div>

          <!-- IDENTITY INFO -->
          <div style="flex: 1;">
            <div style="margin-bottom: 6px;">
              <span class="badge" :class="viewItem.tipo_combustible === 'acpm' ? 'badge-warning' : 'badge-info'">
                {{ (viewItem.tipo_combustible || 'gasolina').toUpperCase() }}
              </span>
            </div>
            <h2 style="margin: 0 0 6px 0; font-size: 1.6rem; color: var(--text-main); font-weight: 700; line-height: 1.2;">
              {{ destinationLabel(viewItem) }}
            </h2>
            <div style="color: var(--text-gray); font-size: 0.9rem; display: flex; align-items: center; gap: 6px;">
               <span class="material-icons-round" style="font-size: 16px;">calendar_today</span> 
               {{ formatDateTime(viewItem.fecha || viewItem.created_at) }}
            </div>
          </div>
        </div>

      <div class="fd-highlights" style="margin-top: 0; padding: 0; margin-bottom: 24px;">
        <div class="fd-highlight-box">
          <span class="material-icons-round" style="color: var(--primary); font-size: 28px;">local_gas_station</span>
          <div class="fd-hb-info">
            <span class="fd-hb-label">Cantidad</span>
            <span class="fd-hb-value" style="font-family: 'Oswald', sans-serif;">{{ formatGallons(viewItem.cantidad_galones) }}</span>
          </div>
        </div>
        <div class="fd-highlight-box" v-if="showHorometro(viewItem)">
          <span class="material-icons-round" style="color: var(--warning); font-size: 28px;">timer</span>
          <div class="fd-hb-info">
            <span class="fd-hb-label">Horómetro</span>
            <span class="fd-hb-value">{{ viewItem.horometro_actual ?? '-' }}</span>
          </div>
        </div>
        <div class="fd-highlight-box" v-if="showKilometraje(viewItem)">
          <span class="material-icons-round" style="color: var(--info); font-size: 28px;">speed</span>
          <div class="fd-hb-info">
            <span class="fd-hb-label">Kilometraje</span>
            <span class="fd-hb-value">{{ viewItem.kilometraje_actual ?? '-' }}</span>
          </div>
        </div>
      </div>

      <div class="detail-grid">
        <div class="detail-item">
          <span class="detail-label"><span class="material-icons-round" style="font-size:14px; vertical-align:middle; margin-right:4px;">category</span>Destino</span>
          <span class="detail-value">{{ destinationTypeLabel(viewItem.tipo_destino) }}</span>
        </div>
        <div class="detail-item">
          <span class="detail-label"><span class="material-icons-round" style="font-size:14px; vertical-align:middle; margin-right:4px;">person</span>Conductor / Responsable</span>
          <span class="detail-value">{{ viewItem.empleado?.name || viewItem.empleado?.nombre || viewItem.tercero_nombre || '-' }}</span>
        </div>
        <div class="detail-item">
          <span class="detail-label"><span class="material-icons-round" style="font-size:14px; vertical-align:middle; margin-right:4px;">badge</span>Registrado por</span>
          <span class="detail-value">{{ viewItem.usuario?.name || viewItem.registrado_por?.name || '-' }}</span>
        </div>
        <div class="detail-item full-width" v-if="viewItem.labor" style="background: var(--surface-light); padding: 12px; border-radius: 8px; margin-top: 8px;">
          <span class="detail-label" style="color: var(--text-main); margin-bottom: 8px;"><span class="material-icons-round" style="font-size:16px; vertical-align:middle; margin-right:6px; color: var(--primary);">work</span>Labor / Destino</span>
          <span class="detail-value" style="font-weight: normal;">{{ viewItem.labor }}</span>
        </div>
        <div class="detail-item full-width" v-if="viewItem.notas" style="background: rgba(255, 193, 7, 0.05); padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 193, 7, 0.2); margin-top: 8px;">
          <span class="detail-label" style="color: var(--warning); margin-bottom: 8px;"><span class="material-icons-round" style="font-size:16px; vertical-align:middle; margin-right:6px;">note</span>Notas</span>
          <span class="detail-value" style="font-weight: normal;">{{ viewItem.notas }}</span>
        </div>
      </div>
      
      </div>

      <div class="modal-footer" style="display: flex; justify-content: space-between; align-items: center;">
        <div style="display: flex; gap: 8px;">
          <button v-if="isAdmin" class="btn btn-secondary" style="color: var(--warning); border-color: var(--warning);" @click="editFromView(viewItem)">
            <span class="material-icons-round" style="font-size: 18px; margin-right: 4px;">edit</span> Editar
          </button>
          <button v-if="isAdmin" class="btn btn-secondary" style="color: var(--danger); border-color: var(--danger);" @click="deleteFromView(viewItem)">
            <span class="material-icons-round" style="font-size: 18px; margin-right: 4px;">delete</span> Eliminar
          </button>
        </div>
        <button class="btn btn-primary" @click="closeViewModal">Cerrar</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { formatCurrencyCO, formatDateCO, formatDateTimeCO } from '../../../shared/utils/formatters';
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
} from '../api/fuelService';
import { useAuthStore } from '../../../shared/stores/auth';
import { useCatalogsStore } from '../../../shared/stores/catalogs';
import SearchableSelect from '../../../shared/components/SearchableSelect.vue';

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

const search = ref('');

// Filtros mejorados
const selectedPeriod = ref('all');
const filterDesde = ref('');
const filterHasta = ref('');

const showCreate = ref(false);
const showEdit = ref(false);
const showView = ref(false);
const saving = ref(false);
const formError = ref('');
const form = ref(defaultForm());
const editForm = ref({});
const viewItem = ref({});
const editingId = ref(null);

// Pagination
const currentPage = ref(1);
const totalPages = ref(1);
const totalItems = ref(0);
const summary = ref(null);

const filteredVehiclesList = computed(() => {
  if (form.value.tipo_destino === 'vehiculo') {
    return vehicles.value.filter(v => v.categoria === 'vehiculo' || !v.categoria);
  }
  if (form.value.tipo_destino === 'maquinaria') {
    return vehicles.value.filter(v => v.categoria === 'maquinaria');
  }
  if (form.value.tipo_destino === 'equipo_menor') {
    return vehicles.value.filter(v => v.categoria === 'equipo_menor');
  }
  return vehicles.value;
});

const isSelectedVehicleMachinery = computed(() => {
  if (!['vehiculo', 'maquinaria', 'equipo_menor'].includes(form.value.tipo_destino) || !form.value.vehiculo_id) return false;
  const v = vehicles.value.find(v => vehicleId(v) == form.value.vehiculo_id);
  if (!v) return false;
  if (v.categoria === 'maquinaria' || v.categoria === 'equipo_menor') return true;
  const t = (v.tipo || '').toLowerCase();
  return t.includes('tractor') || t.includes('maquinaria') || t.includes('pesada') || t.includes('volqueta');
});

const filteredEditVehiclesList = computed(() => {
  if (editForm.value.tipo_destino === 'vehiculo') {
    return vehicles.value.filter(v => v.categoria === 'vehiculo' || !v.categoria);
  }
  if (editForm.value.tipo_destino === 'maquinaria') {
    return vehicles.value.filter(v => v.categoria === 'maquinaria');
  }
  if (editForm.value.tipo_destino === 'equipo_menor') {
    return vehicles.value.filter(v => v.categoria === 'equipo_menor');
  }
  return vehicles.value;
});

const isEditSelectedVehicleMachinery = computed(() => {
  if (!['vehiculo', 'maquinaria', 'equipo_menor'].includes(editForm.value.tipo_destino) || !editForm.value.vehiculo_id) return false;
  const v = vehicles.value.find(v => vehicleId(v) == editForm.value.vehiculo_id);
  if (!v) return false;
  if (v.categoria === 'maquinaria' || v.categoria === 'equipo_menor') return true;
  const t = (v.tipo || '').toLowerCase();
  return t.includes('tractor') || t.includes('maquinaria') || t.includes('pesada') || t.includes('volqueta');
});

function onResponsableSelect(item) {
  if (item.isFreeText) {
    form.value.tercero_nombre = item.text;
    form.value.empleado_id = item.text;
  } else {
    form.value.empleado_id = item.id;
    form.value.tercero_nombre = '';
  }
}

function onEditResponsableSelect(item) {
  if (item.isFreeText) {
    editForm.value.tercero_nombre = item.text;
    editForm.value.empleado_id = item.text;
  } else {
    editForm.value.empleado_id = item.id;
    editForm.value.tercero_nombre = '';
  }
}

watch(
  () => form.value.vehiculo_id,
  (newVal) => {
    if (newVal) {
      const v = vehicles.value.find(v => vehicleId(v) == newVal);
      if (v && v.operador_asignado_id) {
        form.value.empleado_id = v.operador_asignado_id;
      }
    }
  }
);

watch(
  () => editForm.value.vehiculo_id,
  (newVal) => {
    if (newVal) {
      const v = vehicles.value.find(v => vehicleId(v) == newVal);
      if (v && v.operador_asignado_id && !editForm.value.empleado_id) {
        editForm.value.empleado_id = v.operador_asignado_id;
      }
    }
  }
);

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
  return params;
}

function setPeriod(period) {
  selectedPeriod.value = period;
  const today = new Date();

  if (period === 'today') {
    filterDesde.value = formatDateForInput(today);
    filterHasta.value = formatDateForInput(today);
  } else if (period === 'week') {
    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay());
    filterDesde.value = formatDateForInput(startOfWeek);
    filterHasta.value = formatDateForInput(today);
  } else if (period === 'month') {
    filterDesde.value = formatDateForInput(new Date(today.getFullYear(), today.getMonth(), 1));
    filterHasta.value = formatDateForInput(today);
  } else if (period === 'year') {
    filterDesde.value = formatDateForInput(new Date(today.getFullYear(), 0, 1));
    filterHasta.value = formatDateForInput(today);
  } else {
    filterDesde.value = '';
    filterHasta.value = '';
  }

  applyFilters();
}

function formatDateForInput(date) {
  const d = new Date(date);
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${d.getFullYear()}-${month}-${day}`;
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
      const catalogsStore = useCatalogsStore();
      await catalogsStore.fetchEssentialCatalogs();
      
      const params = buildFilterParams();
      const [recordsRes, summaryData] = await Promise.all([
        fetchFuelRecords(params),
        fetchFuelSummary({ fecha_desde: filterDesde.value || undefined, fecha_hasta: filterHasta.value || undefined }),
      ]);

      records.value = recordsRes.data || [];
      totalPages.value = recordsRes.meta?.last_page || 1;
      totalItems.value = recordsRes.meta?.total || 0;
      currentPage.value = recordsRes.meta?.current_page || 1;
      
      vehicles.value = catalogsStore.vehiculos;
      users.value = catalogsStore.empleados;
      summary.value = summaryData;
    }, 'Error al cargar combustible');
  } catch (e) {
    console.error('[Fuel] Error en loadData:', e);
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
  if (form.value.tipo_destino === 'maquinaria' && (!form.value.vehiculo_id || !form.value.empleado_id)) return false;
  if (form.value.tipo_destino === 'equipo_menor' && (!form.value.vehiculo_id || (!form.value.empleado_id && !form.value.tercero_nombre))) return false;
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

  if (['vehiculo', 'maquinaria', 'equipo_menor'].includes(form.value.tipo_destino)) {
    payload.vehiculo_id = Number(form.value.vehiculo_id);
    if (form.value.empleado_id && !isNaN(Number(form.value.empleado_id))) {
      payload.empleado_id = Number(form.value.empleado_id);
    }
    if (form.value.tipo_destino === 'equipo_menor' && form.value.tercero_nombre) {
      payload.tercero_nombre = form.value.tercero_nombre;
    }
  }
  if (form.value.tipo_destino === 'empleado') {
    payload.tercero_nombre = form.value.tercero_nombre;
    if (form.value.placa_manual) payload.placa_manual = form.value.placa_manual;
  }
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
    placa_manual: '',
  };
}

function openEditModal(item) {
  editingId.value = fuelId(item);
  formError.value = '';
  editForm.value = {
    tipo_destino: item.tipo_destino || 'vehiculo',
    vehiculo_id: item.vehiculo_id || '',
    empleado_id: item.empleado_id || '',
    tercero_nombre: item.tercero_nombre || '',
    labor: item.labor || '',
    tipo_combustible: item.tipo_combustible || 'gasolina',
    cantidad_galones: item.cantidad_galones,
    horometro_actual: item.horometro_actual,
    kilometraje_actual: item.kilometraje_actual,
    notas: item.notas || '',
    placa_manual: item.placa_manual || '',
  };
  showEdit.value = true;
}

function closeEditModal() {
  showEdit.value = false;
  editingId.value = null;
  formError.value = '';
}

function openViewModal(item) {
  viewItem.value = item;
  showView.value = true;
}

function closeViewModal() {
  showView.value = false;
  viewItem.value = {};
}

function editFromView(item) {
  closeViewModal();
  openEditModal(item);
}

function deleteFromView(item) {
  closeViewModal();
  confirmDelete(item);
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
  if (type === 'maquinaria') return 'Maquinaria Pesada';
  if (type === 'equipo_menor') return 'Equipo Menor';
  if (type === 'empleado') return 'Empleado';
  return 'Tercero';
}

function destinationLabel(item) {
  return fuelDestinationLabel(item);
}

function formatDate(value) {
  return formatDateCO(value);
}

function formatDateTime(value) {
  return formatDateTimeCO(value);
}

function formatGallons(value) {
  const n = Number(value || 0);
  return `${n.toFixed(1)} gal`;
}

function showHorometro(item) {
  if (!['vehiculo', 'maquinaria', 'equipo_menor'].includes(item.tipo_destino)) return false;
  if (item.vehiculo?.metodo_seguimiento) {
    return item.vehiculo.metodo_seguimiento === 'horometro' || item.vehiculo.metodo_seguimiento === 'ambos';
  }
  return item.horometro_actual != null && Number(item.horometro_actual) > 0;
}

function showKilometraje(item) {
  if (!['vehiculo', 'maquinaria', 'equipo_menor'].includes(item.tipo_destino)) return false;
  if (item.vehiculo?.metodo_seguimiento) {
    return item.vehiculo.metodo_seguimiento === 'kilometraje' || item.vehiculo.metodo_seguimiento === 'ambos';
  }
  return item.kilometraje_actual != null && Number(item.kilometraje_actual) > 0;
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
/* --- Filtros Mejorados --- */
.filters-section {
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  padding: var(--sp-md);
  margin-bottom: var(--sp-md);
}

.filters-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--sp-md);
}

.filter-chips {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.chip {
  padding: 6px 12px;
  background: var(--surface-1);
  border: 1px solid var(--surface-3);
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--text-muted);
  cursor: pointer;
  transition: all 0.2s ease;
}

.chip:hover {
  background: var(--surface-2);
  border-color: var(--primary);
  color: var(--text-main);
}

.chip.active {
  background: var(--primary);
  border-color: var(--primary);
  color: white;
}

/* Métricas en línea */
.metrics-inline {
  display: flex;
  gap: var(--sp-md);
  align-items: center;
}

.metric-card--small {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
  background: var(--surface-1);
  border: 1px solid var(--surface-3);
  border-radius: var(--radius-md);
  padding: 8px 12px;
  min-width: 140px;
}

.metric-card--small .metric-icon {
  font-size: 22px;
  flex-shrink: 0;
}

.metric-card--small .metric-info {
  display: flex;
  flex-direction: column;
  line-height: 1.2;
}

.metric-card--small .metric-value {
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--text-main);
  font-family: 'Oswald', sans-serif;
}

.metric-card--small .metric-label {
  font-size: 0.7rem;
  color: var(--text-gray);
  text-transform: uppercase;
  letter-spacing: 0.5px;
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

tbody tr.clickable-row:hover {
  background-color: var(--surface-light, rgba(255, 255, 255, 0.05));
}

/* Detail Modal */
.detail-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
}
.detail-item {
  display: flex;
  flex-direction: column;
}
.detail-item.full-width {
  grid-column: 1 / -1;
}
.detail-label {
  font-size: 0.75rem;
  color: var(--text-gray);
  text-transform: uppercase;
  margin-bottom: 4px;
}
.detail-value {
  font-size: 0.95rem;
  font-weight: 500;
  color: var(--text-main);
}

/* Premium Fuel Detail Modal */
.fuel-detail-modal {
  padding: 0 !important;
  background: var(--surface);
}
.fuel-detail-modal .modal-header {
  padding: 20px 24px 0 24px;
}
.fuel-detail-modal .modal-body {
  padding: 24px;
}
.fuel-detail-modal .modal-footer {
  padding: 16px 24px;
  background: var(--surface);
  border-top: 1px solid var(--border);
}
.fd-highlights {
  display: flex;
  gap: 12px;
}
.fd-highlight-box {
  flex: 1;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}
.fd-hb-info {
  display: flex;
  flex-direction: column;
}
.fd-hb-label {
  font-size: 0.65rem;
  color: var(--text-gray);
  text-transform: uppercase;
  font-weight: 600;
  letter-spacing: 0.5px;
}
.fd-hb-value {
  font-size: 1.2rem;
  font-weight: 700;
  color: var(--text-main);
}
</style>
