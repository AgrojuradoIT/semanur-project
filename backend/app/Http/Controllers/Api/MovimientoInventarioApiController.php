<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bodega;
use App\Models\Producto;
use App\Models\TransaccionInventario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MovimientoInventarioApiController extends Controller
{
    public function index(Request $request)
    {
        $query = TransaccionInventario::with(['producto', 'usuario'])
            ->orderBy('created_at', 'desc');

        if ($request->filled('producto_id')) {
            $query->where('producto_id', $request->producto_id);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'producto_id' => 'required|exists:productos,producto_id',
            'transaccion_tipo' => 'required|in:ingreso,salida,transferencia',
            'transaccion_cantidad' => 'required|numeric|min:0.01',
            'transaccion_motivo' => 'nullable|string',
            'transaccion_referencia_id' => 'nullable|integer',
            'transaccion_referencia_type' => 'nullable|string',
            'transaccion_notas' => 'nullable|string',
            'bodega_id' => 'nullable|exists:bodegas,bodega_id',
            'bodega_origen_id' => 'required_if:transaccion_tipo,transferencia|nullable|exists:bodegas,bodega_id',
            'bodega_destino_id' => 'required_if:transaccion_tipo,transferencia|nullable|different:bodega_origen_id|exists:bodegas,bodega_id',
        ]);

        return DB::transaction(function () use ($request) {
            $producto = Producto::findOrFail($request->producto_id);

            $bodegaOrigenId = null;
            $bodegaDestinoId = null;

            if ($request->transaccion_tipo === 'transferencia') {
                $bodegaOrigenId = $request->bodega_origen_id;
                $bodegaDestinoId = $request->bodega_destino_id;

                $origen = Bodega::find($bodegaOrigenId);
                $destino = Bodega::find($bodegaDestinoId);

                if (!$origen || !$destino) {
                    return response()->json([
                        'message' => 'Bodega de origen o destino no encontrada',
                    ], 422);
                }

                if ($origen->tipo !== 'estandar' || $destino->tipo !== 'recuperacion') {
                    return response()->json([
                        'message' => 'Solo se permite transferencia desde bodega estandar hacia bodega recuperacion',
                    ], 422);
                }
            } else {
                $bodegaId = $request->bodega_id;
                if (!$bodegaId) {
                    $bodegaPrincipal = Bodega::firstOrCreate(
                        ['tipo' => 'estandar'],
                        ['nombre' => 'Bodega Principal', 'descripcion' => 'Bodega central por defecto']
                    );
                    $bodegaId = $bodegaPrincipal->bodega_id;
                }

                if ($request->transaccion_tipo === 'ingreso') {
                    $bodegaDestinoId = $bodegaId;
                } else {
                    $bodegaOrigenId = $bodegaId;
                }
            }

            if ($bodegaOrigenId) {
                $stockOrigen = DB::table('bodega_producto')
                    ->where('bodega_id', $bodegaOrigenId)
                    ->where('producto_id', $producto->producto_id)
                    ->value('cantidad') ?? 0;

                if ($stockOrigen <= 0) {
                    return response()->json([
                        'message' => 'No es posible realizar salidas. El stock actual en la bodega de origen es 0 o menor.',
                        'stock_actual' => $stockOrigen,
                    ], 422);
                }
            }

            if ($bodegaOrigenId) {
                $this->updateBodegaStock($bodegaOrigenId, $producto->producto_id, -$request->transaccion_cantidad);
            }
            if ($bodegaDestinoId) {
                $this->updateBodegaStock($bodegaDestinoId, $producto->producto_id, $request->transaccion_cantidad);
            }

            $movimiento = TransaccionInventario::create([
                'producto_id' => $request->producto_id,
                'usuario_id' => $request->user()->id,
                'transaccion_tipo' => $request->transaccion_tipo,
                'transaccion_cantidad' => $request->transaccion_cantidad,
                'transaccion_motivo' => $request->transaccion_motivo,
                'transaccion_referencia_id' => $request->transaccion_referencia_id,
                'transaccion_referencia_type' => $request->transaccion_referencia_type,
                'transaccion_notas' => $request->transaccion_notas,
            ]);

            $producto->refresh();

            $warning = null;
            if (in_array($request->transaccion_tipo, ['salida', 'transferencia'])) {
                if ($producto->producto_stock_actual <= $producto->producto_alerta_stock_minimo) {
                    $warning = 'Se ha alcanzado o superado el stock mínimo de alerta para este producto.';

                    // Generar notificación inmediata en MySQL con deduplicación 24h
                    $yaExiste = DB::table('notificaciones')
                        ->where('tipo', 'stock_bajo')
                        ->where('relacionado_id', (string) $producto->producto_id)
                        ->where('created_at', '>=', now()->subHours(24))
                        ->exists();

                    if (!$yaExiste) {
                        DB::table('notificaciones')->insert([
                            'user_id'    => $request->user()->id,
                            'tipo'       => 'stock_bajo',
                            'titulo'     => 'Stock bajo: ' . $producto->producto_nombre,
                            'mensaje'    => "El producto {$producto->producto_nombre} ({$producto->producto_sku}) tiene {$producto->producto_stock_actual} unidades. Mínimo requerido: {$producto->producto_alerta_stock_minimo}.",
                            'prioridad'  => $producto->producto_stock_actual <= 0 ? 'alta' : 'media',
                            'relacionado_id' => (string) $producto->producto_id,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                    }
                }
            }

            return response()->json([
                'message' => 'Movimiento registrado con exito',
                'movimiento' => $movimiento,
                'nuevo_stock_global' => $producto->producto_stock_actual,
                'warning' => $warning,
            ]);
        });
    }

    private function updateBodegaStock(int $bodegaId, int $productoId, float $cantidadCambio): void
    {
        $bodegaProducto = DB::table('bodega_producto')
            ->where('bodega_id', $bodegaId)
            ->where('producto_id', $productoId)
            ->first();

        if ($bodegaProducto) {
            DB::table('bodega_producto')
                ->where('bodega_id', $bodegaId)
                ->where('producto_id', $productoId)
                ->update([
                    'cantidad' => $bodegaProducto->cantidad + $cantidadCambio,
                    'updated_at' => now(),
                ]);
            return;
        }

        DB::table('bodega_producto')->insert([
            'bodega_id' => $bodegaId,
            'producto_id' => $productoId,
            'cantidad' => $cantidadCambio,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}

