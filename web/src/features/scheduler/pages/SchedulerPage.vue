<template>
  <div class="scheduler-container">
    <SchedulerToolbar
      :week-number="weekNumber"
      :week-range-label="weekRangeLabel"
      :employee-filter="employeeFilter"
      @prev-week="changeWeek(-1)"
      @next-week="changeWeek(1)"
      @current-week="goToCurrentWeek"
      @refresh="loadSchedule"
      @update:employee-filter="(val) => employeeFilter = val"
    />

    <SchedulerGrid
      :loading="loading"
      :error="error"
      :week-days="weekDays"
      :employees="filteredEmployees"
      :cell-class="cellClass"
      :get-schedule-for-cell="getScheduleForCell"
      :employee-progress-style="employeeProgressStyle"
      :employee-full-name="employeeFullName"
      :avatar-color="avatarColor"
      :initials="initials"
      :schedule-time-label="scheduleTimeLabel"
      :schedule-vehicle-label="scheduleVehicleLabel"
      :state-icon="stateIcon"
      @cell-click="onCellClick"
    />

    <SchedulerBottomBar
      @report-issue="openIssueModal()"
      @create-schedule="openScheduleModal()"
    />
  </div>
  <ScheduleFormModal
    :visible="showScheduleModal"
    :editing-id="scheduleEditingId"
    :saving="savingSchedule"
    :form="scheduleForm"
    :employees="sortedEmployees"
    :vehicles="vehicles"
    :employee-full-name="employeeFullName"
    :vehicle-id="vehicleId"
    :vehicle-label="vehicleLabel"
    @close="closeScheduleModal"
    @submit="submitSchedule"
  />

  <ScheduleDetailModal
    :visible="showDetailModal"
    :schedule="selectedSchedule"
    :deleting="deletingSchedule"
    :schedule-employee-label="scheduleEmployeeLabel"
    :schedule-date-label="scheduleDateLabel"
    :schedule-vehicle-label="scheduleVehicleLabel"
    @close="closeDetailModal"
    @edit="startEditFromDetail"
    @delete="removeSelectedSchedule"
  />

  <ScheduleIssueModal
    :visible="showIssueModal"
    :saving="savingIssue"
    :form="issueForm"
    :employees="sortedEmployees"
    :vehicles="vehicles"
    :employee-full-name="employeeFullName"
    :vehicle-id="vehicleId"
    :vehicle-label="vehicleLabel"
    @close="closeIssueModal"
    @submit="submitIssue"
    @photo-selected="issuePhoto = $event"
  />
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import http from '../../../shared/api/http';
import SchedulerBottomBar from '../components/SchedulerBottomBar.vue';
import ScheduleDetailModal from '../components/ScheduleDetailModal.vue';
import ScheduleFormModal from '../components/ScheduleFormModal.vue';
import SchedulerGrid from '../components/SchedulerGrid.vue';
import ScheduleIssueModal from '../components/ScheduleIssueModal.vue';
import SchedulerToolbar from '../components/SchedulerToolbar.vue';
import {
  createSchedule,
  deleteSchedule,
  fetchScheduleRange,
  reportScheduleIssue,
  updateSchedule,
} from '../api/schedulerService';
import { isToday, isoWeekNumber, mondayOf, toIsoDate } from '../../../shared/utils/date';
import {
  avatarColor,
  employeeFullName,
  initials,
  scheduleDateLabel,
  scheduleTimeLabel,
  SCHEDULER_DAY_LABELS,
  SCHEDULER_MONTH_SHORT,
  stateClass,
  stateIcon,
} from '../../../shared/utils/scheduler';
import { useCatalogsStore } from '../../../shared/stores/catalogs';

const { loading, error, run, clearError } = useAsyncState('');
const employees = ref([]);
const vehicles = ref([]);
const schedules = ref([]);
const weekStart = ref(mondayOf(new Date()));
const employeeFilter = ref('');

const showScheduleModal = ref(false);
const savingSchedule = ref(false);
const scheduleEditingId = ref(null);
const scheduleForm = ref(defaultScheduleForm());

const showDetailModal = ref(false);
const selectedSchedule = ref(null);
const deletingSchedule = ref(false);

const showIssueModal = ref(false);
const savingIssue = ref(false);
const issuePhoto = ref(null);
const issueForm = ref(defaultIssueForm());

onMounted(async () => {
  await loadDependencies();
  await loadSchedule();
});

async function loadDependencies() {
  try {
    await run(async () => {
      const catalogsStore = useCatalogsStore();
      await catalogsStore.fetchEssentialCatalogs();

      employees.value = catalogsStore.empleados;
      vehicles.value = catalogsStore.vehiculos;
    }, 'Error al cargar dependencias');
  } catch {
    // handled by composable
  }
}

async function loadSchedule() {
  try {
    await run(async () => {
      const startIso = toIsoDate(weekStart.value);
      const end = new Date(weekStart.value);
      end.setDate(end.getDate() + 6);
      schedules.value = await fetchScheduleRange(startIso, toIsoDate(end));
    }, 'Error al cargar programacion');
  } catch {
    schedules.value = [];
  }
}

const sortedEmployees = computed(() =>
  [...employees.value].sort((a, b) => employeeFullName(a).localeCompare(employeeFullName(b))),
);

const filteredEmployees = computed(() => {
  const term = employeeFilter.value.trim().toLowerCase();
  if (!term) return sortedEmployees.value;

  return sortedEmployees.value.filter((emp) => {
    const name = employeeFullName(emp).toLowerCase();
    const cargo = String(emp.cargo || '').toLowerCase();
    return name.includes(term) || cargo.includes(term);
  });
});

const weekDays = computed(() => {
  const list = [];
  for (let i = 0; i < 7; i += 1) {
    const date = new Date(weekStart.value);
    date.setDate(date.getDate() + i);
    list.push({
      date,
      iso: toIsoDate(date),
      label: SCHEDULER_DAY_LABELS[date.getDay()],
      isToday: isToday(date),
    });
  }
  return list;
});

const weekNumber = computed(() => isoWeekNumber(weekStart.value));

const weekRangeLabel = computed(() => {
  const start = weekDays.value[0]?.date;
  const end = weekDays.value[6]?.date;
  if (!start || !end) return '';
  return `${SCHEDULER_MONTH_SHORT[start.getMonth()]} ${start.getDate()} - ${SCHEDULER_MONTH_SHORT[end.getMonth()]} ${end.getDate()}`;
});

const scheduleIndex = computed(() => {
  const index = new Map();
  for (const entry of schedules.value) {
    const employeeId = Number(entry.empleado_id || entry.empleado?.id || 0);
    const date = String(entry.fecha || '').slice(0, 10);
    if (!employeeId || !date) continue;
    index.set(`${employeeId}-${date}`, entry);
  }
  return index;
});

function getScheduleForCell(employeeId, dateIso) {
  return scheduleIndex.value.get(`${Number(employeeId)}-${dateIso}`) || null;
}

function onCellClick(employeeId, dateIso) {
  const entry = getScheduleForCell(employeeId, dateIso);
  if (entry) {
    selectedSchedule.value = entry;
    showDetailModal.value = true;
    return;
  }
  openScheduleModal({
    empleado_id: Number(employeeId),
    fecha: dateIso,
  });
}

function cellClass(employeeId, day) {
  const entry = getScheduleForCell(employeeId, day.iso);
  const classes = [];
  if (!entry) classes.push('cell-empty');
  if (entry) classes.push('cell-filled', stateClass(entry));
  if (day.isToday) classes.push('cell-today');
  return classes.join(' ');
}

function employeeProgressStyle(employeeId) {
  const count = weekDays.value.reduce((acc, day) => (getScheduleForCell(employeeId, day.iso) ? acc + 1 : acc), 0);
  const percent = Math.min((count / 7) * 100, 100);
  return {
    width: `${percent}%`,
    background: avatarColor(String(employeeId)),
  };
}

function changeWeek(direction) {
  const next = new Date(weekStart.value);
  next.setDate(next.getDate() + (direction * 7));
  weekStart.value = mondayOf(next);
  loadSchedule();
}

function goToCurrentWeek() {
  weekStart.value = mondayOf(new Date());
  loadSchedule();
}

function openScheduleModal(seed = null) {
  scheduleEditingId.value = null;
  showScheduleModal.value = true;
  scheduleForm.value = defaultScheduleForm();
  if (seed) {
    scheduleForm.value.empleado_id = seed.empleado_id ?? '';
    scheduleForm.value.fecha = seed.fecha ?? toIsoDate(new Date());
  }
}

function closeScheduleModal() {
  showScheduleModal.value = false;
  savingSchedule.value = false;
  scheduleEditingId.value = null;
  scheduleForm.value = defaultScheduleForm();
}

async function submitSchedule(opts = null) {
  if (savingSchedule.value) return;
  if (!scheduleForm.value.empleado_id || !scheduleForm.value.fecha || !scheduleForm.value.labor) return;

  savingSchedule.value = true;
  clearError();

  try {
    if (opts?.multiDay?.length > 0 && !scheduleEditingId.value) {
      // Multi-day: calcular fechas a partir del lunes de la semana
      const baseDate = new Date(scheduleForm.value.fecha + 'T00:00:00');
      const dayOfWeek = baseDate.getDay(); // 0=Dom
      const monday = new Date(baseDate);
      monday.setDate(baseDate.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));

      const dates = opts.multiDay.map((dayIdx) => {
        const d = new Date(monday);
        d.setDate(monday.getDate() + dayIdx);
        return d.toISOString().slice(0, 10);
      });

      const payload = {
        empleado_id: Number(scheduleForm.value.empleado_id),
        labor: scheduleForm.value.labor,
        ubicacion: scheduleForm.value.ubicacion || null,
        crear_orden_trabajo: Boolean(scheduleForm.value.crear_orden_trabajo),
      };
      if (scheduleForm.value.vehiculo_id) payload.vehiculo_id = Number(scheduleForm.value.vehiculo_id);

      await Promise.all(dates.map((date) => createSchedule({ ...payload, fecha: date })));
    } else {
      const payload = {
        empleado_id: Number(scheduleForm.value.empleado_id),
        fecha: scheduleForm.value.fecha,
        labor: scheduleForm.value.labor,
        ubicacion: scheduleForm.value.ubicacion || null,
      };
      if (scheduleForm.value.vehiculo_id) payload.vehiculo_id = Number(scheduleForm.value.vehiculo_id);
      if (!scheduleEditingId.value) {
        payload.crear_orden_trabajo = Boolean(scheduleForm.value.crear_orden_trabajo);
      }

      if (scheduleEditingId.value) {
        await updateSchedule(scheduleEditingId.value, payload);
      } else {
        await createSchedule(payload);
      }
    }
    closeScheduleModal();
    await loadSchedule();
  } catch (e) {
    error.value = e?.response?.data?.message || e?.message || 'Error al guardar programacion';
  } finally {
    savingSchedule.value = false;
  }
}

function closeDetailModal() {
  showDetailModal.value = false;
  selectedSchedule.value = null;
}

function startEditFromDetail() {
  if (!selectedSchedule.value) return;
  const entry = selectedSchedule.value;
  scheduleEditingId.value = scheduleId(entry);
  scheduleForm.value = {
    empleado_id: Number(entry.empleado_id || entry.empleado?.id || ''),
    fecha: String(entry.fecha || '').slice(0, 10),
    vehiculo_id: entry.vehiculo_id ? Number(entry.vehiculo_id) : '',
    labor: entry.labor || '',
    ubicacion: entry.ubicacion || '',
    crear_orden_trabajo: false,
  };
  closeDetailModal();
  showScheduleModal.value = true;
}

async function removeSelectedSchedule() {
  if (!selectedSchedule.value || deletingSchedule.value) return;
  deletingSchedule.value = true;
  clearError();

  try {
    await deleteSchedule(scheduleId(selectedSchedule.value));
    closeDetailModal();
    await loadSchedule();
  } catch (e) {
    error.value = e?.response?.data?.message || e?.message || 'Error al eliminar programacion';
  } finally {
    deletingSchedule.value = false;
  }
}

function openIssueModal(seed = null) {
  issueForm.value = defaultIssueForm();
  if (seed) {
    issueForm.value.empleado_id = seed.empleado_id ?? '';
    issueForm.value.vehiculo_id = seed.vehiculo_id ?? '';
    issueForm.value.fecha = seed.fecha ?? toIsoDate(new Date());
  }
  showIssueModal.value = true;
}

function closeIssueModal() {
  showIssueModal.value = false;
  savingIssue.value = false;
  issuePhoto.value = null;
  issueForm.value = defaultIssueForm();
}

async function submitIssue() {
  if (savingIssue.value) return;
  if (!issueForm.value.empleado_id || !issueForm.value.fecha || !issueForm.value.descripcion) return;

  savingIssue.value = true;
  clearError();

  const hasPhoto = issuePhoto.value instanceof File;

  try {
    if (hasPhoto) {
      const fd = new FormData();
      fd.append('empleado_id', Number(issueForm.value.empleado_id));
      fd.append('fecha', issueForm.value.fecha);
      fd.append('descripcion', issueForm.value.descripcion);
      fd.append('prioridad', issueForm.value.prioridad || 'Urgente');
      fd.append('pausar_actividad', issueForm.value.pausar_actividad ? 1 : 0);
      if (issueForm.value.vehiculo_id) fd.append('vehiculo_id', Number(issueForm.value.vehiculo_id));
      fd.append('foto', issuePhoto.value);
      await http.post('/programacion/novedad', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    } else {
      await reportScheduleIssue({
        empleado_id: Number(issueForm.value.empleado_id),
        fecha: issueForm.value.fecha,
        descripcion: issueForm.value.descripcion,
        prioridad: issueForm.value.prioridad || 'Urgente',
        pausar_actividad: issueForm.value.pausar_actividad ? 1 : 0,
        vehiculo_id: issueForm.value.vehiculo_id ? Number(issueForm.value.vehiculo_id) : undefined,
      });
    }
    closeIssueModal();
    await loadSchedule();
  } catch (e) {
    error.value = e?.response?.data?.message || e?.message || 'Error al reportar novedad';
  } finally {
    savingIssue.value = false;
  }
}

function scheduleId(entry) {
  return entry?.id ?? entry?.programacion_id ?? 0;
}

function scheduleEmployeeLabel(entry) {
  if (entry?.empleado?.name) return entry.empleado.name;
  if (entry?.empleado?.nombres || entry?.empleado?.apellidos) {
    return `${entry.empleado.nombres || ''} ${entry.empleado.apellidos || ''}`.trim();
  }
  const employee = employees.value.find((item) => Number(item.id) === Number(entry?.empleado_id));
  return employee ? employeeFullName(employee) : '-';
}

function scheduleVehicleLabel(entry) {
  if (entry?.vehiculo?.placa) return entry.vehiculo.placa;
  const vehicle = vehicles.value.find((item) => Number(vehicleId(item)) === Number(entry?.vehiculo_id));
  return vehicle ? vehicle.placa || '-' : '-';
}

function vehicleId(vehicle) {
  return vehicle?.vehiculo_id ?? vehicle?.id ?? '';
}

function vehicleLabel(vehicle) {
  return `${vehicle?.placa || 'Sin placa'} - ${vehicle?.tipo || vehicle?.modelo || ''}`.trim();
}

function defaultScheduleForm() {
  return {
    empleado_id: '',
    fecha: toIsoDate(new Date()),
    vehiculo_id: '',
    labor: '',
    ubicacion: '',
    crear_orden_trabajo: false,
  };
}

function defaultIssueForm() {
  return {
    empleado_id: '',
    vehiculo_id: '',
    fecha: toIsoDate(new Date()),
    prioridad: 'Urgente',
    descripcion: '',
    pausar_actividad: true,
  };
}
</script>

