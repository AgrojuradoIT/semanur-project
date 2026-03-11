import { ref } from 'vue';

export function useAsyncState(defaultError = '') {
  const loading = ref(false);
  const error = ref(defaultError);

  async function run(task, fallbackMessage = 'Error inesperado') {
    loading.value = true;
    error.value = defaultError;
    try {
      return await task();
    } catch (e) {
      error.value = e?.response?.data?.message || e?.message || fallbackMessage;
      throw e;
    } finally {
      loading.value = false;
    }
  }

  function clearError() {
    error.value = defaultError;
  }

  return {
    loading,
    error,
    run,
    clearError,
  };
}
