<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Verificar estructura de la tabla
$columns = DB::select("DESCRIBE orden_trabajos");

echo "Estructura de la tabla orden_trabajos:\n";
echo str_repeat("-", 60) . "\n";
printf("%-25s %-20s %-10s\n", "Campo", "Tipo", "Null");
echo str_repeat("-", 60) . "\n";

foreach ($columns as $column) {
    if (in_array($column->Field, ['fecha_inicio', 'fecha_fin', 'created_at', 'updated_at'])) {
        printf("%-25s %-20s %-10s\n", $column->Field, $column->Type, $column->Null);
    }
}

echo "\n";

// Verificar última orden creada
$ot = App\Models\OrdenTrabajo::orderBy('orden_trabajo_id', 'desc')->first();

if ($ot) {
    echo "Última orden creada:\n";
    echo str_repeat("-", 60) . "\n";
    echo "ID: " . $ot->orden_trabajo_id . "\n";
    echo "Fecha Inicio (raw): " . $ot->getRawOriginal('fecha_inicio') . "\n";
    echo "Fecha Inicio (cast): " . $ot->fecha_inicio . "\n";
    echo "Fecha Inicio (ISO): " . $ot->fecha_inicio->toIso8601String() . "\n";
    echo "Fecha Inicio (timestamp): " . $ot->fecha_inicio->timestamp . "\n";
    echo "Hora: " . $ot->fecha_inicio->hour . ":" . $ot->fecha_inicio->minute . ":" . $ot->fecha_inicio->second . "\n";
}
