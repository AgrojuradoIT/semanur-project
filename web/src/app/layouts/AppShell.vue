<template>
  <div id="app-shell">
    <aside class="sidebar">
      <div class="sidebar-logo">
        <img src="/logo.png" alt="Semanur HUB" class="logo-icon" />
        <div class="logo-text">SEMANUR<span> HUB</span></div>
      </div>

      <nav class="sidebar-nav">
        <div class="sidebar-section-label" v-if="operations.length">OPERACIONES</div>
        <RouterLink v-for="item in operations" :key="item.path" :to="item.path" class="sidebar-item" :class="{ 'active': item.path === '/' ? route.path === '/' : route.path.startsWith(item.path) }">
          <span class="material-icons-round">{{ item.icon }}</span>
          {{ item.label }}
        </RouterLink>

        <div class="sidebar-section-label" v-if="admin.length">ADMINISTRACION</div>
        <RouterLink v-for="item in admin" :key="item.path" :to="item.path" class="sidebar-item" :class="{ 'active': item.path === '/' ? route.path === '/' : route.path.startsWith(item.path) }">
          <span class="material-icons-round">{{ item.icon }}</span>
          {{ item.label }}
          <span v-if="item.path === '/notifications' && notifStore.unreadCount > 0" class="sidebar-badge">{{ notifStore.unreadCount > 99 ? '99+' : notifStore.unreadCount }}</span>
        </RouterLink>
      </nav>

      <div class="sidebar-footer">
        <button class="sidebar-item sidebar-about-btn" @click="showAboutModal = true">
          <span class="material-icons-round">info</span>
          <div class="sidebar-about-text">
            <span class="sidebar-about-title">Semanur HUB</span>
            <span class="sidebar-about-version">0.5-alpha</span>
          </div>
        </button>
      </div>

      <!-- About Modal -->
      <AboutModal :visible="showAboutModal" @close="showAboutModal = false" />
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

          <!-- Panel de Notificaciones -->
          <div class="notif-container" ref="notifContainerRef">
            <button class="btn-icon" title="Notificaciones" @click="toggleNotifPanel" style="position: relative;">
              <span class="material-icons-round">notifications</span>
              <span v-if="notifStore.unreadCount > 0" class="notification-badge">
                {{ notifStore.unreadCount > 9 ? '9+' : notifStore.unreadCount }}
              </span>
            </button>

            <div v-if="notifPanelOpen" class="notif-panel">
              <div class="notif-panel-header">
                <span>Notificaciones</span>
                <button v-if="notifStore.unreadCount > 0" class="notif-mark-all" @click="markAllRead">
                  Marcar todas como leídas
                </button>
              </div>

              <div v-if="notifStore.loading" class="notif-empty">
                <span class="material-icons-round" style="font-size: 32px; color: var(--text-gray);">hourglass_empty</span>
                <p>Cargando...</p>
              </div>

              <div v-else-if="notifStore.sinLeer.length === 0" class="notif-empty">
                <span class="material-icons-round" style="font-size: 32px; color: var(--text-gray);">check_circle</span>
                <p>Sin notificaciones pendientes</p>
              </div>

              <ul v-else class="notif-list">
                <li
                  v-for="n in notifStore.sinLeer"
                  :key="n.id"
                  class="notif-item"
                  @click="handleNotifClick(n)"
                >
                  <span class="material-icons-round notif-icon" :class="prioridadClass(n.prioridad)">
                    {{ notifStore.iconoPorTipo(n.tipo) }}
                  </span>
                  <div class="notif-body">
                    <p class="notif-title">{{ n.titulo }}</p>
                    <p class="notif-msg">{{ n.mensaje }}</p>
                  </div>
                  <button class="notif-close" title="Marcar como leída" @click.stop="notifStore.marcarLeida(n.id)">
                    <span class="material-icons-round" style="font-size: 16px;">close</span>
                  </button>
                </li>
              </ul>

              <RouterLink to="/notifications" class="notif-panel-footer" @click="notifPanelOpen = false">
                Ver centro de notificaciones
                <span class="material-icons-round" style="font-size: 16px;">arrow_forward</span>
              </RouterLink>
            </div>
          </div>

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

    <!-- Dynamic Island -->
    <DynamicIsland
      v-model="islandState.show"
      :type="islandState.type"
      :title="islandState.title"
      :message="islandState.message"
      :duration="islandState.duration"
      :action-label="islandState.actionLabel"
      @action="handleIslandAction"
      @dismiss="dismissIsland"
    />
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '../../shared/stores/auth';
import { useNotificacionesStore } from '../../shared/stores/notificaciones';
import { useRefresh } from '../../shared/composables/useRefresh';
import { useDynamicIsland } from '../../shared/composables/useDynamicIsland';
import AboutModal from '../../shared/components/AboutModal.vue';
import DynamicIsland from '../../shared/components/DynamicIsland.vue';

const auth = useAuthStore();
const notifStore = useNotificacionesStore();
const router = useRouter();
const route = useRoute();
const { islandState, dismiss: dismissIsland, handleAction: handleIslandAction } = useDynamicIsland();
const { triggerRefresh } = useRefresh();

// About Modal
const showAboutModal = ref(false);
let pollTimer = null;

const profileMenuOpen = ref(false);
const notifPanelOpen = ref(false);
const notifContainerRef = ref(null);

function toggleProfileMenu() {
  profileMenuOpen.value = !profileMenuOpen.value;
  notifPanelOpen.value = false;
}

function toggleNotifPanel() {
  notifPanelOpen.value = !notifPanelOpen.value;
  profileMenuOpen.value = false;
}

function closeMenus(e) {
  if (!e.target.closest('.header-profile-container')) {
    profileMenuOpen.value = false;
  }
  if (notifContainerRef.value && !notifContainerRef.value.contains(e.target)) {
    notifPanelOpen.value = false;
  }
}

async function handleNotifClick(n) {
  await notifStore.marcarLeida(n.id);
  const ruta = notifStore.rutaPorNotificacion(n.tipo, n.relacionado_id);
  if (ruta) router.push(ruta);
  notifPanelOpen.value = false;
}

async function markAllRead() {
  await notifStore.marcarTodasLeidas();
}

function prioridadClass(prioridad) {
  if (prioridad === 'alta') return 'notif-icon--alta';
  if (prioridad === 'media') return 'notif-icon--media';
  return 'notif-icon--baja';
}

onMounted(async () => {
  document.addEventListener('click', closeMenus);
  
  // Inicializar tema
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme === 'light') {
    isDark.value = false;
    updateTheme();
  }

  // Cargar notificaciones (no bloquear si falla)
  try {
    await notifStore.fetchNotificaciones();
  } catch (e) {
    console.warn('No se pudieron cargar notificaciones:', e);
  }

  // Polling cada 60s para nuevas notificaciones
  pollTimer = setInterval(() => {
    notifStore.fetchNotificaciones().catch(() => {});
  }, 60000);
});

onUnmounted(() => {
  document.removeEventListener('click', closeMenus);
  if (pollTimer) clearInterval(pollTimer);
});

function handleRefresh() {
  triggerRefresh();
}

function handleManageProfile() {
  profileMenuOpen.value = false;
  alert('Gestión de perfil en construcción. ¡Pronto disponible!');
}

const operations = computed(() => {
  const items = [
    { path: '/', icon: 'dashboard', label: 'Dashboard', modulo: 'analitica' },
    { path: '/inventory', icon: 'inventory_2', label: 'Inventario', modulo: 'inventario' },
    { path: '/fleet', icon: 'local_shipping', label: 'Flota', modulo: 'flota' },
    { path: '/work-orders', icon: 'build_circle', label: 'Ordenes de Trabajo', modulo: 'taller' },
  ];

  if (auth.isJefeDeTaller) {
    items.push({ path: '/work-orders/audit', icon: 'security', label: 'Auditoría OTs', modulo: 'taller' });
  }

  items.push(
    { path: '/loans', icon: 'handyman', label: 'Prestamos Herr.', modulo: 'prestamos' },
    { path: '/preoperacionales', icon: 'assignment_turned_in', label: 'Inspecciones', modulo: 'checklists' },
    { path: '/fuel', icon: 'local_gas_station', label: 'Combustible', modulo: 'combustible' },
    { path: '/scheduler', icon: 'calendar_month', label: 'Programacion', modulo: 'personal' },
  );

  return items.filter(item => auth.canAccessModule(item.modulo));
});

const admin = computed(() => {
  const items = [
    { path: '/history', icon: 'history', label: 'Actividad', modulo: 'analitica' },
    { path: '/employees', icon: 'people', label: 'Empleados', modulo: 'personal' },
    { path: '/notifications', icon: 'notifications', label: 'Notificaciones' },
  ];
  return items.filter(item => !item.modulo || auth.canAccessModule(item.modulo));
});

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

/* ── Notificaciones ─────────────────────────────────────── */
.notif-container {
  position: relative;
}

.notif-panel {
  position: absolute;
  top: calc(100% + 10px);
  right: -8px;
  width: 360px;
  max-height: 480px;
  background: var(--surface);
  border: 1px solid var(--surface-2);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  z-index: 1001;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: dropdownFade 0.2s ease;
}

.notif-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid var(--surface-2);
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--text-main);
}

.notif-mark-all {
  background: none;
  border: none;
  color: var(--primary);
  font-size: 0.75rem;
  font-weight: 500;
  cursor: pointer;
  padding: 0;
}

.notif-mark-all:hover {
  text-decoration: underline;
}

.notif-list {
  list-style: none;
  margin: 0;
  padding: 0;
  overflow-y: auto;
  flex: 1;
}

.notif-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 12px 16px;
  border-bottom: 1px solid var(--surface-2);
  cursor: pointer;
  transition: background 0.15s;
}

.notif-item:last-child { border-bottom: none; }

.notif-item:hover {
  background: var(--surface-2);
}

.notif-icon {
  font-size: 22px;
  flex-shrink: 0;
  margin-top: 2px;
}

.notif-icon--alta  { color: var(--danger); }
.notif-icon--media { color: var(--warning, #f59e0b); }
.notif-icon--baja  { color: var(--primary); }

.notif-body {
  flex: 1;
  min-width: 0;
}

.notif-title {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--text-main);
  margin: 0 0 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.notif-msg {
  font-size: 0.75rem;
  color: var(--text-gray);
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.notif-close {
  background: none;
  border: none;
  color: var(--text-gray);
  cursor: pointer;
  padding: 2px;
  flex-shrink: 0;
  border-radius: 4px;
  display: flex;
  align-items: center;
  opacity: 0;
  transition: opacity 0.15s;
}

.notif-item:hover .notif-close { opacity: 1; }
.notif-close:hover { background: var(--surface-2); color: var(--text-main); }

.notif-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 16px;
  gap: 8px;
  color: var(--text-gray);
  font-size: 0.8rem;
}
.notif-panel-footer {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 16px;
  border-top: 1px solid var(--surface-2);
  font-size: 0.78rem;
  font-weight: 500;
  color: var(--primary);
  text-decoration: none;
  transition: background 0.15s;
}

.notif-panel-footer:hover {
  background: var(--surface-2);
}

/* Sidebar Badge */
.sidebar-badge {
  margin-left: auto;
  background: var(--danger);
  color: #fff;
  font-size: 0.65rem;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 10px;
  min-width: 18px;
  text-align: center;
  line-height: 1.4;
}

/* Sidebar About Button */
.sidebar-about-btn {
  width: 100%;
  text-align: left;
  cursor: pointer;
  transition: all 0.2s ease;
}

.sidebar-about-btn:hover {
  background: var(--surface-2);
}

.sidebar-about-btn .material-icons-round {
  color: var(--primary);
}

.sidebar-about-text {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.sidebar-about-title {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--text-main);
}

.sidebar-about-version {
  font-size: 0.7rem;
  color: var(--text-gray);
  font-weight: 500;
}
</style>
