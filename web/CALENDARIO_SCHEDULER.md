# Calendario de Programación (Scheduler)

Este documento explica cómo se implementó el calendario de programación de labores y cómo recrearlo en otro proyecto Vue.

---

## 📋 Resumen Técnico

| Aspecto | Implementación |
|---------|---------------|
| **Framework** | Vue 3 (Composition API) |
| **Librería de calendario** | ❌ Ninguna (implementación custom) |
| **Estructura** | HTML `<table>` nativo |
| **Estado** | Vue Reactivity (`ref`, `computed`) |
| **Estilos** | CSS personalizado |
| **Fechas** | Utilidades propias (`src/shared/utils/date.js`) |

---

## 🏗️ Arquitectura del Componente

El scheduler está compuesto por los siguientes archivos:

```
src/features/scheduler/
├── pages/
│   └── SchedulerPage.vue          # Página principal (orquestador)
├── components/
│   ├── SchedulerGrid.vue          # Grid del calendario (tabla)
│   ├── SchedulerToolbar.vue       # Barra superior (navegación + filtros)
│   ├── SchedulerBottomBar.vue     # Barra inferior (acciones)
│   ├── ScheduleFormModal.vue      # Modal crear/editar programación
│   ├── ScheduleDetailModal.vue    # Modal ver detalle
│   └── ScheduleIssueModal.vue     # Modal reportar novedad
└── api/
    └── schedulerService.js        # Llamadas a API
```

---

## 🔧 Cómo se Construyó el Calendario

### 1. Estructura Base (SchedulerGrid.vue)

Se utiliza una **tabla HTML** con dos secciones:

```vue
<table class="scheduler-table">
  <thead>
    <tr>
      <th class="sticky-col-header">EMPLEADO</th>
      <th v-for="day in weekDays" :key="day.iso">
        <div class="day-name">{{ day.label }}</div>
        <div class="day-num">{{ day.date.getDate() }}</div>
      </th>
    </tr>
  </thead>
  <tbody>
    <tr v-for="employee in employees" :key="employee.id">
      <td class="sticky-col-left">
        <!-- Columna fija con info del empleado -->
      </td>
      <td
        v-for="day in weekDays"
        :key="`${employee.id}-${day.iso}`"
        :class="cellClass(employee.id, day)"
        @click="$emit('cell-click', employee.id, day.iso)"
      >
        <!-- Celda interactiva por día -->
      </td>
    </tr>
  </tbody>
</table>
```

**Características clave:**
- **Columnas fijas**: La primera columna (empleado) usa `position: sticky` para permanecer visible al hacer scroll horizontal
- **Celdas interactivas**: Cada celda emite un evento `cell-click` con `employeeId` y `fechaIso`
- **Estados visuales**: Las celdas tienen clases condicionales (`cell-today`, `cell-filled`, `cell-empty`, `state-*`)

---

### 2. Lógica de Negocio (SchedulerPage.vue)

#### Estado reactivo

```vue
<script setup>
import { computed, onMounted, ref } from 'vue';

const employees = ref([]);           // Lista de empleados
const schedules = ref([]);           // Programaciones cargadas
const weekStart = ref(mondayOf(new Date())); // Inicio de semana
const employeeFilter = ref('');      // Filtro de búsqueda
</script>
```

#### Cálculo de días de la semana

```javascript
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
```

#### Navegación semanal

```javascript
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
```

#### Índice de programaciones (búsqueda O(1))

```javascript
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
```

---

### 3. Utilidades de Fecha (`src/shared/utils/date.js`)

Funciones esenciales para manipulación de fechas:

```javascript
// Obtener el lunes de la semana de una fecha dada
export function mondayOf(date) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  return new Date(d.setDate(diff));
}

// Convertir fecha a ISO string (YYYY-MM-DD)
export function toIsoDate(date) {
  return date.toISOString().slice(0, 10);
}

// Número de semana ISO
export function isoWeekNumber(date) {
  const d = new Date(date);
  d.setDate(d.getDate() + 4 - (d.getDay() || 7));
  const yearStart = new Date(d.getFullYear(), 0, 1);
  return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
}

// Verificar si una fecha es hoy
export function isToday(date) {
  const today = new Date();
  return toIsoDate(date) === toIsoDate(today);
}
```

---

### 4. Estilos CSS Principales

```css
/* Contenedor con scroll horizontal */
.scheduler-grid-container {
  overflow-x: auto;
  height: 100%;
}

/* Tabla base */
.scheduler-table {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed;
}

/* Columna fija izquierda (empleados) */
.sticky-col-left {
  position: sticky;
  left: 0;
  background: var(--surface);
  z-index: 2;
  min-width: 200px;
}

/* Cabecera fija superior */
.sticky-col-header {
  position: sticky;
  top: 0;
  background: var(--primary);
  color: white;
  z-index: 3;
}

/* Celdas interactivas */
.scheduler-table tbody td {
  border: 1px solid var(--border-light);
  cursor: pointer;
  min-height: 80px;
  transition: background 0.2s;
}

.scheduler-table tbody td:hover {
  background: var(--hover);
}

/* Celda de hoy */
.cell-today {
  background: rgba(0, 123, 255, 0.1);
  border: 2px solid var(--primary);
}

/* Tarjeta de tarea dentro de celda */
.task-card-header {
  font-size: 11px;
  color: var(--muted);
  margin-bottom: 4px;
}

.p-lab {
  font-size: 12px;
  font-weight: 500;
  margin-bottom: 4px;
}

.p-veh, .p-loc {
  font-size: 11px;
  color: var(--muted);
  display: flex;
  align-items: center;
  gap: 4px;
}
```

---

## 🚀 Guía para Recrear en Otro Proyecto Vue

### Paso 1: Estructura de Carpetas

```
src/
├── features/
│   └── scheduler/
│       ├── components/
│       │   ├── SchedulerGrid.vue
│       │   ├── SchedulerToolbar.vue
│       │   └── ScheduleFormModal.vue
│       ├── pages/
│       │   └── SchedulerPage.vue
│       └── api/
│           └── schedulerService.js
└── shared/
    └── utils/
        └── date.js
```

### Paso 2: Crear Utilidades de Fecha

```javascript
// src/shared/utils/date.js
export function mondayOf(date) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  return new Date(d.setDate(diff));
}

export function toIsoDate(date) {
  return date.toISOString().slice(0, 10);
}

export function isToday(date) {
  const today = new Date();
  return toIsoDate(date) === toIsoDate(today);
}
```

### Paso 3: Crear Componente Grid

```vue
<!-- src/features/scheduler/components/SchedulerGrid.vue -->
<template>
  <div class="scheduler-grid-container">
    <table class="scheduler-table">
      <thead>
        <tr>
          <th class="sticky-col-header">EMPLEADO</th>
          <th v-for="day in weekDays" :key="day.iso">
            <div class="day-name">{{ day.label }}</div>
            <div class="day-num">{{ day.date.getDate() }}</div>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in employees" :key="item.id">
          <td class="sticky-col-left">{{ item.name }}</td>
          <td
            v-for="day in weekDays"
            :key="`${item.id}-${day.iso}`"
            @click="$emit('cell-click', item.id, day.iso)"
          >
            <!-- Renderizar contenido de celda -->
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
defineProps({
  weekDays: { type: Array, required: true },
  employees: { type: Array, required: true },
});

defineEmits(['cell-click']);
</script>
```

### Paso 4: Crear Página Principal

```vue
<!-- src/features/scheduler/pages/SchedulerPage.vue -->
<template>
  <div class="scheduler-container">
    <SchedulerToolbar
      :week-number="weekNumber"
      :week-range-label="weekRangeLabel"
      @prev-week="changeWeek(-1)"
      @next-week="changeWeek(1)"
      @current-week="goToCurrentWeek"
    />
    <SchedulerGrid
      :week-days="weekDays"
      :employees="employees"
      @cell-click="onCellClick"
    />
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { mondayOf, toIsoDate, isToday } from '@/shared/utils/date';

const weekStart = ref(mondayOf(new Date()));
const employees = ref([]);
const schedules = ref([]);

const weekDays = computed(() => {
  const list = [];
  for (let i = 0; i < 7; i += 1) {
    const date = new Date(weekStart.value);
    date.setDate(date.getDate() + i);
    list.push({
      date,
      iso: toIsoDate(date),
      label: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'][date.getDay()],
      isToday: isToday(date),
    });
  }
  return list;
});

const weekNumber = computed(() => {
  // Implementar cálculo de número de semana
  return 0;
});

const weekRangeLabel = computed(() => {
  const start = weekDays.value[0]?.date;
  const end = weekDays.value[6]?.date;
  return `${start?.getDate()} - ${end?.getDate()}`;
});

function changeWeek(direction) {
  const next = new Date(weekStart.value);
  next.setDate(next.getDate() + (direction * 7));
  weekStart.value = mondayOf(next);
}

function goToCurrentWeek() {
  weekStart.value = mondayOf(new Date());
}

function onCellClick(employeeId, dateIso) {
  console.log('Celda clickeada:', employeeId, dateIso);
}

onMounted(async () => {
  // Cargar empleados desde API
  // employees.value = await fetchEmployees();
});
</script>
```

### Paso 5: Agregar Estilos

```css
/* En tu archivo CSS global o scoped */
.scheduler-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
}

.scheduler-grid-container {
  overflow-x: auto;
  flex: 1;
}

.scheduler-table {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed;
}

.sticky-col-left {
  position: sticky;
  left: 0;
  background: white;
  z-index: 2;
  min-width: 200px;
  box-shadow: 2px 0 4px rgba(0,0,0,0.1);
}

.sticky-col-header {
  position: sticky;
  top: 0;
  background: #007bff;
  color: white;
  z-index: 3;
}

.scheduler-table tbody td {
  border: 1px solid #e0e0e0;
  cursor: pointer;
  min-height: 80px;
  padding: 8px;
}

.scheduler-table tbody td:hover {
  background: #f5f5f5;
}

.cell-today {
  background: rgba(0, 123, 255, 0.1);
  border: 2px solid #007bff;
}
```

---

## 📦 Dependencias Requeridas

```json
{
  "dependencies": {
    "vue": "^3.5.0",
    "pinia": "^3.0.0",
    "vue-router": "^5.0.0",
    "axios": "^1.6.0"
  }
}
```

**No se requieren librerías de calendario adicionales.**

---

## 🎯 Características Implementadas

| Feature | Estado |
|---------|--------|
| Vista semanal | ✅ |
| Navegación entre semanas | ✅ |
| Ir a semana actual | ✅ |
| Filtro de empleados | ✅ |
| Click en celda para crear | ✅ |
| Click en celda ocupada para ver detalle | ✅ |
| Crear/editar/eliminar programación | ✅ |
| Reportar novedad | ✅ |
| Indicador visual "hoy" | ✅ |
| Scroll horizontal con columna fija | ✅ |
| Progreso semanal por empleado | ✅ |
| Estados de programación (colores) | ✅ |

---

## 🔑 Claves del Éxito de esta Implementación

1. **Sin dependencias externas**: Menos bundle size, más control
2. **Tabla HTML nativa**: Accesibilidad y semántica correctas
3. **Vue 3 Composition API**: Código modular y reutilizable
4. **Índice Map para búsqueda O(1)**: Performance óptima al renderizar
5. **Sticky columns**: UX mejorada con scroll horizontal
6. **Separación de responsabilidades**: Grid, Toolbar, Modals separados

---

## 📝 Notas Finales

Esta implementación es ideal para:
- ✅ Calendarios de programación de personal
- ✅ Vistas semanales tipo "resource timeline"
- ✅ Proyectos que requieren personalización total
- ✅ Equipos que quieren evitar librerías pesadas

No es recomendable si necesitas:
- ❌ Vista mensual compleja
- ❌ Drag & drop avanzado (requeriría librería adicional)
- ❌ Timezones múltiples
- ❌ Recurrencias complejas

---

**Autor**: Documentación generada para el proyecto Semanur  
**Fecha**: Abril 2026  
**Versión**: 1.0
