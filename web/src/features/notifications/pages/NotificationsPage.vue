<template>
  <div>
    <!-- Stats Bar -->
    <div class="card" style="margin-bottom: 16px">
      <div style="display: flex; flex-wrap: wrap; gap: 10px; align-items: center; justify-content: space-between">
        <div style="display: flex; flex-wrap: wrap; gap: 8px">
          <span class="badge badge-neutral">Total: {{ notifStore.notificaciones.length }}</span>
          <span class="badge badge-danger" v-if="notifStore.unreadCount > 0">
            Sin leer: {{ notifStore.unreadCount }}
          </span>
          <span class="badge badge-success" v-else>Todas leidas</span>
          <span class="badge badge-info">Filtradas: {{ filtered.length }}</span>
        </div>
        <div style="display: flex; gap: 8px">
          <button v-if="notifStore.unreadCount > 0" class="btn btn-secondary btn-sm" @click="notifStore.marcarTodasLeidas()">
            <span class="material-icons-round" style="font-size: 18px">done_all</span>
            Marcar todas como leidas
          </button>
          <button class="btn btn-secondary btn-sm" @click="reload" :disabled="notifStore.loading">
            <span class="material-icons-round" style="font-size: 18px">refresh</span>
            {{ notifStore.loading ? 'Cargando...' : 'Actualizar' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Filters -->
    <div class="table-container" style="margin-bottom: 14px">
      <div class="table-header" style="gap: 12px; flex-wrap: wrap">
        <h3 class="table-title">FILTROS</h3>
        <div class="table-actions" style="display: grid; grid-template-columns: repeat(3, minmax(180px, 1fr)); gap: 8px; width: 100%">
          <select class="input" v-model="selectedTipo">
            <option value="Todos">Todos los tipos</option>
            <option v-for="t in uniqueTipos" :key="t" :value="t">{{ labelTipo(t) }}</option>
          </select>

          <select class="input" v-model="selectedPrioridad">
            <option value="Todas">Todas las prioridades</option>
            <option value="alta">Alta</option>
            <option value="media">Media</option>
            <option value="baja">Baja</option>
          </select>

          <select class="input" v-model="selectedEstado">
            <option value="Todos">Todos los estados</option>
            <option value="pendiente">Pendientes</option>
            <option value="leida">Leidas</option>
          </select>
        </div>
      </div>

      <div class="table-header" style="padding-top: 0">
        <div class="table-search" style="width: 100%; max-width: 100%">
          <span class="material-icons-round">search</span>
          <input v-model="search" type="text" placeholder="Buscar por titulo, mensaje, tipo..." />
        </div>
      </div>
    </div>

    <!-- Notification Cards -->
    <div v-if="notifStore.loading && notifStore.notificaciones.length === 0" class="page-loading">
      <span class="spinner"></span>
      Cargando centro de notificaciones...
    </div>

    <div v-else-if="filtered.length === 0" class="empty-state">
      <span class="material-icons-round">notifications_off</span>
      <p>No hay notificaciones para los filtros seleccionados</p>
    </div>

    <div v-else class="notif-grid">
      <div
        v-for="n in filtered"
        :key="n.id"
        class="notif-card"
        :class="{ 'notif-card--unread': !n.fecha_leido }"
        @click="handleClick(n)"
      >
        <div class="notif-card__left">
          <span
            class="material-icons-round notif-card__icon"
            :class="'notif-card__icon--' + (n.prioridad || 'baja')"
          >
            {{ notifStore.iconoPorTipo(n.tipo) }}
          </span>
        </div>
        <div class="notif-card__body">
          <div class="notif-card__header">
            <span class="notif-card__title">{{ n.titulo }}</span>
            <div class="notif-card__tags">
              <span class="badge" :class="prioridadBadge(n.prioridad)">{{ n.prioridad || 'baja' }}</span>
              <span class="badge badge-neutral">{{ labelTipo(n.tipo) }}</span>
            </div>
          </div>
          <p class="notif-card__msg">{{ n.mensaje }}</p>
          <div class="notif-card__footer">
            <span class="notif-card__date">
              <span class="material-icons-round" style="font-size: 14px">schedule</span>
              {{ formatDate(n.created_at) }}
            </span>
            <span v-if="n.fecha_leido" class="notif-card__read">
              <span class="material-icons-round" style="font-size: 14px">visibility</span>
              Leida {{ formatDate(n.fecha_leido) }}
            </span>
            <button
              v-else
              class="notif-card__mark-btn"
              @click.stop="notifStore.marcarLeida(n.id)"
            >
              <span class="material-icons-round" style="font-size: 14px">check</span>
              Marcar como leida
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useNotificacionesStore } from '../../../shared/stores/notificaciones';
import { useRefresh } from '../../../shared/composables/useRefresh';

const notifStore = useNotificacionesStore();
const router = useRouter();
const { refreshTrigger } = useRefresh();

const search = ref('');
const selectedTipo = ref('Todos');
const selectedPrioridad = ref('Todas');
const selectedEstado = ref('Todos');

onMounted(() => {
  notifStore.fetchNotificaciones();
});

watch(refreshTrigger, () => notifStore.fetchNotificaciones());

function reload() {
  notifStore.fetchNotificaciones();
}

const uniqueTipos = computed(() => {
  const set = new Set(notifStore.notificaciones.map((n) => n.tipo).filter(Boolean));
  return [...set].sort();
});

const filtered = computed(() => {
  const q = search.value.trim().toLowerCase();
  return notifStore.notificaciones.filter((n) => {
    if (selectedTipo.value !== 'Todos' && n.tipo !== selectedTipo.value) return false;
    if (selectedPrioridad.value !== 'Todas' && n.prioridad !== selectedPrioridad.value) return false;
    if (selectedEstado.value === 'pendiente' && n.fecha_leido) return false;
    if (selectedEstado.value === 'leida' && !n.fecha_leido) return false;
    if (q) {
      const haystack = `${n.titulo} ${n.mensaje} ${n.tipo}`.toLowerCase();
      if (!haystack.includes(q)) return false;
    }
    return true;
  });
});

function handleClick(n) {
  if (!n.fecha_leido) notifStore.marcarLeida(n.id);
  const ruta = notifStore.rutaPorNotificacion(n.tipo, n.relacionado_id);
  if (ruta) router.push(ruta);
}

function labelTipo(tipo) {
  if (!tipo) return 'General';
  if (tipo.includes('soat')) return 'SOAT';
  if (tipo.includes('tecnomecanica')) return 'Tecnomecánica';
  if (tipo.includes('mantenimiento')) return 'Mantenimiento';
  if (tipo.includes('stock') || tipo.includes('inventory')) return 'Stock Bajo';
  if (tipo.includes('orden')) return 'Orden de Trabajo';
  return tipo.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

function prioridadBadge(p) {
  if (p === 'alta') return 'badge-danger';
  if (p === 'media') return 'badge-warning';
  return 'badge-info';
}

function formatDate(value) {
  if (!value) return '--';
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
</script>

<style scoped>
.notif-grid {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.notif-card {
  display: flex;
  gap: 16px;
  padding: 16px 20px;
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all 0.2s;
}

.notif-card:hover {
  border-color: var(--primary-30, rgba(99, 102, 241, 0.3));
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.15);
}

.notif-card--unread {
  border-left: 3px solid var(--primary);
  background: var(--bg-dark, var(--surface));
}

.notif-card__left {
  flex-shrink: 0;
  display: flex;
  align-items: flex-start;
  padding-top: 2px;
}

.notif-card__icon {
  font-size: 28px;
  padding: 8px;
  border-radius: var(--radius-md);
  background: var(--surface-2);
}

.notif-card__icon--alta  { color: var(--danger); background: var(--danger-10, rgba(239, 68, 68, 0.1)); }
.notif-card__icon--media { color: var(--warning, #f59e0b); background: rgba(245, 158, 11, 0.1); }
.notif-card__icon--baja  { color: var(--primary); background: var(--primary-10, rgba(99, 102, 241, 0.1)); }

.notif-card__body {
  flex: 1;
  min-width: 0;
}

.notif-card__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 6px;
}

.notif-card__title {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--text-main);
}

.notif-card__tags {
  display: flex;
  gap: 6px;
  flex-shrink: 0;
}

.notif-card__msg {
  font-size: 0.82rem;
  color: var(--text-secondary, var(--text-gray));
  margin: 0 0 10px;
  line-height: 1.5;
}

.notif-card__footer {
  display: flex;
  align-items: center;
  gap: 16px;
  font-size: 0.75rem;
  color: var(--text-gray);
}

.notif-card__date,
.notif-card__read {
  display: flex;
  align-items: center;
  gap: 4px;
}

.notif-card__mark-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  background: none;
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-sm, 4px);
  color: var(--primary);
  font-size: 0.75rem;
  font-weight: 500;
  padding: 3px 8px;
  cursor: pointer;
  transition: all 0.15s;
}

.notif-card__mark-btn:hover {
  background: var(--primary-10, rgba(99, 102, 241, 0.1));
  border-color: var(--primary);
}
</style>
