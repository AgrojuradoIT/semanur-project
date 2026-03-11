<template>
  <div id="app-shell">
    <aside class="sidebar">
      <div class="sidebar-logo">
        <img src="/logo.png" alt="Semanur HUB" class="logo-icon" />
        <div class="logo-text">SEMANUR<span> HUB</span></div>
      </div>

      <nav class="sidebar-nav">
        <div class="sidebar-section-label">OPERACIONES</div>
        <RouterLink v-for="item in operations" :key="item.path" :to="item.path" class="sidebar-item" :class="{ 'active': item.path === '/' ? route.path === '/' : route.path.startsWith(item.path) }">
          <span class="material-icons-round">{{ item.icon }}</span>
          {{ item.label }}
        </RouterLink>

        <div class="sidebar-section-label">ADMINISTRACION</div>
        <RouterLink v-for="item in admin" :key="item.path" :to="item.path" class="sidebar-item" :class="{ 'active': item.path === '/' ? route.path === '/' : route.path.startsWith(item.path) }">
          <span class="material-icons-round">{{ item.icon }}</span>
          {{ item.label }}
        </RouterLink>
      </nav>

      <div class="sidebar-footer">
        <div class="sidebar-item" style="cursor: default; opacity: 0.7;">
          <span class="material-icons-round">info</span>
          Semanur HUB 0.5-alpha
        </div>
      </div>
    </aside>

    <main class="main-content">
      <header class="header">
        <div class="header-left">
          <!-- Título de módulo desactivado por diseño -->
        </div>
        <div class="header-right">
          <button class="btn-icon" title="Actualizar" @click="handleRefresh">
            <span class="material-icons-round">refresh</span>
          </button>

          <button class="btn-icon" title="Notificaciones" style="position: relative;">
            <span class="material-icons-round">notifications</span>
            <span class="notification-badge">3</span>
          </button>

          <button class="btn-icon" :title="isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'" @click="toggleTheme">
            <span class="material-icons-round">{{ isDark ? 'light_mode' : 'dark_mode' }}</span>
          </button>

          <div class="header-profile-container">
            <div class="header-user" @click="toggleProfileMenu">
              <div class="header-avatar">
                <span class="material-icons-round">person</span>
              </div>
              <div class="header-user-info">
                <span class="header-user-name">{{ auth.user?.name || 'Usuario' }}</span>
                <span class="header-user-role">{{ auth.user?.email || 'usuario@semanur.com' }}</span>
              </div>
              <span class="material-icons-round" style="color: var(--text-gray); margin-left: 4px; font-size: 18px;">expand_more</span>
            </div>

            <div v-if="profileMenuOpen" class="profile-dropdown">
              <div class="dropdown-header">
                <strong>{{ auth.user?.name || 'Usuario' }}</strong>
                <p>{{ auth.user?.role || 'Operador' }}</p>
              </div>
              <button class="dropdown-item" @click="handleManageProfile">
                <span class="material-icons-round">account_circle</span>
                Gestionar Perfil
              </button>
              <button class="dropdown-item dropdown-danger" @click="onLogout">
                <span class="material-icons-round">logout</span>
                Cerrar Sesion
              </button>
            </div>
          </div>
        </div>
      </header>

      <div class="page-content">
        <RouterView />
      </div>
    </main>
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute, RouterLink, RouterView } from 'vue-router';
import { useAuthStore } from '../../shared/stores/auth';
import { useRefresh } from '../../shared/composables/useRefresh';

const auth = useAuthStore();
const router = useRouter();
const route = useRoute();
const { triggerRefresh } = useRefresh();

const profileMenuOpen = ref(false);

function toggleProfileMenu() {
  profileMenuOpen.value = !profileMenuOpen.value;
}

function closeProfileMenu(e) {
  if (!e.target.closest('.header-profile-container')) {
    profileMenuOpen.value = false;
  }
}

onMounted(() => {
  document.addEventListener('click', closeProfileMenu);
});

onUnmounted(() => {
  document.removeEventListener('click', closeProfileMenu);
});

function handleRefresh() {
  triggerRefresh();
}

function handleManageProfile() {
  profileMenuOpen.value = false;
  // Logica para abrir modal de perfil o navegar
  alert('Gestión de perfil en construcción. ¡Pronto disponible!');
}

const operations = computed(() => [
  { path: '/', icon: 'dashboard', label: 'Dashboard' },
  { path: '/inventory', icon: 'inventory_2', label: 'Inventario' },
  { path: '/fleet', icon: 'local_shipping', label: 'Flota' },
  { path: '/work-orders', icon: 'build_circle', label: 'Ordenes de Trabajo' },
  { path: '/loans', icon: 'handyman', label: 'Prestamos Herr.' },
  { path: '/checklists', icon: 'playlist_add_check', label: 'Checklists' },
  { path: '/fuel', icon: 'local_gas_station', label: 'Combustible' },
]);

const admin = computed(() => [
  { path: '/history', icon: 'history', label: 'Actividad' },
  { path: '/employees', icon: 'people', label: 'Empleados' },
  { path: '/scheduler', icon: 'calendar_month', label: 'Programacion' },
]);

async function onLogout() {
  await auth.logout();
  router.replace('/login');
}

// Theme Management
const isDark = ref(true);

function toggleTheme() {
  isDark.value = !isDark.value;
  updateTheme();
}

function updateTheme() {
  if (isDark.value) {
    document.documentElement.classList.remove('light-mode');
    localStorage.setItem('theme', 'dark');
  } else {
    document.documentElement.classList.add('light-mode');
    localStorage.setItem('theme', 'light');
  }
}

onMounted(() => {
  document.addEventListener('click', closeProfileMenu);
  
  // Initialize theme
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme === 'light') {
    isDark.value = false;
    updateTheme();
  }
});
</script>

<style scoped>
#app-shell {
  display: flex;
  height: 100vh;
  width: 100%;
  flex: 1;
  overflow: hidden;
}

/* El área principal (header + contenido) ocupa el espacio restante junto al sidebar */
.main-content {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
  overflow: hidden;
}

/* Contenido scroll */
.page-content {
  flex: 1;
  overflow-y: auto;
  padding: var(--sp-xl);
  min-height: 0;
}

.notification-badge {
  position: absolute;
  top: -2px;
  right: -2px;
  background: var(--danger);
  color: white;
  font-size: 0.65rem;
  font-weight: 700;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid var(--surface);
}

.header-profile-container {
  position: relative;
}

.profile-dropdown {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  min-width: 220px;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: dropdownFade 0.2s ease;
}

@keyframes dropdownFade {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

.dropdown-header {
  padding: 12px 16px;
  border-bottom: 1px solid var(--surface-2);
  display: flex;
  flex-direction: column;
}

.dropdown-header strong {
  font-size: 0.9rem;
  color: var(--text-main);
}

.dropdown-header p {
  font-size: 0.75rem;
  color: var(--text-gray);
  margin-top: 2px;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: transparent;
  border: none;
  width: 100%;
  text-align: left;
  color: var(--text-secondary);
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.dropdown-item:hover {
  background: var(--surface-2);
  color: var(--text-main);
}

.dropdown-item .material-icons-round {
  font-size: 18px;
}

.dropdown-danger:hover {
  background: var(--danger-10);
  color: var(--danger);
}

.dropdown-danger:hover .material-icons-round {
  color: var(--danger);
}
</style>
