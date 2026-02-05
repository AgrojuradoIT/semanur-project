<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\CategoriaController;
use App\Http\Controllers\ProductoController;
use App\Http\Controllers\VehiculoController;
use App\Http\Controllers\OrdenTrabajoController;
use App\Http\Controllers\TransaccionInventarioController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/dashboard', function () {
    return view('dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');

    // CRUD Routes
    Route::resource('categorias', CategoriaController::class);
    Route::resource('productos', ProductoController::class);
    Route::resource('vehiculos', VehiculoController::class);
    Route::resource('ordenes-trabajo', OrdenTrabajoController::class);
    Route::resource('transacciones-inventario', TransaccionInventarioController::class);
    Route::resource('users', App\Http\Controllers\UserController::class);

    // Test route
    Route::get('/test', [App\Http\Controllers\TestController::class, 'test']);
});

require __DIR__.'/auth.php';
