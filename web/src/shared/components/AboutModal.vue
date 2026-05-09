<template>
  <Teleport to="body">
    <div v-if="visible" class="modal-overlay" @click.self="$emit('close')">
      <div class="modal modal-about">
        <div class="modal-header">
          <h3>ACERCA DE</h3>
          <button class="modal-close" @click="$emit('close')">
            <span class="material-icons-round">close</span>
          </button>
        </div>

        <div class="modal-body about-body">
          <!-- Logo -->
          <div class="about-logo">
            <img :src="logoImage" alt="Semanur HUB" class="about-logo-img" />
          </div>

          <!-- App Name -->
          <h1 class="about-app-name">Semanur HUB</h1>
          <p class="about-tagline">Sistema de Gestión de Taller y Operaciones</p>

          <!-- Version Badge -->
          <div class="about-version-badge">
            <span class="material-icons-round">code</span>
            <span>{{ version }}</span>
          </div>

          <!-- Info Cards -->
          <div class="about-cards">
            <div class="about-card about-card--primary">
              <span class="material-icons-round">business</span>
              <div class="about-card-body">
                <p class="about-card-label">DESARROLLADO POR</p>
                <p class="about-card-value">Agropecuaria Juradó S.A.S.</p>
              </div>
            </div>

            <div class="about-card">
              <span class="material-icons-round">calendar_today</span>
              <div class="about-card-body">
                <p class="about-card-label">AÑO</p>
                <p class="about-card-value">{{ currentYear }}</p>
              </div>
            </div>

            <div class="about-card">
              <span class="material-icons-round">security</span>
              <div class="about-card-body">
                <p class="about-card-label">DERECHOS</p>
                <p class="about-card-value">© {{ currentYear }} Todos reservados</p>
              </div>
            </div>
          </div>

          <!-- Description -->
          <div class="about-description">
            <p>
              Semanur HUB es un sistema integral de gestión de taller y operaciones, 
              diseñado para optimizar el mantenimiento de flota, control de inventarios, 
              gestión de combustible, órdenes de trabajo y programación de actividades 
              operativas.
            </p>
          </div>
        </div>

        <div class="modal-footer about-footer">
          <button class="btn btn-secondary" @click="$emit('close')">
            <span class="material-icons-round">check_circle</span>
            CERRAR
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import logoImage from '/logo.png';

defineProps({
  visible: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['close']);

const version = '0.5-alpha';
const currentYear = new Date().getFullYear();
</script>

<style scoped>
/* Modal About Specific */
.modal-about {
  max-width: 520px;
}

.about-body {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  padding: var(--sp-lg) !important;
}

/* Logo */
.about-logo {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  background: var(--surface-1);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
  margin-bottom: 8px;
  overflow: hidden;
  border: 3px solid var(--surface-3);
  padding: 12px;
}

.about-logo-img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

/* App Name */
.about-app-name {
  font-size: 1.75rem;
  font-weight: 800;
  color: var(--text-main);
  margin: 0;
  letter-spacing: -0.5px;
}

.about-tagline {
  font-size: 0.9rem;
  color: var(--text-gray);
  margin: 0;
  font-weight: 500;
}

/* Version Badge */
.about-version-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  background: var(--surface-2);
  border: 1px solid var(--surface-3);
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--primary);
}

.about-version-badge .material-icons-round {
  font-size: 16px;
}

/* Info Cards */
.about-cards {
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 100%;
}

.about-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  background: var(--surface-1);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  transition: all 0.2s ease;
}

.about-card:hover {
  border-color: var(--primary);
  background: var(--surface-2);
}

.about-card .material-icons-round {
  font-size: 24px;
  color: var(--primary);
  flex-shrink: 0;
}

.about-card-body {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.about-card-label {
  font-size: 0.65rem;
  color: var(--text-gray);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 700;
  margin: 0 0 2px 0;
}

.about-card-value {
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--text-main);
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.about-card--primary {
  background: linear-gradient(135deg, rgba(76, 175, 80, 0.08) 0%, rgba(76, 175, 80, 0.02) 100%);
  border-color: rgba(76, 175, 80, 0.3);
}

.about-card--primary .material-icons-round {
  color: var(--success);
}

/* Description */
.about-description {
  width: 100%;
  text-align: center;
  padding: 12px;
  background: rgba(76, 175, 80, 0.05);
  border: 1px solid rgba(76, 175, 80, 0.2);
  border-radius: var(--radius-md);
}

.about-description p {
  font-size: 0.85rem;
  line-height: 1.6;
  color: var(--text-muted);
  margin: 0;
}

/* Footer */
.about-footer {
  padding: var(--sp-md) var(--sp-lg);
  border-top: 1px solid var(--surface-2);
  background: var(--surface);
  border-radius: 0 0 var(--radius-md) var(--radius-md);
}
</style>
