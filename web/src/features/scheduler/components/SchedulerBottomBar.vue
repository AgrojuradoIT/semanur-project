<template>
  <div class="scheduler-bottom-bar">
    <button class="btn-danger-outline" @click="$emit('report-issue')">
      <span class="material-icons-round" style="font-size: 18px">warning</span>
      NOVEDAD
    </button>
    <button class="btn btn-primary btn-lg" @click="$emit('create-schedule')">
      <span class="material-icons-round" style="font-size: 18px">calendar_today</span>
      PROGRAMAR
    </button>
  </div>
</template>

<script setup>
defineEmits(['report-issue', 'create-schedule']);
</script>
