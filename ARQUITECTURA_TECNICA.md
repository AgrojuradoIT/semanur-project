# Arquitectura Técnica — Semanur App

Documento de referencia para describir la arquitectura del sistema completo (backend + app móvil + web), sus módulos, responsabilidades y flujos técnicos.

---

## 1. Visión general del proyecto

### Propósito y usuarios
- **Problema que resuelve:** operación y control de taller, inventario y flota en un solo sistema: órdenes de trabajo, movimientos de inventario, checklists preoperacionales, combustible, préstamos de herramientas, programación y analítica.
- **Usuarios objetivo:**
  - **Operativos (campo/taller):** registro de actividades, checklists, OT, consumos, evidencias.
  - **Administrativos/supervisión:** control de inventario, flota, reportes, auditoría y seguimiento.

### Arquitectura general
- **Tipo de sistema:** monorepo con **backend central (monolito Laravel)** que expone **API REST** y dos clientes:
  - **App móvil (Flutter)** para operación en campo con enfoque **offline-first**.
  - **Web (Vue 3)** para operación/administración desde navegador.
- **Capas principales:**
  - **Backend:** dominio + persistencia + API + scheduler/cola + panel administrativo.
  - **Frontends:** UI + estado + consumo de API.
  - **Servicios externos:** base de datos relacional, almacenamiento de archivos (disco/driver), servicios de SO para notificaciones locales.

### Stack tecnológico global
- **Backend:** PHP 8.2+, **Laravel 11**, **Sanctum** (tokens), **Backpack + Livewire** (panel admin), **PhpSpreadsheet** (importaciones).
- **Persistencia:** base de datos relacional (en configuración local actual se observa **MySQL**; el framework permite variar por configuración).
- **Móvil:** Flutter (Dart), **Provider/ChangeNotifier**, **Dio**, **SQLite (sqflite)**, secure storage, **workmanager** (background), **flutter_local_notifications**.
- **Web:** Vue 3 + Vite, Vue Router, Pinia, Axios, Playwright (tests).

---

## 2. Backend (Laravel)

### Arquitectura del backend
- **Estilo:** MVC con Eloquent, controladores API como capa de aplicación, y servicios para lógica transversal (p. ej. manejo de media, importaciones).
- **Consistencia de inventario:** los movimientos se registran como transacciones (ledger). La actualización del **stock global** se realiza automáticamente cuando se crea una transacción.
- **Multi-bodega:** existe un stock por bodega adicional al stock global, para separar existencias por ubicación/flujo.

### Módulos principales (responsabilidades)

#### notifications
- **Generación (scheduler):** proceso programado que revisa:
  - **Stock bajo** (productos vs mínimo).
  - **Vencimientos de documentos** (SOAT / tecnomecánica).
  - **Mantenimientos próximos** (por km/horómetro).
- **Persistencia:** crea registros de notificación por usuario, con deduplicación por usuario/tipo/recurso en ventana de 24 horas.
- **API:** listar (con opción de “solo no leídas”) y marcar como leída (individual y masivo).

#### users / auth
- **Login:** autenticación por `email/password` y emisión de **token** (Sanctum) por dispositivo.
- **Sesión:** logout, refresh de token y cierre de todas las sesiones.
- **Autorización:** control por **roles** (campo de rol en usuario) y reglas puntuales por endpoint.

#### dashboard / analytics
- **KPIs agregados:** costos de combustible, costos de mantenimiento (derivados de transacciones de inventario ligadas a OT), cantidad de vehículos, órdenes abiertas.
- **Series/analítica:** consumo mensual de combustible, top costos de mantenimiento por vehículo, stock de combustibles.

#### inventory
- **Catálogo:** productos y categorías; búsqueda y paginación.
- **Ledger:** transacciones de inventario (ingreso/salida/transferencia) con datos de referencia (motivo, notas, entidad referenciada).
- **Multi-bodega:** control de cantidades por bodega (con reglas de transferencia definidas).
- **Importaciones:** carga masiva de productos e importación de compras que generan transacciones.

#### workshop / work-orders
- **Órdenes de trabajo (OT):** creación/consulta/actualización de estado y asociación con vehículo y mecánico.
- **Integración con inventario:** repuestos/herramientas generan **salidas** de inventario con control transaccional.
- **Sesiones de trabajo:** inicio/fin/consulta de sesión activa para registro operacional.
- **Evidencias:** soporte de imagen/archivo asociado a entidades del módulo.

#### fleet
- **Vehículos:** datos operativos, km/horómetro y parámetros de mantenimiento.
- **Documentos:** registros por vehículo con su ciclo de vida.
- **Horómetro:** registro y consulta de lecturas.
- **Asignaciones:** operador/mecánico se gestionan en términos de **empleados** (no solo cuentas técnicas).

#### checklists (preoperacionales)
- **Listas activas:** consulta de listas con sus ítems.
- **Ejecución:** almacenamiento de respuestas, evaluación de criticidad y estado final (aprobado/rechazado).
- **Historial:** consulta paginada y filtrable por vehículo.

#### combustible
- **Registros:** entregas/tanqueos con filtros, resumen y CRUD.
- **Integración con inventario:** cada registro deduce combustible de inventario y deja trazabilidad en transacciones.

#### scheduler (programación)
- **Programación semanal:** asignación por fecha/empleado/vehículo/labor.
- **Novedades:** registro de incidentes/cambios operacionales; puede asociar evidencia y crear OT derivada según reglas.

#### loans (préstamos)
- **Préstamos de herramientas:** registro, devolución y trazabilidad de responsables.

#### media
- **Almacenamiento:** persistencia de archivos por contexto (módulo/entidad/id) y registro de metadatos (mime, tamaño, autor, ruta).
- **API:** listar, subir y eliminar.

### Persistence & DB
- **Entidades típicas persistidas:** usuarios, empleados, vehículos, documentos, productos/categorías, bodegas y stock por bodega, transacciones de inventario, órdenes de trabajo, sesiones, préstamos, registros de combustible, checklists (listas + respuestas), programación/novedades, media y notificaciones.
- **Modelo “ledger” de inventario:**
  - La fuente de verdad de movimientos son las **transacciones** (ingresos/salidas/transferencias).
  - El stock global se deriva/ajusta con base en dichas transacciones.
  - El stock por bodega se mantiene por registros por bodega-producto.

### API pública
- **Tipo de API:** REST (JSON) con autenticación Bearer token (Sanctum).
- **Contratos/operaciones clave por módulo (alto nivel):**
  - Auth: login, user, refresh, logout, logout-all.
  - Inventario: listar/buscar productos, ver detalle, crear/actualizar/eliminar (según rol), importar, registrar transacciones.
  - Taller: listar/crear/ver OT y actualizar estado; sesiones start/stop/active.
  - Flota: listar/crear/actualizar vehículos; documentos; horómetro; checklists.
  - Combustible: listar/resumen/crear/actualizar/eliminar.
  - Programación: consultar rango de fechas y CRUD; novedades.
  - Notificaciones: listar (incluyendo solo no leídas), marcar leída, marcar todas.
  - Media: listar por contexto, subir, eliminar.

### Servicios de background
- **Scheduler:** generación de notificaciones programada **2 veces al día** (mañana y tarde) con zona horaria **America/Bogota** y sin traslapes.
- **Colas (queue):** configuradas para ejecutarse con driver en base de datos (workers disponibles para asíncronos).

### Seguridad
- **Autenticación:** Sanctum (tokens por dispositivo).
- **Autorización:** middleware por rol + reglas específicas por caso de uso.
- **Carga de archivos:** validación de tipo/tamaño; persistencia mediante servicio dedicado.

---

## 3. Frontend (Flutter – App Móvil)

### Arquitectura general
- **Organización por features:** separación por dominio (auth, inventario, flota, taller, scheduler, notificaciones, etc.).
- **Estado:** Provider/ChangeNotifier.
- **Networking:** Dio con:
  - inyección de token desde almacenamiento seguro,
  - refresh automático de token ante 401,
  - soporte opcional de **TLS pinning** configurable por variables de entorno.
- **Offline-first:** SQLite como almacenamiento local y **cola de sincronización** para operaciones pendientes cuando no hay red.

### Módulos principales (roles y responsabilidades)
- **Notificaciones (UI):** listado y acciones de lectura/borrado a nivel visual.
- **Notificaciones (servicio):**
  - sincroniza notificaciones no leídas desde el backend,
  - deduplica contra SQLite,
  - emite notificaciones locales del SO,
  - navega al módulo relacionado al tocar una notificación.
- **Inventario:** lectura de productos, movimientos y operaciones que pueden quedar en cola offline.
- **Flota:** vehículos, checklists y combustible; soporte de alertas por vencimientos/mantenimientos.
- **Taller/OT:** listado y gestión operativa de órdenes; sesiones.
- **Scheduler:** programación operativa y registro de novedades.
- **Analítica/Historial:** visualización de indicadores y actividad.

### Flujo de notificaciones en la app
- **Fuente:** el backend genera notificaciones periódicamente; la app las consulta para obtener las pendientes/no leídas.
- **Presentación:** se registran en SQLite y se emiten como notificación del SO; además se puede navegar al contexto (inventario/flota/OT).
- **Filtros/búsqueda/estado (conceptual):** lectura vs no leído, agrupación por tipo/prioridad y navegación contextual.
- **Push vs local:** en el MVP el mecanismo principal es **notificación local** gatillada por sincronización y recordatorios (no se asume un proveedor externo de push).
- **Sincronización read/unread:** el marcado de lectura se realiza localmente; queda como mejora reflejarlo hacia backend para mantener consistencia cross-device.

### Componentes principales (roles, sin imponer nombres)
- Ítem de notificación (título, cuerpo, tipo, referencia, estado leído).
- Lista de notificaciones con estados vacío/cargando y acciones masivas.
- Navegación contextual por tipo de evento.

### Navegación y estado
- Navegación estándar con rutas/pantallas por feature.
- Estado global por proveedores y sincronización transversal mediante un proveedor de sync.
- **Cola offline:** almacena método/endpoint/payload y reintenta con backoff; soporta mapeos de endpoints para compatibilidad de API.

### Background
- **Workmanager:** ejecución periódica para:
  - sincronizar alertas desde backend,
  - re-notificar recordatorios vencidos,
  - generar resúmenes operativos (p. ej. alertas de flota) con información local.

---

## 4. Frontend (Vue.js – Web)

### Arquitectura general
- **Vue 3 + Vite**, Composition API.
- **Router:** rutas protegidas mediante guardas de autenticación y un layout “shell” común.
- **Estado:** Pinia para:
  - sesión (token + usuario),
  - notificaciones (lista, contadores, acciones).
- **HTTP:** Axios con base URL configurable y token en encabezados.

### Módulos principales (roles y responsabilidades)
- **Shell/layout:** navegación lateral por módulos y header con acciones globales.
- **Centro de notificaciones:** listado completo con filtros por tipo/prioridad/estado, búsqueda, marcado leído/no leído y navegación contextual.
- **Dashboard:** KPIs y gráficas consumiendo endpoints de analítica.
- **Inventario/Flota/OT/Empleados/Préstamos/Combustible/Checklists/Programación/Historial:** páginas por dominio orientadas a operación administrativa.

### Flujo de notificaciones en web
- **Carga:** consulta al backend y actualización del store.
- **Presentación:** panel rápido en el shell + centro dedicado.
- **Acciones:** marcar leída individual y masivo; actualización optimista en UI.
- **Sincronización:** modelo pull (REST).

### Componentes principales (roles, sin imponer nombres)
- Lista de notificaciones, filtros, búsqueda y badges.
- Componentes del shell (sidebar, header, panel de notificaciones, menú de usuario).

### Navegación y estado
- Guards de auth basados en token persistido.
- Stores desacoplados (auth y notificaciones) y composables para refresco global.

### MVP UI
- El MVP web incluye módulos operativos adicionales a notificaciones y un centro de notificaciones funcional con acciones y filtros.

---

## 5. Estado actual del proyecto (MVP)

- Backend Laravel 11 con API REST y autenticación por tokens (Sanctum) operativa.
- Autorización por roles aplicada en endpoints sensibles (creación/importación/edición/borrado).
- Notificaciones implementadas end-to-end en backend + web (listar/leer/leer todas) y generación programada (mañana/tarde).
- App móvil con base offline-first: SQLite + cola de sincronización + manejo de conectividad y reintentos.
- Servicio de notificaciones en móvil con sincronización desde backend y emisión de notificaciones locales del SO; soporta navegación contextual.
- Inventario con ledger de transacciones, multi-bodega y reglas de transferencia; ajuste automático de stock global al crear transacciones.
- Taller/OT integrado con inventario (salidas de repuestos/herramientas) y soporte de evidencias (media).
- Flota con documentos, vencimientos, mantenimientos, horómetro, asignaciones basadas en empleados.
- Checklists preoperacionales con listas activas, registro de respuestas y historial.
- Combustible con deducción obligatoria de inventario y endpoints de resumen para dashboard.
- Programación semanal y novedades implementadas; posibilidad de crear OT derivadas.
- Web con layout shell, router protegido y páginas para módulos principales; notificaciones integradas en shell + centro.
- Pendiente recomendado: sincronizar “leído/no leído” de notificaciones desde móvil hacia backend para consistencia entre dispositivos.
- Pendiente recomendado: unificar la UI de notificaciones móvil con la fuente persistente (SQLite) para que el centro de notificaciones refleje exactamente lo sincronizado/persistido.

