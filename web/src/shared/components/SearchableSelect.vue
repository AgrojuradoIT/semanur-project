<template>
  <div class="searchable-dropdown" ref="dropdownRef">
    <div
      class="dropdown-trigger"
      :class="{ 'dropdown-open': isOpen, 'dropdown-has-value': !!selectedLabel }"
      @click="toggle"
    >
      <span>{{ selectedLabel || placeholder || 'Seleccionar...' }}</span>
      <span class="material-icons-round dropdown-arrow">expand_more</span>
    </div>
    <div v-if="isOpen" class="dropdown-menu">
      <div class="dropdown-search">
        <span class="material-icons-round">search</span>
        <input
          v-model="search"
          class="input"
          type="text"
          placeholder="Buscar..."
          ref="searchInput"
          @keydown="onKeydown"
        />
      </div>
      <div class="dropdown-list">
        <div
          v-for="(item, idx) in filteredItems"
          :key="getItemKey(item)"
          class="dropdown-item"
          :class="{ 'dropdown-item-active': searchIndex === idx }"
          @click="selectItem(item)"
        >
          <slot name="option" :item="item">{{ getItemLabel(item) }}</slot>
        </div>
        <div v-if="filteredItems.length === 0 && !allowFreeText" class="dropdown-empty">
          {{ emptyText || 'No se encontraron resultados' }}
        </div>
        <div
          v-if="allowFreeText && search.trim() && !filteredItems.some(i => getItemLabel(i).toLowerCase() === search.trim().toLowerCase())"
          class="dropdown-item"
          :class="{ 'dropdown-item-active': searchIndex === -1 }"
          @click="selectFreeText(search.trim())"
        >
          <span style="font-style: italic; opacity: 0.8;">Usar texto: </span> <b>{{ search.trim() }}</b>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue';

const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  items: { type: Array, required: true },
  labelFn: { type: Function, default: null },
  valueFn: { type: Function, default: null },
  keyFn: { type: Function, default: null },
  placeholder: { type: String, default: '' },
  emptyText: { type: String, default: 'No se encontraron resultados' },
  allowFreeText: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue', 'select']);

const search = ref('');
const isOpen = ref(false);
const searchIndex = ref(-1);
const dropdownRef = ref(null);
const searchInput = ref(null);

const filteredItems = computed(() => {
  const q = search.value.trim().toLowerCase();
  if (!q) return props.items;
  return props.items.filter((item) =>
    getItemLabel(item).toLowerCase().includes(q),
  );
});

const selectedLabel = computed(() => {
  if (!props.modelValue && props.modelValue !== 0) return '';
  const item = props.items.find((i) => String(getItemValue(i)) === String(props.modelValue));
  if (item) return getItemLabel(item);
  if (props.allowFreeText) return props.modelValue;
  return '';
});

function getItemLabel(item) {
  if (props.labelFn) return props.labelFn(item);
  return item.label ?? item.name ?? item.nombre ?? item.text ?? String(item);
}

function getItemValue(item) {
  if (props.valueFn) return props.valueFn(item);
  return item.value ?? item.id ?? item;
}

function getItemKey(item) {
  if (props.keyFn) return props.keyFn(item);
  return item.id ?? getItemValue(item);
}

function toggle() {
  isOpen.value = !isOpen.value;
  searchIndex.value = -1;
  if (isOpen.value) {
    search.value = '';
    nextTick(() => searchInput.value?.focus());
  }
}

function selectItem(item) {
  emit('update:modelValue', getItemValue(item));
  emit('select', item);
  search.value = '';
  isOpen.value = false;
  searchIndex.value = -1;
}

function selectFreeText(text) {
  emit('update:modelValue', text);
  emit('select', { isFreeText: true, text });
  search.value = '';
  isOpen.value = false;
  searchIndex.value = -1;
}

function onKeydown(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault();
    searchIndex.value = Math.min(searchIndex.value + 1, filteredItems.value.length - 1);
  } else if (e.key === 'ArrowUp') {
    e.preventDefault();
    searchIndex.value = Math.max(searchIndex.value - 1, 0);
  } else if (e.key === 'Enter') {
    e.preventDefault();
    if (searchIndex.value >= 0 && filteredItems.value[searchIndex.value]) {
      selectItem(filteredItems.value[searchIndex.value]);
    } else if (props.allowFreeText && search.value.trim()) {
      selectFreeText(search.value.trim());
    }
  } else if (e.key === 'Escape') {
    isOpen.value = false;
  }
}

function handleClickOutside(e) {
  if (dropdownRef.value && !dropdownRef.value.contains(e.target)) {
    if (isOpen.value && props.allowFreeText && search.value.trim() && searchIndex.value === -1) {
      selectFreeText(search.value.trim());
    }
    isOpen.value = false;
  }
}

onMounted(() => document.addEventListener('click', handleClickOutside));
onUnmounted(() => document.removeEventListener('click', handleClickOutside));
</script>

<style scoped>
.searchable-dropdown {
  position: relative;
  width: 100%;
}

.dropdown-trigger {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  background: var(--bg-dark);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-sm);
  color: var(--text-main);
  cursor: pointer;
  transition: border-color var(--transition-fast);
  font-size: 0.9rem;
  min-height: 42px;
}

.dropdown-trigger:hover {
  border-color: var(--primary);
}

.dropdown-trigger.dropdown-open {
  border-color: var(--primary);
  border-bottom-left-radius: 0;
  border-bottom-right-radius: 0;
}

.dropdown-arrow {
  font-size: 20px;
  color: var(--text-gray);
  transition: transform 0.2s;
  flex-shrink: 0;
}

.dropdown-open .dropdown-arrow {
  transform: rotate(180deg);
}

.dropdown-menu {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  z-index: 1000;
  background: var(--bg-dark);
  border: 1px solid var(--primary);
  border-top: none;
  border-bottom-left-radius: var(--radius-sm);
  border-bottom-right-radius: var(--radius-sm);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  max-height: 280px;
  display: flex;
  flex-direction: column;
}

.dropdown-search {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  border-bottom: 1px solid var(--surface-2);
  position: sticky;
  top: 0;
  background: var(--bg-dark);
}

.dropdown-search .material-icons-round {
  font-size: 18px;
  color: var(--text-gray);
  flex-shrink: 0;
}

.dropdown-search .input {
  flex: 1;
  border: none;
  background: transparent;
  padding: 4px 0;
  font-size: 0.9rem;
  color: var(--text-main);
}

.dropdown-search .input:focus {
  outline: none;
  box-shadow: none;
  border-color: transparent;
}

.dropdown-search .input::placeholder {
  color: var(--text-muted);
}

.dropdown-list {
  overflow-y: auto;
  flex: 1;
}

.dropdown-item {
  padding: 10px 14px;
  cursor: pointer;
  font-size: 0.9rem;
  color: var(--text-main);
  transition: background 0.15s, color 0.15s;
}

.dropdown-item:hover,
.dropdown-item.dropdown-item-active {
  background: var(--primary-10);
  color: var(--primary);
}

.dropdown-empty {
  padding: 16px;
  text-align: center;
  color: var(--text-gray);
  font-size: 0.85rem;
}
</style>
