<template>
  <div ref="rootEl" class="ss" :class="{ 'ss--open': isOpen, 'ss--disabled': disabled }">
    <button
      type="button"
      class="ss__control"
      ref="controlEl"
      :disabled="disabled"
      @click="toggle"
    >
      <div class="ss__value">
        <span v-if="selectedOption" class="ss__value-text">{{ selectedOption.label }}</span>
        <span v-else class="ss__placeholder">{{ placeholder }}</span>
        <span v-if="selectedOption?.description" class="ss__value-sub">{{ selectedOption.description }}</span>
      </div>

      <div class="ss__icons">
        <button
          v-if="clearable && modelValue !== '' && modelValue !== null && modelValue !== undefined"
          type="button"
          class="ss__icon-btn"
          :disabled="disabled"
          aria-label="Limpiar"
          @click.stop="clear"
        >
          <span class="material-icons-round">close</span>
        </button>
        <span class="material-icons-round ss__chevron">expand_more</span>
      </div>
    </button>

    <Teleport to="body">
      <div
        v-if="isOpen"
        ref="dropdownEl"
        class="ss__dropdown"
        :style="dropdownStyle"
        @click.stop
      >
        <div class="ss__search">
          <span class="material-icons-round ss__search-icon">search</span>
          <input
            ref="searchEl"
            v-model="search"
            type="text"
            class="ss__search-input"
            :placeholder="searchPlaceholder"
          />
        </div>

        <div class="ss__list">
          <button
            v-for="opt in visibleOptions"
            :key="String(opt.value)"
            type="button"
            class="ss__option"
            :class="{ 'ss__option--selected': isSelected(opt) }"
            @click="select(opt)"
          >
            <div class="ss__option-main">
              <div class="ss__option-label">{{ opt.label }}</div>
              <div v-if="opt.description" class="ss__option-desc">{{ opt.description }}</div>
            </div>
            <span v-if="isSelected(opt)" class="material-icons-round ss__check">check</span>
          </button>

          <div v-if="visibleOptions.length === 0" class="ss__empty">
            No hay resultados
          </div>
        </div>

        <div v-if="showHint" class="ss__hint">
          Mostrando {{ visibleOptions.length }} de {{ options.length }}. Usa el buscador para filtrar.
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';

const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  options: { type: Array, default: () => [] }, // [{ value, label, description?, keywords? }]
  placeholder: { type: String, default: 'Seleccionar...' },
  searchPlaceholder: { type: String, default: 'Buscar...' },
  disabled: { type: Boolean, default: false },
  clearable: { type: Boolean, default: false },
  maxVisibleWithoutSearch: { type: Number, default: 180 },
});

const emit = defineEmits(['update:modelValue', 'change']);

const rootEl = ref(null);
const controlEl = ref(null);
const dropdownEl = ref(null);
const searchEl = ref(null);
const isOpen = ref(false);
const search = ref('');
const dropdownStyle = ref({});

const selectedOption = computed(() => {
  const mv = props.modelValue;
  return props.options.find((o) => String(o.value) === String(mv)) || null;
});

const filteredOptions = computed(() => {
  const term = search.value.trim().toLowerCase();
  if (!term) return props.options;

  return props.options.filter((opt) => {
    const haystack = String(opt.keywords ?? `${opt.label} ${opt.description ?? ''}`).toLowerCase();
    return haystack.includes(term);
  });
});

const showHint = computed(() => {
  return !search.value.trim() && props.options.length > props.maxVisibleWithoutSearch;
});

const visibleOptions = computed(() => {
  if (!search.value.trim() && props.options.length > props.maxVisibleWithoutSearch) {
    return props.options.slice(0, props.maxVisibleWithoutSearch);
  }
  return filteredOptions.value;
});

function isSelected(opt) {
  return String(opt.value) === String(props.modelValue);
}

function open() {
  if (props.disabled) return;
  isOpen.value = true;
  nextTick(async () => {
    await updatePosition();
    searchEl.value?.focus?.();
  });
}

function close() {
  isOpen.value = false;
  search.value = '';
}

function toggle() {
  if (isOpen.value) close();
  else open();
}

function select(opt) {
  emit('update:modelValue', opt.value);
  emit('change', opt.value);
  close();
}

function clear() {
  emit('update:modelValue', '');
  emit('change', '');
  close();
}

function onDocumentPointerDown(e) {
  const el = rootEl.value;
  const dd = dropdownEl.value;
  if (!el) return;
  if (!el.contains(e.target) && !(dd && dd.contains(e.target))) {
    close();
  }
}

function onDocumentKeyDown(e) {
  if (!isOpen.value) return;
  if (e.key === 'Escape') close();
}

async function updatePosition() {
  if (!isOpen.value) return;
  await nextTick();

  const ctrl = controlEl.value;
  const dd = dropdownEl.value;
  if (!ctrl || !dd) return;

  const rect = ctrl.getBoundingClientRect();
  const ddHeight = dd.offsetHeight || 340;
  const gap = 8;
  const viewportPadding = 8;

  const spaceBelow = window.innerHeight - rect.bottom;
  const spaceAbove = rect.top;

  const openUp = spaceBelow < ddHeight && spaceAbove > spaceBelow;

  let top = openUp ? (rect.top - ddHeight - gap) : (rect.bottom + gap);
  top = Math.max(viewportPadding, Math.min(top, window.innerHeight - ddHeight - viewportPadding));

  let left = rect.left;
  let width = rect.width;

  if (left < viewportPadding) left = viewportPadding;
  if (left + width > window.innerWidth - viewportPadding) {
    width = Math.max(240, window.innerWidth - left - viewportPadding);
  }

  dropdownStyle.value = {
    position: 'fixed',
    top: `${top}px`,
    left: `${left}px`,
    width: `${width}px`,
    zIndex: 1100,
  };
}

onMounted(() => {
  document.addEventListener('pointerdown', onDocumentPointerDown);
  document.addEventListener('keydown', onDocumentKeyDown);
});

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', onDocumentPointerDown);
  document.removeEventListener('keydown', onDocumentKeyDown);
});

watch(
  () => props.disabled,
  (v) => {
    if (v) close();
  },
);

watch(isOpen, (v) => {
  if (v) {
    window.addEventListener('resize', updatePosition);
    window.addEventListener('scroll', updatePosition, true);
    updatePosition();
  } else {
    window.removeEventListener('resize', updatePosition);
    window.removeEventListener('scroll', updatePosition, true);
  }
});
</script>

<style scoped>
.ss {
  position: relative;
  width: 100%;
}

.ss__control {
  width: 100%;
  text-align: left;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;

  padding: 10px 14px;
  background: var(--bg-dark);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-sm);
  color: var(--text-main);
  outline: none;
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
}

.ss--open .ss__control {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px rgba(255, 214, 0, 0.08);
}

.ss--disabled .ss__control {
  opacity: 0.6;
  cursor: not-allowed;
}

.ss__value {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.ss__value-text {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--text-main);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.ss__value-sub {
  font-size: 0.78rem;
  color: var(--text-gray);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.ss__placeholder {
  font-size: 0.9rem;
  color: var(--text-muted);
  font-weight: 600;
}

.ss__icons {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}

.ss__icon-btn {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: none;
  background: rgba(255, 255, 255, 0.06);
  color: var(--text-gray);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background var(--transition-fast), color var(--transition-fast);
}

.ss__icon-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: var(--text-main);
}

.ss__icon-btn .material-icons-round {
  font-size: 18px;
}

.ss__chevron {
  font-size: 20px;
  color: var(--text-gray);
  transition: transform var(--transition-fast);
}

.ss--open .ss__chevron {
  transform: rotate(180deg);
}

.ss__dropdown {
  /* Se posiciona dinámicamente con style (fixed) */
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  overflow: hidden;
}

.ss__search {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.03), transparent);
}

.ss__search-icon {
  font-size: 18px;
  color: var(--text-gray);
}

.ss__search-input {
  width: 100%;
  border: 1px solid var(--surface-2);
  background: var(--bg-dark);
  color: var(--text-main);
  border-radius: var(--radius-sm);
  padding: 8px 10px;
  outline: none;
  font-size: 0.88rem;
}

.ss__search-input:focus {
  border-color: var(--primary);
}

.ss__list {
  max-height: 280px;
  overflow: auto;
}

.ss__option {
  width: 100%;
  border: none;
  background: transparent;
  color: var(--text-main);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 10px 12px;
  cursor: pointer;
  transition: background var(--transition-fast);
  border-bottom: 1px solid rgba(255, 255, 255, 0.04);
}

.ss__option:hover {
  background: rgba(255, 255, 255, 0.04);
}

.ss__option--selected {
  background: var(--primary-10);
}

.ss__option-main {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.ss__option-label {
  font-size: 0.88rem;
  font-weight: 650;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.ss__option-desc {
  font-size: 0.76rem;
  color: var(--text-gray);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.ss__check {
  font-size: 18px;
  color: var(--primary);
  flex-shrink: 0;
}

.ss__empty {
  padding: 14px 12px;
  color: var(--text-gray);
  font-size: 0.85rem;
}

.ss__hint {
  padding: 10px 12px;
  font-size: 0.76rem;
  color: var(--text-muted);
  border-top: 1px solid rgba(255, 255, 255, 0.06);
  background: rgba(0, 0, 0, 0.15);
}
</style>

