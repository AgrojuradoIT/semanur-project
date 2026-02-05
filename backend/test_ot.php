<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use App\Models\Vehiculo;
use App\Models\OrdenTrabajo;

echo "Starting OT Logic Test...\n";

// Ensure we have a mechanic
$mechanic = User::first();
if (!$mechanic) {
    echo "Creating mechanic...\n";
    $mechanic = User::factory()->create(['name' => 'Juan Mecanico']);
}

// Create Vehicle
echo "Creating Vehicle...\n";
$placa = 'ABC-' . rand(100, 999);
$vehiculo = Vehiculo::create([
    'placa' => $placa,
    'tipo' => 'Tractor',
    'marca' => 'John Deere',
    'modelo' => '5090E',
]);

echo "Vehicle Created: " . $vehiculo->placa . "\n";

// Create OT
echo "Creating Work Order...\n";
$ot = OrdenTrabajo::create([
    'vehiculo_id' => $vehiculo->vehiculo_id,
    'mecanico_asignado_id' => $mechanic->id,
    'fecha_inicio' => now(),
    'estado' => 'Abierta',
    'prioridad' => 'Alta',
    'descripcion' => 'Change oil and filters',
]);

echo "OT Created ID: " . $ot->orden_trabajo_id . "\n";

// Verify Relationships
$ot->refresh();

if ($ot->vehiculo->placa !== $placa) {
    echo "FAIL: Vehicle relationship mismatch.\n";
    exit(1);
}

if ($ot->mecanico->id !== $mechanic->id) {
    echo "FAIL: Mechanic relationship mismatch.\n";
    exit(1);
}

echo "SUCCESS: OT logic and relationships verified.\n";
