<template>
  <div class="scheduler-toolbar">
    <div class="week-nav">
      <button class="btn btn-icon" title="Semana anterior" @click="$emit('prev-week')">
        <span class="material-icons-round">chevron_left</span>
      </button>
      <div class="week-display-box">
        <span class="week-label">SEMANA {{ weekNumber }}</span>
        <span class="week-range">{{ weekRangeLabel }}</span>
      </div>
      <button class="btn btn-icon" title="Semana siguiente" @click="$emit('next-week')">
        <span class="material-icons-round">chevron_right</span>
      </button>
      <button
        class="btn btn-secondary"
        style="margin-left: 8px; padding: 6px 14px; font-size: 0.78rem"
        @click="$emit('current-week')"
      >
        HOY
      </button>
      <button class="btn btn-icon" title="Recargar" @click="$emit('refresh')">
        <span class="material-icons-round" style="font-size: 18px">refresh</span>
      </button>
    </div>

    <div class="scheduler-toolbar-right">
      <div class="scheduler-search">
        <span class="material-icons-round scheduler-search-icon">search</span>
        <input
          :value="employeeFilter"
          type="text"
          class="scheduler-search-input"
          placeholder="Buscar empleado o cargo..."
          @input="$emit('update:employee-filter', $event.target.value)"
        />
      </div>

      <div class="week-view-badge">
        <span class="material-icons-round" style="font-size: 14px">calendar_view_week</span>
        VISTA SEMANAL
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  weekNumber: {
    type: Number,
    required: true,
  },
  weekRangeLabel: {
    type: String,
    required: true,
  },
  employeeFilter: {
    type: String,
    default: '',
  },
});

defineEmits(['prev-week', 'next-week', 'current-week', 'refresh', 'update:employee-filter']);
</script>
