import { defineStore } from 'pinia';
import http from '../api/http';

const TOKEN_KEY = 'semanur_token';
const USER_KEY = 'semanur_user';

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: null,
    user: null,
    loading: false,
    error: null,
  }),
  getters: {
    isAuthenticated: (state) => !!state.token,
  },
  actions: {
    hydrateFromStorage() {
      this.token = localStorage.getItem(TOKEN_KEY);
      const savedUser = localStorage.getItem(USER_KEY);
      this.user = savedUser ? JSON.parse(savedUser) : null;
    },
    persistSession(token, user) {
      this.token = token;
      this.user = user;
      localStorage.setItem(TOKEN_KEY, token);
      localStorage.setItem(USER_KEY, JSON.stringify(user));
    },
    clearSession() {
      this.token = null;
      this.user = null;
      this.error = null;
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(USER_KEY);
    },
    async login({ email, password }) {
      this.loading = true;
      this.error = null;
      try {
        const { data } = await http.post('/login', {
          email,
          password,
          device_name: 'Semanur Web Vue',
        });

        this.persistSession(data.token, data.user);
        return true;
      } catch (error) {
        this.error =
          error?.response?.data?.message ||
          error?.message ||
          'No fue posible iniciar sesion';
        return false;
      } finally {
        this.loading = false;
      }
    },
    async logout() {
      try {
        if (this.token) {
          await http.post('/logout');
        }
      } catch {
        // ignore API logout failures and clear local session anyway
      } finally {
        this.clearSession();
      }
    },
  },
});
