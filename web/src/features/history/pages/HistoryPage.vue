<template>
  <div>
    <div class="card" style="margin-bottom: 16px">
      <div style="display: flex; flex-wrap: wrap; gap: 10px; align-items: center; justify-content: space-between">
        <div style="display: flex; flex-wrap: wrap; gap: 8px">
          <span class="badge badge-neutral">Total: {{ allEvents.length }}</span>
          <span class="badge badge-info">Filtrados: {{ filteredEvents.length }}</span>
          <span class="badge badge-warning">Usuarios: {{ uniqueUsersCount }}</span>
          <span class="badge badge-success">
            Ult. actividad: {{ lastActivityLabel }}
          </span>
        </div>
        <button class="btn btn-secondary btn-sm" @click="loadData" :disabled="loading">
          <span class="material-icons-round" style="font-size: 18px">refresh</span>
          {{ loading ? 'Actualizando...' : 'Actualizar' }}
        </button>
      </div>
    </div>

    <div class="table-container" style="margin-bottom: 14px">
      <div class="table-header" style="gap: 12px; flex-wrap: wrap">
        <h3 class="table-title">FILTROS DE AUDITORIA</h3>
        <div class="table-actions" style="display: grid; grid-template-columns: repeat(4, minmax(180px, 1fr)); gap: 8px; width: 100%">
          <select class="input" v-model="selectedModule">
            <option value="Todos">Todos los modulos</option>
            <option value="Inventario">Inventario</option>
            <option value="Taller">Taller</option>
            <option value="Flota">Flota</option>
          </select>

          <select class="input" v-model="selectedAction">
            <option value="Todas">Todas las acciones</option>
            <option value="Crear">Crear</option>
            <option value="Actualizar">Actualizar</option>
            <option value="Eliminar">Eliminar</option>
            <option value="Estado">Estado</option>
            <option value="Sesion">Sesion</option>
          </select>

          <select class="input" v-model="selectedRange">
            <option value="7d">Ultimos 7 dias</option>
            <option value="30d">Ultimos 30 dias</option>
            <option value="all">Todo</option>
          </select>

          <SearchableSelect
            :items="['Todos', ...users]"
            v-model="selectedUser"
            placeholder="Todos los usuarios"
            empty-text="No se encontraron usuarios"
          />
        </div>
      </div>

      <div class="table-header" style="padding-top: 0">
        <div class="table-search" style="width: 100%; max-width: 100%">
          <span class="material-icons-round">search</span>
          <input
            v-model="search"
            type="text"
            placeholder="Buscar por usuario, referencia, titulo o descripcion..."
          />
        </div>
      </div>
    </div>

    <div class="table-container">
      <div class="table-scroll">
        <table v-if="!loading && !error && filteredEvents.length > 0">
          <thead>
            <tr>
              <th>FECHA</th>
              <th>MODULO</th>
              <th>ACCION</th>
              <th>USUARIO</th>
              <th>TITULO</th>
              <th>DESCRIPCION</th>
              <th>REFERENCIA</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="event in filteredEvents" :key="event.id">
              <td>{{ formatDate(event.timestamp) }}</td>
              <td><span class="badge badge-neutral">{{ event.module }}</span></td>
              <td><span class="badge" :class="actionBadgeClass(event.action)">{{ event.action }}</span></td>
              <td style="color: var(--text-main)">{{ event.user }}</td>
              <td style="color: var(--text-main); font-weight: 600">{{ event.title }}</td>
              <td style="max-width: 400px; white-space: normal">{{ event.description }}</td>
              <td>{{ event.reference || '—' }}</td>
            </tr>
          </tbody>
        </table>

        <div v-else-if="loading" class="page-loading">
          <span class="spinner"></span>
          Cargando centro de actividad...
        </div>

        <div v-else-if="error" class="empty-state">
          <span class="material-icons-round">cloud_off</span>
          <p>{{ error }}</p>
        </div>

        <div v-else class="empty-state">
          <span class="material-icons-round">history_toggle_off</span>
          <p>No hay eventos para los filtros seleccionados</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import { fetchHistorySources } from '../api/historyService';
import { useRefresh } from '../../../shared/composables/useRefresh';
import SearchableSelect from '../../../shared/components/SearchableSelect.vue';

const { refreshTrigger } = useRefresh();

const { loading, error, run } = useAsyncState('');
const allEvents = ref([]);

const search = ref('');
const selectedModule = ref('Todos');
const selectedAction = ref('Todas');
const selectedRange = ref('30d');
const selectedUser = ref('Todos');

onMounted(async () => {
  await loadData();
});

watch(refreshTrigger, loadData);

async function loadData() {
  try {
    await run(async () => {
      const { movimientos, ordenes, combustible, prestamos } = await fetchHistorySources();

      const events = [
        ...mapMovements(movimientos),
        ...mapWorkOrders(ordenes),
        ...mapFuel(combustible),
        ...mapLoans(prestamos),
      ];

      events.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
      allEvents.value = events;
    }, 'Error cargando historial');
  } catch {
    // handled by composable
  }
}

const users = computed(() => {
  const set = new Set(allEvents.value.map((e) => e.user).filter(Boolean));
  return [...set].sort((a, b) => a.localeCompare(b));
});

const uniqueUsersCount = computed(() => users.value.length);

const lastActivityLabel = computed(() => {
  if (!allEvents.value.length) return '--';
  return formatDate(allEvents.value[0].timestamp);
});

const filteredEvents = computed(() => {
  const q = search.value.trim().toLowerCase();
  const from = rangeStartDate(selectedRange.value);

  return allEvents.value.filter((event) => {
    const matchesModule = selectedModule.value === 'Todos' || event.module === selectedModule.value;
    const matchesAction = selectedAction.value === 'Todas' || event.action === selectedAction.value;
    const matchesUser = selectedUser.value === 'Todos' || event.user === selectedUser.value;

    const eventDate = new Date(event.timestamp);
    const matchesRange = !from || eventDate >= from;

    const matchesSearch =
      !q ||
      event.title.toLowerCase().includes(q) ||
      event.description.toLowerCase().includes(q) ||
      event.user.toLowerCase().includes(q) ||
      (event.reference || '').toLowerCase().includes(q);

    return matchesModule && matchesAction && matchesUser && matchesRange && matchesSearch;
  });
});

function rangeStartDate(range) {
  const now = new Date();
  if (range === '7d') return new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  if (range === '30d') return new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  return null;
}

function formatDate(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '--';
  return date.toLocaleString('es-CO', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function actionBadgeClass(action) {
  if (action === 'Crear') return 'badge-success';
  if (action === 'Actualizar') return 'badge-info';
  if (action === 'Eliminar') return 'badge-danger';
  if (action === 'Estado') return 'badge-warning';
  if (action === 'Sesion') return 'badge-neutral';
  return 'badge-neutral';
}

function mapMovements(items) {
  return items.map((m) => {
    const tipo = (m.transaccion_tipo || m.tipo || '').toLowerCase();
    return {
      id: `mov_${m.transaccion_id || m.id || Math.random().toString(36).slice(2)}`,
      module: 'Inventario',
      action: 'Crear',
      user: m.usuario?.name || m.usuario_nombre || m.usuarioNombre || 'Sistema',
      title: `${(tipo || 'movimiento').toUpperCase()} - ${m.producto?.producto_nombre || m.producto?.nombre || m.producto_nombre || 'Producto'}`,
      description: `${m.transaccion_motivo || m.motivo || 'Sin motivo'} (${m.transaccion_cantidad || m.cantidad || 0} unid)`,
      timestamp: m.created_at || m.fecha || new Date().toISOString(),
      reference: `MOV-${m.transaccion_id || m.id || '-'}`,
    };
  });
}

function mapWorkOrders(items) {
  return items.map((o) => ({
    id: `ot_${o.orden_trabajo_id || o.id}`,
    module: 'Taller',
    action: 'Estado',
    user: o.mecanico?.name || o.mecanico_asignado?.name || 'Sistema',
    title: `OT #${o.orden_trabajo_id || o.id} - ${o.vehiculo?.placa || 'Vehiculo'}`,
    description: `Estado: ${o.estado || 'N/A'} - ${o.descripcion || 'Sin descripcion'}`,
    timestamp: o.fecha_inicio || o.created_at || new Date().toISOString(),
    reference: `OT-${o.orden_trabajo_id || o.id}`,
  }));
}

function mapFuel(items) {
  return items.map((f) => ({
    id: `fuel_${f.registro_id || f.id || Math.random().toString(36).slice(2)}`,
    module: 'Flota',
    action: 'Crear',
    user: f.usuario?.name || f.usuario_nombre || f.usuarioNombre || f.responsable?.name || 'Sistema',
    title: `Combustible - ${f.vehiculo?.placa || f.vehiculo_placa || 'N/A'}`,
    description: `${f.galones || f.cantidad_galones || 0} gal - ${f.estacion_servicio || f.estacionServicio || 'Estacion'}`,
    timestamp: f.fecha || f.created_at || new Date().toISOString(),
    reference: `FUEL-${f.registro_id || f.id || '-'}`,
  }));
}

function mapLoans(items) {
  return items.map((l) => ({
    id: `loan_${l.prestamo_id || l.id || Math.random().toString(36).slice(2)}`,
    module: 'Inventario',
    action: 'Sesion',
    user: l.admin?.name || l.admin_nombre || l.adminNombre || 'Admin',
    title: `Prestamo - ${l.producto?.producto_nombre || l.producto?.nombre || l.producto_nombre || 'Herramienta'}`,
    description: `${l.prestamo_cantidad || l.cantidad || 0} unid a ${l.mecanico?.name || l.mecanico_nombre || l.mecanicoNombre || 'Mecanico'}`,
    timestamp: l.fecha_prestamo || l.created_at || new Date().toISOString(),
    reference: `PREST-${l.prestamo_id || l.id || '-'}`,
  }));
}

</script>
