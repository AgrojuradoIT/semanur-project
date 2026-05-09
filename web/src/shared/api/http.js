import axios from 'axios';

import {
  AUTH_UNAUTHORIZED_EVENT,
  clearStoredSession,
  getStoredToken,
} from '../auth/session';

export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api';

const http = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  },
  timeout: 30000,
});

http.interceptors.request.use((config) => {
  const token = getStoredToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

http.interceptors.response.use(
  (response) => response,
  async (error) => {
    // 1. Manejo 401 Unauthorized (Sesión inválida o expirada)
    if (error.response?.status === 401) {
      clearStoredSession();
      window.dispatchEvent(new CustomEvent(AUTH_UNAUTHORIZED_EVENT));
    }

    // 2. Normalización del Error
    // Decoramos el error original sin destruirlo para mantener compatibilidad
    if (error.response) {
      // El servidor respondió con código de error
      if (error.response.status === 422) {
        error.isValidationError = true;
        error.validationErrors = error.response.data?.errors || {};
        error.displayMessage = error.response.data?.message || 'Error de validación de datos.';
      } else {
        error.displayMessage = error.response.data?.message || `Error del servidor (${error.response.status})`;
      }
    } else if (error.request) {
      // Petición enviada pero sin respuesta
      error.displayMessage = 'No se pudo conectar con el servidor. Verifica tu conexión a red.';
    } else {
      // Error al armar la petición
      error.displayMessage = error.message;
    }

    return Promise.reject(error);
  }
);

export default http;
