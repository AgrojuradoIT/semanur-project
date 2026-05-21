<template>
  <div class="alerts-panel">
    <h4 class="alerts-title">
      <span class="material-icons-round">notifications_active</span>
      Alertas Activas
      <span class="alerts-count" v-if="alerts.length > 0">{{ alerts.length }}</span>
    </h4>

    <div v-if="alerts.length === 0" class="no-alerts">
      <span class="material-icons-round">check_circle</span>
      Sin alertas activas
    </div>

    <div v-for="(alert, idx) in alerts" :key="idx" class="alert-item" :class="`alert-item--${alert.type}`">
      <span class="alert-icon">{{ alert.icon }}</span>
      <span class="alert-text">{{ alert.message }}</span>
      <button class="alert-action" @click="alert.action">Ver</button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  semanas: { type: Array, default: () => [] },
});

const emit = defineEmits(['view-semana']);

function viewSemana(semana) {
  emit('view-semana', semana);
}

const alerts = computed(() => {
  const result = [];

  for (const semana of props.semanas) {
    const placa = semana.vehiculoPlaca || 'Sin placa';

    // 1. Critical failure alerts
    if (semana.dailyForms) {
      for (const form of semana.dailyForms) {
        if (form.estado !== 'completado') continue;
        const responses = form.responses || [];

        const criticalFailures = responses.filter(
          (r) => r.es_critico && r.valor === 'M'
        );

        for (const failure of criticalFailures) {
          const diaLabel = diaLabelMap[form.dia_semana] || form.dia_semana;
          const itemDesc = failure.pregunta || failure.nombre || 'Item';
          result.push({
            type: 'critical',
            icon: '\u26A0',
            message: `${placa}: ${itemDesc} = Malo el ${diaLabel} \u2014 Ver detalle`,
            action: () => viewSemana(semana),
          });
        }
      }
    }

    // 2. Fuera de servicio alerts
    if (semana.estado === 'fuera_servicio') {
      result.push({
        type: 'fuera-servicio',
        icon: '\uD83D\uDD34',
        message: `${placa}: Marcado fuera de servicio \u2014 Ver detalle`,
        action: () => viewSemana(semana),
      });
    }

    // 3. Document expiry alerts (from documentosVehiculoSnapshot)
    if (semana.documentosVehiculoSnapshot) {
      const docs = semana.documentosVehiculoSnapshot;
      const today = new Date();

      for (const doc of Object.values(docs)) {
        if (!doc.fecha_vencimiento) continue;
        const vencimiento = new Date(doc.fecha_vencimiento);
        const diffDays = Math.ceil((vencimiento - today) / (1000 * 60 * 60 * 24));

        if (diffDays > 0 && diffDays <= 15) {
          result.push({
            type: 'warning',
            icon: '\u26A0',
            message: `${placa}: ${doc.tipo || 'Documento'} vence en ${diffDays} d\u00EDas \u2014 Ver documento`,
            action: () => {},
          });
        } else if (diffDays <= 0) {
          result.push({
            type: 'critical',
            icon: '\u26D4',
            message: `${placa}: ${doc.tipo || 'Documento'} vencido \u2014 Ver documento`,
            action: () => {},
          });
        }
      }
    }

    // 4. Overdue alerts
    if (semana.estado === 'vencida') {
      result.push({
        type: 'overdue',
        icon: '\u26D4',
        message: `${placa}: Semana vencida sin completar \u2014 Asignar operador`,
        action: () => viewSemana(semana),
      });
    }
  }

  return result;
});

const diaLabelMap = {
  lunes: 'Lunes',
  martes: 'Martes',
  miercoles: 'Mi\u00E9rcoles',
  jueves: 'Jueves',
  viernes: 'Viernes',
  sabado: 'S\u00E1bado',
  domingo: 'Domingo',
};
</script>

<style scoped>
.alerts-panel {
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-lg);
  padding: var(--sp-lg);
}

.alerts-title {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
  font-family: 'Oswald', sans-serif;
  font-size: 1rem;
  font-weight: 600;
  color: var(--text-main);
  margin: 0 0 var(--sp-md) 0;
  letter-spacing: 0.5px;
}

.alerts-title .material-icons-round {
  font-size: 20px;
  color: var(--warning);
}

.alerts-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 22px;
  height: 22px;
  padding: 0 6px;
  border-radius: 12px;
  background: var(--danger);
  color: #fff;
  font-size: 0.7rem;
  font-weight: 700;
  font-family: 'Inter', sans-serif;
}

.no-alerts {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
  color: var(--success);
  font-size: 0.88rem;
  font-weight: 500;
  padding: var(--sp-md) 0;
}

.no-alerts .material-icons-round {
  font-size: 22px;
}

.alert-item {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
  padding: var(--sp-sm) var(--sp-md);
  margin-bottom: var(--sp-sm);
  border-radius: var(--radius-sm);
  border-left: 4px solid var(--surface-3);
  background: var(--bg-dark);
  transition: background var(--transition-fast);
}

.alert-item:hover {
  background: var(--surface-2);
}

.alert-item--critical {
  border-left-color: var(--danger);
}

.alert-item--warning {
  border-left-color: var(--warning);
}

.alert-item--fuera-servicio {
  border-left-color: var(--danger);
}

.alert-item--overdue {
  border-left-color: var(--danger);
}

.alert-item--info {
  border-left-color: var(--info);
}

.alert-icon {
  font-size: 1rem;
  flex-shrink: 0;
}

.alert-text {
  flex: 1;
  font-size: 0.85rem;
  color: var(--text-secondary);
  line-height: 1.4;
}

.alert-action {
  padding: 4px 12px;
  border: 1px solid var(--surface-3);
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--text-gray);
  font-size: 0.75rem;
  font-weight: 600;
  cursor: pointer;
  transition: all var(--transition-fast);
  flex-shrink: 0;
}

.alert-action:hover {
  background: var(--primary-10);
  border-color: var(--primary);
  color: var(--primary);
}
</style>
