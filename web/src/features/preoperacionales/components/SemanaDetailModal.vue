<template>
  <Teleport to="body">
    <div v-if="modelValue && semana" class="drawer-overlay" @click.self="close">
      <div class="side-drawer" :class="{ 'drawer-open': modelValue }">
        <!-- Header -->
        <div class="drawer-header">
          <div class="drawer-title-group">
            <h3>{{ semana.vehiculo_placa || 'Veh&iacute;culo' }}</h3>
            <span class="week-range">{{ weekRange }}</span>
            <span class="badge" :class="estadoClass(semana.estado)">{{ estadoLabel(semana.estado) }}</span>
          </div>
          <button class="drawer-close" @click="close" title="Cerrar panel">
            <span class="material-icons-round">close</span>
          </button>
        </div>

        <!-- Tabs -->
        <div class="day-tabs-scroll">
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
        </div>

        <!-- Body -->
        <div class="drawer-body">
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
        <div class="drawer-footer">
          <button
            v-if="semana.estado !== 'fuera_servicio'"
            class="btn btn-danger"
            @click="confirmFueraServicio"
          >
            <span class="material-icons-round" style="font-size: 18px">block</span>
            FUERA DE SERVICIO
          </button>
          <div class="spacer"></div>
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
  semana: { type: Object, default: null },
  template: { type: Object, default: null },
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

watch(() => props.modelValue, (isOpen) => {
  if (isOpen && props.semana?.daily_forms) {
    const todayStr = ['domingo', 'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado'][new Date().getDay()];
    // Default to today if it exists, otherwise first completed, otherwise 'lunes'
    const todayForm = props.semana.daily_forms.find(f => f.dia_semana === todayStr);
    const completedForm = props.semana.daily_forms.find(f => f.completado);
    
    if (todayForm?.completado) {
      activeDia.value = todayStr;
    } else if (completedForm) {
      activeDia.value = completedForm.dia_semana;
    } else {
      activeDia.value = todayStr;
    }
  }
});

const activeForm = computed(() => {
  if (!props.semana?.daily_forms) return null;
  return props.semana.daily_forms.find((df) => df.dia_semana === activeDia.value);
});

const activeSections = computed(() => {
  const sections = [];
  if (props.template?.sections && props.template.sections.length > 0) {
    sections.push(...props.template.sections);
  }
  if (props.template?.items && props.template.items.length > 0) {
    sections.push({
      id: 'flat-items',
      nombre: 'Generales',
      items: props.template.items
    });
  }
  return sections;
});

const weekRange = computed(() => {
  if (!props.semana?.semana_inicio) return '';
  const start = new Date(props.semana.semana_inicio + 'T00:00:00');
  const end = props.semana.semana_fin ? new Date(props.semana.semana_fin + 'T00:00:00') : start;
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
  return activeForm.value.responses.find((r) => r.item_id === itemId);
}

function itemStatusClass(itemId) {
  const resp = getResponse(itemId);
  if (!resp) return 'status-pending';
  const good = ['B', 'C', 'N'];
  const bad = ['M', 'NC', 'A'];
  if (good.includes(resp.estado)) return 'status-bueno';
  if (bad.includes(resp.estado)) return 'status-malo';
  return 'status-pending';
}

function itemStatusLabel(itemId) {
  const resp = getResponse(itemId);
  if (!resp) return 'Pendiente';
  const map = {
    B: 'Bueno',
    M: 'Malo',
    C: 'Cumple',
    NC: 'No Cumple',
    N: 'Normal',
    A: 'Anormal'
  };
  return map[resp.estado] || resp.estado;
}

function itemObservation(itemId) {
  const resp = getResponse(itemId);
  return resp?.observacion || '';
}

function dayTabDotClass(dia) {
  const form = props.semana?.daily_forms?.find((df) => df.dia_semana === dia);
  if (props.semana?.estado === 'fuera_servicio') return 'dot-fuera';
  if (!form) return 'dot-pending';
  if (form.completado) {
    const hasMalo = form.responses?.some((r) => r.estado === 'M');
    const hasCritical = form.responses?.some((r) => r.item?.es_critico && r.estado === 'M');
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
}, { immediate: true });
</script>

<style scoped>
.drawer-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(4px);
  z-index: 1000;
  display: flex;
  justify-content: flex-end;
}

.side-drawer {
  width: 100%;
  max-width: 500px;
  background: var(--surface);
  height: 100vh;
  display: flex;
  flex-direction: column;
  box-shadow: -10px 0 30px rgba(0, 0, 0, 0.1);
  transform: translateX(100%);
  transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  animation: slideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes slideIn {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

.drawer-header {
  padding: var(--sp-lg);
  border-bottom: 1px solid var(--surface-2);
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  background: var(--surface);
}

.drawer-title-group {
  display: flex;
  flex-direction: column;
  gap: var(--sp-sm);
}

.drawer-title-group h3 {
  margin: 0;
  font-size: 1.5rem;
  font-weight: 800;
  color: var(--text-primary);
}

.week-range {
  font-size: 0.85rem;
  color: var(--text-muted);
}

.drawer-close {
  background: var(--surface-2);
  border: none;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: var(--text-muted);
  transition: all 0.2s;
}

.drawer-close:hover {
  background: var(--surface-3);
  color: var(--text-primary);
}

.day-tabs-scroll {
  background: var(--surface-1);
  border-bottom: 1px solid var(--surface-2);
  overflow-x: auto;
}

.day-tabs {
  display: flex;
  padding: 0 var(--sp-md);
  min-width: max-content;
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

.drawer-body {
  flex: 1;
  overflow-y: auto;
  padding: var(--sp-lg);
  display: flex;
  flex-direction: column;
  gap: var(--sp-lg);
  background: var(--bg-dark);
}

.drawer-footer {
  padding: var(--sp-md) var(--sp-lg);
  border-top: 1px solid var(--surface-2);
  display: flex;
  gap: var(--sp-sm);
  background: var(--surface);
  align-items: center;
}

.spacer {
  flex: 1;
}

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
  background: var(--surface);
}

.section-header {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
  width: 100%;
  padding: var(--sp-sm) var(--sp-md);
  background: var(--surface-1);
  border: none;
  color: var(--text-primary);
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  transition: background var(--transition-fast);
}

.section-header:hover {
  background: var(--surface-2);
}

.section-header .material-icons-round {
  font-size: 20px;
  transition: transform var(--transition-fast);
  color: var(--text-muted);
}

.section-header .section-expanded {
  transform: rotate(180deg);
}

.section-count {
  margin-left: auto;
  font-size: 0.75rem;
  color: var(--text-muted);
  font-weight: 600;
  background: var(--surface-2);
  padding: 2px 8px;
  border-radius: 12px;
}

.section-items {
  display: flex;
  flex-direction: column;
  background: var(--surface);
}

.review-item {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--sp-md);
  padding: 12px 16px;
  border-bottom: 1px solid var(--surface-2);
  transition: background 0.2s;
}

.review-item:last-child {
  border-bottom: none;
}

.review-item:hover {
  background: var(--surface-1);
}

.review-item--critical {
  background: linear-gradient(90deg, rgba(239, 68, 68, 0.05) 0%, transparent 100%);
  border-left: 3px solid var(--danger);
}

.review-item-content {
  flex: 1;
  min-width: 0;
}

.review-item-question {
  font-weight: 500;
  color: var(--text-primary);
  margin: 0 0 6px 0;
  font-size: 0.9rem;
  line-height: 1.4;
}

.review-item-critical {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 0.75rem;
  color: var(--danger);
  font-weight: 700;
  margin: 0;
}

.review-item-critical .material-icons-round {
  font-size: 14px;
}

.review-item-status {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 6px;
  flex-shrink: 0;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.status-bueno { background: rgba(34, 197, 94, 0.15); color: var(--success); }
.status-malo { background: rgba(239, 68, 68, 0.15); color: var(--danger); }
.status-pending { background: var(--surface-2); color: var(--text-muted); }

.item-observation {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin: 0;
  max-width: 220px;
  text-align: right;
  font-style: italic;
}

/* Observaciones generales */
.observaciones-generales {
  padding: var(--sp-md);
  background: var(--surface);
  border-radius: var(--radius-md);
  border: 1px dashed var(--surface-2);
}

.observaciones-generales label {
  font-size: 0.8rem;
  font-weight: 800;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  display: block;
  margin-bottom: var(--sp-sm);
}

.observaciones-text {
  font-size: 0.9rem;
  color: var(--text-primary);
  margin: 0;
  line-height: 1.5;
}
</style>
