import { defineStore } from 'pinia';
import { ref } from 'vue';
import http from '../api/http.js';
import { extractList } from '../utils/apiResponse.js';

export const useCatalogsStore = defineStore('catalogs', () => {
  const empleados = ref([]);
  const vehiculos = ref([]);
  const productos = ref([]);

  const loadingEmpleados = ref(false);
  const loadingVehiculos = ref(false);
  const loadingProductos = ref(false);

  async function fetchEmpleados(force = false) {
    if (!force && empleados.value.length > 0) return empleados.value;
    loadingEmpleados.value = true;
    try {
      const { data } = await http.get('/empleados');
      empleados.value = extractList(data);
    } catch (e) {
      console.error('Error fetching empleados for cache', e);
    } finally {
      loadingEmpleados.value = false;
    }
    return empleados.value;
  }

  async function fetchVehiculos(force = false) {
    if (!force && vehiculos.value.length > 0) return vehiculos.value;
    loadingVehiculos.value = true;
    try {
      const { data } = await http.get('/vehiculos');
      vehiculos.value = extractList(data);
    } catch (e) {
      console.error('Error fetching vehiculos for cache', e);
    } finally {
      loadingVehiculos.value = false;
    }
    return vehiculos.value;
  }

  async function fetchProductos(force = false) {
    if (!force && productos.value.length > 0) return productos.value;
    loadingProductos.value = true;
    try {
      // Pedimos todos los productos que se pueden utilizar en modulos
      const { data } = await http.get('/productos');
      productos.value = extractList(data);
    } catch (e) {
      console.error('Error fetching productos for cache', e);
    } finally {
      loadingProductos.value = false;
    }
    return productos.value;
  }

  /**
   * Asegura que los tres catálogos estén cargados.
   * Si ya tienen datos, retornará inmediatamente sin red.
   */
  async function fetchEssentialCatalogs(force = false) {
     await Promise.all([
       fetchEmpleados(force),
       fetchVehiculos(force),
       fetchProductos(force)
     ]);
  }

  return {
    empleados, vehiculos, productos,
    loadingEmpleados, loadingVehiculos, loadingProductos,
    fetchEmpleados, fetchVehiculos, fetchProductos, fetchEssentialCatalogs
  };
});
