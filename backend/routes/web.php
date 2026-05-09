<?php

use App\Http\Controllers\ProfileController;
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

    // Redirecciones para rutas antiguas -> Filament
    Route::redirect('/categorias', '/admin/categorias');
    Route::redirect('/categorias/{any}', '/admin/categorias')->where('any', '.*');
    Route::redirect('/productos', '/admin/productos');
    Route::redirect('/productos/{any}', '/admin/productos')->where('any', '.*');
    Route::redirect('/vehiculos', '/admin/vehiculos');
    Route::redirect('/vehiculos/{any}', '/admin/vehiculos')->where('any', '.*');
    Route::redirect('/ordenes-trabajo', '/admin/orden-trabajos');
    Route::redirect('/ordenes-trabajo/{any}', '/admin/orden-trabajos')->where('any', '.*');
    Route::redirect('/transacciones-inventario', '/admin/transaccion-inventarios');
    Route::redirect('/transacciones-inventario/{any}', '/admin/transaccion-inventarios')->where('any', '.*');
    Route::redirect('/users', '/admin/users');
    Route::redirect('/users/{any}', '/admin/users')->where('any', '.*');
});

require __DIR__.'/auth.php';
