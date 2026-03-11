<template>
  <div v-if="visible && schedule" class="modal-overlay" @click.self="$emit('close')">
    <div class="modal">
      <div class="modal-header">
        <h3>DETALLE DE PROGRAMACION</h3>
        <button class="modal-close" @click="$emit('close')">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>

      <div class="modal-body">
        <div style="background: var(--bg-dark); padding: 14px; border-radius: var(--radius-sm); border-left: 3px solid var(--primary)">
          <p style="font-weight: 700; color: var(--text-main)">{{ schedule.labor || 'Sin labor' }}</p>
          <p style="font-size: 0.86rem; color: var(--text-gray)">Empleado: {{ scheduleEmployeeLabel(schedule) }}</p>
          <p style="font-size: 0.86rem; color: var(--text-gray)">Fecha: {{ scheduleDateLabel(schedule) }}</p>
          <p style="font-size: 0.86rem; color: var(--text-gray)">Vehiculo: {{ scheduleVehicleLabel(schedule) }}</p>
          <p style="font-size: 0.86rem; color: var(--text-gray)">Ubicacion: {{ schedule.ubicacion || '-' }}</p>
          <p style="font-size: 0.86rem; color: var(--text-gray)">Estado: {{ schedule.estado || 'pendiente' }}</p>
        </div>
      </div>

      <div class="modal-footer">
        <button class="btn btn-secondary" @click="$emit('close')">Cerrar</button>
        <button class="btn btn-secondary" @click="$emit('edit')">Editar</button>
        <button class="btn btn-danger" :disabled="deleting" @click="$emit('delete')">
          {{ deleting ? 'ELIMINANDO...' : 'Eliminar' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  visible: { type: Boolean, required: true },
  schedule: { type: Object, default: null },
  deleting: { type: Boolean, required: true },
  scheduleEmployeeLabel: { type: Function, required: true },
  scheduleDateLabel: { type: Function, required: true },
  scheduleVehicleLabel: { type: Function, required: true },
});

defineEmits(['close', 'edit', 'delete']);
</script>
