<template>
  <Teleport to="body">
    <div v-if="visible" class="modal-overlay" @click.self="$emit('close')">
      <div class="modal modal-about">
        <div class="modal-header">
          <h3>Acerca de</h3>
          <button class="modal-close" @click="$emit('close')">
            <span class="material-icons-round">close</span>
          </button>
        </div>

        <div class="modal-body about-body">
          <!-- Logo -->
          <div class="about-logo">
            <img :src="logoImage" alt="Semanur HUB" />
          </div>

          <!-- Title -->
          <div class="about-title">
            <h1>Semanur HUB</h1>
            <p>Sistema Integral de Gestion de Taller y Operaciones</p>
          </div>

          <!-- Version -->
          <div class="about-version">
            <span class="version-pill">{{ version }}</span>
          </div>

          <!-- Divider -->
          <div class="about-divider"></div>

          <!-- Info Lines -->
          <div class="about-info">
            <div class="info-row">
              <span class="info-label">Desarrollado por</span>
              <span class="info-value">Agropecuaria Jurado S.A.S.</span>
            </div>
            <div class="info-row">
              <span class="info-label">Stack</span>
              <span class="info-value">Vue 3 + Laravel 11 + Flutter</span>
            </div>
            <div class="info-row">
              <span class="info-label">Derechos</span>
              <span class="info-value">&copy; {{ currentYear }} Todos los derechos reservados</span>
            </div>
          </div>

          <!-- Description -->
          <div class="about-description">
            <p>
              Semanur HUB es un sistema integral disenado para optimizar el mantenimiento 
              de flota, control de inventarios, gestion de combustible, ordenes de trabajo 
              y programacion de actividades operativas en tiempo real.
            </p>
          </div>
        </div>

        <div class="modal-footer about-footer">
          <button class="btn btn-secondary" @click="$emit('close')">
            Cerrar
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import logoImage from '/logo.png';

defineProps({
  visible: { type: Boolean, default: false },
});

defineEmits(['close']);

const version = '0.5-alpha';
const currentYear = new Date().getFullYear();
</script>

<style scoped>
.modal-about {
  max-width: 480px;
  width: 100%;
}

.about-body {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  padding: 32px 40px !important;
  text-align: center;
}

/* Logo */
.about-logo {
  width: 120px;
  height: 120px;
  border-radius: 20px;
  background: var(--surface-1);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.about-logo img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

/* Title */
.about-title h1 {
  font-size: 1.8rem;
  font-weight: 800;
  color: var(--text-main);
  margin: 0;
  letter-spacing: -0.5px;
}

.about-title p {
  font-size: 0.9rem;
  color: var(--text-gray);
  margin: 6px 0 0 0;
  font-weight: 500;
}

/* Version */
.about-version {
  margin-top: 4px;
}

.version-pill {
  display: inline-block;
  padding: 4px 14px;
  background: var(--primary-10);
  border: 1px solid var(--primary-20);
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--primary);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Divider */
.about-divider {
  width: 60px;
  height: 3px;
  background: var(--primary);
  border-radius: 2px;
  opacity: 0.6;
}

/* Info Lines */
.about-info {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid var(--surface-2);
}

.info-row:last-child {
  border-bottom: none;
}

.info-label {
  font-size: 0.8rem;
  color: var(--text-gray);
  font-weight: 500;
}

.info-value {
  font-size: 0.85rem;
  color: var(--text-main);
  font-weight: 600;
}

/* Description */
.about-description {
  width: 100%;
  padding: 16px;
  background: var(--surface-1);
  border-radius: var(--radius-md);
  border: 1px solid var(--surface-2);
}

.about-description p {
  font-size: 0.85rem;
  line-height: 1.6;
  color: var(--text-muted);
  margin: 0;
}

/* Footer */
.about-footer {
  padding: 16px 24px;
  border-top: 1px solid var(--surface-2);
  display: flex;
  justify-content: center;
}

.about-footer .btn {
  min-width: 120px;
}

/* Responsive */
@media (max-width: 480px) {
  .about-body {
    padding: 24px 20px !important;
  }
  
  .info-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
}
</style>
