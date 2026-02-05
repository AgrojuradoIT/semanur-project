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

        if ($transaccion->transaccion_tipo === 'entrada') {
            $producto->producto_stock_actual += $transaccion->transaccion_cantidad;
        } elseif ($transaccion->transaccion_tipo === 'salida') {
            $producto->producto_stock_actual -= $transaccion->transaccion_cantidad;
        }

        $producto->save();
    }
}
