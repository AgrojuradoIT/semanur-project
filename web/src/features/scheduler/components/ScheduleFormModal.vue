<template>
  <div v-if="visible" class="modal-overlay" @click.self="$emit('close')">
    <div class="modal modal-wide">
      <div class="modal-header">
        <h3>{{ editingId ? 'EDITAR PROGRAMACION' : 'NUEVA PROGRAMACION' }}</h3>
        <button class="modal-close" @click="$emit('close')">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>

      <div class="modal-body">
        <form class="form-grid" @submit.prevent="handleSubmit">
          <div class="input-group">
            <label>Empleado</label>
            <SearchableSelect
              v-model="form.empleado_id"
              :items="employees"
              :label-fn="employeeFullName"
              placeholder="Seleccionar..."
            />
          </div>

          <div class="input-group">
            <label>Fecha</label>
            <input v-model="form.fecha" class="input" type="date" required />
          </div>

          <div class="input-group full-width">
            <label>Labor</label>
            <input v-model.trim="form.labor" class="input" type="text" required placeholder="Descripcion de la tarea" />
          </div>

          <div class="input-group">
            <label>Vehiculo (Opcional)</label>
            <SearchableSelect
              v-model="form.vehiculo_id"
              :items="vehicles"
              :label-fn="vehicleLabel"
              :value-fn="vehicleId"
              placeholder="Ninguno"
            />
          </div>

          <div class="input-group">
            <label>Ubicacion (Opcional)</label>
            <input v-model.trim="form.ubicacion" class="input" type="text" />
          </div>

          <template v-if="!editingId">
            <!-- Repetir varios días -->
            <div class="input-group full-width">
              <label class="toggle-label" @click="repeatDays = !repeatDays">
                <span class="toggle-text">Repetir varios dias</span>
                <span class="toggle-switch" :class="{ active: repeatDays }">
                  <span class="toggle-thumb"></span>
                </span>
              </label>
            </div>

            <div v-if="repeatDays" class="input-group full-width">
              <label>Dias de la semana</label>
              <div class="day-pills">
                <button
                  v-for="(day, idx) in dayLabels"
                  :key="idx"
                  type="button"
                  class="day-pill"
                  :class="{ active: selectedDays.includes(idx) }"
                  @click="toggleDay(idx)"
                >
                  {{ day }}
                </button>
              </div>
            </div>

            <div class="input-group full-width">
              <label class="toggle-label" @click="form.crear_orden_trabajo = !form.crear_orden_trabajo">
                <span class="toggle-text">Crear orden de trabajo automaticamente</span>
                <span class="toggle-switch" :class="{ active: form.crear_orden_trabajo }">
                  <span class="toggle-thumb"></span>
                </span>
              </label>
            </div>
          </template>
        </form>
      </div>

      <div class="modal-footer">
        <button class="btn btn-secondary" @click="$emit('close')">Cancelar</button>
        <button class="btn btn-primary" :disabled="saving" @click="handleSubmit">
          <span class="material-icons-round" style="font-size: 18px">save</span>
          {{ saving ? 'GUARDANDO...' : editingId ? 'ACTUALIZAR' : 'PROGRAMAR' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import SearchableSelect from '../../../shared/components/SearchableSelect.vue';

const props = defineProps({
  visible: { type: Boolean, required: true },
  editingId: { type: [Number, String, null], default: null },
  saving: { type: Boolean, required: true },
  form: { type: Object, required: true },
  employees: { type: Array, required: true },
  vehicles: { type: Array, required: true },
  employeeFullName: { type: Function, required: true },
  vehicleId: { type: Function, required: true },
  vehicleLabel: { type: Function, required: true },
});

const emit = defineEmits(['close', 'submit']);

const dayLabels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
const repeatDays = ref(false);
const selectedDays = ref([]);

function toggleDay(idx) {
  const pos = selectedDays.value.indexOf(idx);
  if (pos >= 0) {
    selectedDays.value.splice(pos, 1);
  } else {
    selectedDays.value.push(idx);
  }
}

// Al cambiar la fecha, preseleccionar el día correspondiente
watch(() => props.form?.fecha, (newDate) => {
  if (newDate && !props.editingId) {
    const d = new Date(newDate + 'T00:00:00');
    const weekday = d.getDay(); // 0=Dom, 1=Lun...6=Sab
    const idx = weekday === 0 ? 6 : weekday - 1; // 0=Lun, 6=Dom
    selectedDays.value = [idx];
  }
}, { immediate: true });

// Reset al abrir/cerrar
watch(() => props.visible, (v) => {
  if (!v) {
    repeatDays.value = false;
    selectedDays.value = [];
  }
});

function handleSubmit() {
  if (repeatDays.value && selectedDays.value.length > 0) {
    // Emitir con los dias seleccionados
    emit('submit', { multiDay: selectedDays.value });
  } else {
    emit('submit');
  }
}
</script>

<style scoped>
/* Toggle switch */
.toggle-label {
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  text-transform: none !important;
  letter-spacing: normal !important;
  font-weight: 500;
  padding: 4px 0;
}

.toggle-text {
  color: var(--text-main);
  font-size: 0.9rem;
}

.toggle-switch {
  width: 44px;
  height: 24px;
  border-radius: 12px;
  background: var(--surface-3);
  position: relative;
  transition: background 0.25s ease;
  flex-shrink: 0;
}

.toggle-switch.active {
  background: var(--primary);
}

.toggle-thumb {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--text-main);
  transition: transform 0.25s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}

.toggle-switch.active .toggle-thumb {
  transform: translateX(20px);
  background: #000;
}

/* Day pills */
.day-pills {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.day-pill {
  padding: 6px 14px;
  background: var(--surface-1);
  border: 1px solid var(--surface-3);
  border-radius: 20px;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--text-muted);
  cursor: pointer;
  transition: all 0.2s ease;
}

.day-pill:hover {
  border-color: var(--primary);
  color: var(--text-main);
}

.day-pill.active {
  background: var(--primary);
  border-color: var(--primary);
  color: #000;
}
</style>
