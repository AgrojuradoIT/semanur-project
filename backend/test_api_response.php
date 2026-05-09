<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$orden = App\Models\OrdenTrabajo::with([
    'vehiculo',
    'mecanico',
    'movimientos_inventario.producto',
    'sesiones.user',
    'sesiones.empleado'
])->find(13);

$response = [
    'orden_id' => $orden->orden_trabajo_id,
    'sesiones_count' => $orden->sesiones->count(),
    'sesiones' => $orden->sesiones->map(fn($s) => [
        'sesion_id' => $s->sesion_id,
        'empleado_id' => $s->empleado_id,
        'orden_trabajo_id' => $s->orden_trabajo_id,
        'fecha_inicio' => $s->fecha_inicio,
        'fecha_fin' => $s->fecha_fin,
    ])->toArray(),
];

echo json_encode($response, JSON_PRETTY_PRINT);
