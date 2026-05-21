<template>
  <div class="weekly-grid-container">
    <div class="table-scroll">
      <table v-if="semanas.length > 0">
        <thead>
          <tr>
            <th>VEH&Iacute;CULO</th>
            <th>TIPO</th>
            <th>LUN</th>
            <th>MAR</th>
            <th>MIE</th>
            <th>JUE</th>
            <th>VIE</th>
            <th>S&Aacute;B</th>
            <th>DOM</th>
            <th>ESTADO</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="semana in semanas"
            :key="semana.id"
            class="semana-row"
            @click="$emit('row-click', semana)"
          >
            <td class="vehiculo-cell">{{ semana.vehiculo_placa || semana.vehiculo?.placa || 'Sin placa' }}</td>
            <td class="tipo-cell">{{ templateName(semana.template_id) }}</td>
            <td v-for="dia in dias" :key="dia">
              <span class="day-cell" :class="dayStatusClass(semana, dia)" :title="dayTooltip(semana, dia)">
                {{ dayIcon(semana, dia) }}
              </span>
            </td>
            <td>
              <span class="badge" :class="estadoClass(semana.estado)">
                {{ estadoLabel(semana.estado) }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>

      <div v-else class="empty-state">
        <span class="material-icons-round">calendar_month</span>
        <p>No hay semanas registradas</p>
      </div>
    </div>

    <div class="table-footer">
      <span>Mostrando {{ semanas.length }} semana{{ semanas.length === 1 ? '' : 's' }}</span>
      <div class="legend">
        <span class="legend-item"><span class="legend-dot legend-dot--completed"></span> Completado</span>
        <span class="legend-item"><span class="legend-dot legend-dot--warning"></span> Con observaciones</span>
        <span class="legend-item"><span class="legend-dot legend-dot--critical"></span> Falla cr&iacute;tica</span>
        <span class="legend-item"><span class="legend-dot legend-dot--pending"></span> Pendiente</span>
        <span class="legend-item"><span class="legend-dot legend-dot--future"></span> Futuro</span>
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

const dias = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];

function templateName(templateId) {
  const t = props.templates.find((t) => t.id === templateId);
  return t ? (t.codigo || t.nombre || '') : '-';
}

function getDayForm(semana, dia) {
  if (!semana.dailyForms) return null;
  return semana.dailyForms.find((df) => df.dia_semana === dia);
}

function isFutureDay(dia) {
  const dayMap = {
    lunes: 1,
    martes: 2,
    miercoles: 3,
    jueves: 4,
    viernes: 5,
    sabado: 6,
    domingo: 0,
  };
  const today = new Date().getDay();
  const target = dayMap[dia] ?? -1;
  return target > today;
}

function dayStatus(semana, dia) {
  const form = getDayForm(semana, dia);

  if (!form) {
    return isFutureDay(dia) ? 'future' : 'pending';
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

  return 'pending';
}

function dayStatusClass(semana, dia) {
  return `day-cell--${dayStatus(semana, dia)}`;
}

function dayIcon(semana, dia) {
  const status = dayStatus(semana, dia);
  const icons = {
    completed: '✓',
    warning: '⚠',
    critical: '⚠',
    pending: '○',
    future: '—',
    fuera_servicio: '🚫',
  };
  return icons[status] || '○';
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
.weekly-grid-container {
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-lg);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  flex: 1;
}

.table-scroll {
  flex: 1;
  min-height: 0;
  overflow-x: auto;
  overflow-y: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
}

thead th {
  padding: 12px var(--sp-md);
  text-align: left;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--text-gray);
  text-transform: uppercase;
  letter-spacing: 1px;
  background: var(--bg-dark);
  border-bottom: 1px solid var(--surface-2);
  position: sticky;
  top: 0;
  white-space: nowrap;
}

thead th:nth-child(n + 3):nth-child(-n + 9) {
  text-align: center;
  min-width: 60px;
}

tbody tr {
  border-bottom: 1px solid var(--surface-2);
  transition: background var(--transition-fast);
  cursor: pointer;
}

tbody tr:hover {
  background: var(--primary-10);
}

tbody td {
  padding: 12px var(--sp-md);
  font-size: 0.88rem;
  color: var(--text-secondary);
  white-space: nowrap;
}

tbody td:nth-child(n + 3):nth-child(-n + 9) {
  text-align: center;
}

.vehiculo-cell {
  color: var(--primary);
  font-weight: 700;
}

.tipo-cell {
  color: var(--text-muted);
  font-size: 0.8rem;
}

/* Day cell base */
.day-cell {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  font-size: 0.85rem;
  transition: all var(--transition-fast);
}

.day-cell--completed {
  background: var(--success-10);
  color: var(--success);
}

.day-cell--warning {
  background: var(--warning-10);
  color: var(--warning);
}

.day-cell--critical {
  background: var(--danger-10);
  color: var(--danger);
}

.day-cell--pending {
  background: var(--surface-2);
  color: var(--text-muted);
}

.day-cell--future {
  color: var(--text-muted);
  opacity: 0.4;
}

.day-cell--fuera_servicio {
  background: var(--danger-10);
  color: var(--danger);
}

/* Legend */
.legend {
  display: flex;
  gap: var(--sp-md);
  flex-wrap: wrap;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.75rem;
  color: var(--text-gray);
}

.legend-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  display: inline-block;
}

.legend-dot--completed {
  background: var(--success);
}

.legend-dot--warning {
  background: var(--warning);
}

.legend-dot--critical {
  background: var(--danger);
}

.legend-dot--pending {
  background: var(--text-muted);
}

.legend-dot--future {
  background: var(--surface-3);
}
</style>
