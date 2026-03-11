<template>
  <div class="table-container">
    <div class="table-header">
      <div style="display: flex; align-items: center; gap: var(--sp-md); flex-wrap: wrap">
        <h3 class="table-title">GESTION DE FLOTA</h3>
        <div class="filter-chips">
          <button
            v-for="chip in typeFilters"
            :key="chip.value"
            class="chip"
            :class="{ active: selectedType === chip.value }"
            @click="selectedType = chip.value"
          >
            {{ chip.label }}
          </button>
        </div>
      </div>

      <div class="table-actions">
        <div class="table-search">
          <span class="material-icons-round">search</span>
          <input v-model="search" type="text" placeholder="Buscar por placa o marca..." />
        </div>
        <button class="btn btn-primary btn-sm" @click="openVehicleModal()" style="cursor: pointer;">
          <span class="material-icons-round" style="font-size: 18px;">add_circle</span>
          NUEVO VEHÍCULO
        </button>
      </div>
    </div>

    <div class="table-scroll">
      <table v-if="!loading && !error && filteredVehicles.length > 0">
        <thead>
          <tr>
            <th>PLACA</th>
            <th>TIPO</th>
            <th>MARCA</th>
            <th>MODELO</th>
            <th>KILOMETRAJE</th>
            <th>HOROMETRO</th>
            <th>SOAT</th>
            <th>RTM</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="vehicle in filteredVehicles" :key="vehicleId(vehicle)" @click="goToVehicle(vehicle)" style="cursor: pointer;">
            <td style="color: var(--primary); font-weight: 700">{{ vehiclePlate(vehicle) }}</td>
            <td><span class="badge badge-neutral">{{ vehicleType(vehicle) }}</span></td>
            <td style="color: var(--text-main)">{{ vehicleBrand(vehicle) }}</td>
            <td>{{ vehicleModel(vehicle) }}</td>
            <td style="font-family: 'Oswald', sans-serif">{{ formatNumber(vehicleKm(vehicle)) }} km</td>
            <td style="font-family: 'Oswald', sans-serif">{{ formatNumber(vehicleHourmeter(vehicle)) }} h</td>
            <td><span class="badge" :class="dateBadgeClass(vehicle.soat || vehicle.fecha_vencimiento_soat)">{{ dateBadgeLabel(vehicle.soat || vehicle.fecha_vencimiento_soat) }}</span></td>
            <td><span class="badge" :class="dateBadgeClass(vehicle.rtm || vehicle.fecha_vencimiento_tecnomecanica)">{{ dateBadgeLabel(vehicle.rtm || vehicle.fecha_vencimiento_tecnomecanica) }}</span></td>
          </tr>
        </tbody>
      </table>

      <div v-else-if="loading" class="page-loading">
        <span class="spinner"></span>
        Cargando flota...
      </div>

      <div v-else-if="error" class="empty-state">
        <span class="material-icons-round">cloud_off</span>
        <p>{{ error }}</p>
      </div>

      <div v-else class="empty-state">
        <span class="material-icons-round">local_shipping</span>
        <p>No se encontraron vehiculos para los filtros aplicados</p>
      </div>
    </div>

    <div class="table-footer">
      Mostrando {{ filteredVehicles.length }} vehiculo{{ filteredVehicles.length === 1 ? '' : 's' }}
    </div>
  </div>

  <!-- Block of Modals Moved Here -->
  <!-- Fleet Detail Modal -->
  <div v-if="showDetailModal && selectedVehicle" class="modal-overlay" @click.self="closeDetailModal">
        <div class="fd-modal">
          <!-- Header Nav -->
          <header class="fd-header">
            <div class="fd-header-content">
              <div class="fd-header-title">
                <span class="material-icons-round" style="font-size: 16px;">construction</span>
                <h2>Semanur Hub <span class="fd-header-subtitle">/ Flota</span></h2>
              </div>
              
              <!-- Tabs At Top (Inside Header) -->
              <div class="fd-tabs fd-tabs-header">
                <button :class="{ active: activeTab === 'resumen' }" @click="activeTab = 'resumen'">General</button>
                <button :class="{ active: activeTab === 'preoperacionales' }" @click="activeTab = 'preoperacionales'">Preoperacionales</button>
                <button :class="{ active: activeTab === 'taller' }" @click="activeTab = 'taller'">Taller</button>
                <button :class="{ active: activeTab === 'repuestos' }" @click="activeTab = 'repuestos'">Repuestos</button>
                <button :class="{ active: activeTab === 'combustible' }" @click="activeTab = 'combustible'">Combustible</button>
                <button v-if="isMachinery(selectedVehicle)" :class="{ active: activeTab === 'horometro' }" @click="activeTab = 'horometro'">Horómetro</button>
              </div>
            </div>

            <button class="fd-close" @click="closeDetailModal">
              <span class="material-icons-round">close</span>
            </button>
          </header>

          <div class="fd-body">
            <div v-if="loadingDetails" class="page-loading" style="min-height: 200px;">
              <span class="spinner"></span>
            </div>

            <!-- Resumen Tab -->
            <div v-else-if="activeTab === 'resumen'" class="fd-tab-content">
              <!-- Vehicle Identity Section (Moved inside Resumen Tab, or keep global if it should be in all tabs) -->
              <!-- The user requested "botones arriba de la foto y placa" which means tabs go first, then the identity section -->
              <div class="fd-identity">
                <div class="fd-image-container" @click="isEditing ? $refs.fileInput.click() : null" :style="{ cursor: isEditing ? 'pointer' : 'default' }">
                  <img :src="getVehicleImage(selectedVehicle)" alt="Vehicle Image" class="fd-image" />
                  <div class="fd-image-overlay" v-if="isEditing">
                    <span class="material-icons-round">photo_camera</span>
                    <span>{{ isUploading ? 'SUBIENDO...' : 'CAMBIAR IMAGEN' }}</span>
                  </div>
                  <input 
                    type="file" 
                    ref="fileInput" 
                    style="display: none" 
                    accept="image/*" 
                    @change="handleImageUpload"
                  />
                </div>
                <div class="fd-identity-info">
                  <div class="fd-identity-top">
                    <div>
                      <h1 class="fd-plate">{{ vehiclePlate(selectedVehicle) }}</h1>
                      <p class="fd-model">{{ vehicleBrand(selectedVehicle) }} {{ vehicleModel(selectedVehicle) }}</p>
                    </div>
                    <button class="fd-btn-edit" @click="openVehicleModal(selectedVehicle)">
                      <span class="material-icons-round" style="font-size: 16px;">edit_note</span>
                      EDITAR HOJA DE VIDA
                    </button>
                  </div>
                  
                  <!-- Status Indicators -->
                  <div class="fd-status-grid">
                    <div class="fd-status-card">
                      <div class="fd-status-dot" :class="statusDotClass(selectedVehicle.soat || selectedVehicle.fecha_vencimiento_soat)"></div>
                      <div class="fd-status-text">
                        <span class="fd-status-label">SEGURO OBLIGATORIO</span>
                        <span class="fd-status-value" :class="statusValueClass(selectedVehicle.soat || selectedVehicle.fecha_vencimiento_soat)">SOAT: {{ dateBadgeLabel(selectedVehicle.soat || selectedVehicle.fecha_vencimiento_soat) }}</span>
                      </div>
                    </div>
                    <div class="fd-status-card">
                      <div class="fd-status-dot" :class="statusDotClass(selectedVehicle.rtm || selectedVehicle.fecha_vencimiento_tecnomecanica)"></div>
                      <div class="fd-status-text">
                        <span class="fd-status-label">REVISIÓN MECÁNICA</span>
                        <span class="fd-status-value" :class="statusValueClass(selectedVehicle.rtm || selectedVehicle.fecha_vencimiento_tecnomecanica)">TÉCNICO-MECÁNICA: {{ dateBadgeLabel(selectedVehicle.rtm || selectedVehicle.fecha_vencimiento_tecnomecanica) }}</span>
                      </div>
                    </div>
                  </div>

                  <!-- Assignees -->
                  <div class="fd-assignees">
                    <h4 style="font-family: 'Inter', sans-serif; font-size: 0.85rem; color: var(--text-gray); margin-bottom: 8px; text-transform: uppercase;">Personal Asignado</h4>
                    <div class="fd-assignee-grid">
                      <div class="fd-assignee-card">
                        <div class="fd-assignee-avatar">
                          <span class="material-icons-round">engineering</span>
                        </div>
                        <div class="fd-assignee-info">
                          <span class="fd-assignee-role">Conductor / Operador</span>
                          <span class="fd-assignee-name" :style="!selectedVehicle.operador ? 'color: var(--text-gray); font-style: italic;' : ''">
                            {{ selectedVehicle.operador ? selectedVehicle.operador.name : 'Sin asignar' }}
                          </span>
                        </div>
                      </div>
                      
                      <div class="fd-assignee-card">
                        <div class="fd-assignee-avatar" style="background: rgba(244, 67, 54, 0.1); color: var(--danger);">
                          <span class="material-icons-round">handyman</span>
                        </div>
                        <div class="fd-assignee-info">
                          <span class="fd-assignee-role">Mecánico Encargado</span>
                          <span class="fd-assignee-name" :style="!selectedVehicle.mecanico ? 'color: var(--text-gray); font-style: italic;' : ''">
                            {{ selectedVehicle.mecanico ? selectedVehicle.mecanico.name : 'Sin asignar' }}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>

                </div>
              </div>

              <!-- KPI Indicators -->
              <div class="fd-kpi-grid">
              <div class="fd-kpi-card">
                <div class="fd-kpi-header">
                  <span class="material-icons-round">speed</span>
                  <span>KILOMETRAJE TOTAL</span>
                </div>
                <p class="fd-kpi-value">{{ formatNumber(vehicleKm(selectedVehicle)) }} <span class="fd-kpi-unit">Km</span></p>
              </div>
              <div class="fd-kpi-card">
                <div class="fd-kpi-header">
                  <span class="material-icons-round">timer</span>
                  <span>HORAS DE MOTOR</span>
                </div>
                <p class="fd-kpi-value">{{ formatNumber(vehicleHourmeter(selectedVehicle)) }} <span class="fd-kpi-unit">Hrs</span></p>
              </div>
              <div class="fd-kpi-card fd-kpi-primary">
                <div class="fd-kpi-header">
                  <span class="material-icons-round">event_upcoming</span>
                  <span>PRÓXIMO MANTENIMIENTO</span>
                </div>
                <!-- Mocked next maintenance values for UI, needs backend support normally -->
                <p class="fd-kpi-value-primary">1,500 <span class="fd-kpi-unit">Km restantes</span></p>
              </div>
            </div>
            </div>

            <!-- Taller Tab -->
            <div v-else-if="activeTab === 'taller'" class="fd-tab-content">
              <div class="fd-history-header" style="justify-content: space-between;">
                <h3>
                  <span class="material-icons-round">build</span>
                  Historial de Taller
                </h3>
                <button class="fd-btn-outline" style="color: var(--primary); border-color: var(--primary); display: flex; align-items: center; gap: 6px; padding: 6px 16px; font-size: 0.75rem;" @click="goToNewWorkOrder">
                  <span class="material-icons-round">add_circle</span>
                  NUEVA ORDEN
                </button>
              </div>
              <div v-if="!selectedVehicle.ordenes_trabajo?.length" class="empty-state">
                <span class="material-icons-round">build_circle</span>
                <p>No hay historial de taller para este vehículo</p>
              </div>
              <div v-else class="fd-history-table">
                <table>
                  <thead>
                    <tr>
                      <th>ID Orden</th>
                      <th>Fecha Inicio</th>
                      <th>Descripción</th>
                      <th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="ot in selectedVehicle.ordenes_trabajo" :key="ot.orden_trabajo_id">
                      <td style="font-weight: 500;">#OT-{{ ot.orden_trabajo_id }}</td>
                      <td style="color: var(--text-gray);">{{ formatDate(ot.fecha_inicio) }}</td>
                      <td>{{ ot.descripcion }}</td>
                      <td>
                        <span :class="ot.estado === 'Completada' ? 'fd-badge-completed' : (ot.estado === 'En Progreso' ? 'fd-badge-progress' : 'badge-neutral')">
                          {{ ot.estado?.toUpperCase() || 'DESCONOCIDO' }}
                        </span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Repuestos Tab -->
            <div v-else-if="activeTab === 'repuestos'" class="fd-tab-content">
              <div class="fd-history-header" style="justify-content: space-between;">
                <h3>
                  <span class="material-icons-round">inventory_2</span>
                  Historial de Repuestos
                </h3>
                <button class="fd-btn-outline" style="padding: 6px 16px; font-size: 0.75rem;" @click="goToInventory">+ REGISTRAR SALIDA</button>
              </div>
              <div v-if="!repuestosList.length" class="empty-state">
                <span class="material-icons-round">settings</span>
                <p>No hay registro de repuestos usados en este vehículo</p>
              </div>
              <div v-else class="fd-history-table">
                <table>
                  <thead>
                    <tr>
                      <th>Fecha</th>
                      <th>Repuesto</th>
                      <th>Motivo / Referencia</th>
                      <th style="text-align: right;">Cantidad</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="mov in repuestosList" :key="mov.transaccion_id">
                      <td style="color: var(--text-gray);">{{ formatDate(mov.created_at) }}</td>
                      <td style="font-weight: 500;">{{ mov.producto?.producto_nombre ?? 'Repuesto Desconocido' }}</td>
                      <td>
                        {{ mov.transaccion_motivo }}
                        <span v-if="mov.transaccion_referencia_type === 'OrdenTrabajo'" style="color: var(--text-gray); font-size: 11px;">
                          (OT #{{ mov.transaccion_referencia_id }})
                        </span>
                      </td>
                      <td style="text-align: right; font-family: monospace; color: var(--danger); font-weight: bold;">
                        -{{ Number(mov.transaccion_cantidad) }} {{ mov.producto?.producto_unidad_medida || 'unid.' }}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Preoperacionales Tab -->
            <div v-else-if="activeTab === 'preoperacionales'" class="fd-tab-content">
              <div class="fd-history-header" style="justify-content: space-between;">
                <h3>
                  <span class="material-icons-round">fact_check</span>
                  Historial Preoperacional
                </h3>
                <button class="fd-btn-outline" style="color: var(--success); border-color: var(--success); display: flex; align-items: center; gap: 6px; padding: 6px 16px; font-size: 0.75rem;" @click="goToFillChecklist">
                  <span class="material-icons-round">assignment_turned_in</span>
                  LLENAR PRE-OPERACIONAL
                </button>
              </div>
              <div v-if="!preoperacionalesList.length" class="empty-state">
                <span class="material-icons-round">assignment</span>
                <p>No se han registrado inspecciones para este vehículo</p>
              </div>
              <div v-else class="fd-history-table">
                <table>
                  <thead>
                    <tr>
                      <th>Fecha</th>
                      <th>Supervisor / Conductor</th>
                      <th>Estado General</th>
                      <th>Kilometraje</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="chk in preoperacionalesList" :key="chk.id">
                      <td style="color: var(--text-gray);">{{ formatDate(chk.created_at || chk.fecha) }}</td>
                      <td style="font-weight: 500;">{{ chk.operador?.name || 'Desconocido' }}</td>
                      <td>
                        <span :class="chk.estado === 'Aprobado' ? 'fd-badge-completed' : (chk.estado === 'Rechazado' ? 'badge-danger' : 'badge-warning')">
                          {{ chk.estado?.toUpperCase() || 'N/A' }}
                        </span>
                      </td>
                      <td>{{ formatNumber(chk.kilometraje_actual) }} Km</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Combustible Tab -->
            <div v-else-if="activeTab === 'combustible'" class="fd-tab-content">
              <div class="fd-history-header" style="justify-content: space-between;">
                <h3>
                  <span class="material-icons-round">local_gas_station</span>
                  Historial de Tanqueos
                </h3>
                <button class="fd-btn-outline" style="padding: 6px 16px; font-size: 0.75rem;" @click="goToRegisterFuel">+ REGISTRAR TANQUEO</button>
              </div>
              <div v-if="!combustibleList.length" class="empty-state">
                <span class="material-icons-round">local_gas_station</span>
                <p>No hay registros de combustible para este vehículo</p>
              </div>
              <div v-else class="fd-history-table">
                <table>
                  <thead>
                    <tr>
                      <th>Fecha</th>
                      <th>Conductor / Destino</th>
                      <th>Estación</th>
                      <th style="text-align: right;">Galones</th>
                      <th style="text-align: right;">Costo Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="fuel in combustibleList" :key="fuel.id">
                      <td style="color: var(--text-gray);">{{ formatDate(fuel.fecha) }}</td>
                      <td style="font-weight: 500;">
                        {{ fuel.empleado?.nombre ?? fuel.tercero_nombre ?? 'N/D' }}
                      </td>
                      <td>{{ fuel.estacion_servicio || 'Interno' }}</td>
                      <td style="text-align: right; font-weight: bold; color: var(--primary);">
                        {{ Number(fuel.cantidad_galones).toFixed(2) }} Gal
                      </td>
                      <td style="text-align: right; font-family: monospace;">
                        ${{ formatNumber(fuel.valor_total) }}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Horometro Tab -->
            <div v-else-if="activeTab === 'horometro'" class="fd-tab-content">
              <div class="fd-history-header" style="justify-content: space-between;">
                <h3>
                  <span class="material-icons-round">timer</span>
                  Historial de Horómetro
                </h3>
                <button class="fd-btn-outline" style="padding: 6px 16px; font-size: 0.75rem;" @click="goToFillChecklist">+ TOMAR LECTURA</button>
              </div>
              <div v-if="!horometroList.length" class="empty-state">
                <span class="material-icons-round">timer_off</span>
                <p>No hay lecturas de horómetro registradas</p>
              </div>
              <div v-else class="fd-history-table">
                <table>
                  <thead>
                    <tr>
                      <th>Fecha Captura</th>
                      <th>Registrado por</th>
                      <th style="text-align: right;">Lectura Ant.</th>
                      <th style="text-align: right;">Lectura Nueva</th>
                      <th>Notas</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="horo in horometroList" :key="horo.id">
                      <td style="color: var(--text-gray);">{{ formatDate(horo.created_at) }}</td>
                      <td style="font-weight: 500;">{{ horo.usuario?.name || 'Sistema' }}</td>
                      <td style="text-align: right;">{{ formatNumber(horo.valor_anterior) }} h</td>
                      <td style="text-align: right; font-weight: bold; color: var(--text-main);">{{ formatNumber(horo.valor_nuevo) }} h</td>
                      <td style="color: var(--text-gray); font-size: 0.8rem; max-width: 200px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                        {{ horo.notas || '—' }}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

          </div>

          <!-- Footer Actions -->
          <footer class="fd-footer">
            <button class="fd-btn-outline" @click="closeDetailModal">CERRAR</button>
            <button class="fd-btn-primary-lg" @click="showDocsModal = true">
              <span class="material-icons-round">description</span>
              DOCUMENTACIÓN
            </button>
          </footer>
        </div>
      </div>

      <!-- Documentation Modal -->
      <div v-if="showDocsModal && selectedVehicle" class="modal-overlay" @click.self="showDocsModal = false" style="z-index: 1001;">
        <div class="fd-modal" style="width: 600px; max-height: 80vh;">
          <header class="fd-header">
            <div class="fd-header-content">
              <div class="fd-header-title">
                <span class="material-icons-round" style="font-size: 16px;">library_books</span>
                <h2>DOCUMENTACIÓN <span class="fd-header-subtitle">/ {{ vehiclePlate(selectedVehicle) }}</span></h2>
              </div>
            </div>
            <button class="fd-close" @click="showDocsModal = false">
              <span class="material-icons-round">close</span>
            </button>
          </header>

          <div class="fd-body" style="min-height: auto;">
            <!-- SOAT History Placeholder -->
            <div class="fd-history-header">
              <h3>
                <span class="material-icons-round">health_and_safety</span>
                Seguro Obligatorio (SOAT)
              </h3>
            </div>
            <div class="fd-history-table">
              <table>
                <thead>
                  <tr>
                    <th>Fecha Inicio</th>
                    <th>Fecha Vencimiento</th>
                    <th>Compañía</th>
                    <th>Estado</th>
                    <th>Certificado</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="doc in documentosList.filter(d => d.tipo === 'soat')" :key="doc.id">
                    <td style="color: var(--text-gray);">{{ formatDate(doc.fecha_inicio) }}</td>
                    <td style="color: var(--text-gray);">{{ formatDate(doc.fecha_vencimiento) }}</td>
                    <td style="font-weight: 500;">{{ doc.compania || '—' }}</td>
                    <td>
                      <span class="badge" :class="dateBadgeClass(doc.fecha_vencimiento)">
                        {{ dateBadgeLabel(doc.fecha_vencimiento) }}
                      </span>
                    </td>
                    <td>
                      <a v-if="doc.certificado_pdf" :href="getDocUrl(doc.certificado_pdf)" target="_blank" class="material-icons-round" style="color: var(--primary);">description</a>
                      <span v-else>—</span>
                    </td>
                  </tr>
                  <tr v-if="documentosList.filter(d => d.tipo === 'soat').length === 0">
                    <td colspan="5" style="text-align: center; color: var(--text-gray);">No hay documentos SOAT registrados</td>
                  </tr>
                </tbody>
              </table>
              <div style="margin-top: 8px; text-align: right;">
                <button class="fd-btn-outline" @click="openRenewModal('soat')" style="font-size: 0.75rem; padding: 4px 12px; border-color: transparent;">+ Renovar SOAT</button>
              </div>
            </div>

            <hr style="border: none; border-top: 1px solid rgba(255, 255, 255, 0.1); margin: var(--sp-sm) 0;" />

            <!-- RTM History Placeholder -->
            <div class="fd-history-header">
              <h3>
                <span class="material-icons-round">verified</span>
                Revisión Técnico-Mecánica
              </h3>
            </div>
            <div class="fd-history-table">
              <table>
                <thead>
                  <tr>
                    <th>Fecha Inicio</th>
                    <th>Fecha Vencimiento</th>
                    <th>CDA</th>
                    <th>Estado</th>
                    <th>Certificado</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="doc in documentosList.filter(d => d.tipo === 'tecnomecanica')" :key="doc.id">
                    <td style="color: var(--text-gray);">{{ formatDate(doc.fecha_inicio) }}</td>
                    <td style="color: var(--text-gray);">{{ formatDate(doc.fecha_vencimiento) }}</td>
                    <td style="font-weight: 500;">{{ doc.compania || '—' }}</td>
                    <td>
                      <span class="badge" :class="dateBadgeClass(doc.fecha_vencimiento)">
                        {{ dateBadgeLabel(doc.fecha_vencimiento) }}
                      </span>
                    </td>
                    <td>
                      <a v-if="doc.certificado_pdf" :href="getDocUrl(doc.certificado_pdf)" target="_blank" class="material-icons-round" style="color: var(--primary);">description</a>
                      <span v-else>—</span>
                    </td>
                  </tr>
                  <tr v-if="documentosList.filter(d => d.tipo === 'tecnomecanica').length === 0">
                    <td colspan="5" style="text-align: center; color: var(--text-gray);">No hay documentos de tecnicomecánica registrados</td>
                  </tr>
                </tbody>
              </table>
               <div style="margin-top: 8px; text-align: right;">
                <button class="fd-btn-outline" @click="openRenewModal('tecnomecanica')" style="font-size: 0.75rem; padding: 4px 12px; border-color: transparent;">+ Renovar Tecnomecánica</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Renew Document Modal -->
      <div v-if="showRenewModal" class="modal-overlay" @click.self="closeRenewModal" style="z-index: 1002;">
        <div class="modal">
          <div class="modal-header">
            <h3>Renovar {{ renewType === 'soat' ? 'SOAT' : 'Tecnomecánica' }}</h3>
            <button @click="closeRenewModal" class="modal-close">
              <span class="material-icons-round">close</span>
            </button>
          </div>
          <div class="modal-body">
            <form @submit.prevent="submitRenewal">
              <div class="form-grid">
                <div class="input-group">
                  <label>Fecha Inicio</label>
                  <input v-model="renewForm.fecha_inicio" type="date" required class="input">
                </div>
                <div class="input-group">
                  <label>Fecha Vencimiento</label>
                  <input v-model="renewForm.fecha_vencimiento" type="date" required class="input">
                </div>
                <div class="input-group full-width">
                  <label>{{ renewType === 'soat' ? 'Compañía Aseguradora' : 'CDA' }}</label>
                  <input v-model="renewForm.compania" type="text" class="input">
                </div>
                <div class="input-group full-width">
                  <label>Certificado PDF</label>
                  <input @change="renewForm.certificado_pdf = $event.target.files[0]" type="file" accept=".pdf" class="input">
                </div>
              </div>
              <div class="modal-footer" style="border: none; padding: var(--sp-md) 0 0 0;">
                <button type="button" @click="closeRenewModal" class="btn btn-secondary" style="cursor: pointer;">Cancelar</button>
                <button type="submit" class="btn btn-primary" :disabled="loading" style="cursor: pointer;">Renovar</button>
              </div>
            </form>
          </div>
        </div>
      </div>

      <!-- Vehicle Create/Edit Modal -->
      <div v-if="showVehicleModal" class="modal-overlay" @click.self="closeVehicleModal">
        <div class="modal modal-wide">
          <div class="modal-header">
            <h3>{{ isEditingVehicle ? 'Editar Vehículo' : 'Nuevo Vehículo' }}</h3>
            <button @click="closeVehicleModal" class="modal-close">
              <span class="material-icons-round">close</span>
            </button>
          </div>
          <div class="modal-body">
            <form @submit.prevent="submitVehicle">
              <div class="form-grid">
                <div class="input-group">
                  <label>Placa <span style="color: var(--danger);">*</span></label>
                  <input v-model="vehicleForm.placa" type="text" required class="input" placeholder="ABC123" style="text-transform: uppercase;">
                </div>
                <div class="input-group">
                  <label>Tipo <span style="color: var(--danger);">*</span></label>
                  <select v-model="vehicleForm.tipo" required class="input">
                    <option value="" disabled>Seleccionar tipo</option>
                    <option v-for="t in typeFilters.filter(f => f.value !== 'all')" :key="t.value" :value="t.value">{{ t.label }}</option>
                  </select>
                </div>
                <div class="input-group full-width" style="display: grid; grid-template-columns: 1fr 1fr; gap: var(--sp-md);">
                  <div>
                    <label>Operador / Conductor Asignado</label>
                    <select v-model="vehicleForm.operador_asignado_id" class="input">
                      <option :value="''">(Sin asignar)</option>
                      <option v-for="op in operatorsList" :key="op.id" :value="op.id">
                        {{ op.nombres }} {{ op.apellidos || '' }}
                      </option>
                    </select>
                  </div>
                  <div>
                    <label>Mecánico Encargado</label>
                    <select v-model="vehicleForm.mecanico_asignado_id" class="input">
                      <option :value="''">(Sin asignar)</option>
                      <option v-for="mec in mechanicsList" :key="mec.id" :value="mec.id">
                        {{ mec.nombres }} {{ mec.apellidos || '' }}
                      </option>
                    </select>
                  </div>
                </div>
                <div class="input-group">
                  <label>Marca</label>
                  <input v-model="vehicleForm.marca" type="text" class="input" placeholder="Ej: Chevrolet">
                </div>
                <div class="input-group">
                  <label>Modelo (Año)</label>
                  <input v-model="vehicleForm.modelo" type="text" class="input" placeholder="Ej: 2024">
                </div>
                <div class="input-group">
                  <label>Kilometraje Actual</label>
                  <input v-model="vehicleForm.kilometraje_actual" type="number" min="0" class="input">
                </div>
                <div class="input-group">
                  <label>Horómetro Actual</label>
                  <input v-model="vehicleForm.horometro_actual" type="number" step="0.1" min="0" class="input">
                </div>
                <div class="input-group" v-if="!isEditingVehicle">
                  <label>Vencimiento SOAT</label>
                  <input v-model="vehicleForm.fecha_vencimiento_soat" type="date" class="input">
                </div>
                <div class="input-group" v-if="!isEditingVehicle">
                  <label>Vencimiento Tecnomecánica</label>
                  <input v-model="vehicleForm.fecha_vencimiento_tecnomecanica" type="date" class="input">
                </div>
              </div>

              <!-- Foto del vehículo (solo al editar) -->
              <div v-if="isEditingVehicle" class="vehicle-photo-section">
                <div class="vehicle-photo-wrap" @click="$refs.fileInputModal.click()" :title="isUploading ? 'Subiendo...' : 'Clic para cambiar la foto'">
                  <img
                    :src="getVehicleImage(selectedVehicle)"
                    alt="Foto del vehículo"
                    class="vehicle-photo-preview"
                    @error="$event.target.src = 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22160%22 height=%22110%22 viewBox=%220 0 160 110%22%3E%3Crect width=%22160%22 height=%22110%22 fill=%22%231e1e1e%22/%3E%3Ctext x=%2250%25%22 y=%2245%25%22 dominant-baseline=%22middle%22 text-anchor=%22middle%22 font-size=%2232%22%3E%F0%9F%9A%97%3C/text%3E%3Ctext x=%2250%25%22 y=%2270%25%22 dominant-baseline=%22middle%22 text-anchor=%22middle%22 font-family=%22sans-serif%22 font-size=%2210%22 fill=%22%23666%22%3ESin foto%3C/text%3E%3C/svg%3E'"
                  />
                  <div class="vehicle-photo-overlay">
                    <span class="material-icons-round">{{ isUploading ? 'hourglass_top' : 'photo_camera' }}</span>
                    <span>{{ isUploading ? 'SUBIENDO...' : 'CAMBIAR FOTO' }}</span>
                  </div>
                  <input
                    type="file"
                    ref="fileInputModal"
                    style="display: none"
                    accept="image/*"
                    @change="handleImageUpload"
                  />
                </div>
                <p class="vehicle-photo-hint">Clic en la imagen para subir una nueva foto</p>
              </div>

              <div class="modal-footer" style="border: none; padding: var(--sp-md) 0 0 0;">
                <button type="button" @click="closeVehicleModal" class="btn btn-secondary" style="cursor: pointer;">Cancelar</button>
                <button type="submit" class="btn btn-primary" :disabled="loadingVehicle" style="cursor: pointer;">
                  {{ loadingVehicle ? 'Guardando...' : (isEditingVehicle ? 'Guardar Cambios' : 'Crear Vehículo') }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useAsyncState } from '../../../shared/composables/useAsyncState';
import { fetchFleetVehicles, uploadVehicleImage, getVehicleDetails, getVehicleFuelHistory, getVehicleHourMeters, getVehiclePreoperacionales, getVehicleDocuments, createVehicleDocument, createVehicle, updateVehicle, fetchMechanics, fetchOperators } from '../api/fleetService';
import { useRefresh } from '../../../shared/composables/useRefresh';

const router = useRouter();
const { refreshTrigger } = useRefresh();

const { loading, error, run } = useAsyncState('');
const search = ref('');
const selectedType = ref('all');
const vehicles = ref([]);
const operatorsList = ref([]);
const mechanicsList = ref([]);
const showDetailModal = ref(false);
const showDocsModal = ref(false);
const selectedVehicle = ref(null);
const isUploading = ref(false);
const isEditing = ref(false); // Keeps image upload state
const showVehicleModal = ref(false);
const isEditingVehicle = ref(false);
const loadingVehicle = ref(false);
const activeTab = ref('resumen');
const loadingDetails = ref(false);
const combustibleList = ref([]);
const horometroList = ref([]);
const preoperacionalesList = ref([]);
const documentosList = ref([]);
const showRenewModal = ref(false);
const renewType = ref('');
const renewForm = ref({
  fecha_inicio: '',
  fecha_vencimiento: '',
  compania: '',
  certificado_pdf: null
});

const vehicleForm = ref({
  placa: '',
  tipo: '',
  marca: '',
  modelo: '',
  kilometraje_actual: 0,
  horometro_actual: 0,
  fecha_vencimiento_soat: '',
  fecha_vencimiento_tecnomecanica: '',
  operador_asignado_id: '',
  mecanico_asignado_id: ''
});

const typeFilters = [
  { value: 'all', label: 'Todos' },
  { value: 'tractor', label: 'Tractores' },
  { value: 'volqueta', label: 'Volquetas' },
  { value: 'camioneta', label: 'Camionetas' },
  { value: 'moto', label: 'Motos' },
  { value: 'maquinaria', label: 'Maquinaria' },
];

const loadData = async () => {
  try {
    await run(async () => {
      const [vData, oData, mData] = await Promise.all([
        fetchFleetVehicles(),
        fetchOperators(),
        fetchMechanics()
      ]);
      vehicles.value = vData;
      operatorsList.value = oData;
      mechanicsList.value = mData;
    }, 'Error al cargar datos');
  } catch {
    // handled by composable
  }
};

onMounted(loadData);

watch(refreshTrigger, loadData);

const filteredVehicles = computed(() => {
  const q = search.value.trim().toLowerCase();

  return vehicles.value.filter((v) => {
    const plate = vehiclePlate(v).toLowerCase();
    const brand = vehicleBrand(v).toLowerCase();
    const model = vehicleModel(v).toLowerCase();
    const type = vehicleType(v).toLowerCase();

    const matchesSearch = !q || plate.includes(q) || brand.includes(q) || model.includes(q);
    const matchesType = selectedType.value === 'all' || type.includes(selectedType.value);

    return matchesSearch && matchesType;
  });
});

const repuestosList = computed(() => {
  if (!selectedVehicle.value) return [];
  const list = [];
  
  if (selectedVehicle.value.movimientos_directos) {
    list.push(...selectedVehicle.value.movimientos_directos);
  }
  
  if (selectedVehicle.value.ordenes_trabajo) {
    selectedVehicle.value.ordenes_trabajo.forEach(ot => {
      if (ot.movimientos_inventario) {
        list.push(...ot.movimientos_inventario);
      }
    });
  }
  
  // Sort descending by created_at
  return list.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
});

function isMachinery(v) {
  if (!v) return false;
  const t = (v.tipo || '').toLowerCase();
  return t.includes('tractor') || t.includes('maquinaria') || t.includes('pesada') || t.includes('volqueta');
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('es-CO', { year: 'numeric', month: 'short', day: 'numeric' });
}

function vehicleId(v) {
  return v.vehiculo_id ?? v.id ?? v.placa ?? Math.random();
}

function vehiclePlate(v) {
  return v.placa ?? '—';
}

function vehicleType(v) {
  return v.tipo ?? '—';
}

function vehicleBrand(v) {
  return v.marca ?? '—';
}

function vehicleModel(v) {
  return v.modelo ?? '—';
}

function vehicleKm(v) {
  return Number(v.kilometraje_actual ?? 0);
}

function vehicleHourmeter(v) {
  return Number(v.horometro_actual ?? 0);
}

function formatNumber(value) {
  return Number(value || 0).toLocaleString('es-CO');
}

function dateBadgeClass(rawDate) {
  if (!rawDate) return 'badge-neutral';

  const expiry = new Date(rawDate);
  if (Number.isNaN(expiry.getTime())) return 'badge-neutral';

  const now = new Date();
  const diffDays = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return 'badge-danger';
  if (diffDays <= 30) return 'badge-warning';
  return 'badge-success';
}

function dateBadgeLabel(rawDate) {
  if (!rawDate) return 'N/D';

  const expiry = new Date(rawDate);
  if (Number.isNaN(expiry.getTime())) return 'N/D';

  const now = new Date();
  const diffDays = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return 'Vencido';
  if (diffDays <= 30) return `${diffDays}d`;
  return 'Vigente';
}

async function goToVehicle(vehicle) {
  selectedVehicle.value = vehicle;
  showDetailModal.value = true;
  activeTab.value = 'resumen';
  combustibleList.value = [];
  horometroList.value = [];
  preoperacionalesList.value = [];
  documentosList.value = [];
  
  loadingDetails.value = true;
  try {
    const vId = vehicle.vehiculo_id || vehicle.id;
    const [fullData, fuelData, horoData, preopsData, docsData] = await Promise.all([
      getVehicleDetails(vId),
      getVehicleFuelHistory(vId),
      isMachinery(vehicle) ? getVehicleHourMeters(vId) : Promise.resolve([]),
      getVehiclePreoperacionales(vId),
      getVehicleDocuments(vId)
    ]);
    
    selectedVehicle.value = { ...vehicle, ...fullData };
    combustibleList.value = fuelData;
    horometroList.value = horoData;
    preoperacionalesList.value = preopsData;
    documentosList.value = docsData;
  } catch (err) {
    console.error('Error fetching vehicle details:', err);
  } finally {
    loadingDetails.value = false;
  }
}

function closeDetailModal() {
  showDetailModal.value = false;
  showDocsModal.value = false;
  selectedVehicle.value = null;
  isEditing.value = false;
}

function openRenewModal(type) {
  renewType.value = type;
  renewForm.value = {
    fecha_inicio: '',
    fecha_vencimiento: '',
    compania: '',
    certificado_pdf: null
  };
  showRenewModal.value = true;
}

function closeRenewModal() {
  showRenewModal.value = false;
  renewType.value = '';
}

function getDocUrl(path) {
  if (!path) return '#';
  if (path.startsWith('http')) return path;
  return `${import.meta.env.VITE_API_BASE_URL.replace('/api', '')}/storage/${path}`;
}

function openVehicleModal(vehicle = null) {
  isEditingVehicle.value = !!vehicle;
  if (vehicle) {
    vehicleForm.value = {
      placa: vehicle.placa || '',
      tipo: (vehicle.tipo || '').toLowerCase(),
      marca: vehicle.marca || '',
      modelo: vehicle.modelo || '',
      kilometraje_actual: vehicle.kilometraje_actual || 0,
      horometro_actual: vehicle.horometro_actual || 0,
      // Default to empty strings for specific edits
      fecha_vencimiento_soat: '', 
      fecha_vencimiento_tecnomecanica: '',
      operador_asignado_id: vehicle.operador_asignado_id || '',
      mecanico_asignado_id: vehicle.mecanico_asignado_id || ''
    };
  } else {
    vehicleForm.value = {
      placa: '',
      tipo: '',
      marca: '',
      modelo: '',
      kilometraje_actual: 0,
      horometro_actual: 0,
      fecha_vencimiento_soat: '',
      fecha_vencimiento_tecnomecanica: '',
      operador_asignado_id: '',
      mecanico_asignado_id: ''
    };
  }
  showVehicleModal.value = true;
}

function closeVehicleModal() {
  showVehicleModal.value = false;
  isEditingVehicle.value = false;
}

async function submitVehicle() {
  loadingVehicle.value = true;
  try {
    const payload = { ...vehicleForm.value };
    // Asegurarse de que la placa siempre sea mayúscula
    if (payload.placa) payload.placa = payload.placa.toUpperCase();
    
    if (isEditingVehicle.value && selectedVehicle.value) {
      const vId = selectedVehicle.value.vehiculo_id || selectedVehicle.value.id;
      // Remover fechas si están vacias en edición para no sobreescribir con null a menos que mande explícito
      Object.keys(payload).forEach(key => {
        if (payload[key] === '' || payload[key] === null) {
            delete payload[key];
        }
      });
      const res = await updateVehicle(vId, payload);
      alert('Vehículo actualizado exitosamente');
      // Actualizar vista de detalle
      if (res && res.vehiculo) {
        selectedVehicle.value = { ...selectedVehicle.value, ...res.vehiculo };
      }
    } else {
      await createVehicle(payload);
      alert('Vehículo creado exitosamente');
    }
    
    closeVehicleModal();
    // Refrescar lista principal
    await loadData();
    
  } catch (err) {
    const msg = err.response?.data?.message || err.response?.data?.errors?.placa?.[0] || 'Error al guardar el vehículo';
    alert(msg);
  } finally {
    loadingVehicle.value = false;
  }
}


async function submitRenewal() {
  try {
    await run(async () => {
      const vId = selectedVehicle.value.vehiculo_id || selectedVehicle.value.id;
      await createVehicleDocument(vId, {
        tipo: renewType.value,
        ...renewForm.value
      });
      // Recargar documentos
      documentosList.value = await getVehicleDocuments(vId);
    }, 'Documento renovado exitosamente');
    closeRenewModal();
  } catch (err) {
    // Error handled by composable
  }
}

function goToFillChecklist() {
  if (!selectedVehicle.value) return;
  const vId = selectedVehicle.value.vehiculo_id || selectedVehicle.value.id;
  closeDetailModal();
  router.push({ name: 'checklists', query: { vehiculo_id: vId, action: 'new' } });
}

function goToRegisterFuel() {
  if (!selectedVehicle.value) return;
  const vId = selectedVehicle.value.vehiculo_id || selectedVehicle.value.id;
  closeDetailModal();
  router.push({ name: 'fuel', query: { vehiculo_id: vId, action: 'new' } });
}

function goToNewWorkOrder() {
  if (!selectedVehicle.value) return;
  const vId = selectedVehicle.value.vehiculo_id || selectedVehicle.value.id;
  closeDetailModal();
  router.push({ name: 'work-orders', query: { vehiculo_id: vId, action: 'new' } });
}

function goToInventory() {
  closeDetailModal();
  router.push({ name: 'inventory' });
}

function statusDotClass(rawDate) {
  if (!rawDate) return 'fd-dot-neutral';
  
  const expiry = new Date(rawDate);
  if (Number.isNaN(expiry.getTime())) return 'fd-dot-neutral';

  const now = new Date();
  const diffDays = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return 'fd-dot-danger';
  if (diffDays <= 30) return 'fd-dot-warning';
  return 'fd-dot-success';
}

function statusValueClass(rawDate) {
  if (!rawDate) return 'fd-text-neutral';
  
  const expiry = new Date(rawDate);
  if (Number.isNaN(expiry.getTime())) return 'fd-text-neutral';

  const now = new Date();
  const diffDays = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));

  if (diffDays < 0) return 'fd-text-danger';
  if (diffDays <= 30) return 'fd-text-warning';
  return 'fd-text-success';
}

function compressImage(file, maxWidth = 1000, quality = 0.8) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = (event) => {
      const img = new Image();
      img.src = event.target.result;
      img.onload = () => {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');

        // Calculate new dimensions
        let width = img.width;
        let height = img.height;
        if (width > maxWidth) {
          height = Math.round((height * maxWidth) / width);
          width = maxWidth;
        }

        canvas.width = width;
        canvas.height = height;
        ctx.drawImage(img, 0, 0, width, height);

        // Convert canvas back to Blob (file-like object)
        canvas.toBlob(
          (blob) => {
            if (!blob) {
              reject(new Error('Canvas to Blob failed'));
              return;
            }
            // Create a new File from the Blob
            const compressedFile = new File([blob], file.name.replace(/\.[^/.]+$/, "") + ".jpg", {
              type: 'image/jpeg',
              lastModified: Date.now(),
            });
            resolve(compressedFile);
          },
          'image/jpeg',
          quality
        );
      };
      img.onerror = (error) => reject(error);
    };
    reader.onerror = (error) => reject(error);
  });
}

async function handleImageUpload(event) {
  const rawFile = event.target.files[0];
  if (!rawFile || !selectedVehicle.value) return;

  isUploading.value = true;
  try {
    // Compress the file on the client side before uploading
    const compressedFile = await compressImage(rawFile, 1000, 0.82);
    
    const vehicleId = selectedVehicle.value.vehiculo_id || selectedVehicle.value.id;
    await uploadVehicleImage(vehicleId, compressedFile);
    
    // Refresh list to get new image URL
    await loadData();
    // Update local selected vehicle if it matches
    const updated = vehicles.value.find(v => (v.vehiculo_id || v.id) === vehicleId);
    if (updated) selectedVehicle.value = updated;
  } catch (err) {
    console.error('Error al subir imagen:', err);
    alert('No se pudo subir la imagen');
  } finally {
    isUploading.value = false;
    event.target.value = ''; // Reset input
  }
}


function getVehicleImage(v) {
  if (!v) return '/fleet/generic.png';

  // If backend provides an image, use it
  if (v.imagen_url) {
    // Basic check if it's a full URL or relative
    if (v.imagen_url.startsWith('http')) return v.imagen_url;
    // Assuming backend serves from static or similar, might need adjustment 
    // depending on where the backend serves images from.
    return `${import.meta.env.VITE_API_BASE_URL.replace('/api', '')}/storage/${v.imagen_url}`;
  }
  
  const type = vehicleType(v).toLowerCase();
  
  if (type.includes('tractor') || type.includes('camion') || type.includes('mula')) {
    return '/fleet/tractor.png';
  }
  if (type.includes('volqueta')) {
    return '/fleet/volqueta.png';
  }
  if (type.includes('camioneta') || type.includes('pickup')) {
    return '/fleet/camioneta.png';
  }
  if (type.includes('moto')) {
    return '/fleet/moto.png';
  }
  if (type.includes('maquinaria') || type.includes('excavadora')) {
    return '/fleet/maquinaria.png';
  }

  return '/fleet/generic.png';
}
</script>

<style scoped>
/* Modal Container */
.fd-modal {
  width: 850px;
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

/* Header */
.fd-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
  border-bottom: 1px solid var(--surface-2);
  background: var(--surface);
  position: sticky;
  top: 0;
  z-index: 10;
}

.fd-header-content {
  display: flex;
  align-items: center;
  gap: 20px;
  flex: 1;
}

.fd-header-title {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--primary);
  flex-shrink: 0;
}

/* Tabs inside Header */
.fd-tabs-header {
  border-bottom: none;
  margin: 0 0 0 auto;
  display: flex;
  gap: 4px;
  background: var(--bg-dark);
  padding: 4px;
  border-radius: 40px;
  border: 1px solid var(--surface-2);
  align-items: center;
}

.fd-tabs-header button {
  padding: 6px 14px;
  border: none;
  border-radius: 30px;
  font-size: 0.7rem;
  color: var(--text-main);
  background: transparent;
  transition: all 0.2s ease;
  font-family: 'Inter', sans-serif;
  font-weight: 500;
  opacity: 0.8;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.fd-tabs-header button:hover {
  background: var(--surface-2);
  opacity: 1;
}

.fd-tabs-header button.active {
  background: var(--primary-10); 
  color: var(--primary);
  font-weight: 700;
  opacity: 1;
}

@media (max-width: 768px) {
  .fd-header-content {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }
  .fd-tabs-header {
    width: 100%;
    overflow-x: auto;
    padding-bottom: 4px;
  }
}

.fd-header-title h2 {
  font-family: 'Inter', sans-serif;
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--text-main);
  letter-spacing: -0.5px;
  text-transform: uppercase;
  margin: 0;
}

.fd-header-subtitle {
  color: rgba(242, 242, 13, 0.7);
}

.fd-close {
  padding: 8px;
  border-radius: 50%;
  border: none;
  background: transparent;
  color: var(--text-gray);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.fd-close:hover {
  background: var(--surface-2);
}

/* Body */
.fd-body {
  padding: var(--sp-lg);
  display: flex;
  flex-direction: column;
  gap: var(--sp-lg);
  overflow-y: auto;
  min-height: 65vh;
}

/* Identity Section */
.fd-identity {
  display: flex;
  flex-direction: column;
  gap: var(--sp-lg);
  align-items: flex-start;
}

@media (min-width: 768px) {
  .fd-identity {
    flex-direction: row;
  }
}

.fd-image-container {
  width: 100%;
  height: 192px;
  border-radius: var(--radius-md);
  overflow: hidden;
  flex-shrink: 0;
  background: var(--surface-2);
  border: 2px solid var(--primary-20);
}

@media (min-width: 768px) {
  .fd-image-container {
    width: 192px;
  }
}

.fd-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.fd-image-container {
  position: relative;
  cursor: pointer;
}

.fd-image-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  opacity: 0;
  transition: opacity 0.3s ease;
  color: white;
  pointer-events: none;
}

.fd-image-container:hover .fd-image-overlay {
  opacity: 1;
}

.fd-image-overlay span:last-child {
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 1px;
}


.fd-identity-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: var(--sp-md);
  width: 100%;
}

.fd-identity-top {
  display: flex;
  flex-direction: column;
  gap: var(--sp-sm);
  justify-content: space-between;
}

@media (min-width: 640px) {
  .fd-identity-top {
    flex-direction: row;
    align-items: center;
  }
}

.fd-plate {
  font-family: 'Oswald', sans-serif;
  font-size: 2rem;
  font-weight: 700;
  color: var(--text-main);
  line-height: 1;
  margin: 0 0 4px 0;
}

.fd-model {
  color: var(--text-gray);
  font-weight: 500;
  font-size: 1.1rem;
  margin: 0;
}

.fd-btn-edit {
  background: var(--primary);
  color: #000;
  font-weight: 700;
  font-family: 'Inter', sans-serif;
  padding: 8px 16px;
  border-radius: var(--radius-sm);
  border: none;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.82rem;
  text-transform: uppercase;
  cursor: pointer;
  transition: filter var(--transition-fast);
}

.fd-btn-edit:hover {
  filter: brightness(1.1);
}

/* Status Indicators */
.fd-status-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--sp-md);
}

@media (min-width: 640px) {
  .fd-status-grid {
    grid-template-columns: 1fr 1fr;
  }
}

.fd-status-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  border-radius: var(--radius-sm);
  background: var(--bg-dark);
  border: 1px solid var(--surface-2);
}

.fd-status-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
}

.fd-dot-success {
  background: var(--success);
  box-shadow: 0 0 10px rgba(76, 175, 80, 0.5);
}

.fd-dot-danger {
  background: var(--danger);
  box-shadow: 0 0 10px rgba(244, 67, 54, 0.5);
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.fd-dot-warning {
  background: var(--warning);
  box-shadow: 0 0 10px rgba(255, 152, 0, 0.5);
}

.fd-dot-neutral {
  background: var(--text-gray);
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: .5; }
}

.fd-status-text {
  display: flex;
  flex-direction: column;
}

.fd-status-label {
  font-size: 0.62rem;
  text-transform: uppercase;
  font-weight: 700;
  color: var(--text-gray);
  line-height: 1;
  margin-bottom: 2px;
}

.fd-status-value {
  font-weight: 700;
  text-transform: uppercase;
  font-size: 0.85rem;
}

.fd-text-success { color: var(--text-main); }
.fd-text-danger { color: var(--danger); }
.fd-text-warning { color: var(--warning); }
.fd-text-neutral { color: var(--text-gray); }


/* KPI Grid */
.fd-kpi-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--sp-md);
  margin-top: 32px;
}

@media (min-width: 640px) {
  .fd-kpi-grid {
    grid-template-columns: 1fr 1fr 1fr;
  }
}

.fd-kpi-card {
  background: var(--bg-dark);
  padding: var(--sp-md);
  border-radius: var(--radius-sm);
  border-left: 4px solid var(--primary);
}

.fd-kpi-primary {
  background: var(--primary-10);
}

.fd-kpi-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.fd-kpi-header .material-icons-round {
  color: var(--primary);
  font-size: 20px;
}

.fd-kpi-header span:not(.material-icons-round) {
  font-size: 0.68rem;
  font-weight: 700;
  text-transform: uppercase;
  color: var(--text-gray);
}

.fd-kpi-value {
  font-family: 'Oswald', sans-serif;
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--text-main);
  margin: 0;
}

.fd-kpi-value-primary {
  font-family: 'Oswald', sans-serif;
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--primary);
  margin: 0;
}

.fd-kpi-unit {
  font-family: 'Inter', sans-serif;
  font-size: 0.8rem;
  font-weight: 400;
  color: var(--text-gray);
}

/* Assignees */
.fd-assignees {
  margin-top: 8px;
}
.fd-assignee-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
}
@media (min-width: 640px) {
  .fd-assignee-grid {
    grid-template-columns: 1fr 1fr;
  }
}
.fd-assignee-card {
  display: flex;
  align-items: center;
  gap: 12px;
  background: var(--bg-dark);
  padding: 12px 16px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--surface-2);
}
.fd-assignee-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--primary-10);
  color: var(--primary);
  display: flex;
  align-items: center;
  justify-content: center;
}
.fd-assignee-info {
  display: flex;
  flex-direction: column;
}
.fd-assignee-role {
  font-size: 0.65rem;
  color: var(--text-gray);
  text-transform: uppercase;
  font-weight: 700;
}
.fd-assignee-name {
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--text-main);
}

/* History */
.fd-history {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.fd-history-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.fd-history-header h3 {
  font-family: 'Inter', sans-serif;
  font-size: 1.1rem;
  font-weight: 700;
  text-transform: none;
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0;
}

.fd-link-btn {
  font-size: 0.72rem;
  font-weight: 700;
  color: var(--primary);
  text-transform: uppercase;
  background: none;
  border: none;
  border-bottom: 1px solid rgba(242, 242, 13, 0.3);
  padding: 0 0 2px 0;
  cursor: pointer;
  transition: border-color var(--transition-fast);
}

.fd-link-btn:hover {
  border-color: var(--primary);
}

.fd-history-table {
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.fd-history-table table {
  width: 100%;
  text-align: left;
  font-size: 0.85rem;
  border-collapse: collapse;
}

.fd-history-table thead tr {
  background: var(--bg-dark);
}

.fd-history-table th {
  padding: 12px 16px;
  color: var(--text-gray);
  text-transform: uppercase;
  font-size: 0.62rem;
  font-weight: 700;
  letter-spacing: 0.5px;
  border-bottom: 1px solid var(--surface-2);
}

.fd-history-table td {
  padding: 12px 16px;
  border-bottom: 1px solid var(--surface-2);
}

.fd-history-table tbody tr:hover {
  background: var(--primary-10);
  transition: background var(--transition-fast);
}

.fd-badge-completed {
  background: var(--success-10);
  color: var(--success);
  font-size: 0.62rem;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 10px;
  text-transform: uppercase;
}

.fd-badge-progress {
  background: var(--primary-20);
  color: var(--primary);
  font-size: 0.62rem;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 10px;
  text-transform: uppercase;
}

/* Footer Actions */
.fd-footer {
  padding: var(--sp-lg);
  background: var(--bg-dark);
  border-top: 1px solid var(--surface-2);
  display: flex;
  flex-direction: column;
  gap: 12px;
  justify-content: flex-end;
}

@media (min-width: 640px) {
  .fd-footer {
    flex-direction: row;
  }
}

.fd-btn-outline {
  padding: 12px 24px;
  border-radius: 24px;
  border: 1px solid var(--surface-3);
  background: transparent;
  color: var(--text-main);
  font-weight: 700;
  text-transform: uppercase;
  font-size: 0.85rem;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.fd-btn-outline:hover {
  background: var(--surface-2);
}

.fd-btn-primary-lg {
  padding: 12px 32px;
  border-radius: 24px;
  background: var(--primary);
  color: #000;
  font-weight: 700;
  text-transform: uppercase;
  font-size: 0.85rem;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  box-shadow: 0 4px 15px rgba(242, 242, 13, 0.2);
  cursor: pointer;
  transition: transform var(--transition-fast);
}

.fd-btn-primary-lg:hover {
  transform: scale(1.02);
}

.fd-btn-primary-lg:active {
  transform: scale(0.98);
}


.fd-tab-content {
  animation: fadeIn 0.3s ease;
}
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(5px); }
  to { opacity: 1; transform: translateY(0); }
}
/* ── Foto en modal de editar ── */
.vehicle-photo-section {
  margin: var(--sp-md) 0 var(--sp-sm) 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.vehicle-photo-wrap {
  position: relative;
  width: 160px;
  height: 110px;
  border-radius: var(--radius-md);
  overflow: hidden;
  cursor: pointer;
  border: 2px solid var(--surface-2);
  transition: border-color 0.2s ease;
}

.vehicle-photo-wrap:hover {
  border-color: var(--primary);
}

.vehicle-photo-preview {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.vehicle-photo-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.55);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  opacity: 0;
  transition: opacity 0.2s ease;
  color: var(--primary);
  font-size: 0.65rem;
  font-weight: 800;
  letter-spacing: 1px;
}

.vehicle-photo-overlay .material-icons-round {
  font-size: 26px;
}

.vehicle-photo-wrap:hover .vehicle-photo-overlay {
  opacity: 1;
}

.vehicle-photo-hint {
  font-size: 0.72rem;
  color: var(--text-muted);
  font-style: italic;
}
</style>

