<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$ot = App\Models\OrdenTrabajo::first();

if ($ot) {
    echo "ID: " . $ot->orden_trabajo_id . PHP_EOL;
    echo "Fecha Inicio (DB): " . $ot->fecha_inicio . PHP_EOL;
    echo "Fecha Inicio (ISO): " . $ot->fecha_inicio->toIso8601String() . PHP_EOL;
    echo "Timezone: " . $ot->fecha_inicio->tzName . PHP_EOL;
    echo "Timestamp: " . $ot->fecha_inicio->timestamp . PHP_EOL;
} else {
    echo "No hay ordenes de trabajo\n";
}
