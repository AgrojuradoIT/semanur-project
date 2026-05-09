import './style.css';

import { createApp } from 'vue';
import { createPinia } from 'pinia';

import App from './App.vue';
import router from './app/router';
import { AUTH_UNAUTHORIZED_EVENT } from './shared/auth/session';
import { useAuthStore } from './shared/stores/auth';

const app = createApp(App);
const pinia = createPinia();

app.use(pinia);

const authStore = useAuthStore();
authStore.hydrateFromStorage();

window.addEventListener(AUTH_UNAUTHORIZED_EVENT, () => {
  authStore.clearSession();

  if (router.currentRoute.value.path !== '/login' && !router.currentRoute.value.path.includes('/diagnostic')) {
    router.replace('/login');
  }
});

app.use(router);
app.mount('#app');
