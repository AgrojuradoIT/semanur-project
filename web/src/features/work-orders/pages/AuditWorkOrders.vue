<template>
  <div class="audit-container">
    <div class="audit-header">
      <div class="header-left">
        <h3 class="page-title">Centro de Control · Auditoría de OTs</h3>
        <p class="page-subtitle">Robinson Casierra · Jefe de Taller</p>
      </div>
      <button class="btn btn-secondary btn-sm" @click="$router.push('/work-orders')">
        <span class="material-icons-round" style="font-size: 18px">arrow_back</span>
        VOLVER A OTs
      </button>
    </div>

    <!-- Main Workspace -->
    <div v-if="!loading && !error" class="audit-workspace">
      <!-- Left side: List of OTs -->
      <aside class="audit-sidebar">
        <div class="sidebar-head">
          <span class="badge badge-warning">{{ filteredOrders.length }} Pendientes</span>
        </div>

        <div v-if="filteredOrders.length > 0" class="sidebar-list">
          <article
            v-for="order in filteredOrders"
            :key="order.orden_trabajo_id"
            class="audit-item-card"
            :class="{ active: selectedOrder?.orden_trabajo_id === order.orden_trabajo_id }"
            @click="selectOrder(order)"
          >
            <div class="card-top">
              <span class="order-id">#{{ order.orden_trabajo_id }}</span>
              <span :class="['badge-priority', order.prioridad.toLowerCase()]">{{ order.prioridad }}</span>
            </div>
            
            <p class="vehicle-plate">{{ order.vehiculo?.placa || '—' }}</p>
            <p class="order-desc-short">{{ truncateText(order.descripcion, 60) }}</p>
            
            <div class="card-bottom">
              <span class="mecanico-name">
                <span class="material-icons-round">engineering</span>
                {{ order.mecanico?.nombre || order.mecanico_asignado?.nombre || 'Sin asignar' }}
              </span>
              <span class="order-date">{{ formatDate(order.fecha_inicio) }}</span>
            </div>
          </article>
        </div>

        <div v-else class="sidebar-empty">
          <span class="material-icons-round">verified</span>
          <p>No hay órdenes de trabajo pendientes de auditoría.</p>
        </div>
      </aside>

      <!-- Right side: Detail Panel -->
      <section class="audit-detail-panel">
        <div v-if="selectedOrder" class="detail-content">
          <!-- Detail Head -->
          <div class="detail-header">
            <div class="detail-title-wrap">
              <span class="detail-id">ORDEN DE TRABAJO #{{ selectedOrder.orden_trabajo_id }}</span>
              <h2>{{ selectedOrder.vehiculo?.placa || 'Sin Placa' }} - {{ selectedOrder.vehiculo?.marca }} {{ selectedOrder.vehiculo?.modelo }}</h2>
            </div>
            <div class="detail-meta">
              <span :class="['badge-priority', selectedOrder.prioridad.toLowerCase()]">{{ selectedOrder.prioridad }} Priority</span>
              <span class="detail-state badge badge-warning">Pendiente Firma</span>
            </div>
          </div>

          <!-- Quick Stats Grid -->
          <div class="quick-stats-grid">
            <div class="q-stat-card">
              <span class="material-icons-round">schedule</span>
              <div>
                <p class="q-val">{{ totalDuration(selectedOrder.sesiones) }}</p>
                <p class="q-label">Tiempo Total</p>
              </div>
            </div>
            <div class="q-stat-card">
              <span class="material-icons-round">engineering</span>
              <div>
                <p class="q-val">{{ selectedOrder.mecanico?.nombre || '—' }}</p>
                <p class="q-label">Mecánico Asignado</p>
              </div>
            </div>
            <div class="q-stat-card">
              <span class="material-icons-round">inventory_2</span>
              <div>
                <p class="q-val">{{ selectedOrder.movimientos_inventario?.length || 0 }}</p>
                <p class="q-label">Repuestos Usados</p>
              </div>
            </div>
          </div>

          <!-- Sections Grid -->
          <div class="detail-grid">
            <!-- Left col: Description & Evidence -->
            <div class="detail-col">
              <div class="panel-section">
                <h3>Descripción del Trabajo</h3>
                <div class="description-box">
                  <p>{{ selectedOrder.descripcion }}</p>
                </div>
              </div>

              <div class="panel-section">
                <h3>Evidencia Fotográfica</h3>
                <div v-if="selectedOrder.foto_evidencia" class="evidence-image-container">
                  <img :src="getEvidenciaUrl(selectedOrder.foto_evidencia)" alt="Evidencia de Taller" class="evidence-img" />
                </div>
                <div v-else class="no-evidence">
                  <span class="material-icons-round">no_photography</span>
                  <p>No se subieron imágenes de evidencia para esta OT</p>
                </div>
              </div>
            </div>

            <!-- Right col: Sessions & Repuestos -->
            <div class="detail-col">
              <div class="panel-section">
                <h3>Sesiones de Trabajo</h3>
                <div v-if="selectedOrder.sesiones?.length" class="sessions-list">
                  <div v-for="s in selectedOrder.sesiones" :key="s.id" class="session-item">
                    <div class="session-left">
                      <span class="material-icons-round">play_arrow</span>
                      <div>
                        <p class="sess-time">{{ formatTime(s.fecha_inicio) }} - {{ formatTime(s.fecha_fin) }}</p>
                        <p class="sess-date">{{ formatDate(s.fecha_inicio) }}</p>
                      </div>
                    </div>
                    <span class="sess-dur">{{ formatDuration(s.fecha_inicio, s.fecha_fin) }}</span>
                  </div>
                </div>
                <div v-else class="no-data-panel">Sin registros de tiempo</div>
              </div>

              <div class="panel-section">
                <h3>Repuestos y Consumibles</h3>
                <table v-if="selectedOrder.movimientos_inventario?.length" class="repuestos-table">
                  <thead>
                    <tr>
                      <th>PRODUCTO</th>
                      <th style="text-align: right">CANT</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="mov in selectedOrder.movimientos_inventario" :key="mov.transaccion_id">
                      <td class="rep-name">
                        <span class="rep-sku">{{ mov.producto?.producto_sku }}</span>
                        {{ mov.producto?.producto_nombre }}
                      </td>
                      <td class="rep-cant">{{ mov.transaccion_cantidad }} {{ mov.producto?.producto_unidad_medida || 'UN' }}</td>
                    </tr>
                  </tbody>
                </table>
                <div v-else class="no-data-panel">No se usaron repuestos en esta orden</div>
              </div>
            </div>
          </div>

          <!-- Bottom Actions -->
          <div class="detail-actions">
            <button class="btn btn-success btn-lg" @click="authorize(selectedOrder)">
              <span class="material-icons-round">verified</span>
              AUTORIZAR Y APROBAR TRABAJO
            </button>
          </div>
        </div>

        <div v-else class="detail-placeholder">
          <span class="material-icons-round animate-float">dashboard_customize</span>
          <h3>Inspección de Órdenes</h3>
          <p>Selecciona una orden de trabajo de la lista lateral para auditar sus firmas, evidencias e inventario.</p>
        </div>
      </section>
    </div>

    <div v-else-if="loading" class="page-loading">
      <span class="spinner"></span>
      Cargando centro de auditoría...
    </div>

    <div v-else class="page-error">
      <span class="material-icons-round">cloud_off</span>
      <p>{{ error }}</p>
      <button class="btn btn-secondary btn-sm" @click="loadData">REINTENTAR</button>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import { fetchWorkOrders, updateWorkOrderStatus } from '../api/workOrdersService';

const { loading, error, run } = useAsyncState('');
const orders = ref([]);
const selectedOrder = ref(null);

onMounted(async () => {
  await loadData();
});

async function loadData() {
  try {
    await run(async () => {
      const data = await fetchWorkOrders();
      orders.value = data;
      // Seleccionar por defecto la primera si hay
      const pending = data.filter(o => o.estado === 'Pendiente Auditoria');
      if (pending.length > 0) {
        selectedOrder.value = pending[0];
      }
    }, 'Error al cargar ordenes');
  } catch {}
}

const filteredOrders = computed(() => {
  // Filtrar OTs que estén en "Pendiente Auditoria" para la aprobación del Jefe
  return orders.value.filter(o => o.estado === 'Pendiente Auditoria');
});

function selectOrder(order) {
  selectedOrder.value = order;
}

async function authorize(order) {
  try {
    await run(async () => {
      await updateWorkOrderStatus(order.orden_trabajo_id, 'Cerrada');
      orders.value = orders.value.filter(o => o.orden_trabajo_id !== order.orden_trabajo_id);
      selectedOrder.value = filteredOrders.value[0] || null;
    }, 'Error al autorizar orden');
  } catch {}
}

function truncateText(text, limit) {
  if (!text) return '';
  return text.length > limit ? text.substring(0, limit) + '...' : text;
}

function formatDate(dateString) {
  if (!dateString) return '—';
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString('es-CO', { day: 'numeric', month: 'short' });
}

function formatTime(dateString) {
  if (!dateString) return '—';
  const date = new Date(dateString);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: false });
}

function formatDuration(start, end) {
  if (!start || !end) return 'En curso';
  const diffMs = new Date(end) - new Date(start);
  const diffHrs = Math.floor(diffMs / 3600000);
  const diffMins = Math.round((diffMs % 3600000) / 60000);
  return `${diffHrs}h ${diffMins}m`;
}

function totalDuration(sesiones) {
  if (!sesiones || sesiones.length === 0) return '0h 0m';
  let totalMs = 0;
  sesiones.forEach(s => {
    if (s.fecha_inicio && s.fecha_fin) {
      totalMs += new Date(s.fecha_fin) - new Date(s.fecha_inicio);
    }
  });
  const diffHrs = Math.floor(totalMs / 3600000);
  const diffMins = Math.round((totalMs % 3600000) / 60000);
  return `${diffHrs}h ${diffMins}m`;
}

function getEvidenciaUrl(path) {
  if (!path) return '';
  if (path.startsWith('http')) return path;
  return `${import.meta.env.VITE_API_URL || 'http://localhost:8000'}/storage/${path}`;
}
</script>

<style scoped>
.audit-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
  height: calc(100vh - 110px);
}

.audit-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
}

.header-left {
  display: flex;
  flex-direction: column;
}

.page-title {
  font-family: 'Oswald', sans-serif;
  font-size: 1.6rem;
  font-weight: 700;
  color: var(--text-main);
  text-transform: uppercase;
}

.page-subtitle {
  font-size: 0.8rem;
  color: var(--primary);
  font-weight: 600;
  letter-spacing: 0.5px;
}

/* Workspace Layout */
.audit-workspace {
  display: grid;
  grid-template-columns: 340px 1fr;
  gap: 20px;
  flex-grow: 1;
  min-height: 0; /* Important for flex-child scroll */
}

/* Sidebar list */
.audit-sidebar {
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  min-height: 0;
  overflow: hidden;
}

.sidebar-head {
  padding: 16px;
  border-bottom: 1px solid var(--surface-2);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.sidebar-list {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  overflow-y: auto;
  flex-grow: 1;
}

.audit-item-card {
  padding: 16px;
  border-radius: 12px;
  background: var(--surface-2);
  border: 1px solid transparent;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  gap: 8px;
  transition: all 0.2s ease;
}

.audit-item-card:hover {
  background: var(--surface-3);
  transform: translateY(-1px);
}

.audit-item-card.active {
  background: var(--primary-10);
  border-color: var(--primary);
}

.card-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.order-id {
  font-family: 'Oswald', sans-serif;
  font-weight: 800;
  color: var(--text-main);
}

.badge-priority {
  font-size: 0.65rem;
  font-weight: 800;
  padding: 2px 8px;
  border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.badge-priority.alta { background: rgba(239, 68, 68, 0.15); color: #f87171; }
.badge-priority.media { background: rgba(245, 158, 11, 0.15); color: #fbbf24; }
.badge-priority.baja { background: rgba(59, 130, 246, 0.15); color: #60a5fa; }

.vehicle-plate {
  font-size: 1.1rem;
  font-weight: 800;
  color: var(--text-main);
}

.order-desc-short {
  font-size: 0.75rem;
  color: var(--text-gray);
  line-height: 1.3;
}

.card-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.7rem;
  color: var(--text-muted);
  margin-top: 4px;
  border-top: 1px dashed var(--surface-3);
  padding-top: 8px;
}

.mecanico-name {
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 600;
  color: var(--text-gray);
}

.mecanico-name .material-icons-round {
  font-size: 12px;
}

.sidebar-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--text-muted);
  gap: 12px;
  padding: 40px;
  text-align: center;
}

.sidebar-empty .material-icons-round {
  font-size: 48px;
  color: var(--success);
  opacity: 0.6;
}

/* Detail Panel */
.audit-detail-panel {
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: 16px;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.detail-content {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.detail-header {
  padding: 24px;
  border-bottom: 1px solid var(--surface-2);
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 20px;
  flex-shrink: 0;
}

.detail-title-wrap {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-id {
  font-family: 'Oswald', sans-serif;
  font-weight: 800;
  color: var(--primary);
  letter-spacing: 1px;
}

.detail-header h2 {
  font-size: 1.4rem;
  font-weight: 800;
  color: var(--text-main);
}

.detail-meta {
  display: flex;
  align-items: center;
  gap: 10px;
}

.quick-stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  padding: 16px 24px;
  background: var(--surface-2);
  border-bottom: 1px solid var(--surface-2);
  flex-shrink: 0;
}

.q-stat-card {
  display: flex;
  align-items: center;
  gap: 12px;
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: 10px;
  padding: 12px;
}

.q-stat-card .material-icons-round {
  font-size: 24px;
  color: var(--primary);
}

.q-val {
  font-size: 0.95rem;
  font-weight: 800;
  color: var(--text-main);
}

.q-label {
  font-size: 0.65rem;
  color: var(--text-muted);
  text-transform: uppercase;
  font-weight: 600;
}

/* Detail Workspace Grid */
.detail-grid {
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 24px;
  padding: 24px;
  overflow-y: auto;
  flex-grow: 1;
}

.detail-col {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.panel-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.panel-section h3 {
  font-size: 0.8rem;
  font-weight: 800;
  text-transform: uppercase;
  color: var(--primary);
  letter-spacing: 0.8px;
}

.description-box {
  background: var(--surface-2);
  border-radius: 10px;
  padding: 16px;
  font-size: 0.85rem;
  line-height: 1.5;
  color: var(--text-main);
  border-left: 3px solid var(--primary);
}

.evidence-image-container {
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid var(--surface-2);
  aspect-ratio: 16 / 10;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #000;
}

.evidence-img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.no-evidence {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px;
  border: 2px dashed var(--surface-3);
  border-radius: 12px;
  color: var(--text-muted);
  gap: 8px;
  background: var(--surface-2);
}

.no-evidence .material-icons-round {
  font-size: 32px;
}

.sessions-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.session-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 14px;
  background: var(--surface-2);
  border-radius: 8px;
}

.session-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.session-left .material-icons-round {
  color: var(--success);
  font-size: 18px;
}

.sess-time {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--text-main);
}

.sess-date {
  font-size: 0.65rem;
  color: var(--text-muted);
}

.sess-dur {
  font-size: 0.75rem;
  font-weight: 800;
  color: var(--text-gray);
}

.no-data-panel {
  padding: 16px;
  background: var(--surface-2);
  border-radius: 8px;
  font-size: 0.75rem;
  color: var(--text-muted);
  text-align: center;
}

.repuestos-table {
  width: 100%;
  border-collapse: collapse;
}

.repuestos-table th {
  font-size: 0.65rem;
  font-weight: 800;
  text-transform: uppercase;
  color: var(--text-muted);
  padding-bottom: 6px;
  border-bottom: 1px solid var(--surface-3);
}

.repuestos-table td {
  padding: 10px 0;
  border-bottom: 1px solid var(--surface-2);
  font-size: 0.8rem;
}

.rep-name {
  color: var(--text-main);
  font-weight: 600;
}

.rep-sku {
  display: block;
  font-size: 0.65rem;
  color: var(--primary);
  font-weight: 700;
}

.rep-cant {
  text-align: right;
  font-weight: 700;
  color: var(--text-gray);
}

/* Detail Placeholder */
.detail-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--text-muted);
  gap: 16px;
  padding: 40px;
  text-align: center;
}

.detail-placeholder h3 {
  font-family: 'Oswald', sans-serif;
  font-size: 1.4rem;
  font-weight: 700;
  color: var(--text-main);
}

.detail-placeholder p {
  max-width: 320px;
  font-size: 0.85rem;
  line-height: 1.4;
}

.detail-placeholder .material-icons-round {
  font-size: 64px;
  color: var(--surface-3);
}

.animate-float {
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

.detail-actions {
  padding: 16px 24px;
  border-top: 1px solid var(--surface-2);
  display: flex;
  justify-content: flex-end;
  flex-shrink: 0;
}
</style>
