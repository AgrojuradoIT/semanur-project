<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Producto;
use App\Models\Vehiculo;
use App\Models\Notificacion;
use App\Models\User;
use Carbon\Carbon;

class CheckNotifications extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:check-notifications';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Revisar stock, vencimientos y mantenimientos para generar notificaciones';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Iniciando revision de notificaciones...');

        $this->checkStockBajo();
        $this->checkVencimientosDocumentos();
        $this->checkMantenimientosProximos();

        $this->info('Revision completada.');
    }

    /**
     * 1. Revisar Stock de Productos
     */
    private function checkStockBajo()
    {
        $productos = Producto::whereColumn('producto_stock_actual', '<=', 'producto_alerta_stock_minimo')
            ->where('producto_stock_actual', '>', 0) // Solo si hay algo o está justo en el límite
            ->get();

        $admins = User::whereIn('role', ['admin', 'jefe_taller', 'auxiliar_bodega'])->get();

        foreach ($productos as $p) {
            foreach ($admins as $user) {
                $this->upsertNotificacion(
                    $user->id,
                    'stock_bajo',
                    "Stock bajo: {$p->producto_nombre}",
                    "El producto {$p->producto_nombre} ({$p->producto_sku}) tiene {$p->producto_stock_actual} unidades. Minimo requerido: {$p->producto_alerta_stock_minimo}",
                    $p->id,
                    'alta'
                );
            }
        }
    }

    /**
     * 2. Revisar Vencimientos de SOAT y Tecnomecánica
     */
    private function checkVencimientosDocumentos()
    {
        $vehiculos = Vehiculo::all();
        $admins = User::whereIn('role', ['admin', 'jefe_taller'])->get();
        $hoy = Carbon::now();

        foreach ($vehiculos as $v) {
            $vencimientos = [
                'soat' => $v->fecha_vencimiento_soat,
                'tecnomecanica' => $v->fecha_vencimiento_tecnomecanica
            ];

            foreach ($vencimientos as $tipo => $fecha) {
                if (!$fecha) continue;

                $fechaVenc = Carbon::parse((string)$fecha);
                $diasRestantes = $hoy->diffInDays($fechaVenc, false);

                // Notificar si vence en 15, 7, 3 días o si ya venció
                if ($diasRestantes <= 15 && $diasRestantes >= -5) {
                    $prioridad = ($diasRestantes <= 3) ? 'alta' : 'media';
                    $msg = ($diasRestantes < 0) 
                        ? "VENCIDO hace " . abs($diasRestantes) . " dias."
                        : "Vence en $diasRestantes dias.";

                    foreach ($admins as $user) {
                        $this->upsertNotificacion(
                            $user->id,
                            "vencimiento_$tipo",
                            "Documento $tipo proximo a vencer: {$v->placa}",
                            "El $tipo del vehiculo {$v->placa} ({$v->marca}) $msg Fecha: " . $fechaVenc->format('d/m/Y'),
                            "{$v->id}|{$v->placa}",
                            $prioridad
                        );
                    }
                }
            }
        }
    }

    /**
     * 3. Revisar Mantenimientos (Kilometraje y Horómetro)
     */
    private function checkMantenimientosProximos()
    {
        $vehiculos = Vehiculo::all();
        $admins = User::whereIn('role', ['admin', 'jefe_taller'])->get();

        foreach ($vehiculos as $v) {
            // Kilometraje
            if ($v->kilometraje_proximo_mantenimiento > 0) {
                $restanteKm = $v->kilometraje_proximo_mantenimiento - $v->kilometraje_actual;
                if ($restanteKm <= 500 && $restanteKm >= -100) {
                    foreach ($admins as $user) {
                        $this->upsertNotificacion(
                            $user->id,
                            'mantenimiento_preventivo',
                            "Mantenimiento proximo (Km): {$v->placa}",
                            "Al vehiculo {$v->placa} le faltan $restanteKm Km para su mantenimiento preventivo.",
                            "{$v->id}|{$v->placa}",
                            'media'
                        );
                    }
                }
            }

            // Horómetro
            if ($v->horometro_proximo_mantenimiento > 0) {
                $restanteHrs = $v->horometro_proximo_mantenimiento - $v->horometro_actual;
                if ($restanteHrs <= 50 && $restanteHrs >= -10) {
                    foreach ($admins as $user) {
                        $this->upsertNotificacion(
                            $user->id,
                            'mantenimiento_preventivo',
                            "Mantenimiento proximo (Horas): {$v->placa}",
                            "Al vehiculo {$v->placa} le faltan $restanteHrs horas para su mantenimiento preventivo.",
                            "{$v->id}|{$v->placa}",
                            'media'
                        );
                    }
                }
            }
        }
    }

    /**
     * Evitar duplicados: Solo crea la notificación si no existe una idéntica 
     * pendiente (sin leer) en las últimas 24 horas para ese usuario y recurso.
     */
    private function upsertNotificacion($userId, $tipo, $titulo, $mensaje, $relId, $prioridad)
    {
        $existe = Notificacion::where('user_id', $userId)
            ->where('tipo', $tipo)
            ->where('relacionado_id', $relId)
            ->whereNull('fecha_leido')
            ->where('created_at', '>', Carbon::now()->subDay())
            ->exists();

        if (!$existe) {
            Notificacion::create([
                'user_id' => $userId,
                'tipo' => $tipo,
                'titulo' => $titulo,
                'mensaje' => $mensaje,
                'relacionado_id' => $relId,
                'prioridad' => $prioridad
            ]);
        }
    }
}
