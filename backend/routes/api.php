<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProductoApiController;
use App\Http\Controllers\Api\OrdenTrabajoApiController;
use App\Http\Controllers\Api\MediaApiController;
use App\Http\Controllers\Api\VehiculoApiController;
use App\Http\Controllers\Api\VehiculoDocumentoApiController;
use App\Http\Controllers\Api\MovimientoInventarioApiController;
use App\Http\Controllers\Api\PrestamoApiController;
use App\Http\Controllers\Api\CombustibleApiController;
use App\Http\Controllers\Api\HorometroApiController;
use App\Http\Controllers\Api\ChecklistApiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

// Rutas públicas
Route::post('/login', [AuthController::class, 'login']);

// Ruta temporal para verificar timezone (pública para testing)
Route::get('/verificar-hora', function() {
    $now = now();
    
    try {
        $mysqlNow = DB::select('SELECT NOW() as now')[0]->now;
    } catch (\Exception $e) {
        $mysqlNow = 'Error: ' . $e->getMessage();
    }
    
    return [
        'timezone_php' => date_default_timezone_get(),
        'carbon_now' => $now->toIso8601String(),
        'carbon_timezone' => $now->tzName,
        'offset' => $now->offsetHours . ' horas',
        'mysql_now' => $mysqlNow,
        'mensaje' => 'Si offset es -5, está correcto para Bogotá',
        'timestamp_unix' => $now->timestamp
    ];
});
// Rutas protegidas
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'user']);
    Route::get('/users', [AuthController::class, 'index']); // Mantener compatibilidad o reemplazar por UserApiController
    Route::apiResource('/empleados', \App\Http\Controllers\Api\EmpleadoApiController::class);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/refresh', [AuthController::class, 'refresh']);
    Route::post('/logout-all', [AuthController::class, 'logoutAll']);

    // Productos
    Route::get('/productos', [ProductoApiController::class, 'index']);
    Route::get('/productos/buscar', [ProductoApiController::class, 'search']);
    Route::get('/productos/{id}', [ProductoApiController::class, 'show']);
    Route::post('/productos', [ProductoApiController::class, 'store'])->middleware('role:admin,jefe_taller,auxiliar_bodega');
    Route::put('/productos/{id}', [ProductoApiController::class, 'update'])->middleware('role:admin');
    Route::delete('/productos/{id}', [ProductoApiController::class, 'destroy'])->middleware('role:admin');
    Route::post('/productos/import', [ProductoApiController::class, 'import'])->middleware('role:admin,jefe_taller,auxiliar_bodega');
    Route::post('/inventario/import-compras', [\App\Http\Controllers\Api\InventarioImportApiController::class, 'importCompras'])->middleware('role:admin,jefe_taller,auxiliar_bodega');

    // Órdenes de Trabajo
    Route::get('/ordenes-trabajo', [OrdenTrabajoApiController::class, 'index']);
    Route::post('/ordenes-trabajo', [OrdenTrabajoApiController::class, 'store']);
    Route::get('/ordenes-trabajo/{id}', [OrdenTrabajoApiController::class, 'show']);
    Route::patch('/ordenes-trabajo/{id}/estado', [OrdenTrabajoApiController::class, 'updateStatus']);

    // Vehículos
    Route::get('/vehiculos', [VehiculoApiController::class, 'index']);
    Route::post('/vehiculos', [VehiculoApiController::class, 'store']);
    Route::post('/vehiculos/imagen', [VehiculoApiController::class, 'uploadImage']);
    Route::get('/vehiculos/{id}', [VehiculoApiController::class, 'show']);
    Route::put('/vehiculos/{id}', [VehiculoApiController::class, 'update']);

    // Documentos de Vehículos
    Route::get('/vehiculos/{vehiculoId}/documentos', [VehiculoDocumentoApiController::class, 'index']);
    Route::post('/vehiculos/{vehiculoId}/documentos', [VehiculoDocumentoApiController::class, 'store']);
    Route::get('/vehiculos/{vehiculoId}/documentos/{id}', [VehiculoDocumentoApiController::class, 'show']);
    Route::put('/vehiculos/{vehiculoId}/documentos/{id}', [VehiculoDocumentoApiController::class, 'update']);
    Route::delete('/vehiculos/{vehiculoId}/documentos/{id}', [VehiculoDocumentoApiController::class, 'destroy']);

    // Movimientos de Inventario
    Route::get('/movimientos', [MovimientoInventarioApiController::class, 'index']);
    Route::post('/movimientos', [MovimientoInventarioApiController::class, 'store']);

    Route::get('/prestamos', [PrestamoApiController::class, 'index']);
    Route::post('/prestamos', [PrestamoApiController::class, 'store']);
    Route::post('/prestamos/{id}/devolver', [PrestamoApiController::class, 'devolver']);

    // Combustible y Horómetro
    Route::get('/combustible', [CombustibleApiController::class, 'index']);
    Route::get('/combustible/resumen', [CombustibleApiController::class, 'summary']);
    Route::post('/combustible', [CombustibleApiController::class, 'store'])->middleware('role:admin,jefe_taller,auxiliar_bodega');
    Route::put('/combustible/{id}', [CombustibleApiController::class, 'update'])->middleware('role:admin');
    Route::delete('/combustible/{id}', [CombustibleApiController::class, 'destroy'])->middleware('role:admin');
    
    Route::get('/vehiculos/{id}/horometro', [HorometroApiController::class, 'index']);
    Route::post('/horometro', [HorometroApiController::class, 'store']);

    // Checklists Preoperacionales
    Route::get('/checklists', [ChecklistApiController::class, 'index']);
    Route::post('/checklists', [ChecklistApiController::class, 'store']);
    Route::get('/checklists/history', [ChecklistApiController::class, 'history']);

    // Sesiones de Trabajo (Mecánicos)
    Route::post('/sesiones-trabajo/start', [\App\Http\Controllers\Api\WorkSessionApiController::class, 'start']);
    Route::post('/sesiones-trabajo/{id}/stop', [\App\Http\Controllers\Api\WorkSessionApiController::class, 'stop']);
    Route::get('/sesiones-trabajo/active', [\App\Http\Controllers\Api\WorkSessionApiController::class, 'activeSession']);

    // Analítica y BFF (Backend For Frontend)
    Route::get('/dashboard/all', [\App\Http\Controllers\Api\AnalyticsApiController::class, 'getDashboard']);
    Route::get('/history/all', [\App\Http\Controllers\Api\HistoryApiController::class, 'getHistoryAll']);
    Route::get('/analytics/summary', [\App\Http\Controllers\Api\AnalyticsApiController::class, 'getSummary']);
    Route::get('/analytics/fuel', [\App\Http\Controllers\Api\AnalyticsApiController::class, 'getFuelMonthly']);
    Route::get('/analytics/maintenance', [\App\Http\Controllers\Api\AnalyticsApiController::class, 'getMaintenanceByVehicle']);
    Route::get('/analytics/fuel-stock', [\App\Http\Controllers\Api\AnalyticsApiController::class, 'getFuelStock']);

    // Programación Semanal
    Route::get('/programacion', [\App\Http\Controllers\Api\ProgramacionApiController::class, 'index']);
    Route::post('/programacion', [\App\Http\Controllers\Api\ProgramacionApiController::class, 'store']);
    Route::post('/programacion/novedad', [\App\Http\Controllers\Api\ProgramacionApiController::class, 'novedad']);
    Route::put('/programacion/{id}', [\App\Http\Controllers\Api\ProgramacionApiController::class, 'update']);
    Route::delete('/programacion/{id}', [\App\Http\Controllers\Api\ProgramacionApiController::class, 'destroy']);

    // Media (fotos, archivos)
    Route::get('/media', [MediaApiController::class, 'index']);
    Route::post('/media', [MediaApiController::class, 'store']);
    Route::delete('/media/{id}', [MediaApiController::class, 'destroy']);
    // Notifications
    Route::get('notifications', [App\Http\Controllers\Api\NotificacionApiController::class, 'index']);
    Route::post('notifications/{id}/read', [App\Http\Controllers\Api\NotificacionApiController::class, 'markAsRead']);
    Route::post('notifications/read-all', [App\Http\Controllers\Api\NotificacionApiController::class, 'markAllAsRead']);
});
