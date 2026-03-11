import http from '../../../shared/api/http';
import { extractList } from '../../../shared/utils/apiResponse';

export async function fetchInventoryProducts(params = {}) {
  const { data } = await http.get('/productos', { params });
  return data; // { data: [...], meta: {...}, metrics: {...} }
}

export async function searchInventoryProducts(query) {
  const { data } = await http.get('/productos', {
    params: { q: query },
  });
  return data;
}

export async function createProduct(payload) {
  const { data } = await http.post('/productos', payload);
  return data;
}

export async function updateProduct(id, payload) {
  const { data } = await http.put(`/productos/${id}`, payload);
  return data;
}

export async function deleteProduct(id) {
  const { data } = await http.delete(`/productos/${id}`);
  return data;
}

export async function createMovement(payload) {
  const { data } = await http.post('/movimientos', payload);
  return data;
}

export async function uploadCsv(file, skipDuplicates = true, options = {}) {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('skip_duplicates', skipDuplicates ? 1 : 0);
  if (options?.categoria_id) {
    formData.append('categoria_id', Number(options.categoria_id));
  }
  if (options?.unidad_medida) {
    formData.append('unidad_medida', options.unidad_medida);
  }
  if (options?.alerta_stock_minimo !== undefined && options?.alerta_stock_minimo !== null) {
    formData.append('alerta_stock_minimo', Number(options.alerta_stock_minimo));
  }

  const { data } = await http.post('/productos/import', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return data;
}

export async function uploadPurchasesPreview(file, options = {}, onProgress = null) {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('dry_run', 1);

  if (options?.categoria_id) {
    formData.append('categoria_id', Number(options.categoria_id));
  }
  if (options?.unidad_medida) {
    formData.append('unidad_medida', options.unidad_medida);
  }
  if (options?.alerta_stock_minimo !== undefined && options?.alerta_stock_minimo !== null) {
    formData.append('alerta_stock_minimo', Number(options.alerta_stock_minimo));
  }

  const { data } = await http.post('/inventario/import-compras', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: (e) => {
      if (onProgress && e.total) onProgress(Math.round((e.loaded / e.total) * 100));
    },
  });
  return data;
}

export async function uploadPurchasesConfirm(file, options = {}, onProgress = null) {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('dry_run', 0);

  if (options?.categoria_id) {
    formData.append('categoria_id', Number(options.categoria_id));
  }
  if (options?.unidad_medida) {
    formData.append('unidad_medida', options.unidad_medida);
  }
  if (options?.alerta_stock_minimo !== undefined && options?.alerta_stock_minimo !== null) {
    formData.append('alerta_stock_minimo', Number(options.alerta_stock_minimo));
  }

  const { data } = await http.post('/inventario/import-compras', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
    timeout: 120000,
    onUploadProgress: (e) => {
      if (onProgress && e.total) onProgress(Math.round((e.loaded / e.total) * 100));
    },
  });
  return data;
}
