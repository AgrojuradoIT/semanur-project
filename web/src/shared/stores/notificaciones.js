import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import http from '../api/http.js';

export const useNotificacionesStore = defineStore('notificaciones', () => {
  const notificaciones = ref([]);
  const loading = ref(false);

  const unreadCount = computed(
    () => notificaciones.value.filter((n) => !n.fecha_leido).length
  );

  const sinLeer = computed(() =>
    notificaciones.value.filter((n) => !n.fecha_leido)
  );

  async function fetchNotificaciones() {
    loading.value = true;
    try {
      const { data } = await http.get('/notifications');
      if (data?.success) {
        notificaciones.value = data.data;
      }
    } catch (e) {
      console.error('Error cargando notificaciones:', e);
    } finally {
      loading.value = false;
    }
  }

  async function marcarLeida(id) {
    try {
      await http.post(`/notifications/${id}/read`);
      const n = notificaciones.value.find((n) => n.id === id);
      if (n) n.fecha_leido = new Date().toISOString();
    } catch (e) {
      console.error('Error marcando notificación:', e);
    }
  }

  async function marcarTodasLeidas() {
    try {
      await http.post('/notifications/read-all');
      notificaciones.value.forEach((n) => {
        if (!n.fecha_leido) n.fecha_leido = new Date().toISOString();
      });
    } catch (e) {
      console.error('Error marcando todas:', e);
    }
  }

  /** Devuelve el ícono de Material Icons según el tipo */
  function iconoPorTipo(tipo) {
    if (tipo?.includes('soat') || tipo?.includes('tecnomecanica')) return 'description';
    if (tipo?.includes('mantenimiento')) return 'build';
    if (tipo?.includes('stock') || tipo?.includes('inventory')) return 'inventory_2';
    if (tipo?.includes('orden')) return 'build_circle';
    return 'notifications';
  }

  /** Devuelve la ruta de navegación según tipo y relacionado_id */
  function rutaPorNotificacion(tipo, relacionadoId) {
    if (tipo?.includes('soat') || tipo?.includes('tecnomecanica') || tipo?.includes('mantenimiento')) {
      // relacionadoId = 'vehiculoId|placa'
      const vehiculoId = relacionadoId?.split('|')[0] || null;
      return { path: '/fleet', query: vehiculoId ? { vehiculo_id: vehiculoId } : {} };
    }
    if (tipo?.includes('stock') || tipo?.includes('inventory')) {
      return { path: '/inventory', query: relacionadoId ? { producto_id: relacionadoId } : {} };
    }
    if (tipo?.includes('orden')) {
      return '/work-orders';
    }
    return null;
  }

  return {
    notificaciones,
    loading,
    unreadCount,
    sinLeer,
    fetchNotificaciones,
    marcarLeida,
    marcarTodasLeidas,
    iconoPorTipo,
    rutaPorNotificacion,
  };
});
