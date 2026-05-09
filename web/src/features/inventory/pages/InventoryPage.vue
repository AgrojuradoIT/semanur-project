<template>
  <div class="table-container">
    <div class="table-header" style="flex-wrap: wrap; gap: 16px">
      <div style="display: flex; align-items: center; gap: var(--sp-md); flex-wrap: wrap">
        <h3 class="table-title">GESTION DE INVENTARIO</h3>
        <div class="filter-chips">
          <button
            v-for="chip in categoryChips"
            :key="chip"
            class="chip"
            :class="{ active: selectedCategory === chip }"
            @click="selectedCategory = chip"
          >
            {{ chip }}
          </button>
        </div>
      </div>

      <div class="table-actions" style="flex-wrap: wrap">
        <div class="table-search">
          <span class="material-icons-round">search</span>
          <input
            v-model="search"
            type="text"
            placeholder="Buscar por nombre o SKU..."
            @keyup.enter="onSearchEnter"
          />
        </div>
        <button v-if="canCreate" class="btn btn-secondary btn-sm" @click="openCsvModal">
          <span class="material-icons-round" style="font-size: 18px">upload_file</span>
          IMPORTAR CSV
        </button>
        <button v-if="canCreate" class="btn btn-secondary btn-sm" @click="openMovementModal">
          <span class="material-icons-round" style="font-size: 18px">swap_horiz</span>
          MOVIMIENTO
        </button>
        <button v-if="canCreate" class="btn btn-primary btn-sm" @click="openProductModal()">
          <span class="material-icons-round" style="font-size: 18px">add_circle</span>
          NUEVO PRODUCTO
        </button>
      </div>
    </div>

    <!-- Métricas -->
    <div class="metrics-row" v-if="metrics">
      <div class="metric-card">
        <span class="material-icons-round metric-icon">inventory_2</span>
        <div class="metric-info">
          <span class="metric-value">{{ metrics.total_products }}</span>
          <span class="metric-label">Total Productos</span>
        </div>
      </div>
      <div class="metric-card" :class="{ 'metric-danger': metrics.low_stock > 0 }">
        <span class="material-icons-round metric-icon">warning</span>
        <div class="metric-info">
          <span class="metric-value">{{ metrics.low_stock }}</span>
          <span class="metric-label">Stock Bajo Alerta</span>
        </div>
      </div>
      <div class="metric-card">
        <span class="material-icons-round metric-icon">payments</span>
        <div class="metric-info">
          <span class="metric-value">{{ formatCurrencyCO(metrics.total_value) }}</span>
          <span class="metric-label">Valor Inventario</span>
        </div>
      </div>
    </div>

    <div class="table-scroll">
      <table v-if="!loading && !error && filteredProducts.length > 0">
        <thead>
          <tr>
            <th>SKU</th>
            <th>NOMBRE</th>
            <th>CATEGORIA</th>
            <th>STOCK</th>
            <th>UNIDAD</th>
            <th>ALERTA MIN.</th>
            <th>PRECIO</th>
            <th>UBICACION</th>
          </tr>
        </thead>
        <tbody>
          <tr 
            v-for="product in filteredProducts" 
            :key="normalizeId(product)"
            style="cursor: pointer"
            @click="goToProduct(product)"
            class="table-row-hover"
          >
            <td style="color: var(--text-main); font-weight: 600">
              {{ normalizeSku(product) }}
              <div v-if="normalizeRef(product)" style="font-size: 0.75rem; color: var(--text-gray); font-weight: 400;">
                Ref: {{ normalizeRef(product) }}
              </div>
            </td>
            <td style="color: var(--text-main)">{{ normalizeName(product) }}</td>
            <td>
              <span class="badge badge-info">{{ normalizeCategory(product) }}</span>
            </td>
            <td>
              <span class="badge" :class="stockBadgeClass(product)">
                {{ normalizeStock(product) }}
              </span>
            </td>
            <td>{{ normalizeUnit(product) }}</td>
            <td>{{ normalizeAlert(product) }}</td>
            <td>{{ normalizePrice(product) }}</td>
            <td>{{ normalizeLocation(product) }}</td>
          </tr>
        </tbody>
      </table>

      <div v-else-if="loading" class="page-loading">
        <span class="spinner"></span>
        Cargando inventario...
      </div>

      <div v-else-if="error" class="empty-state">
        <span class="material-icons-round">cloud_off</span>
        <p>{{ error }}</p>
      </div>

      <div v-else class="empty-state">
        <span class="material-icons-round">category</span>
        <p>No se encontraron productos para los filtros aplicados</p>
      </div>
    </div>

    <div class="table-footer">
      <span>Página {{ currentPage }} de {{ totalPages }} — {{ totalItems }} producto{{ totalItems === 1 ? '' : 's' }}</span>
      <div class="pagination-controls">
        <button class="btn btn-secondary btn-sm" :disabled="currentPage <= 1" @click="goPage(currentPage - 1)">
          <span class="material-icons-round" style="font-size: 16px">chevron_left</span>
        </button>
        <button class="btn btn-secondary btn-sm" :disabled="currentPage >= totalPages" @click="goPage(currentPage + 1)">
          <span class="material-icons-round" style="font-size: 16px">chevron_right</span>
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Nuevo Producto -->
  <div v-if="showProductModal" class="modal-overlay" @click.self="closeProductModal">
    <div class="modal modal-wide">
      <div class="modal-header">
        <h3>{{ editingProductId ? 'EDITAR PRODUCTO' : 'NUEVO PRODUCTO' }}</h3>
        <button class="modal-close" @click="closeProductModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>
      <div class="modal-body">
        <form id="productForm" class="form-grid" @submit.prevent="submitProduct">
          <div class="input-group">
            <label>Código Interno (SKU)</label>
            <input v-model="productForm.producto_sku" type="text" class="input" required />
          </div>
          <div class="input-group">
            <label>Referencia de Fábrica (Opcional)</label>
            <input v-model="productForm.referencia_fabrica" type="text" class="input" placeholder="Ej. ANCO3122B" />
          </div>
          <div class="input-group">
            <label>Nombre del Producto</label>
            <input v-model="productForm.producto_nombre" type="text" class="input" required />
          </div>
          <div class="input-group">
            <label>Categoría</label>
            <select v-model="productForm.categoria_id" class="input" required>
              <option value="">Seleccionar...</option>
              <option v-for="cat in categories" :key="cat.categoria_id" :value="cat.categoria_id">
                {{ cat.nombre }}
              </option>
            </select>
          </div>
          <div class="input-group">
            <label>Unidad de Medida</label>
            <select v-model="productForm.producto_unidad_medida" class="input" required>
              <option value="unidad">Unidad</option>
              <option value="litro">Litro</option>
              <option value="galon">Galón</option>
              <option value="metro">Metro</option>
              <option value="kilo">Kilo</option>
            </select>
          </div>
          <div class="input-group">
            <label>Alerta Stock Mínimo</label>
            <input v-model="productForm.producto_alerta_stock_minimo" type="number" step="0.01" class="input" required />
          </div>
          <div class="input-group">
            <label>Precio de Costo</label>
            <input v-model="productForm.producto_precio_costo" type="number" step="0.01" class="input" />
          </div>
          <div class="input-group full-width">
            <label>Ubicación (Estante/Bodega)</label>
            <input v-model="productForm.producto_ubicacion" type="text" class="input" />
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" type="button" @click="closeProductModal">Cancelar</button>
        <button type="submit" form="productForm" class="btn btn-primary" :disabled="saving">
          <span class="material-icons-round" style="font-size: 18px">save</span>
          {{ saving ? 'GUARDANDO...' : (editingProductId ? 'ACTUALIZAR' : 'GUARDAR') }}
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Nuevo Movimiento -->
  <div v-if="showMovementModal" class="modal-overlay" @click.self="closeMovementModal">
    <div class="modal" style="height: 540px;">
      <div class="modal-header">
        <h3>REGISTRAR MOVIMIENTO</h3>
        <button class="modal-close" @click="closeMovementModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>
      <div class="modal-body modal-body--overflow-visible">
        <form id="movementForm" class="form-grid" style="grid-template-columns: 1fr;" @submit.prevent="submitMovement">
          <div class="input-group">
            <label>Tipo de Transacción</label>
            <div class="transaction-toggles">
              <button
                type="button"
                class="toggle-btn"
                :class="{ active: movementForm.transaccion_tipo === 'ingreso', 'is-ingreso': movementForm.transaccion_tipo === 'ingreso' }"
                @click="movementForm.transaccion_tipo = 'ingreso'"
              >
                <span class="material-icons-round">add_circle</span>
                Ingreso (+)
              </button>
              <button
                type="button"
                class="toggle-btn"
                :class="{ active: movementForm.transaccion_tipo === 'salida', 'is-salida': movementForm.transaccion_tipo === 'salida' }"
                @click="movementForm.transaccion_tipo = 'salida'"
              >
                <span class="material-icons-round">remove_circle</span>
                Salida (-)
              </button>
            </div>
          </div>
          <div class="input-group">
            <label>Producto</label>
            <SearchableSelect
              v-model="movementForm.producto_id"
              :options="productOptionsForMovement"
              placeholder="Seleccionar..."
              search-placeholder="Buscar por SKU, nombre o referencia..."
              :clearable="true"
            />
          </div>
          <div class="input-group" v-if="movementForm.transaccion_tipo === 'salida'">
            <label>Entregado a (Empleado)</label>
            <SearchableSelect
              v-model="movementForm.transaccion_referencia_id"
              :options="empleadoOptionsForMovement"
              placeholder="Seleccionar empleado..."
              search-placeholder="Buscar por nombre o cargo..."
              :clearable="true"
            />
          </div>
          <div class="input-group">
            <label>Cantidad</label>
            <input v-model="movementForm.transaccion_cantidad" type="number" step="0.01" min="0.01" class="input" required />
          </div>
          <div class="input-group">
            <label>Motivo / Observaciones (Opcional)</label>
            <textarea v-model="movementForm.transaccion_motivo" class="input" rows="2" placeholder="Ej. Retiro para orden de trabajo..."></textarea>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" type="button" @click="closeMovementModal">Cancelar</button>
        <button type="submit" form="movementForm" class="btn btn-primary" :disabled="saving">
          <span class="material-icons-round" style="font-size: 18px">save</span>
          {{ saving ? 'REGISTRANDO...' : 'REGISTRAR' }}
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Importar CSV -->
  <div v-if="showCsvModal" class="modal-overlay" @click.self="closeCsvModal">
    <div class="modal" style="position: relative;">
      <!-- Loading overlay -->
      <div v-if="saving" class="import-loading-overlay">
        <div class="import-loading-spinner"></div>
        <p class="import-loading-text">{{ importStage || 'Procesando...' }}</p>
        <div class="import-progress-bar">
          <div class="import-progress-fill" :style="{ width: importProgress + '%' }"></div>
        </div>
        <p class="import-loading-pct">{{ importProgress }}%</p>
      </div>
      <div class="modal-header">
        <h3>IMPORTAR COMPRAS DESDE SIIGO</h3>
        <button class="modal-close" @click="closeCsvModal">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>
      <div class="modal-body">
        <p style="margin-bottom: 12px; color: var(--text-secondary); font-size: 0.9rem;">
          Sube un archivo de Siigo con columnas: <br/>
          <strong>Código | Nombre | Referencia fábrica | Categoría | Saldo cantidades</strong>
        </p>
        <div class="input-group" style="margin-bottom: 12px;">
          <label>Categoría por defecto (si el CSV no trae categoria_id)</label>
          <select v-model="csvCategoriaId" class="input">
            <option value="">Seleccionar...</option>
            <option v-for="cat in categories" :key="cat.categoria_id" :value="cat.categoria_id">
              {{ cat.nombre }}
            </option>
          </select>
        </div>
        <div class="input-group">
          <input type="file" accept=".csv,.xlsx,.xls" class="input" @change="onFileChange" />
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" :disabled="saving" @click="closeCsvModal">Cancelar</button>
        <button class="btn btn-primary" :disabled="saving || !csvFile" @click="submitCsv">
          <span class="material-icons-round" style="font-size: 18px">upload</span>
          {{ saving ? 'SUBIENDO...' : 'IMPORTAR' }}
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Previsualización Importación Compras -->
  <div
    v-if="showPurchasesPreviewModal && purchasesPreview"
    class="modal-overlay"
    @click.self="showPurchasesPreviewModal = false"
  >
    <div class="modal" style="width: 960px; max-width: 95vw; position: relative;">
      <!-- Loading overlay confirmación -->
      <div v-if="saving" class="import-loading-overlay">
        <div class="import-loading-spinner"></div>
        <p class="import-loading-text">{{ importStage || 'Procesando...' }}</p>
        <div class="import-progress-bar">
          <div class="import-progress-fill" :style="{ width: importProgress + '%' }"></div>
        </div>
        <p class="import-loading-pct">{{ importProgress }}%</p>
        <p class="import-loading-sub">Creando {{ purchasesPreview.summary?.new_products_count || 0 }} nuevos y actualizando {{ purchasesPreview.summary?.existing_products_count || 0 }} existentes</p>
      </div>
      <div class="modal-header">
        <h3>PREVISUALIZAR IMPORTACIÓN DE COMPRAS</h3>
        <button class="modal-close" @click="showPurchasesPreviewModal = false">
          <span class="material-icons-round" style="font-size: 18px">close</span>
        </button>
      </div>
      <div class="modal-body">
        <div style="display: flex; flex-wrap: wrap; gap: 16px; margin-bottom: 16px;">
          <div class="badge badge-info">
            Nuevos: {{ purchasesPreview.summary?.new_products_count || 0 }}
          </div>
          <div class="badge badge-success">
            Existentes: {{ purchasesPreview.summary?.existing_products_count || 0 }}
          </div>
          <div class="badge badge-neutral">
            Filas: {{ purchasesPreview.summary?.total_rows || 0 }}
          </div>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
          <div style="min-width: 0;">
            <h4 style="margin-bottom: 8px;">Productos nuevos</h4>
            <div class="import-table-wrap">
              <table class="import-preview-table">
                <thead>
                  <tr>
                    <th style="width: 28%;">SKU</th>
                    <th style="width: 52%;">NOMBRE</th>
                    <th style="width: 20%;">CANTIDAD</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in purchasesPreview.new || []" :key="item.sku">
                    <td class="cell-sku">{{ item.sku }}</td>
                    <td class="cell-truncate" :title="item.nombre">{{ item.nombre }}</td>
                    <td style="text-align: right;">{{ item.cantidad_total }}</td>
                  </tr>
                  <tr v-if="!purchasesPreview.new || purchasesPreview.new.length === 0">
                    <td colspan="3" style="text-align: center; padding: 12px; color: var(--text-gray);">
                      Sin productos nuevos
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div style="min-width: 0;">
            <h4 style="margin-bottom: 8px;">Productos existentes</h4>
            <div class="import-table-wrap">
              <table class="import-preview-table">
                <thead>
                  <tr>
                    <th style="width: 25%;">SKU</th>
                    <th style="width: 39%;">NOMBRE</th>
                    <th style="width: 18%;">ACTUAL</th>
                    <th style="width: 18%;">+COMPRA</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in purchasesPreview.existing || []" :key="item.sku">
                    <td class="cell-sku">{{ item.sku }}</td>
                    <td class="cell-truncate" :title="item.nombre">{{ item.nombre }}</td>
                    <td style="text-align: right;">{{ item.stock_actual }}</td>
                    <td style="text-align: right;">{{ item.cantidad_total }}</td>
                  </tr>
                  <tr v-if="!purchasesPreview.existing || purchasesPreview.existing.length === 0">
                    <td colspan="4" style="text-align: center; padding: 12px; color: var(--text-gray);">
                      Sin productos existentes
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div v-if="purchasesPreview.errors && purchasesPreview.errors.length" style="margin-top: 16px;">
          <h4 style="margin-bottom: 8px;">Advertencias</h4>
          <div class="import-table-wrap" style="max-height: 150px;">
            <ul style="font-size: 0.85rem; color: var(--text-gray); padding-left: 18px; margin: 0;">
              <li v-for="(errMsg, idx) in purchasesPreview.errors" :key="idx">
                {{ errMsg }}
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" @click="showPurchasesPreviewModal = false">Cancelar</button>
        <button class="btn btn-primary" :disabled="saving" @click="confirmPurchasesImport">
          <span class="material-icons-round" style="font-size: 18px">check_circle</span>
          {{ saving ? 'APLICANDO...' : 'CONFIRMAR IMPORTACIÓN' }}
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Detalle Producto -->
  <div v-if="showDetailModal && selectedProduct" class="modal-overlay" @click.self="closeDetailModal">
    <div class="pd-modal">
      <!-- Hero Header -->
      <div class="pd-hero">
        <button class="pd-close" @click="closeDetailModal">
          <span class="material-icons-round">close</span>
        </button>
        <div class="pd-hero-text">
          <h1 class="pd-hero-name">{{ normalizeName(selectedProduct) }}</h1>
          <p class="pd-hero-sub">{{ normalizeCategory(selectedProduct) }} · {{ normalizeUnit(selectedProduct) }}</p>
        </div>
      </div>

      <!-- Content -->
      <div class="pd-content">
        <!-- Specs Grid -->
        <div class="pd-specs">
          <div class="pd-spec">
            <span class="pd-spec-label">SKU Interno</span>
            <span class="pd-spec-value">{{ normalizeSku(selectedProduct) }}</span>
          </div>
          <div class="pd-spec" v-if="normalizeRef(selectedProduct)">
            <span class="pd-spec-label">Ref. Fábrica</span>
            <span class="pd-spec-value">{{ normalizeRef(selectedProduct) }}</span>
          </div>
          <div class="pd-spec">
            <span class="pd-spec-label">Categoría</span>
            <span class="pd-spec-value">{{ normalizeCategory(selectedProduct) }}</span>
          </div>
          <div class="pd-spec">
            <span class="pd-spec-label">Ubicación</span>
            <span class="pd-spec-value">{{ normalizeLocation(selectedProduct) || '—' }}</span>
          </div>
        </div>

        <!-- Stock Status -->
        <div class="pd-stock-card">
          <div class="pd-stock-top">
            <div class="pd-stock-left">
              <span class="material-icons-round pd-stock-icon">{{ stockIcon(selectedProduct) }}</span>
              <span class="pd-stock-title">Estado de Stock</span>
            </div>
            <span class="pd-stock-pct">{{ Math.round(stockPercent(selectedProduct)) }}%</span>
          </div>
          <div class="pd-bar">
            <div class="pd-bar-fill" :style="{ width: stockPercent(selectedProduct) + '%' }"></div>
          </div>
          <p class="pd-stock-note">
            <template v-if="normalizeStock(selectedProduct) <= normalizeAlert(selectedProduct)">
              Alerta: Solo {{ normalizeStock(selectedProduct) }} {{ normalizeUnit(selectedProduct) }} disponibles. Mínimo: {{ normalizeAlert(selectedProduct) }}.
            </template>
            <template v-else>
              {{ normalizeStock(selectedProduct) }} {{ normalizeUnit(selectedProduct) }} disponibles. Mínimo: {{ normalizeAlert(selectedProduct) }}.
            </template>
          </p>
        </div>

        <!-- Details -->
        <div class="pd-details">
          <div class="pd-detail-row">
            <span class="pd-detail-label">Precio de Costo</span>
            <span class="pd-detail-value">{{ normalizePrice(selectedProduct) || '—' }}</span>
          </div>
          <div class="pd-detail-row">
            <span class="pd-detail-label">Unidad de Medida</span>
            <span class="pd-detail-value">{{ normalizeUnit(selectedProduct) }}</span>
          </div>
          <div class="pd-detail-row">
            <span class="pd-detail-label">Stock Actual</span>
            <span class="pd-detail-value">{{ normalizeStock(selectedProduct) }} {{ normalizeUnit(selectedProduct) }}</span>
          </div>
          <div class="pd-detail-row pd-detail-muted">
            <span class="pd-detail-label">ID</span>
            <span class="pd-detail-value">{{ normalizeId(selectedProduct) }}</span>
          </div>
        </div>

        <!-- Recent Movements -->
        <div class="pd-movements" v-if="productMovements.length > 0">
          <h3 class="pd-section-title">
            <span class="material-icons-round" style="font-size: 16px;">history</span>
            Movimientos Recientes
          </h3>
          <div class="pd-movements-table">
            <table>
              <thead>
                <tr>
                  <th>Fecha</th>
                  <th>Tipo</th>
                  <th style="text-align: right;">Cantidad</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(mov, i) in productMovements.slice(0, 5)" :key="i">
                  <td>{{ formatMovDate(mov.created_at || mov.transaccion_fecha) }}</td>
                  <td>{{ mov.transaccion_tipo || '—' }}</td>
                  <td style="text-align: right;" :class="mov.transaccion_tipo === 'ingreso' ? 'pd-mov-in' : 'pd-mov-out'">
                    {{ mov.transaccion_tipo === 'ingreso' ? '+' : '-' }}{{ mov.transaccion_cantidad }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="pd-actions">
          <button class="pd-btn-secondary" @click="closeDetailModal">
            <span class="material-icons-round" style="font-size: 16px;">visibility</span>
            CERRAR
          </button>
          <button v-if="canCreate" class="pd-btn-primary" @click="closeDetailModal(); openMovementModal();">
            <span class="material-icons-round" style="font-size: 16px;">sync_alt</span>
            REGISTRAR MOVIMIENTO
          </button>
          <button v-if="isAdmin" class="pd-btn-primary" style="background: var(--warning);" @click="editProduct(selectedProduct)">
            <span class="material-icons-round" style="font-size: 16px;">edit</span>
            EDITAR
          </button>
          <button v-if="isAdmin" class="pd-btn-primary" style="background: var(--danger);" @click="confirmDeleteProduct(selectedProduct)">
            <span class="material-icons-round" style="font-size: 16px;">delete</span>
            ELIMINAR
          </button>
        </div>
      </div>
    </div>
  </div>
  <!-- Toast Notification -->
  <Teleport to="body">
    <Transition name="toast-slide">
      <div v-if="toast.show" class="app-toast" :class="'app-toast--' + toast.type" @click="toast.show = false">
        <span class="material-icons-round app-toast-icon">{{ toastIcon }}</span>
        <div class="app-toast-body">
          <p class="app-toast-title">{{ toast.title }}</p>
          <p v-if="toast.message" class="app-toast-msg">{{ toast.message }}</p>
        </div>
        <span class="material-icons-round app-toast-close">close</span>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import { formatCurrencyCO } from '../../../shared/utils/formatters';
import SearchableSelect from '../../../shared/components/SearchableSelect.vue';
import {
  productAlert,
  productCategory,
  productCategoryToken,
  productCost,
  productId,
  productLocation,
  productName,
  productRef,
  productSku,
  productStock,
  productUnit,
} from '../../../shared/adapters/productAdapter';
import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';
import {
  fetchInventoryProducts,
  searchInventoryProducts,
  createProduct,
  updateProduct,
  deleteProduct,
  createMovement,
  uploadCsv,
  uploadPurchasesPreview,
  uploadPurchasesConfirm,
} from '../api/inventoryService';
import { useRefresh } from '../../../shared/composables/useRefresh';
import { useAuthStore } from '../../../shared/stores/auth';

const auth = useAuthStore();
const userRole = computed(() => auth.user?.role || 'visualizador');
const isAdmin = computed(() => userRole.value === 'admin');
const canCreate = computed(() => ['admin', 'jefe_taller', 'auxiliar_bodega'].includes(userRole.value));

const { refreshTrigger, triggerRefresh } = useRefresh();

const router = useRouter();
const route = useRoute();

const { loading, error, run } = useAsyncState('');
const search = ref('');
const selectedCategory = ref('Todos');
const allProducts = ref([]);
const currentPage = ref(1);
const totalPages = ref(1);
const totalItems = ref(0);
const metrics = ref(null);

// Categorias dummy para el formulario. Lo ideal sería un endpoint, pero se simplifica con quemados o sacados de props.
const categories = ref([
  { categoria_id: 1, nombre: 'Repuestos' },
  { categoria_id: 2, nombre: 'Tornilleria' },
  { categoria_id: 3, nombre: 'Lubricantes' },
  { categoria_id: 4, nombre: 'Combustible' },
  { categoria_id: 5, nombre: 'Herramientas' },
]);
const categoryChips = ['Todos', 'Repuestos', 'Tornilleria', 'Lubricantes', 'Combustible', 'Herramientas'];

// Modals State
const showProductModal = ref(false);
const showMovementModal = ref(false);
const showCsvModal = ref(false);
const showDetailModal = ref(false);
const selectedProduct = ref(null);
const productMovements = ref([]);
const empleados = ref([]);
const saving = ref(false);
const editingProductId = ref(null);

const productForm = ref({
  producto_sku: '',
  referencia_fabrica: '',
  producto_nombre: '',
  categoria_id: '',
  producto_unidad_medida: 'unidad',
  producto_alerta_stock_minimo: 5,
  producto_precio_costo: 0,
  producto_ubicacion: '',
});

const movementForm = ref({
  producto_id: '',
  transaccion_tipo: 'ingreso',
  transaccion_cantidad: '',
  transaccion_motivo: '',
  transaccion_referencia_id: '',
  transaccion_referencia_type: 'empleado',
});

const csvFile = ref(null);
const skipDuplicates = ref(true);
const csvCategoriaId = ref('');
const purchasesPreview = ref(null);
const showPurchasesPreviewModal = ref(false);

// Toast system
const toast = ref({ show: false, type: 'info', title: '', message: '' });
let toastTimer = null;
const toastIcon = computed(() => {
  const icons = { success: 'check_circle', error: 'error', warning: 'warning', info: 'info' };
  return icons[toast.value.type] || 'info';
});
function showToast(type, title, message = '') {
  if (toastTimer) clearTimeout(toastTimer);
  toast.value = { show: true, type, title, message };
  const duration = type === 'error' ? 6000 : 4000;
  toastTimer = setTimeout(() => { toast.value.show = false; }, duration);
}

// Progress system
const importProgress = ref(0);
const importStage = ref('');
let progressInterval = null;

function startSimulatedProgress(fromPct, toPct, durationMs, stage) {
  importStage.value = stage;
  const steps = 30;
  const increment = (toPct - fromPct) / steps;
  const intervalMs = durationMs / steps;
  let current = fromPct;
  progressInterval = setInterval(() => {
    current += increment;
    if (current >= toPct) {
      current = toPct;
      clearInterval(progressInterval);
      progressInterval = null;
    }
    importProgress.value = Math.round(current);
  }, intervalMs);
}

function stopProgress() {
  if (progressInterval) { clearInterval(progressInterval); progressInterval = null; }
  importProgress.value = 100;
  setTimeout(() => { importProgress.value = 0; importStage.value = ''; }, 400);
}

onMounted(async () => {
  await loadProducts();
  await loadEmpleados();

  // Auto-abrir detalle si viene de una notificación con producto_id
  const productoId = route.query.producto_id;
  if (productoId) {
    try {
      const { data: producto } = await http.get(`/productos/${productoId}`);
      if (producto) {
        goToProduct(producto);
      }
    } catch (e) {
      console.warn('No se encontró el producto de la notificación:', e);
    }
    // Limpiar query param para evitar re-apertura
    router.replace({ query: {} });
  }
});

watch(refreshTrigger, async () => {
  await loadProducts();
});

let searchDebounce = null;
watch(search, (value) => {
  clearTimeout(searchDebounce);
  const q = value.trim();
  searchDebounce = setTimeout(async () => {
    currentPage.value = 1;
    await loadProducts();
  }, q.length >= 3 ? 400 : 0);
});

watch(selectedCategory, async () => {
  currentPage.value = 1;
  await loadProducts();
});

async function loadProducts() {
  try {
    await run(async () => {
      const params = { page: currentPage.value, per_page: 25 };
      const q = search.value.trim();
      if (q.length >= 2) params.q = q;

      // Enviar categoría al backend
      if (selectedCategory.value !== 'Todos') {
        const cat = categories.value.find(c => c.nombre === selectedCategory.value);
        if (cat) params.categoria_id = cat.categoria_id;
      }

      const res = await fetchInventoryProducts(params);
      allProducts.value = res.data || [];
      totalPages.value = res.meta?.last_page || 1;
      totalItems.value = res.meta?.total || 0;
      currentPage.value = res.meta?.current_page || 1;
      if (res.metrics) metrics.value = res.metrics;
    }, 'Error al cargar inventario');
  } catch {
    // handled by composable
  }
}

async function loadEmpleados() {
  try {
    const { data } = await http.get('/empleados');
    empleados.value = extractList(data);
  } catch (err) {
    console.error('Error cargando empleados:', err);
  }
}

function goPage(page) {
  if (page < 1 || page > totalPages.value) return;
  currentPage.value = page;
  loadProducts();
}

async function onSearchEnter() {
  currentPage.value = 1;
  await loadProducts();
}

// Modal functions
function openProductModal(product = null) {
  if (product) {
    editingProductId.value = normalizeId(product);
    productForm.value = {
      producto_sku: normalizeSku(product),
      referencia_fabrica: normalizeRef(product) || '',
      producto_nombre: normalizeName(product),
      categoria_id: product.categoria_id || product.categoria?.categoria_id || '',
      producto_unidad_medida: normalizeUnit(product) || 'unidad',
      producto_alerta_stock_minimo: normalizeAlert(product) || 5,
      producto_precio_costo: normalizePrice(product) ? parseFloat(String(normalizePrice(product)).replace(/[^0-9.]/g, '')) : 0,
      producto_ubicacion: normalizeLocation(product) || '',
    };
  } else {
    editingProductId.value = null;
    productForm.value = {
      producto_sku: '',
      referencia_fabrica: '',
      producto_nombre: '',
      categoria_id: '',
      producto_unidad_medida: 'unidad',
      producto_alerta_stock_minimo: 5,
      producto_precio_costo: 0,
      producto_ubicacion: '',
    };
  }
  showProductModal.value = true;
}
function closeProductModal() {
  showProductModal.value = false;
  editingProductId.value = null;
}
async function submitProduct() {
  try {
    saving.value = true;
    if (editingProductId.value) {
      await updateProduct(editingProductId.value, productForm.value);
      showToast('success', 'Producto actualizado');
    } else {
      await createProduct(productForm.value);
      showToast('success', 'Producto creado');
    }
    closeProductModal();
    triggerRefresh();
  } catch (err) {
    showToast('error', 'Error al guardar producto', err.response?.data?.message || err.message);
  } finally {
    saving.value = false;
  }
}

function editProduct(product) {
  closeDetailModal();
  openProductModal(product);
}

async function confirmDeleteProduct(product) {
  const name = normalizeName(product);
  if (!confirm(`¿Eliminar "${name}"? Esta acción no se puede deshacer.`)) return;
  try {
    saving.value = true;
    await deleteProduct(normalizeId(product));
    showToast('success', 'Producto eliminado');
    closeDetailModal();
    triggerRefresh();
  } catch (err) {
    showToast('error', 'Error al eliminar', err.response?.data?.message || err.message);
  } finally {
    saving.value = false;
  }
}

function openMovementModal() {
  movementForm.value = {
    producto_id: '',
    transaccion_tipo: 'ingreso',
    transaccion_cantidad: '',
    transaccion_motivo: '',
    transaccion_referencia_id: '',
    transaccion_referencia_type: 'empleado',
  };
  showMovementModal.value = true;
}
function closeMovementModal() {
  showMovementModal.value = false;
}
async function submitMovement() {
  try {
    if (!movementForm.value.producto_id) {
      showToast('warning', 'Selecciona un producto');
      return;
    }
    if (movementForm.value.transaccion_tipo === 'salida' && !movementForm.value.transaccion_referencia_id) {
      showToast('warning', 'Selecciona el empleado al que se entrega');
      return;
    }
    const qty = Number(movementForm.value.transaccion_cantidad);
    if (!qty || qty <= 0) {
      showToast('warning', 'Ingresa una cantidad válida');
      return;
    }

    saving.value = true;
    const res = await createMovement(movementForm.value);
    closeMovementModal();
    triggerRefresh();
    if (res?.warning) {
      showToast('warning', 'Atención', res.warning);
    }
  } catch (err) {
    showToast('error', 'Error al registrar movimiento', err.response?.data?.message || err.message);
  } finally {
    saving.value = false;
  }
}

function openCsvModal() {
  csvFile.value = null;
  skipDuplicates.value = true;
  const current = categories.value.find((c) => c.nombre === selectedCategory.value);
  csvCategoriaId.value = current ? String(current.categoria_id) : '';
  showCsvModal.value = true;
}
function closeCsvModal() {
  showCsvModal.value = false;
}
function onFileChange(e) {
  csvFile.value = e.target.files[0] || null;
}
async function submitCsv() {
  if (!csvFile.value) return;
  try {
    saving.value = true;
    importProgress.value = 0;
    importStage.value = 'Subiendo archivo...';
    const res = await uploadPurchasesPreview(csvFile.value, {
      categoria_id: csvCategoriaId.value || undefined,
    }, (pct) => {
      importProgress.value = Math.round(pct * 0.5); // upload = 0-50%
      if (pct >= 100) {
        startSimulatedProgress(50, 95, 8000, 'Analizando productos...');
      }
    });
    stopProgress();
    purchasesPreview.value = res;
    showPurchasesPreviewModal.value = true;
  } catch (err) {
    stopProgress();
    showToast('error', 'Error al previsualizar importación', err.response?.data?.message || err.message);
  } finally {
    saving.value = false;
  }
}

async function confirmPurchasesImport() {
  if (!csvFile.value) return;
  try {
    saving.value = true;
    importProgress.value = 0;
    importStage.value = 'Subiendo archivo...';
    const res = await uploadPurchasesConfirm(csvFile.value, {
      categoria_id: csvCategoriaId.value || undefined,
    }, (pct) => {
      importProgress.value = Math.round(pct * 0.4); // upload = 0-40%
      if (pct >= 100) {
        startSimulatedProgress(40, 95, 15000, 'Importando productos a la base de datos...');
      }
    });
    stopProgress();
    showToast('success', 'Importación aplicada', `${res.created_products} productos nuevos, ${res.updated_products} actualizados, ${res.movements_created} movimientos creados.`);
    showPurchasesPreviewModal.value = false;
    closeCsvModal();
    triggerRefresh();
  } catch (err) {
    stopProgress();
    showToast('error', 'Error al aplicar importación', err.response?.data?.message || err.message);
  } finally {
    saving.value = false;
    purchasesPreview.value = null;
    csvFile.value = null;
  }
}

const productOptionsForMovement = computed(() => {
  return filteredProducts.value.map((prod) => {
    const sku = normalizeSku(prod);
    const name = normalizeName(prod);
    const ref = normalizeRef(prod);
    const stock = normalizeStock(prod);
    const value = String(normalizeId(prod));

    return {
      value,
      label: `${sku} - ${name}`,
      description: ref ? `Ref: ${ref} · Stock: ${stock}` : `Stock: ${stock}`,
      keywords: `${sku} ${name} ${ref || ''}`.trim(),
    };
  });
});

const empleadoOptionsForMovement = computed(() => {
  return empleados.value.map((emp) => {
    const nombres = String(emp.nombres || '').trim();
    const apellidos = String(emp.apellidos || '').trim();
    const cargo = String(emp.cargo || 'Sin cargo').trim();
    const label = `${nombres} ${apellidos}`.trim() || 'Sin nombre';
    const value = String(emp.id);

    return {
      value,
      label,
      description: cargo,
      keywords: `${label} ${cargo}`.trim(),
    };
  });
});

const filteredProducts = computed(() => allProducts.value);

async function goToProduct(product) {
  selectedProduct.value = product;
  showDetailModal.value = true;
  productMovements.value = [];
  try {
    const id = normalizeId(product);
    const { data } = await http.get('/movimientos', { params: { producto_id: id } });
    productMovements.value = extractList(data);
  } catch {
    productMovements.value = [];
  }
}

function closeDetailModal() {
  showDetailModal.value = false;
  selectedProduct.value = null;
  productMovements.value = [];
}

function normalizeId(product) {
  return productId(product);
}

function normalizeSku(product) {
  return productSku(product);
}

function normalizeRef(product) {
  return productRef(product);
}

function normalizeName(product) {
  return productName(product);
}

function normalizeCategory(product) {
  return productCategory(product);
}

function normalizeStock(product) {
  return productStock(product);
}

function normalizeAlert(product) {
  return productAlert(product);
}

function normalizeUnit(product) {
  return productUnit(product);
}

function normalizePrice(product) {
  return formatCurrencyCO(productCost(product));
}

function normalizeLocation(product) {
  return productLocation(product);
}

function stockBadgeClass(product) {
  const stock = normalizeStock(product);
  const alert = normalizeAlert(product);
  return stock <= alert ? 'badge-danger' : 'badge-success';
}

function stockStatusClass(product) {
  const stock = normalizeStock(product);
  const alert = normalizeAlert(product);
  if (stock <= 0) return 'pd-stock-critical';
  if (stock <= alert) return 'pd-stock-low';
  return 'pd-stock-ok';
}

function stockIcon(product) {
  const stock = normalizeStock(product);
  const alert = normalizeAlert(product);
  if (stock <= 0) return 'error';
  if (stock <= alert) return 'warning';
  return 'check_circle';
}

function stockStatusLabel(product) {
  const stock = normalizeStock(product);
  const alert = normalizeAlert(product);
  if (stock <= 0) return 'Sin Stock';
  if (stock <= alert) return 'Stock Bajo';
  return 'Stock Normal';
}

function stockPercent(product) {
  const stock = normalizeStock(product);
  const alert = normalizeAlert(product);
  if (alert <= 0) return 100;
  const ratio = (stock / (alert * 3)) * 100;
  return Math.min(ratio, 100);
}

function formatMovDate(dateStr) {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' });
  } catch {
    return dateStr;
  }
}
</script>

<style scoped>
/* Pagination controls */
.pagination-controls {
  display: flex;
  gap: 4px;
}
.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* Metrics cards */
.metrics-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--sp-md);
  margin-bottom: var(--sp-md);
}
.metric-card {
  display: flex;
  align-items: center;
  gap: var(--sp-sm);
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  padding: var(--sp-md);
}
.metric-card.metric-danger .metric-icon {
  color: var(--danger);
}
.metric-card.metric-danger .metric-value {
  color: var(--danger);
}
.metric-icon {
  font-size: 28px;
  color: var(--primary);
  opacity: 0.8;
}
.metric-info {
  display: flex;
  flex-direction: column;
}
.metric-value {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--text-main);
  font-family: 'Oswald', sans-serif;
}
.metric-label {
  font-size: 0.7rem;
  color: var(--text-gray);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Modal Container */
.pd-modal {
  width: 520px;
  max-width: 95vw;
  max-height: 90vh;
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-lg);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  animation: modalSlideUp 0.3s ease;
  box-shadow: var(--shadow-lg);
}

/* Hero */
.pd-hero {
  position: relative;
  height: 140px;
  background: linear-gradient(135deg, #1a1a1a 0%, var(--surface-2) 50%, #1a1a1a 100%);
  display: flex;
  align-items: flex-end;
  padding: var(--sp-lg);
}

.pd-close {
  position: absolute;
  top: 12px;
  right: 12px;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: none;
  background: var(--surface-3);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background var(--transition-fast);
}

.pd-close:hover {
  background: var(--surface-2);
}

.pd-close .material-icons-round {
  font-size: 18px;
}

.pd-hero-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.pd-hero-name {
  font-family: 'Oswald', sans-serif;
  font-size: 1.6rem;
  font-weight: 700;
  color: var(--primary);
  letter-spacing: 1px;
  text-transform: uppercase;
  line-height: 1.1;
}

.pd-hero-sub {
  font-size: 0.8rem;
  color: var(--text-gray);
  font-weight: 500;
}

/* Content */
.pd-content {
  padding: var(--sp-lg);
  display: flex;
  flex-direction: column;
  gap: var(--sp-lg);
  overflow-y: auto;
}

/* Specs Grid */
.pd-specs {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: var(--sp-md);
  padding-bottom: var(--sp-lg);
  border-bottom: 1px solid var(--surface-2);
}

.pd-spec {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.pd-spec-label {
  font-size: 0.62rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  color: var(--text-muted);
}

.pd-spec-value {
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--text-secondary);
}

/* Stock Card */
.pd-stock-card {
  background: var(--primary-10);
  border: 1px solid var(--primary-20);
  border-radius: var(--radius-md);
  padding: var(--sp-md);
}

.pd-stock-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.pd-stock-left {
  display: flex;
  align-items: center;
  gap: 6px;
}

.pd-stock-icon {
  font-size: 18px;
  color: var(--primary);
}

.pd-stock-title {
  font-family: 'Oswald', sans-serif;
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--primary);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.pd-stock-pct {
  font-weight: 700;
  font-size: 0.88rem;
  color: var(--primary);
}

.pd-bar {
  width: 100%;
  height: 6px;
  background: var(--surface-2);
  border-radius: 3px;
  overflow: hidden;
}

.pd-bar-fill {
  height: 100%;
  background: var(--primary);
  border-radius: 3px;
  transition: width 0.5s ease;
}

.pd-stock-note {
  font-size: 0.75rem;
  color: var(--text-gray);
  margin-top: 8px;
  font-style: italic;
}

/* Details */
.pd-details {
  display: flex;
  flex-direction: column;
}

.pd-detail-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid var(--surface-2);
}

.pd-detail-row:last-child {
  border-bottom: none;
}

.pd-detail-label {
  font-size: 0.8rem;
  color: var(--text-gray);
}

.pd-detail-value {
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--text-secondary);
}

.pd-detail-muted .pd-detail-value {
  color: var(--text-muted);
  font-family: 'Consolas', 'SF Mono', monospace;
  font-size: 0.78rem;
}

/* Movements */
.pd-section-title {
  font-family: 'Oswald', sans-serif;
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--text-secondary);
  letter-spacing: 1.5px;
  text-transform: uppercase;
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 10px;
}

.pd-movements-table {
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.pd-movements-table table {
  width: 100%;
  text-align: left;
  font-size: 0.78rem;
  border-collapse: collapse;
}

.pd-movements-table thead {
  background: var(--bg-dark);
}

.pd-movements-table th {
  padding: 6px 10px;
  font-weight: 500;
  color: var(--text-gray);
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border-bottom: 1px solid var(--surface-2);
}

.pd-movements-table td {
  padding: 6px 10px;
  color: var(--text-secondary);
  border-bottom: 1px solid var(--surface-2);
}

.pd-movements-table tr:hover {
  background: var(--primary-10);
}

.pd-mov-in {
  color: var(--success) !important;
}

.pd-mov-out {
  color: var(--danger) !important;
}

/* Actions */
.pd-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--sp-md);
  padding-top: var(--sp-lg);
  border-top: 1px solid var(--surface-2);
}

.pd-btn-secondary,
.pd-btn-primary {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 16px;
  border: none;
  border-radius: var(--radius-sm);
  font-family: 'Oswald', sans-serif;
  font-size: 0.82rem;
  font-weight: 600;
  letter-spacing: 1px;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.pd-btn-secondary {
  background: var(--surface-2);
  color: var(--text-main);
}

.pd-btn-secondary:hover {
  background: var(--surface-3);
}

.pd-btn-primary {
  background: var(--primary);
  color: #000;
  font-weight: 700;
}

.pd-btn-primary:hover {
  background: var(--primary-hover);
  box-shadow: 0 0 20px rgba(255, 214, 0, 0.15);
}

/* Form overrides */
.transaction-toggles {
  display: flex;
  gap: 10px;
  width: 100%;
}
.toggle-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px;
  background: var(--bg-dark);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-sm);
  color: var(--text-gray);
  font-weight: 600;
  cursor: pointer;
  transition: all var(--transition-fast);
}
.toggle-btn:hover {
  background: var(--surface-2);
  color: var(--text-main);
}
.toggle-btn.active.is-ingreso {
  background: rgba(46, 204, 113, 0.15); /* success color approx */
  border-color: var(--success);
  color: var(--success);
}
.toggle-btn.active.is-salida {
  background: rgba(231, 76, 60, 0.15); /* danger color approx */
  border-color: var(--danger);
  color: var(--danger);
}

/* Permite que el dropdown del selector se vea completo dentro del modal */
.modal-body--overflow-visible {
  overflow: visible;
}

/* --- Import Loading Overlay --- */
.import-loading-overlay {
  position: absolute;
  inset: 0;
  z-index: 50;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  background: rgba(18, 18, 18, 0.92);
  backdrop-filter: blur(6px);
  border-radius: var(--radius-xl);
  animation: importOverlayIn 0.3s ease;
}

@keyframes importOverlayIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.import-loading-spinner {
  width: 48px;
  height: 48px;
  border: 4px solid rgba(255, 255, 255, 0.08);
  border-top: 4px solid var(--primary);
  border-radius: 50%;
  animation: importSpin 0.9s linear infinite;
}

@keyframes importSpin {
  to { transform: rotate(360deg); }
}

.import-loading-text {
  font-family: 'Oswald', sans-serif;
  font-size: 1.1rem;
  font-weight: 600;
  letter-spacing: 0.5px;
  color: var(--text-main);
  margin: 0;
}

.import-loading-sub {
  font-size: 0.85rem;
  color: var(--text-gray);
  margin: 0;
  text-align: center;
  max-width: 320px;
}

.import-loading-hint {
  font-size: 0.75rem;
  color: var(--text-muted);
  margin: 8px 0 0;
  animation: importPulse 2s ease-in-out infinite;
}

@keyframes importPulse {
  0%, 100% { opacity: 0.5; }
  50% { opacity: 1; }
}

.import-progress-bar {
  width: 80%;
  max-width: 280px;
  height: 6px;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 3px;
  overflow: hidden;
}

.import-progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--primary), #ffed4a);
  border-radius: 3px;
  transition: width 0.4s ease;
  position: relative;
}

.import-progress-fill::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
  animation: progressShine 1.5s ease-in-out infinite;
}

@keyframes progressShine {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

.import-loading-pct {
  font-family: 'Oswald', sans-serif;
  font-size: 2rem;
  font-weight: 700;
  color: var(--primary);
  margin: 0;
  letter-spacing: 1px;
}

/* --- Import Preview Tables --- */
.import-table-wrap {
  max-height: 260px;
  overflow: auto;
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-sm);
}

.import-preview-table {
  width: 100%;
  table-layout: fixed;
  border-collapse: collapse;
  font-size: 0.82rem;
}

.import-preview-table thead {
  position: sticky;
  top: 0;
  z-index: 1;
}

.import-preview-table th {
  padding: 8px 10px;
  background: var(--surface-2);
  color: var(--text-gray);
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.5px;
  text-align: left;
  text-transform: uppercase;
  white-space: nowrap;
}

.import-preview-table td {
  padding: 6px 10px;
  border-top: 1px solid var(--surface-2);
  color: var(--text-secondary);
}

.import-preview-table tbody tr:hover {
  background: var(--primary-10);
}

.cell-truncate {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.cell-sku {
  font-weight: 600;
  color: var(--text-main) !important;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* --- App Toast --- */
.app-toast {
  position: fixed;
  bottom: 28px;
  right: 28px;
  z-index: 9999;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 18px;
  min-width: 320px;
  max-width: 460px;
  border-radius: var(--radius-md);
  border: 1px solid var(--surface-2);
  background: var(--surface);
  backdrop-filter: blur(12px);
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.5);
  cursor: pointer;
  user-select: none;
}

.app-toast-icon {
  font-size: 22px;
  margin-top: 1px;
  flex-shrink: 0;
}

.app-toast-body {
  flex: 1;
  min-width: 0;
}

.app-toast-title {
  margin: 0;
  font-family: 'Oswald', sans-serif;
  font-size: 0.92rem;
  font-weight: 600;
  letter-spacing: 0.3px;
  color: var(--text-main);
}

.app-toast-msg {
  margin: 4px 0 0;
  font-size: 0.82rem;
  color: var(--text-gray);
  line-height: 1.4;
}

.app-toast-close {
  font-size: 16px;
  color: var(--text-muted);
  flex-shrink: 0;
  margin-top: 2px;
  transition: color 0.15s;
}

.app-toast:hover .app-toast-close {
  color: var(--text-main);
}

/* Toast types */
.app-toast--success {
  border-left: 3px solid var(--success);
}
.app-toast--success .app-toast-icon {
  color: var(--success);
}

.app-toast--error {
  border-left: 3px solid var(--danger);
}
.app-toast--error .app-toast-icon {
  color: var(--danger);
}

.app-toast--warning {
  border-left: 3px solid var(--warning, #f59e0b);
}
.app-toast--warning .app-toast-icon {
  color: var(--warning, #f59e0b);
}

.app-toast--info {
  border-left: 3px solid var(--primary);
}
.app-toast--info .app-toast-icon {
  color: var(--primary);
}

/* Toast transition */
.toast-slide-enter-active {
  animation: toastSlideIn 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}
.toast-slide-leave-active {
  animation: toastSlideOut 0.25s ease forwards;
}

@keyframes toastSlideIn {
  from {
    opacity: 0;
    transform: translateX(60px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateX(0) scale(1);
  }
}

@keyframes toastSlideOut {
  from {
    opacity: 1;
    transform: translateX(0) scale(1);
  }
  to {
    opacity: 0;
    transform: translateX(60px) scale(0.95);
  }
}
</style>
