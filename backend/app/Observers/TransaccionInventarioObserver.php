<?php

namespace App\Observers;

use App\Models\TransaccionInventario;

class TransaccionInventarioObserver
{
    /**
     * Handle the TransaccionInventario "created" event.
     */
    public function created(TransaccionInventario $transaccion): void
    {
        $producto = $transaccion->producto;

        if (!$producto) {
            return;
        }

        $tipo = strtolower((string) $transaccion->transaccion_tipo);

        if (in_array($tipo, ['entrada', 'ingreso'], true)) {
            $producto->producto_stock_actual += $transaccion->transaccion_cantidad;
        } elseif ($tipo === 'salida') {
            $producto->producto_stock_actual -= $transaccion->transaccion_cantidad;
        }

        $producto->save();
    }
}
