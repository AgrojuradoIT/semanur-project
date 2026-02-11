<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProductoApiController;
use App\Http\Controllers\Api\OrdenTrabajoApiController;
use App\Http\Controllers\Api\MediaApiController;
use App\Http\Controllers\Api\VehiculoApiController;
use App\Http\Controllers\Api\MovimientoInventarioApiController;
use App\Http\Controllers\Api\PrestamoApiController;
use App\Http\Controllers\Api\CombustibleApiController;
use App\Http\Controllers\Api\HorometroApiController;
use App\Http\Controllers\Api\ChecklistApiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Rutas públicas
Route::post('/login', [AuthController::class, 'login']);

// Rutas protegidas
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'user']);
    Route::get('/users', [AuthController::class, 'index']); // Mantener compatibilidad o reemplazar por UserApiController
    Route::apiResource('/empleados', \App\Http\Controllers\Api\EmpleadoApiController::class);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Productos
    Route::get('/productos', [ProductoApiController::class, 'index']);
    Route::get('/productos/buscar', [ProductoApiController::class, 'search']);
    Route::post('/productos/import', [ProductoApiController::class, 'import']);
    Route::get('/productos/{id}', [ProductoApiController::class, 'show']);

    // Órdenes de Trabajo
    Route::get('/ordenes-trabajo', [OrdenTrabajoApiController::class, 'index']);
    Route::post('/ordenes-trabajo', [OrdenTrabajoApiController::class, 'store']);
    Route::get('/ordenes-trabajo/{id}', [OrdenTrabajoApiController::class, 'show']);
    Route::patch('/ordenes-trabajo/{id}/estado', [OrdenTrabajoApiController::class, 'updateStatus']);

    // Vehículos
    Route::get('/vehiculos', [VehiculoApiController::class, 'index']);
    Route::get('/vehiculos/{id}', [VehiculoApiController::class, 'show']);
    Route::put('/vehiculos/{id}', [VehiculoApiController::class, 'update']);

    // Movimientos de Inventario
    Route::get('/movimientos', [MovimientoInventarioApiController::class, 'index']);
    Route::post('/movimientos', [MovimientoInventarioApiController::class, 'store']);

    Route::get('/prestamos', [PrestamoApiController::class, 'index']);
    Route::post('/prestamos', [PrestamoApiController::class, 'store']);
    Route::post('/prestamos/{id}/devolver', [PrestamoApiController::class, 'devolver']);

    // Combustible y Horómetro
    Route::get('/combustible', [CombustibleApiController::class, 'index']);
    Route::post('/combustible', [CombustibleApiController::class, 'store']);
    
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

    // Analítica
    Route::get('/analytics/summary', [\App\Http\Controllers\Api\AnalyticsApiController::class, 'getSummary']);
    Route::get('/analytics/fuel', [\App\Http\Controllers\Api\AnalyticsApiController::class, 'getFuelMonthly']);
    Route::get('/analytics/maintenance', [\App\Http\Controllers\Api\AnalyticsApiController::class, 'getMaintenanceByVehicle']);

    // Programación Semanal
    Route::get('/programacion', [\App\Http\Controllers\Api\ProgramacionApiController::class, 'index']);
    Route::post('/programacion', [\App\Http\Controllers\Api\ProgramacionApiController::class, 'store']);
    Route::post('/programacion/novedad', [\App\Http\Controllers\Api\ProgramacionApiController::class, 'novedad']);

    // Media (fotos, archivos)
    Route::get('/media', [MediaApiController::class, 'index']);
    Route::post('/media', [MediaApiController::class, 'store']);
    Route::delete('/media/{id}', [MediaApiController::class, 'destroy']);
});
