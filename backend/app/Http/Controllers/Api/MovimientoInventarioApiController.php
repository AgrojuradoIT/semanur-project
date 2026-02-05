<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TransaccionInventario;
use App\Models\Producto;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MovimientoInventarioApiController extends Controller
{
    public function index()
    {
        $movimientos = TransaccionInventario::with(['producto', 'usuario'])
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json($movimientos);
    }

    public function store(Request $request)
    {
        $request->validate([
            'producto_id' => 'required|exists:productos,producto_id',
            'transaccion_tipo' => 'required|in:ingreso,salida',
            'transaccion_cantidad' => 'required|numeric|min:0.01',
            'transaccion_motivo' => 'required|string',
            'transaccion_referencia_id' => 'nullable|integer',
            'transaccion_referencia_type' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request) {
            $producto = Producto::find($request->producto_id);

            if ($request->transaccion_tipo === 'salida' && $producto->producto_stock_actual < $request->transaccion_cantidad) {
                return response()->json([
                    'message' => 'Stock insuficiente para esta salida',
                    'stock_actual' => $producto->producto_stock_actual
                ], 422);
            }

            // Crear el movimiento
            $movimiento = new TransaccionInventario();
            $movimiento->producto_id = $request->producto_id;
            $movimiento->usuario_id = $request->user()->id;
            $movimiento->transaccion_tipo = $request->transaccion_tipo;
            $movimiento->transaccion_cantidad = $request->transaccion_cantidad;
            $movimiento->transaccion_motivo = $request->transaccion_motivo;
            $movimiento->transaccion_referencia_id = $request->transaccion_referencia_id;
            $movimiento->transaccion_referencia_type = $request->transaccion_referencia_type;
            $movimiento->save();

            // Actualizar stock del producto
            if ($request->transaccion_tipo === 'ingreso') {
                $producto->producto_stock_actual += $request->transaccion_cantidad;
            } else {
                $producto->producto_stock_actual -= $request->transaccion_cantidad;
            }
            $producto->save();

            return response()->json([
                'message' => 'Movimiento registrado con éxito',
                'movimiento' => $movimiento,
                'nuevo_stock' => $producto->producto_stock_actual
            ]);
        });
    }
}
