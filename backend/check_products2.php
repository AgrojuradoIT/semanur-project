<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$productos = \App\Models\Producto::where('producto_nombre', 'like', '%gasol%')
    ->orWhere('producto_nombre', 'like', '%acpm%')
    ->orWhere('producto_sku', 'COMB-001')
    ->orWhere('producto_sku', 'COMB-002')
    ->get(['producto_id', 'producto_sku', 'producto_nombre', 'producto_stock_actual'])
    ->toArray();

file_put_contents('products.json', json_encode($productos, JSON_PRETTY_PRINT));
echo "Done";
