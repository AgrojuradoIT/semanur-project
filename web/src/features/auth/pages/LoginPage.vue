<template>
  <div class="login-page">
    <div class="login-card">
      <div class="login-logo">
        <img src="/logo.png" alt="Semanur HUB" class="logo-icon" />
        <h1>SEMANUR<span> HUB</span></h1>
      </div>
      <p class="login-subtitle">Tu plataforma inteligente de gestión de taller y flota</p>

      <form class="login-form" @submit.prevent="onSubmit">
        <div class="input-group">
          <label>CORREO</label>
          <input v-model="email" class="input" type="email" required />
        </div>

        <div class="input-group">
          <label>CONTRASENA</label>
          <input v-model="password" class="input" type="password" required />
        </div>

        <p v-if="auth.error" class="login-error show">{{ auth.error }}</p>

        <button class="btn btn-primary" type="submit" :disabled="auth.loading">
          {{ auth.loading ? 'VALIDANDO...' : 'INICIAR SESION' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../../../shared/stores/auth';

const router = useRouter();
const auth = useAuthStore();

const email = ref('');
const password = ref('');

async function onSubmit() {
  const success = await auth.login({ email: email.value, password: password.value });
  if (success) {
    router.replace('/');
  }
}
</script>
