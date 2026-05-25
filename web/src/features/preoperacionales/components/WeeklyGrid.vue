<template>
  <div class="weekly-list-container">
    <div v-if="semanas.length > 0" class="list-wrapper">
      <!-- List Header -->
      <div class="list-header">
        <div class="col-vehicle">Veh&iacute;culo</div>
        <div class="col-days">Registro Semanal</div>
        <div class="col-status">Estado</div>
      </div>

      <!-- List Body -->
      <div
        v-for="semana in semanas"
        :key="semana.id"
        class="list-row"
        @click="$emit('row-click', semana)"
      >
        <div class="col-vehicle">
          <span class="plate">{{ semana.vehiculo_placa || semana.vehiculo?.placa || 'Sin placa' }}</span>
          <span class="template-name">{{ templateName(semana.template_id) }}</span>
          <span class="week-date" v-if="semana.semana_inicio">{{ formatWeekLabel(semana.semana_inicio) }}</span>
        </div>

        <div class="col-days">
          <div class="days-tracker">
            <div
              v-for="dia in dias"
              :key="dia.key"
              class="day-indicator"
              :class="dayStatusClass(semana, dia.key)"
              :title="dayTooltip(semana, dia.key)"
            >
              <span class="day-label">{{ dia.label }}</span>
              <span class="day-dot"></span>
            </div>
          </div>
        </div>
        
        <div class="col-status">
          <div v-if="semana.inspector_nombre" class="inspector-info">
            <span class="material-icons-round">engineering</span>
            <span>{{ semana.inspector_nombre }}</span>
          </div>
          <span class="badge" :class="estadoClass(semana.estado)">
            {{ estadoLabel(semana.estado) }}
          </span>
        </div>
      </div>
    </div>

    <div v-else class="empty-state">
      <span class="material-icons-round">calendar_month</span>
      <p>No hay semanas registradas</p>
    </div>

    <div class="table-footer">
      <span>Mostrando {{ semanas.length }} semana{{ semanas.length === 1 ? '' : 's' }}</span>
      <div class="legend">
        <span class="legend-item"><span class="legend-dot legend-dot--completed"></span> Completado</span>
        <span class="legend-item"><span class="legend-dot legend-dot--warning"></span> Observaciones</span>
        <span class="legend-item"><span class="legend-dot legend-dot--critical"></span> Cr&iacute;tico</span>
        <span class="legend-item"><span class="legend-dot legend-dot--pending"></span> Pendiente</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  semanas: { type: Array, required: true },
  templates: { type: Array, default: () => [] },
});

defineEmits(['row-click']);

const dias = [
  { key: 'lunes', label: 'Lun' },
  { key: 'martes', label: 'Mar' },
  { key: 'miercoles', label: 'Mié' },
  { key: 'jueves', label: 'Jue' },
  { key: 'viernes', label: 'Vie' },
  { key: 'sabado', label: 'Sáb' },
  { key: 'domingo', label: 'Dom' },
];

function templateName(templateId) {
  const t = props.templates.find((t) => t.id === templateId);
  return t ? (t.codigo || t.nombre || '') : 'Sin plantilla';
}

function formatWeekLabel(dateStr) {
  if (!dateStr) return 'Semana Desconocida';
  const d = new Date(dateStr);
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay()||7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1));
  const weekNo = Math.ceil((((d - yearStart) / 86400000) + 1)/7);
  return `Semana ${weekNo}`;
}

function getDayForm(semana, dia) {
  if (!semana.daily_forms) return null;
  return semana.daily_forms.find((df) => df.dia_semana === dia);
}

function isFutureDay(semana, dia) {
  const form = getDayForm(semana, dia);
  if (!form) return false;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const formDate = new Date(form.fecha + 'T00:00:00');
  return formDate > today;
}

function dayStatus(semana, dia) {
  const form = getDayForm(semana, dia);

  if (!form) {
    return 'pending';
  }

  if (form.estado === 'fuera_servicio') return 'fuera_servicio';

  if (form.completado) {
    const responses = form.responses || [];
    const hasCritical = responses.some((r) => r.item?.es_critico && r.estado === 'M');
    const hasMalo = responses.some((r) => r.estado === 'M');

    if (hasCritical) return 'critical';
    if (hasMalo) return 'warning';
    return 'completed';
  }

  return isFutureDay(semana, dia) ? 'future' : 'pending';
}

function dayStatusClass(semana, dia) {
  return `status-${dayStatus(semana, dia)}`;
}

function dayTooltip(semana, dia) {
  const status = dayStatus(semana, dia);
  const tooltips = {
    completed: 'Completado - Todo bien',
    warning: 'Completado con observaciones',
    critical: 'Falla crítica detectada',
    pending: 'Pendiente',
    future: 'Día futuro',
    fuera_servicio: 'Fuera de servicio',
  };
  return tooltips[status] || '';
}

function estadoClass(estado) {
  const map = {
    pendiente: 'badge-neutral',
    en_progreso: 'badge-info',
    completado: 'badge-success',
    fuera_servicio: 'badge-danger',
    vencida: 'badge-warning',
  };
  return map[estado] || 'badge-neutral';
}

function estadoLabel(estado) {
  const map = {
    pendiente: 'Pendiente',
    en_progreso: 'En Progreso',
    completado: 'Completado',
    fuera_servicio: 'Fuera Servicio',
    vencida: 'Vencida',
  };
  return map[estado] || estado || '-';
}
</script>

<style scoped>
.weekly-list-container {
  display: flex;
  flex-direction: column;
  flex: 1;
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-lg);
  overflow: hidden;
}

.list-wrapper {
  display: flex;
  flex-direction: column;
}

.list-header {
  display: flex;
  padding: 12px 24px;
  background: var(--bg-dark);
  border-bottom: 1px solid var(--surface-2);
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.list-row {
  display: flex;
  align-items: center;
  padding: 14px 24px;
  border-bottom: 1px solid var(--surface-2);
  cursor: pointer;
  transition: background 0.15s ease;
}

.list-row:last-child {
  border-bottom: none;
}

.list-row:hover {
  background: var(--surface-1);
}

.col-vehicle {
  flex: 0 0 250px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.plate {
  font-size: 1.1rem;
  font-weight: 800;
  color: var(--text-primary);
  letter-spacing: -0.2px;
}

.template-name {
  font-size: 0.75rem;
  color: var(--text-muted);
  font-weight: 600;
}

.week-date {
  font-size: 0.75rem;
  color: var(--primary);
  font-weight: 600;
}

.col-days {
  flex: 1;
  display: flex;
  justify-content: stretch;
  padding-right: 32px;
}

.days-tracker {
  display: flex;
  flex: 1;
  justify-content: space-between;
  background: var(--bg-dark);
  padding: 10px 32px;
  border-radius: 12px;
  border: 1px solid var(--surface-2);
}

.day-indicator {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.day-label {
  font-size: 0.65rem;
  font-weight: 700;
  color: var(--text-muted);
  line-height: 1;
}

.day-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--surface-2);
  transition: all 0.2s ease;
}

/* Status Colors */
.status-completed .day-dot { background: var(--success); box-shadow: 0 0 6px rgba(34, 197, 94, 0.3); }
.status-warning .day-dot { background: var(--warning); box-shadow: 0 0 6px rgba(245, 158, 11, 0.3); }
.status-critical .day-dot { background: var(--danger); box-shadow: 0 0 6px rgba(239, 68, 68, 0.3); }
.status-future .day-dot { background: transparent; border: 1px solid var(--surface-2); }
.status-fuera_servicio .day-dot { background: var(--danger); border-radius: 2px; }

.col-status {
  flex: 0 0 300px;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 16px;
}

.inspector-info {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 0.8rem;
  color: var(--text-gray);
  font-weight: 500;
}

.inspector-info .material-icons-round {
  font-size: 16px;
  color: var(--text-muted);
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 2rem;
  color: var(--text-muted);
}

.empty-state .material-icons-round {
  font-size: 48px;
  margin-bottom: 1rem;
  opacity: 0.5;
}

.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 24px;
  font-size: 0.85rem;
  color: var(--text-gray);
  background: var(--bg-dark);
  border-top: 1px solid var(--surface-2);
}

.legend {
  display: flex;
  gap: var(--sp-md);
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--surface-2);
}

.legend-dot--completed { background: var(--success); }
.legend-dot--warning { background: var(--warning); }
.legend-dot--critical { background: var(--danger); }
.legend-dot--pending { background: var(--surface-2); }
.legend-dot--future {
  background: var(--surface-3);
}
</style>
