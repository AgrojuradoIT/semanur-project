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
        <form class="form-grid" @submit.prevent="$emit('submit')">
          <div class="input-group">
            <label>Empleado</label>
            <SearchableSelect
              v-model="form.empleado_id"
              :options="employeeOptions"
              placeholder="Seleccionar..."
              search-placeholder="Buscar empleado..."
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
              :options="vehicleOptions"
              placeholder="Ninguno"
              search-placeholder="Buscar vehículo..."
              :clearable="true"
            />
          </div>

          <div class="input-group">
            <label>Ubicacion (Opcional)</label>
            <input v-model.trim="form.ubicacion" class="input" type="text" />
          </div>

          <div class="input-group full-width">
            <label style="display: flex; align-items: center; gap: 8px; text-transform: none; letter-spacing: normal">
              <input v-model="form.crear_orden_trabajo" type="checkbox" />
              Crear orden de trabajo automaticamente
            </label>
          </div>
        </form>
      </div>

      <div class="modal-footer">
        <button class="btn btn-secondary" @click="$emit('close')">Cancelar</button>
        <button class="btn btn-primary" :disabled="saving" @click="$emit('submit')">
          <span class="material-icons-round" style="font-size: 18px">save</span>
          {{ saving ? 'GUARDANDO...' : editingId ? 'ACTUALIZAR' : 'PROGRAMAR' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
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

defineEmits(['close', 'submit']);

const employeeOptions = computed(() =>
  props.employees.map((employee) => {
    const label = props.employeeFullName(employee);
    return {
      value: String(employee.id),
      label,
      keywords: label,
    };
  }),
);

const vehicleOptions = computed(() =>
  props.vehicles.map((vehicle) => {
    const id = props.vehicleId(vehicle);
    const label = props.vehicleLabel(vehicle);
    return {
      value: String(id),
      label,
      keywords: label,
    };
  }),
);
</script>
