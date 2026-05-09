<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Verificar sesiones de la orden 13
$orden_id = 13;

echo "Verificando sesiones para orden #$orden_id:\n";
echo str_repeat("-", 60) . "\n";

$sesiones = App\Models\WorkSession::where('orden_trabajo_id', $orden_id)
    ->orderBy('fecha_inicio', 'desc')
    ->get();

echo "Total sesiones encontradas: " . $sesiones->count() . "\n\n";

foreach ($sesiones as $s) {
    echo "Sesion ID: " . $s->sesion_id . "\n";
    echo "  Empleado ID: " . $s->empleado_id . "\n";
    echo "  Fecha Inicio: " . $s->fecha_inicio . "\n";
    echo "  Fecha Fin: " . ($s->fecha_fin ?? 'NULL') . "\n";
    echo "  Notas: " . ($s->notas ?? 'NULL') . "\n";
    echo "\n";
}

// Verificar orden con relaciones
echo "\nVerificando orden con relaciones:\n";
echo str_repeat("-", 60) . "\n";

$orden = App\Models\OrdenTrabajo::with('sesiones')->find($orden_id);

if ($orden) {
    echo "Orden ID: " . $orden->orden_trabajo_id . "\n";
    echo "Sesiones count: " . $orden->sesiones->count() . "\n";
    
    foreach ($orden->sesiones as $s) {
        echo "  - Sesion #" . $s->sesion_id . ": " . $s->fecha_inicio . " -> " . ($s->fecha_fin ?? 'En curso') . "\n";
    }
} else {
    echo "Orden no encontrada\n";
}
