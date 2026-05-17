<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CombustibleRequest;
use App\Models\RegistroCombustible;
use App\Models\TransaccionInventario;
use App\Services\CombustibleService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CombustibleApiController extends Controller
{
    public function __construct(
        private readonly CombustibleService $combustibleService,
    ) {}

    public function index(Request $request)
    {
        $query = RegistroCombustible::with(['vehiculo', 'empleado', 'usuario'])
            ->orderBy('fecha', 'desc');

        if ($request->filled('vehiculo_id')) {
            $query->where('vehiculo_id', $request->vehiculo_id);
        }
        if ($request->filled('tipo_combustible')) {
            $query->where('tipo_combustible', $request->tipo_combustible);
        }
        if ($request->filled('tipo_destino')) {
            $query->where('tipo_destino', $request->tipo_destino);
        }
        if ($request->filled('fecha_desde')) {
            $query->where('fecha', '>=', Carbon::parse($request->fecha_desde)->startOfDay());
        }
        if ($request->filled('fecha_hasta')) {
            $query->where('fecha', '<=', Carbon::parse($request->fecha_hasta)->endOfDay());
        }

        $perPage = min((int) $request->get('per_page', 25), 100);
        $paginated = $query->paginate($perPage);

        return response()->json([
            'data' => $paginated->items(),
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
            ],
        ]);
    }

    public function summary(Request $request)
    {
        $query = RegistroCombustible::query();

        if ($request->filled('fecha_desde')) {
            $query->where('fecha', '>=', Carbon::parse($request->fecha_desde)->startOfDay());
        }
        if ($request->filled('fecha_hasta')) {
            $query->where('fecha', '<=', Carbon::parse($request->fecha_hasta)->endOfDay());
        }

        $gasolina = (clone $query)->where('tipo_combustible', 'gasolina');
        $acpm = (clone $query)->where('tipo_combustible', 'acpm');
        $totalQuery = (clone $query);

        return response()->json([
            'total_registros' => $totalQuery->count(),
            'gasolina_galones' => round($gasolina->sum('cantidad_galones'), 2),
            'gasolina_valor' => round($totalQuery->where('tipo_combustible', 'gasolina')->sum('valor_total'), 2),
            'acpm_galones' => round($acpm->sum('cantidad_galones'), 2),
            'acpm_valor' => round($totalQuery->where('tipo_combustible', 'acpm')->sum('valor_total'), 2),
            'valor_total' => round($totalQuery->sum('valor_total'), 2),
        ]);
    }

    public function store(CombustibleRequest $request)
    {
        try {
            return DB::transaction(function () use ($request) {
                $empleadoId = $request->tipo_destino === 'vehiculo' ? $request->empleado_id : null;

                $producto = $this->combustibleService->resolveCombustibleProducto($request->tipo_combustible);

                if (!$producto) {
                    return response()->json([
                        'message' => "No se encontró el producto de combustible ({$request->tipo_combustible}). Verifique el inventario.",
                    ], 422);
                }

                if ($producto->producto_stock_actual < $request->cantidad_galones) {
                    return response()->json([
                        'message' => "Stock insuficiente de {$request->tipo_combustible}. Stock actual: {$producto->producto_stock_actual}",
                    ], 422);
                }

                [$refType, $refId, $notas] = $this->combustibleService->buildReferencia(
                    $request->tipo_destino,
                    $request->vehiculo_id,
                    $request->tercero_nombre,
                    $request->labor,
                );

                $bodegaId = $this->resolveDefaultBodegaId();

                $transaccion = TransaccionInventario::create([
                    'producto_id' => $producto->producto_id,
                    'bodega_id' => $bodegaId,
                    'usuario_id' => $request->user()->id,
                    'transaccion_tipo' => 'salida',
                    'transaccion_cantidad' => $request->cantidad_galones,
                    'transaccion_motivo' => 'Consumo de Combustible (Interno)',
                    'transaccion_referencia_id' => $refId,
                    'transaccion_referencia_type' => $refType,
                    'transaccion_notas' => $notas,
                ]);

                $registro = RegistroCombustible::create([
                    'vehiculo_id' => $request->vehiculo_id,
                    'empleado_id' => $empleadoId,
                    'tercero_nombre' => $request->tercero_nombre,
                    'tipo_destino' => $request->tipo_destino,
                    'tipo_combustible' => $request->tipo_combustible,
                    'usuario_id' => $request->user()->id,
                    'fecha' => Carbon::now(),
                    'cantidad_galones' => $request->cantidad_galones,
                    'valor_total' => $request->valor_total ?? 0,
                    'horometro_actual' => $request->horometro_actual,
                    'kilometraje_actual' => $request->kilometraje_actual,
                    'estacion_servicio' => $request->estacion_servicio,
                    'placa_manual' => $request->placa_manual,
                    'notas' => $request->notas,
                    'labor' => $request->labor,
                    'transaccion_id' => $transaccion->transaccion_id,
                ]);

                return response()->json([
                    'message' => 'Registro de combustible creado con éxito',
                    'registro' => $registro->load(['vehiculo', 'empleado']),
                ], 201);
            });
        } catch (\Exception $e) {
            \Log::error("Error en CombustibleApiController@store: " . $e->getMessage(), [
                'exception' => $e,
                'request' => $request->all(),
            ]);
            return response()->json([
                'message' => 'Error interno al registrar abastecimiento',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, $id)
    {
        $registro = RegistroCombustible::find($id);

        if (!$registro) {
            return response()->json(['message' => 'Registro no encontrado'], 404);
        }

        $validated = $request->validate([
            'tipo_combustible' => ['sometimes', 'in:gasolina,acpm'],
            'cantidad_galones' => ['sometimes', 'numeric', 'min:0.01'],
            'valor_total' => ['nullable', 'numeric', 'min:0'],
            'horometro_actual' => ['nullable', 'numeric'],
            'kilometraje_actual' => ['nullable', 'numeric'],
            'estacion_servicio' => ['nullable', 'string'],
            'notas' => ['nullable', 'string'],
            'labor' => ['nullable', 'string'],
        ]);

        $registro->update($validated);

        return response()->json([
            'message' => 'Registro actualizado con éxito',
            'registro' => $registro->load(['vehiculo', 'empleado', 'usuario']),
        ]);
    }

    public function destroy($id)
    {
        $registro = RegistroCombustible::find($id);

        if (!$registro) {
            return response()->json(['message' => 'Registro no encontrado'], 404);
        }

        return DB::transaction(function () use ($registro) {
            $transaccion = null;

            if ($registro->transaccion_id) {
                $transaccion = TransaccionInventario::find($registro->transaccion_id);
            }

            if (!$transaccion) {
                $transaccion = TransaccionInventario::where('transaccion_motivo', 'Consumo de Combustible (Interno)')
                    ->where('transaccion_tipo', 'salida')
                    ->where('transaccion_cantidad', $registro->cantidad_galones)
                    ->where('created_at', '>=', $registro->created_at->copy()->subMinute())
                    ->where('created_at', '<=', $registro->created_at->copy()->addMinute())
                    ->first();
            }

            if ($transaccion) {
                TransaccionInventario::create([
                    'producto_id' => $transaccion->producto_id,
                    'bodega_id' => $transaccion->bodega_id,
                    'usuario_id' => auth()->id(),
                    'transaccion_tipo' => 'ingreso',
                    'transaccion_cantidad' => $transaccion->transaccion_cantidad,
                    'transaccion_motivo' => 'Reversión por eliminación de tanqueo',
                    'transaccion_referencia_type' => 'combustible',
                    'transaccion_referencia_id' => $registro->registro_id,
                    'transaccion_notas' => "Reversión automática del registro #{$registro->registro_id}",
                ]);
            }

            $registro->delete();

            return response()->json([
                'message' => 'Registro eliminado' . ($transaccion ? ' y stock revertido' : ''),
            ]);
        });
    }

    private function resolveDefaultBodegaId(): ?int
    {
        return \App\Models\Bodega::value('bodega_id');
    }
}
