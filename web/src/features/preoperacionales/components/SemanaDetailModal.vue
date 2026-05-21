<template>
  <Teleport to="body">
    <div v-if="modelValue" class="modal-overlay" @click.self="close">
      <div class="modal modal-wide semana-detail-modal">
        <!-- Header -->
        <div class="modal-header">
          <div class="modal-title-group">
            <h3>{{ semana.vehiculoPlaca || 'Veh&iacute;culo' }}</h3>
            <span class="week-range">{{ weekRange }}</span>
            <span class="badge" :class="estadoClass(semana.estado)">{{ estadoLabel(semana.estado) }}</span>
          </div>
          <button class="modal-close" @click="close">
            <span class="material-icons-round" style="font-size: 18px">close</span>
          </button>
        </div>

        <!-- Tabs -->
        <div class="day-tabs">
          <button
            v-for="dia in dias"
            :key="dia.key"
            class="day-tab"
            :class="{ 'day-tab--active': activeDia === dia.key }"
            @click="activeDia = dia.key"
          >
            <span class="day-tab-label">{{ dia.label }}</span>
            <span class="day-tab-dot" :class="dayTabDotClass(dia.key)"></span>
          </button>
        </div>

        <!-- Body -->
        <div class="modal-body">
          <div v-if="loading" class="page-loading">
            <span class="spinner"></span>
            Cargando formulario...
          </div>

          <div v-else-if="!activeForm" class="empty-state">
            <span class="material-icons-round">event_note</span>
            <p>No hay formulario para este d&iacute;a</p>
          </div>

          <div v-else class="form-review">
            <!-- Sections -->
            <div
              v-for="section in activeSections"
              :key="section.id"
              class="review-section"
            >
              <button class="section-header" @click="toggleSection(section.id)">
                <span class="material-icons-round" :class="{ 'section-expanded': openSections.has(section.id) }">
                  expand_more
                </span>
                <span class="section-title">{{ section.nombre || section.codigo || 'Secci&oacute;n' }}</span>
                <span class="section-count">{{ sectionItemCount(section) }} &iacute;tems</span>
              </button>

              <div v-show="openSections.has(section.id)" class="section-items">
                <div
                  v-for="item in sectionItems(section)"
                  :key="item.id"
                  class="review-item"
                  :class="{ 'review-item--critical': item.es_critico }"
                >
                  <div class="review-item-content">
                    <p class="review-item-question">{{ item.pregunta || item.nombre || 'Item' }}</p>
                    <p v-if="item.es_critico" class="review-item-critical">
                      <span class="material-icons-round">warning</span>
                      Item cr&iacute;tico
                    </p>
                  </div>
                  <div class="review-item-status">
                    <span
                      class="status-badge"
                      :class="itemStatusClass(item.id)"
                    >
                      {{ itemStatusLabel(item.id) }}
                    </span>
                    <p v-if="itemObservation(item.id)" class="item-observation">
                      {{ itemObservation(item.id) }}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Observaciones generales -->
            <div class="observaciones-generales">
              <label>Observaciones Generales</label>
              <p class="observaciones-text">
                {{ activeForm.observaciones_generales || activeForm.observaciones || 'Sin observaciones' }}
              </p>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="modal-footer">
          <button
            v-if="semana.estado !== 'fuera_servicio'"
            class="btn btn-danger"
            @click="confirmFueraServicio"
          >
            <span class="material-icons-round" style="font-size: 18px">block</span>
            MARCAR FUERA DE SERVICIO
          </button>
          <button class="btn btn-secondary" @click="close">Cerrar</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed, ref, watch } from 'vue';

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  semana: { type: Object, default: () => ({}) },
  template: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['update:modelValue', 'fuera-servicio']);

const dias = [
  { key: 'lunes', label: 'LUN' },
  { key: 'martes', label: 'MAR' },
  { key: 'miercoles', label: 'MIE' },
  { key: 'jueves', label: 'JUE' },
  { key: 'viernes', label: 'VIE' },
  { key: 'sabado', label: 'SAB' },
  { key: 'domingo', label: 'DOM' },
];

const activeDia = ref('lunes');
const openSections = ref(new Set());
const loading = ref(false);

const activeForm = computed(() => {
  if (!props.semana.dailyForms) return null;
  return props.semana.dailyForms.find((df) => df.dia_semana === activeDia.value);
});

const activeSections = computed(() => {
  if (!props.template.sections) return [];
  return props.template.sections;
});

const weekRange = computed(() => {
  if (!props.semana.fecha_inicio) return '';
  const start = new Date(props.semana.fecha_inicio);
  const end = new Date(props.semana.fecha_fin);
  const fmt = (d) => d.toLocaleDateString('es-CO', { day: '2-digit', month: 'short' });
  return `${fmt(start)} - ${fmt(end)}`;
});

function sectionItems(section) {
  if (!section.items) return [];
  return section.items;
}

function sectionItemCount(section) {
  return sectionItems(section).length;
}

function getResponse(itemId) {
  if (!activeForm.value?.responses) return null;
  return activeForm.value.responses.find((r) => r.template_item_id === itemId);
}

function itemStatusClass(itemId) {
  const resp = getResponse(itemId);
  if (!resp) return 'status-pending';
  return resp.valor === 'B' ? 'status-bueno' : 'status-malo';
}

function itemStatusLabel(itemId) {
  const resp = getResponse(itemId);
  if (!resp) return 'Pendiente';
  return resp.valor === 'B' ? 'Bueno' : 'Malo';
}

function itemObservation(itemId) {
  const resp = getResponse(itemId);
  return resp?.observacion || '';
}

function dayTabDotClass(dia) {
  const form = props.semana.dailyForms?.find((df) => df.dia_semana === dia);
  if (!form) return 'dot-pending';
  if (form.estado === 'fuera_servicio') return 'dot-fuera';
  if (form.estado === 'completado') {
    const hasMalo = form.responses?.some((r) => r.valor === 'M');
    const hasCritical = form.responses?.some((r) => r.es_critico && r.valor === 'M');
    if (hasCritical) return 'dot-critical';
    if (hasMalo) return 'dot-warning';
    return 'dot-completed';
  }
  return 'dot-pending';
}

function toggleSection(sectionId) {
  if (openSections.value.has(sectionId)) {
    openSections.value.delete(sectionId);
  } else {
    openSections.value.add(sectionId);
  }
  openSections.value = new Set(openSections.value);
}

function estadoClass(estado) {
  const map = {
    activa: 'badge-info',
    completada: 'badge-success',
    fuera_servicio: 'badge-danger',
    vencida: 'badge-warning',
  };
  return map[estado] || 'badge-neutral';
}

function estadoLabel(estado) {
  const map = {
    activa: 'Activa',
    completada: 'Completada',
    fuera_servicio: 'Fuera Servicio',
    vencida: 'Vencida',
  };
  return map[estado] || estado || '-';
}

function close() {
  emit('update:modelValue', false);
}

function confirmFueraServicio() {
  emit('fuera-servicio', props.semana.id);
}

// Open first section by default when form changes
watch(activeForm, (form) => {
  if (form && activeSections.value.length > 0) {
    openSections.value = new Set([activeSections.value[0].id]);
  }
});
</script>

<style scoped>
.semana-detail-modal {
  display: flex;
  flex-direction: column;
}

.modal-title-group {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
}

.modal-title-group h3 {
  margin: 0;
}

.week-range {
  font-size: 0.8rem;
  color: var(--text-gray);
}

/* Day tabs */
.day-tabs {
  display: flex;
  border-bottom: 1px solid var(--surface-2);
  padding: 0 var(--sp-lg);
  background: var(--bg-dark);
  overflow-x: auto;
}

.day-tab {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: var(--sp-sm) var(--sp-md);
  background: none;
  border: none;
  color: var(--text-gray);
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
  border-bottom: 2px solid transparent;
  transition: all var(--transition-fast);
  min-width: 60px;
}

.day-tab:hover {
  color: var(--text-main);
  background: var(--surface-2);
}

.day-tab--active {
  color: var(--primary);
  border-bottom-color: var(--primary);
}

.day-tab-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.dot-completed { background: var(--success); }
.dot-warning { background: var(--warning); }
.dot-critical { background: var(--danger); }
.dot-pending { background: var(--text-muted); }
.dot-fuera { background: var(--danger); }

/* Form review */
.form-review {
  display: flex;
  flex-direction: column;
  gap: var(--sp-md);
}

.review-section {
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.section-header {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
  width: 100%;
  padding: var(--sp-sm) var(--sp-md);
  background: var(--surface-1, var(--surface-2));
  border: none;
  color: var(--text-main);
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  transition: background var(--transition-fast);
}

.section-header:hover {
  background: var(--surface-3);
}

.section-header .material-icons-round {
  font-size: 20px;
  transition: transform var(--transition-fast);
  color: var(--text-gray);
}

.section-header .section-expanded {
  transform: rotate(180deg);
}

.section-count {
  margin-left: auto;
  font-size: 0.75rem;
  color: var(--text-muted);
  font-weight: 400;
}

.section-items {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: var(--sp-sm) var(--sp-md);
  background: var(--surface);
}

.review-item {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--sp-md);
  padding: 10px 14px;
  background: var(--bg-dark);
  border-radius: var(--radius-sm);
  border-left: 3px solid transparent;
}

.review-item--critical {
  border-left-color: var(--warning);
  background: linear-gradient(90deg, rgba(255, 152, 0, 0.05) 0%, var(--bg-dark) 100%);
}

.review-item-content {
  flex: 1;
  min-width: 0;
}

.review-item-question {
  font-weight: 600;
  color: var(--text-main);
  margin: 0 0 4px 0;
  font-size: 0.88rem;
  line-height: 1.4;
}

.review-item-critical {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 0.72rem;
  color: var(--warning);
  font-weight: 600;
  margin: 0;
}

.review-item-critical .material-icons-round {
  font-size: 14px;
}

.review-item-status {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
  flex-shrink: 0;
}

.status-badge {
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.72rem;
  font-weight: 600;
}

.status-bueno {
  background: var(--success-10);
  color: var(--success);
}

.status-malo {
  background: var(--danger-10);
  color: var(--danger);
}

.status-pending {
  background: var(--surface-2);
  color: var(--text-muted);
}

.item-observation {
  font-size: 0.75rem;
  color: var(--text-gray);
  margin: 0;
  max-width: 200px;
  text-align: right;
  font-style: italic;
}

/* Observaciones generales */
.observaciones-generales {
  margin-top: var(--sp-md);
  padding: var(--sp-md);
  background: var(--bg-dark);
  border-radius: var(--radius-md);
  border: 1px solid var(--surface-2);
}

.observaciones-generales label {
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--text-gray);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  display: block;
  margin-bottom: var(--sp-xs);
}

.observaciones-text {
  font-size: 0.88rem;
  color: var(--text-secondary);
  margin: 0;
  line-height: 1.5;
}
</style>
