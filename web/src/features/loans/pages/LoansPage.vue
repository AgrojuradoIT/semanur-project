<template>
  <div class="table-container">
    <div class="table-header">
      <div style="display: flex; align-items: center; gap: var(--sp-md); flex-wrap: wrap">
        <h3 class="table-title">PRESTAMOS DE HERRAMIENTAS</h3>
        <div class="filter-chips">
          <button
            v-for="chip in loanFilters"
            :key="chip.value"
            class="chip"
            :class="{ active: selectedFilter === chip.value }"
            @click="selectedFilter = chip.value"
          >
            {{ chip.label }}
          </button>
        </div>
      </div>

      <div class="table-actions">
        <div class="table-search">
          <span class="material-icons-round">search</span>
          <input v-model="search" type="text" placeholder="Buscar..." />
        </div>
        <button class="btn btn-primary btn-sm" @click="openCreateModal">
          <span class="material-icons-round" style="font-size: 18px">add_circle</span>
          NUEVO PRESTAMO
        </button>
      </div>
    </div>

    <div class="table-scroll">
      <table v-if="!loading && !error && filteredLoans.length > 0">
        <thead>
          <tr>
            <th>HERRAMIENTA</th>
            <th>MECANICO</th>
            <th>CANT.</th>
            <th>FECHA PRESTAMO</th>
            <th>FECHA DEVOLUCION</th>
            <th>ESTADO</th>
            <th>NOTAS</th>
            <th>ACCIONES</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="loan in filteredLoans" :key="loanId(loan)">
            <td style="color: var(--text-main); font-weight: 600">{{ loanProduct(loan) }}</td>
            <td>{{ loanMechanic(loan) }}</td>
            <td style="text-align: center">{{ loanQuantity(loan) }}</td>
            <td>{{ formatDate(loan.fecha_prestamo || loan.created_at) }}</td>
            <td>{{ formatDate(loan.fecha_devolucion) }}</td>
            <td>
              <span class="badge" :class="loanStatusClass(loan.estado)">{{ loan.estado || '—' }}</span>
            </td>
            <td style="max-width: 220px; white-space: normal">{{ loan.notas || '—' }}</td>
            <td>
              <div class="table-row-actions" v-if="loan.estado === 'prestado'">
                <button class="action-btn" title="Devolver" @click="openReturnModal(loan)">
                  <span class="material-icons-round">assignment_return</span>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <div v-else-if="loading" class="page-loading">
        <span class="spinner"></span>
        Cargando prestamos...
      </div>

      <div v-else-if="error" class="empty-state">
        <span class="material-icons-round">cloud_off</span>
        <p>{{ error }}</p>
      </div>

      <div v-else class="empty-state">
        <span class="material-icons-round">handyman</span>
        <p>No se encontraron prestamos</p>
      </div>
    </div>

    <div class="table-footer">
      Mostrando {{ filteredLoans.length }} prestamo{{ filteredLoans.length === 1 ? '' : 's' }}
    </div>
  </div>

  <div v-if="showCreate" class="modal-overlay" @click.self="closeCreateModal">
    <div class="modal modal-wide">
      <div class="modal-header">
        <h3>NUEVO PRESTAMO</h3>
        <button class="modal-close" @click="closeCreateModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>
      <div class="modal-body">
        <form class="form-grid" @submit.prevent="submitCreate">
          <div class="input-group full-width">
            <label>Herramienta / Producto</label>
            <SearchableSelect
              v-model="createForm.producto_id"
              :items="availableProducts"
              :label-fn="productLabel"
              :value-fn="productId"
              placeholder="Seleccionar producto..."
              empty-text="No se encontraron productos"
            />
          </div>

          <div class="input-group">
            <label>Mecanico / Responsable</label>
            <SearchableSelect
              v-model="createForm.mecanico_id"
              :items="employees"
              :label-fn="(e) => e.name || ''"
              placeholder="Seleccionar responsable..."
              empty-text="No se encontraron responsables"
            />
          </div>

          <div class="input-group">
            <label>Cantidad</label>
            <input v-model.number="createForm.prestamo_cantidad" class="input" type="number" min="1" required />
          </div>

          <div class="input-group full-width">
            <label>Notas</label>
            <textarea v-model="createForm.notas" class="input" rows="3" placeholder="Motivo del prestamo..."></textarea>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" @click="closeCreateModal">Cancelar</button>
        <button class="btn btn-primary" :disabled="savingCreate" @click="submitCreate">
          <span class="material-icons-round" style="font-size: 18px">save</span>
          {{ savingCreate ? 'REGISTRANDO...' : 'REGISTRAR PRESTAMO' }}
        </button>
      </div>
    </div>
  </div>

  <div v-if="showReturn" class="modal-overlay" @click.self="closeReturnModal">
    <div class="modal">
      <div class="modal-header">
        <h3>DEVOLVER HERRAMIENTA</h3>
        <button class="modal-close" @click="closeReturnModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>
      <div class="modal-body">
        <div style="margin-bottom: var(--sp-md); padding: var(--sp-md); background: var(--bg-dark); border-radius: var(--radius-md)">
          <p>
            <strong style="color: var(--primary)">{{ loanProduct(selectedLoan) }}</strong>
          </p>
          <p style="color: var(--text-gray); font-size: 0.85rem">
            Prestado a: {{ loanMechanic(selectedLoan) }} | Cantidad: {{ loanQuantity(selectedLoan) }}
          </p>
        </div>

        <form class="form-grid" @submit.prevent="submitReturn">
          <div class="input-group full-width">
            <label>Estado de devolucion</label>
            <select v-model="returnForm.estado" class="input" required>
              <option value="devuelto">Devuelto (en buen estado)</option>
              <option value="dañado">Dañado</option>
              <option value="perdido">Perdido</option>
            </select>
          </div>

          <div class="input-group full-width">
            <label>Notas de devolucion</label>
            <textarea v-model="returnForm.notas" class="input" rows="3" placeholder="Observaciones..."></textarea>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" @click="closeReturnModal">Cancelar</button>
        <button class="btn btn-primary" :disabled="savingReturn" @click="submitReturn">
          <span class="material-icons-round" style="font-size: 18px">assignment_return</span>
          {{ savingReturn ? 'PROCESANDO...' : 'PROCESAR DEVOLUCION' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { formatDateCO } from '../../../shared/utils/formatters';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import {
  loanId as mapLoanId,
  loanMechanicName,
  loanProductName,
  loanQuantity as mapLoanQuantity,
} from '../../../shared/adapters/loanAdapter';
import {
  productId as mapProductId,
  productLabelWithStock,
  productName as mapProductName,
  productStock as mapProductStock,
} from '../../../shared/adapters/productAdapter';
import {
  fetchLoans,
  createLoan,
  returnLoan,
} from '../api/loansService';
import { useCatalogsStore } from '../../../shared/stores/catalogs';
import SearchableSelect from '../../../shared/components/SearchableSelect.vue';

const { loading, error, run, clearError } = useAsyncState('');
const loans = ref([]);
const products = ref([]);
const employees = ref([]);

const search = ref('');
const selectedFilter = ref('all');

const loanFilters = [
  { value: 'all', label: 'Todos' },
  { value: 'prestado', label: 'Prestados' },
  { value: 'devuelto', label: 'Devueltos' },
];

const showCreate = ref(false);
const savingCreate = ref(false);
const createForm = ref({
  producto_id: '',
  mecanico_id: '',
  prestamo_cantidad: 1,
  notas: '',
});

const showReturn = ref(false);
const savingReturn = ref(false);
const selectedLoan = ref(null);
const returnForm = ref({
  estado: 'devuelto',
  notas: '',
});

onMounted(async () => {
  await loadData();
});

async function loadData() {
  try {
    await run(async () => {
    const catalogsStore = useCatalogsStore();
    await catalogsStore.fetchEssentialCatalogs();

    const [loanData] = await Promise.all([
      fetchLoans(),
    ]);

    loans.value = loanData;
    products.value = catalogsStore.productos;
    employees.value = catalogsStore.empleados;
    }, 'Error al cargar prestamos');
  } catch {
    // handled by composable
  }
}

const availableProducts = computed(() =>
  products.value.filter((p) => Number(productStock(p)) > 0),
);

const filteredLoans = computed(() => {
  const q = search.value.trim().toLowerCase();
  return loans.value.filter((loan) => {
    const matchesFilter =
      selectedFilter.value === 'all' || loan.estado === selectedFilter.value;

    const matchesSearch =
      !q ||
      loanProduct(loan).toLowerCase().includes(q) ||
      loanMechanic(loan).toLowerCase().includes(q);

    return matchesFilter && matchesSearch;
  });
});

function openCreateModal() {
  showCreate.value = true;
}

function closeCreateModal() {
  showCreate.value = false;
  createForm.value = {
    producto_id: '',
    mecanico_id: '',
    prestamo_cantidad: 1,
    notas: '',
  };
}

async function submitCreate() {
  if (savingCreate.value) return;

  if (
    !createForm.value.producto_id ||
    !createForm.value.mecanico_id ||
    !createForm.value.prestamo_cantidad
  ) {
    return;
  }

  savingCreate.value = true;
  clearError();

  try {
    await createLoan({
      producto_id: Number(createForm.value.producto_id),
      mecanico_id: Number(createForm.value.mecanico_id),
      prestamo_cantidad: Number(createForm.value.prestamo_cantidad),
      notas: createForm.value.notas?.trim() || null,
    });

    closeCreateModal();
    await loadData();
  } catch (e) {
    error.value = e?.response?.data?.message || e?.message || 'Error al registrar prestamo';
  } finally {
    savingCreate.value = false;
  }
}

function openReturnModal(loan) {
  selectedLoan.value = loan;
  returnForm.value = {
    estado: 'devuelto',
    notas: '',
  };
  showReturn.value = true;
}

function closeReturnModal() {
  showReturn.value = false;
  selectedLoan.value = null;
  returnForm.value = {
    estado: 'devuelto',
    notas: '',
  };
}

async function submitReturn() {
  if (savingReturn.value || !selectedLoan.value) return;

  savingReturn.value = true;
  clearError();

  try {
    await returnLoan(loanId(selectedLoan.value), {
      estado: returnForm.value.estado,
      notas: returnForm.value.notas?.trim() || null,
    });

    closeReturnModal();
    await loadData();
  } catch (e) {
    error.value = e?.response?.data?.message || e?.message || 'Error al procesar devolucion';
  } finally {
    savingReturn.value = false;
  }
}

function loanId(loan) {
  return mapLoanId(loan);
}

function loanProduct(loan) {
  return loanProductName(loan);
}

function loanMechanic(loan) {
  return loanMechanicName(loan);
}

function loanQuantity(loan) {
  return mapLoanQuantity(loan);
}

function formatDate(value) {
  return formatDateCO(value);
}

function loanStatusClass(status) {
  if (status === 'prestado') return 'badge-warning';
  if (status === 'devuelto') return 'badge-success';
  if (status === 'dañado' || status === 'perdido') return 'badge-danger';
  return 'badge-neutral';
}

function productId(product) {
  return mapProductId(product);
}

function productName(product) {
  return mapProductName(product);
}

function productStock(product) {
  return mapProductStock(product);
}

function productLabel(product) {
  return productLabelWithStock(product);
}
</script>

