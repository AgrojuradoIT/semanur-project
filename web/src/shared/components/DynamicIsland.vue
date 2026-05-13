<template>
  <Teleport to="body">
    <Transition name="island-enter">
      <div v-if="visible" class="dynamic-island" :class="`island--${type}`" @click="expanded = !expanded">
        <div class="island-header">
          <span class="island-icon material-icons-round">{{ icon }}</span>
          <span class="island-title">{{ title }}</span>
          <button class="island-close" @click.stop="dismiss">
            <span class="material-icons-round">close</span>
          </button>
        </div>
        <div v-if="expanded && message" class="island-body">
          <span class="island-message">{{ message }}</span>
          <button v-if="actionLabel" class="island-action" @click.stop="handleAction">{{ actionLabel }}</button>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  type: { type: String, default: 'info' }, // success | error | warning | info
  title: { type: String, default: '' },
  message: { type: String, default: '' },
  duration: { type: Number, default: 0 }, // 0 = no auto-dismiss
  actionLabel: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue', 'action', 'dismiss']);

const visible = ref(false);
const expanded = ref(false);
let expandTimer = null;
let dismissTimer = null;

const icon = computed(() => ({
  success: 'check_circle',
  error: 'error',
  warning: 'warning',
  info: 'notifications',
}[props.type] || 'notifications'));

watch(() => props.modelValue, (v) => {
  if (v) {
    visible.value = true;
    expanded.value = true;
    // Collapse after 3s
    if (expandTimer) clearTimeout(expandTimer);
    expandTimer = setTimeout(() => { expanded.value = false; }, 3000);
    // Auto-dismiss
    if (props.duration > 0) {
      if (dismissTimer) clearTimeout(dismissTimer);
      dismissTimer = setTimeout(() => dismiss(), props.duration);
    }
  } else {
    visible.value = false;
    expanded.value = false;
  }
});

function dismiss() {
  if (expandTimer) clearTimeout(expandTimer);
  if (dismissTimer) clearTimeout(dismissTimer);
  visible.value = false;
  expanded.value = false;
  emit('update:modelValue', false);
  emit('dismiss');
}

function handleAction() {
  emit('action');
  dismiss();
}

onBeforeUnmount(() => {
  if (expandTimer) clearTimeout(expandTimer);
  if (dismissTimer) clearTimeout(dismissTimer);
});
</script>

<style scoped>
.dynamic-island {
  position: fixed;
  top: 16px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 10000;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 14px 24px;
  border-radius: 28px;
  background: var(--surface-2);
  border: 1px solid var(--surface-3);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
  cursor: pointer;
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
  min-width: 280px;
  max-width: 600px;
  user-select: none;
}

.dynamic-island:hover {
  transform: translateX(-50%) scale(1.02);
}

.island-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.island-icon {
  font-size: 22px;
  flex-shrink: 0;
}

.island-title {
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--text-main);
  flex: 1;
  text-align: center;
}

.island-close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--text-gray);
  cursor: pointer;
  transition: background 0.2s;
  flex-shrink: 0;
}

.island-close:hover {
  background: var(--surface-3);
}

.island-close .material-icons-round {
  font-size: 18px;
}

.island-body {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.island-message {
  font-size: 0.85rem;
  color: var(--text-gray);
  line-height: 1.5;
  word-break: break-word;
  padding-left: 32px;
}

.island-action {
  align-self: flex-end;
  padding: 6px 14px;
  border: none;
  border-radius: 16px;
  font-size: 0.8rem;
  font-weight: 700;
  color: inherit;
  background: var(--primary-10);
  cursor: pointer;
  white-space: nowrap;
}

.island-action {
  padding: 6px 14px;
  border: none;
  border-radius: 16px;
  font-size: 0.8rem;
  font-weight: 700;
  color: inherit;
  background: var(--primary-10);
  cursor: pointer;
  white-space: nowrap;
}

.island-close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--text-gray);
  cursor: pointer;
  transition: background 0.2s;
}

.island-close:hover {
  background: var(--surface-3);
}

.island-close .material-icons-round {
  font-size: 16px;
}

/* Colors */
.island--success .island-icon { color: var(--success); }
.island--success { border-left: 3px solid var(--success); }

.island--error .island-icon { color: var(--danger); }
.island--error { border-left: 3px solid var(--danger); }

.island--warning .island-icon { color: var(--warning); }
.island--warning { border-left: 3px solid var(--warning); }

.island--info .island-icon { color: var(--primary); }
.island--info { border-left: 3px solid var(--primary); }

/* Enter/leave transitions */
.island-enter-enter-active {
  animation: islandIn 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

.island-enter-leave-active {
  animation: islandOut 0.3s ease forwards;
}

@keyframes islandIn {
  from {
    opacity: 0;
    transform: translateX(-50%) translateY(-20px) scale(0.9);
  }
  to {
    opacity: 1;
    transform: translateX(-50%) translateY(0) scale(1);
  }
}

@keyframes islandOut {
  from {
    opacity: 1;
    transform: translateX(-50%) translateY(0) scale(1);
  }
  to {
    opacity: 0;
    transform: translateX(-50%) translateY(-20px) scale(0.9);
  }
}
</style>
