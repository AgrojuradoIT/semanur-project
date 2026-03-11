<template>
  <div style="padding: 20px; font-family: monospace;">
    <h1>🔍 Diagnóstico de Conexión API</h1>
    
    <div style="margin: 20px 0; border: 1px solid #ccc; padding: 15px;">
      <h2>Configuración</h2>
      <p><strong>API Base URL:</strong> {{ apiUrl }}</p>
      <p><strong>Estado:</strong> <span :style="{ color: isConnected ? 'green' : 'red' }">
        {{ isConnected ? '✅ Conectado' : '❌ Desconectado' }}
      </span></p>
    </div>

    <div style="margin: 20px 0;">
      <h2>Pruebas</h2>
      <button @click="testLogin" style="padding: 10px 20px; margin: 5px; cursor: pointer;">
        Probar Login
      </button>
      <button @click="testVehiculos" style="padding: 10px 20px; margin: 5px; cursor: pointer;">
        Probar Vehículos
      </button>
      <button @click="testAnalytics" style="padding: 10px 20px; margin: 5px; cursor: pointer;">
        Probar Analytics
      </button>
    </div>

    <div style="margin: 20px 0; border: 1px solid #ddd; padding: 15px; background: #f5f5f5;">
      <h2>Respuestas:</h2>
      <pre style="max-height: 400px; overflow-y: auto;">{{ responses }}</pre>
    </div>

    <div style="margin: 20px 0; border: 1px solid #ffa500; padding: 15px; background: #fff9e6;">
      <h2>⚠️ Errores:</h2>
      <pre style="color: red; max-height: 300px; overflow-y: auto;">{{ errors }}</pre>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import http, { API_BASE_URL } from '../shared/api/http';

const apiUrl = API_BASE_URL;
const isConnected = ref(false);
const responses = ref('Esperando pruebas...');
const errors = ref('Sin errores aún');

const logResponse = (title, data) => {
  const timestamp = new Date().toLocaleTimeString();
  responses.value += `\n\n[${timestamp}] ${title}:\n` + JSON.stringify(data, null, 2);
};

const logError = (title, error) => {
  const timestamp = new Date().toLocaleTimeString();
  const errorMsg = error?.response?.data?.message || error?.message || String(error);
  errors.value += `\n[${timestamp}] ${title}: ${errorMsg}`;
};

const testLogin = async () => {
  try {
    responses.value = 'Probando login...\n';
    const { data } = await http.post('/login', {
      email: 'admin@semanur.com',
      password: 'password',
      device_name: 'Web Diagnostic',
    });
    isConnected.value = true;
    logResponse('✅ Login exitoso', data);
  } catch (error) {
    isConnected.value = false;
    logError('❌ Error en Login', error);
  }
};

const testVehiculos = async () => {
  try {
    responses.value += '\n\nProbando /vehiculos...\n';
    const { data } = await http.get('/vehiculos');
    logResponse('✅ Vehículos obtenidos', { count: data.length, sample: data[0] });
  } catch (error) {
    logError('❌ Error en Vehículos', error);
  }
};

const testAnalytics = async () => {
  try {
    responses.value += '\n\nProbando /analytics/summary...\n';
    const { data } = await http.get('/analytics/summary');
    logResponse('✅ Analytics obtenidos', data);
  } catch (error) {
    logError('❌ Error en Analytics', error);
  }
};
</script>
