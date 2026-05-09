<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empleado;
use App\Models\Producto;
use App\Models\RegistroCombustible;
use App\Models\TransaccionInventario;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CombustibleApiController extends Controller
{
    private function resolveCombustibleProducto(string $tipo): ?Producto
    {
        $needle = strtoupper($tipo === 'gasolina' ? 'GASOLINA' : 'ACPM');

        $byCategoria = Producto::whereHas('categoria', function ($q) {
            $q->where('categoria_tipo', 'combustible')
                ->orWhereRaw('LOWER(categoria_nombre) LIKE ?', ['%combustible%']);
        })
            ->where(function ($q) use ($needle) {
                $q->whereRaw('UPPER(producto_nombre) LIKE ?', ["%{$needle}%"])
                    ->orWhereRaw('UPPER(producto_sku) LIKE ?', ["%{$needle}%"]);
            })
            ->orderByRaw('CASE WHEN UPPER(producto_nombre) = ? THEN 0 ELSE 1 END', [$needle])
            ->first();

        if ($byCategoria) {
            return $byCategoria;
        }

        return Producto::where(function ($q) use ($needle) {
            $q->whereRaw('UPPER(producto_nombre) LIKE ?', ["%{$needle}%"])
                ->orWhereRaw('UPPER(producto_sku) LIKE ?', ["%{$needle}%"]);
        })
            ->orderByRaw('CASE WHEN UPPER(producto_nombre) = ? THEN 0 ELSE 1 END', [$needle])
            ->first();
    }

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
            // Usar startOfDay para incluir todo el día desde las 00:00:00
            $query->where('fecha', '>=', Carbon::parse($request->fecha_desde)->startOfDay());
        }
        if ($request->filled('fecha_hasta')) {
            // Usar endOfDay para incluir todo el día hasta las 23:59:59
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

        return response()->json([
            'total_registros' => $query->count(),
            'gasolina_galones' => round($gasolina->sum('cantidad_galones'), 2),
            'gasolina_valor' => round((clone $query)->where('tipo_combustible', 'gasolina')->sum('valor_total'), 2),
            'acpm_galones' => round($acpm->sum('cantidad_galones'), 2),
            'acpm_valor' => round((clone $query)->where('tipo_combustible', 'acpm')->sum('valor_total'), 2),
            'valor_total' => round((clone $query)->sum('valor_total'), 2),
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'tipo_destino' => 'required|in:vehiculo,empleado,tercero',
            'tipo_combustible' => 'required|in:gasolina,acpm',
            'vehiculo_id' => 'nullable|exists:vehiculos,vehiculo_id',
            'empleado_id' => 'nullable|exists:empleados,id',
            'tercero_nombre' => 'nullable|string',
            'cantidad_galones' => 'required|numeric|min:0.01',
            'valor_total' => 'nullable|numeric|min:0',
            'horometro_actual' => 'nullable|numeric',
            'kilometraje_actual' => 'nullable|numeric',
            'estacion_servicio' => 'nullable|string',
            'notas' => 'nullable|string',
            'labor' => 'nullable|string',
            'placa_manual' => 'nullable|string',
        ]);

        try {
            return DB::transaction(function () use ($request) {
                $empleadoId = null;

                // Validaciones especificas segun el tipo de destino
                if ($request->tipo_destino === 'vehiculo') {
                    if (!$request->vehiculo_id) {
                        return response()->json(['message' => 'El vehiculo_id es requerido para destino vehiculo'], 422);
                    }
                    if (!$request->empleado_id) {
                        return response()->json(['message' => 'El empleado_id (A quien se le entrega) es requerido'], 422);
                    }
                    $empleadoId = $request->empleado_id;
                }

                if ($request->tipo_destino === 'empleado' && !$request->tercero_nombre) {
                    return response()->json(['message' => 'El nombre del empleado es requerido'], 422);
                }

                if ($request->tipo_destino === 'tercero' && !$request->tercero_nombre) {
                    return response()->json(['message' => 'El nombre del tercero es requerido'], 422);
                }

                // Deducción obligatoria de inventario basada en el tipo de combustible (Gasolina / ACPM)
                $producto = $this->resolveCombustibleProducto($request->tipo_combustible);

                if (!$producto) {
                    return response()->json(['message' => "No se encontró el producto de combustible ({$request->tipo_combustible}). Verifique el inventario."], 422);
                }

                if ($producto->producto_stock_actual < $request->cantidad_galones) {
                    return response()->json(['message' => "Stock insuficiente del combustible ({$request->tipo_combustible}). Stock actual: {$producto->producto_stock_actual}"], 422);
                }

                // Determinar referencia para transaccion
                $refType = null;
                $refId = null;
                $notas = 'Tanqueo interno';

                if ($request->tipo_destino === 'vehiculo') {
                    $refType = 'Vehiculo';
                    $refId = $request->vehiculo_id;
                    $notas .= " para vehiculo ID {$request->vehiculo_id}";
                } elseif ($request->tipo_destino === 'empleado') {
                    $refType = 'EmpleadoTexto';
                    $notas .= " para empleado: {$request->tercero_nombre}";
                } else {
                    $refType = 'Tercero';
                    $notas .= " para tercero: {$request->tercero_nombre}";
                }

                if ($request->filled('labor')) {
                    $notas .= " | Labor: {$request->labor}";
                }

                // Registrar transaccion de salida (el stock se ajusta por observer)
                TransaccionInventario::create([
                    'producto_id' => $producto->producto_id,
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
                ]);

                return response()->json([
                    'message' => 'Registro de combustible creado con exito',
                    'registro' => $registro->load(['vehiculo', 'empleado']),
                ], 201);
            });
        } catch (\Exception $e) {
            \Log::error("Error en CombustibleApiController@store: " . $e->getMessage(), [
                'exception' => $e,
                'request' => $request->all()
            ]);
            return response()->json([
                'message' => 'Error interno al registrar abastecimiento',
                'error' => $e->getMessage()
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
            'tipo_combustible' => 'sometimes|in:gasolina,acpm',
            'cantidad_galones' => 'sometimes|numeric|min:0.01',
            'valor_total' => 'nullable|numeric|min:0',
            'horometro_actual' => 'nullable|numeric',
            'kilometraje_actual' => 'nullable|numeric',
            'estacion_servicio' => 'nullable|string',
            'notas' => 'nullable|string',
            'labor' => 'nullable|string',
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
            // Buscar y revertir transacción de inventario asociada
            $transaccion = TransaccionInventario::where('transaccion_motivo', 'Consumo de Combustible (Interno)')
                ->where('transaccion_tipo', 'salida')
                ->where('transaccion_cantidad', $registro->cantidad_galones)
                ->where('created_at', '>=', $registro->created_at->subMinute())
                ->where('created_at', '<=', $registro->created_at->addMinute())
                ->first();

            if ($transaccion) {
                // Crear movimiento de ingreso para revertir
                TransaccionInventario::create([
                    'producto_id' => $transaccion->producto_id,
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
}
