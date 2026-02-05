<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use App\Models\Categoria;
use App\Models\Producto;
use App\Models\TransaccionInventario;

echo "Starting Stock Logic Test...\n";

// Ensure we have a user
$user = User::first();
if (!$user) {
    echo "Creating user...\n";
    $user = User::factory()->create();
}

// Create Category
echo "Creating Category...\n";
$cat = Categoria::create([
    'categoria_nombre' => 'Test Cat ' . uniqid(),
    'categoria_tipo' => 'repuesto'
]);

// Create Product
echo "Creating Product...\n";
$prod = Producto::create([
    'categoria_id' => $cat->categoria_id,
    'producto_sku' => 'SKU' . uniqid(),
    'producto_nombre' => 'Test Prod',
    'producto_unidad_medida' => 'unidad',
    'producto_stock_actual' => 0,
    'producto_alerta_stock_minimo' => 5,
    'producto_precio_costo' => 100,
    'producto_ubicacion' => 'A1'
]);

echo "Initial Stock: " . $prod->producto_stock_actual . "\n";

// Transaction 1: Entrada
echo "Creating Entrada Transaction (+10)...\n";
TransaccionInventario::create([
    'producto_id' => $prod->producto_id,
    'usuario_id' => $user->id,
    'transaccion_tipo' => 'entrada',
    'transaccion_cantidad' => 10,
    'transaccion_motivo' => 'compra',
    'transaccion_notas' => 'Initial stock'
]);

$prod->refresh();
echo "Stock after Entrada: " . $prod->producto_stock_actual . "\n";

if ($prod->producto_stock_actual != 10) {
    echo "FAIL: Expected 10\n";
    exit(1);
}

// Transaction 2: Salida
echo "Creating Salida Transaction (-3)...\n";
TransaccionInventario::create([
    'producto_id' => $prod->producto_id,
    'usuario_id' => $user->id,
    'transaccion_tipo' => 'salida',
    'transaccion_cantidad' => 3,
    'transaccion_motivo' => 'ajuste',
    'transaccion_notas' => 'Used'
]);

$prod->refresh();
echo "Stock after Salida: " . $prod->producto_stock_actual . "\n";

if ($prod->producto_stock_actual != 7) {
    echo "FAIL: Expected 7\n";
    exit(1);
}

echo "SUCCESS: Stock logic verified.\n";
