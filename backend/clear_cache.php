<?php
/**
 * Script para limpiar el cache de Laravel
 * 
 * Instrucciones:
 * 1. Sube este archivo a la raíz del backend en tu hosting
 * 2. Accede desde el navegador: https://backsm.agrojurado.com/clear_cache.php
 * 3. Verifica que el cache se limpió correctamente
 * 4. Elimina este archivo por seguridad
 */

define('LARAVEL_START', microtime(true));

// Verificar si es HTTPS
if (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
    $protocol = 'https';
} else {
    $protocol = 'http';
}

// Verificación básica de seguridad (opcional)
// Descomenta y cambia la contraseña para proteger el script
// $password = 'tu_contraseña_segura';
// if (!isset($_GET['pwd']) || $_GET['pwd'] !== $password) {
//     die('Acceso denegado. Proporciona la contraseña correcta.');
// }

echo "<!DOCTYPE html>";
echo "<html><head><title>Limpiar Cache Laravel</title>";
echo "<style>body{font-family:monospace;background:#1a1a2e;color:#eee;padding:20px;} pre{background:#16213e;padding:15px;border-radius:5px;overflow-x:auto;}</style>";
echo "</head><body>";
echo "<h1>🔧 Limpiar Cache de Laravel</h1>";
echo "<p>Host: " . $_SERVER['HTTP_HOST'] . "</p>";
echo "<p>Fecha: " . date('Y-m-d H:i:s') . "</p>";
echo "<hr>";

try {
    require __DIR__.'/vendor/autoload.php';
    
    $app = require_once __DIR__.'/bootstrap/app.php';
    $kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
    $kernel->bootstrap();

    echo "<h2>✅ Iniciando limpieza de cache...</h2>\n";
    echo "<pre>\n";

    echo "📁 Limpiando configuración...\n";
    Artisan::call('config:clear');
    echo Artisan::output();
    echo "\n";

    echo "🗑️  Limpiando cache general...\n";
    Artisan::call('cache:clear');
    echo Artisan::output();
    echo "\n";

    echo "🛣️  Limpiando rutas...\n";
    Artisan::call('route:clear');
    echo Artisan::output();
    echo "\n";

    echo "🎨 Limpiando vistas...\n";
    Artisan::call('view:clear');
    echo Artisan::output();
    echo "\n";

    echo "📦 Optimizando (opcional)...\n";
    Artisan::call('optimize');
    echo Artisan::output();
    echo "\n";

    echo "</pre>\n";
    
    echo "<h2>✅ ¡Cache limpiado exitosamente!</h2>\n";
    
    // Verificar timezone
    echo "<hr>";
    echo "<h2>🕐 Verificación de Timezone</h2>\n";
    echo "<pre>\n";
    echo "PHP Timezone: " . date_default_timezone_get() . "\n";
    echo "Carbon Now: " . \Carbon\Carbon::now()->toIso8601String() . "\n";
    echo "Offset: " . \Carbon\Carbon::now()->offsetHours . " horas\n";
    echo "</pre>\n";
    
    if (\Carbon\Carbon::now()->offsetHours == -5) {
        echo "<p style='color:#4ade80;font-weight:bold;'>✅ Timezone configurada correctamente para Bogotá (UTC-5)</p>";
    } else {
        echo "<p style='color:#f87171;font-weight:bold;'>⚠️ Timezone NO es Bogotá. Verifica config/timezone.php</p>";
    }
    
    echo "<hr>";
    echo "<h2>📋 Próximos Pasos</h2>\n";
    echo "<ol>\n";
    echo "<li>Accede a: <a href='/api/verificar-hora' style='color:#4ade80;'>/api/verificar-hora</a></li>\n";
    echo "<li>Prueba crear una orden de trabajo desde la app</li>\n";
    echo "<li>Verifica que la hora se muestra correctamente</li>\n";
    echo "<li><strong>Elimina este archivo clear_cache.php por seguridad</strong></li>\n";
    echo "</ol>\n";
    
} catch (\Exception $e) {
    echo "<h2 style='color:#f87171;'>❌ Error</h2>\n";
    echo "<pre style='color:#f87171;'>" . htmlspecialchars($e->getMessage()) . "</pre>\n";
    echo "<p>Posibles causas:</p>\n";
    echo "<ul>\n";
    echo "<li>El archivo vendor/autoload.php no existe (ejecuta composer install)</li>\n";
    echo "<li>Permisos incorrectos en las carpetas storage/ y bootstrap/cache/</li>\n";
    echo "<li>El archivo .env no está configurado correctamente</li>\n";
    echo "</ul>\n";
}

echo "<hr>";
echo "<p style='color:#6b7280;font-size:12px;'>Tiempo de ejecución: " . round((microtime(true) - LARAVEL_START), 2) . " segundos</p>";
echo "</body></html>";
