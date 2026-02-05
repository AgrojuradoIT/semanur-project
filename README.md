# Sistema de Gestión de Taller e Inventario

## Estructura del Proyecto

*   **backend/**: API REST y Panel Administrativo (Laravel 11 + Backpack for Laravel).
*   **frontend/**: Aplicación Móvil y Web (Flutter).

## Requisitos Previos

*   PHP 8.2+
*   Composer
*   Flutter SDK
*   PostgreSQL / MySQL

## Configuración Inicial

1.  **Backend:**
    ```bash
    cd backend
    composer install
    cp .env.example .env
    php artisan key:generate
    php artisan migrate
    ```

2.  **Frontend:**
    ```bash
    cd frontend
    flutter pub get
    flutter run
    ```
