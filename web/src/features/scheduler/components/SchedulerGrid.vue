<template>
  <div class="scheduler-grid-container">
    <div v-if="loading" class="page-loading" style="height: 100%">
      <span class="spinner"></span>
      Cargando programacion...
    </div>

    <div v-else-if="error" class="empty-state">
      <span class="material-icons-round">cloud_off</span>
      <p>{{ error }}</p>
    </div>

    <table v-else class="scheduler-table">
      <thead>
        <tr>
          <th class="sticky-col-header">EMPLEADO</th>
          <th
            v-for="day in weekDays"
            :key="day.iso"
            :class="{ 'day-today': day.isToday }"
          >
            <div class="day-name">{{ day.label }}</div>
            <div class="day-num">{{ day.date.getDate() }}</div>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="employee in employees" :key="employee.id">
          <td class="sticky-col-left">
            <div class="emp-cell">
              <div class="emp-avatar" :style="{ background: avatarColor(employeeFullName(employee)) }">
                {{ initials(employeeFullName(employee)) }}
              </div>
              <div class="emp-info">
                <div class="emp-name">{{ employeeFullName(employee) }}</div>
                <div class="emp-role">{{ employee.cargo || 'Personal' }}</div>
                <div class="emp-progress-track">
                  <div class="emp-progress-bar" :style="employeeProgressStyle(employee.id)"></div>
                </div>
              </div>
            </div>
          </td>

          <td
            v-for="day in weekDays"
            :key="`${employee.id}-${day.iso}`"
            :class="cellClass(employee.id, day)"
            @click="$emit('cell-click', employee.id, day.iso)"
          >
            <div v-if="!entryFor(employee.id, day.iso)" class="cell-add-btn">+</div>

            <template v-else>
              <div class="task-card-header">
                <span class="task-time">{{ scheduleTimeLabel(entryFor(employee.id, day.iso)) }}</span>
              </div>
              <div class="p-lab">{{ entryFor(employee.id, day.iso).labor || 'Sin labor' }}</div>
              <div v-if="scheduleVehicleLabel(entryFor(employee.id, day.iso)) !== '-'" class="p-veh">
                <span class="material-icons-round" style="font-size: 12px">local_shipping</span>
                {{ scheduleVehicleLabel(entryFor(employee.id, day.iso)) }}
              </div>
              <div v-if="entryFor(employee.id, day.iso).ubicacion" class="p-loc">
                <span class="material-icons-round" style="font-size: 12px">place</span>
                {{ entryFor(employee.id, day.iso).ubicacion }}
              </div>
              <span class="material-icons-round task-state-icon">{{ stateIcon(entryFor(employee.id, day.iso)) }}</span>
            </template>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
const props = defineProps({
  loading: {
    type: Boolean,
    required: true,
  },
  error: {
    type: String,
    required: true,
  },
  weekDays: {
    type: Array,
    required: true,
  },
  employees: {
    type: Array,
    required: true,
  },
  cellClass: {
    type: Function,
    required: true,
  },
  getScheduleForCell: {
    type: Function,
    required: true,
  },
  employeeProgressStyle: {
    type: Function,
    required: true,
  },
  employeeFullName: {
    type: Function,
    required: true,
  },
  avatarColor: {
    type: Function,
    required: true,
  },
  initials: {
    type: Function,
    required: true,
  },
  scheduleTimeLabel: {
    type: Function,
    required: true,
  },
  scheduleVehicleLabel: {
    type: Function,
    required: true,
  },
  stateIcon: {
    type: Function,
    required: true,
  },
});

defineEmits(['cell-click']);

function entryFor(employeeId, dayIso) {
  return props.getScheduleForCell(employeeId, dayIso);
}
</script>
