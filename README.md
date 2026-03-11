# 🛠️ Semanur App - Sistema de Gestión de Taller e Inventario

Semanur App es una solución integral diseñada para la gestión eficiente de operaciones de taller, control de inventarios, seguimiento de flota y programación de servicios. El sistema combina un potente backend administrativo con aplicaciones versátiles para dispositivos móviles y entorno web.

---

## 🏗️ Arquitectura del Proyecto

El ecosistema se divide en tres componentes principales:

1.  **Backend (`/backend`):** Núcleo del sistema desarrollado en Laravel 11. Proporciona una API RESTful para los clientes y un panel administrativo robusto (Backpack).
2.  **Frontend (`/frontend`):** Aplicación móvil multiplataforma desarrollada en Flutter, optimizada para el trabajo en campo y sincronización offline.
3.  **Web (`/web`):** Dashboard administrativo y de visualización desarrollado con Vue 3 y Vite para acceso rápido vía navegador.

---

## 🚀 Funcionalidades Principales

-   **Gestión de Órdenes de Trabajo (OT):** Ciclo completo desde la creación hasta la liquidación.
-   **Control de Inventario:** Gestión de productos, bodegas, movimientos y stock mínimo.
-   **Mantenimiento de Flota:** Seguimiento de vehículos, horómetros, registros de combustible y listas de chequeo pre-operacional.
-   **Gestión de Personal:** Control de empleados, roles y sesiones de trabajo.
-   **Sincronización Offline:** El frontend móvil permite trabajar sin conexión y sincronizar datos al detectar red.
-   **Reportes y Analítica:** Dashboards con métricas clave de operación.

---

## 📦 Listado de Dependencias por Proyecto

### 🔐 Backend (Laravel 11)
| Dependencia | Propósito |
| :--- | :--- |
| `backpack/crud` | Panel administrativo dinámico y gestión de modelos. |
| `laravel/framework` | Core del sistema (v11.0). |
| `laravel/sanctum` | Autenticación basada en tokens para la API. |
| `livewire/livewire` | Componentes reactivos para el panel administrativo. |
| `phpoffice/phpspreadsheet` | Exportación e importación de reportes en Excel. |

### 📱 Frontend (Flutter)
| Dependencia | Propósito |
| :--- | :--- |
| `dio` | Cliente HTTP avanzado para consumo de API. |
| `flutter_secure_storage` | Almacenamiento seguro de credenciales y tokens. |
| `provider` | Gestión de estado de la aplicación. |
| `sqflite` | Base de datos local para soporte offline. |
| `mobile_scanner` | Escaneo de códigos de barras y QR para inventarios. |
| `workmanager` | Ejecución de tareas en segundo plano para sincronización. |
| `fl_chart` | Visualización de datos y estadísticas. |

### 🌐 Web (Vue 3 + Vite)
| Dependencia | Propósito |
| :--- | :--- |
| `vue` | Framework base para la interfaz web. |
| `pinia` | Gestión de estado global. |
| `vue-router` | Navegación entre vistas. |
| `axios` | Comunicación con el backend. |
| `vite` | Herramienta de construcción y entorno de desarrollo rápido. |

---

## 🛠️ Configuración e Instalación

### 1. Requisitos Previos
- PHP 8.2+ & Composer
- Node.js & npm/pnpm
- Flutter SDK (versión estable)
- Base de datos (MySQL o PostgreSQL)

### 2. Configuración del Backend
```bash
cd backend
composer install
cp .env.example .env # Configura tus credenciales de BD aquí
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### 3. Configuración del Frontend (Móvil)
```bash
cd frontend
flutter pub get
# Crea un archivo .env en la raíz de frontend con: API_URL=http://tu-ip:8000/api
flutter run
```

### 4. Configuración de la Web
```bash
cd web
pnpm install
pnpm dev
```

---

## 📂 Estructura de Directorios
- `/backend`: Lógica de negocio, API y Administración.
- `/frontend`: Aplicación móvil Flutter (Android/iOS).
- `/web`: Aplicación web Vue.js.
- `/.agents`: Configuraciones de agentes inteligentes (omitido en Git).
- `/docs`: Documentación técnica detallada (omitido en Git).
