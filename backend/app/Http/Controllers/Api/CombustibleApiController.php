<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RegistroCombustible;
use App\Models\Vehiculo;
use Illuminate\Http\Request;
use Carbon\Carbon;

use App\Models\Producto;
use App\Models\TransaccionInventario;
use Illuminate\Support\Facades\DB;

class CombustibleApiController extends Controller
{
    public function index(Request $request)
    {
        $query = RegistroCombustible::with(['vehiculo', 'usuario'])
            ->orderBy('fecha', 'desc');

        if ($request->has('vehiculo_id')) {
            $query->where('vehiculo_id', $request->vehiculo_id);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'tipo_destino' => 'required|in:vehiculo,empleado,tercero',
            'vehiculo_id' => 'nullable|exists:vehiculos,vehiculo_id',
            'empleado_id' => 'nullable|exists:users,id',
            'tercero_nombre' => 'nullable|string',
            'cantidad_galones' => 'required|numeric|min:0.01',
            'valor_total' => 'required|numeric|min:0',
            'horometro_actual' => 'nullable|numeric',
            'kilometraje_actual' => 'nullable|numeric',
            'estacion_servicio' => 'nullable|string',
            'notas' => 'nullable|string',
            'producto_id' => 'nullable|exists:productos,producto_id',
            'placa_manual' => 'nullable|string', // Nuevo campo opcional
        ]);

        return DB::transaction(function () use ($request) {
            // Validaciones específicas según el tipo de destino
            if ($request->tipo_destino == 'vehiculo' && !$request->vehiculo_id) {
                 return response()->json(['message' => 'El vehiculo_id es requerido para destino vehiculo'], 422);
            }
            if ($request->tipo_destino == 'empleado' && !$request->empleado_id) {
                 return response()->json(['message' => 'El empleado_id es requerido para destino empleado'], 422);
            }
            if ($request->tipo_destino == 'tercero' && !$request->tercero_nombre) {
                 return response()->json(['message' => 'El nombre del tercero es requerido'], 422);
            }

            // Si es interno, manejar inventario
            if ($request->has('producto_id') && $request->producto_id) {
                $producto = Producto::find($request->producto_id);

                if ($producto->producto_stock_actual < $request->cantidad_galones) {
                    return response()->json(['message' => 'Stock insuficiente de combustible'], 422);
                }

                $producto->producto_stock_actual -= $request->cantidad_galones;
                $producto->save();

                // Determinar referencia para transacción
                $refType = null;
                $refId = null;
                $notas = "Tanqueo interno";

                if ($request->tipo_destino == 'vehiculo') {
                    $refType = 'Vehiculo';
                    $refId = $request->vehiculo_id;
                    $notas .= " para vehículo ID {$request->vehiculo_id}";
                } else if ($request->tipo_destino == 'empleado') {
                    $refType = 'Empleado';
                    $refId = $request->empleado_id;
                    $notas .= " para empleado ID {$request->empleado_id}";
                } else if ($request->tipo_destino == 'tercero') {
                    $refType = 'Tercero';
                    $notas .= " para tercero: {$request->tercero_nombre}";
                }

                // Registrar transacción de salida
                TransaccionInventario::create([
                    'producto_id' => $request->producto_id,
                    'usuario_id' => $request->user()->id,
                    'transaccion_tipo' => 'salida',
                    'transaccion_cantidad' => $request->cantidad_galones,
                    'transaccion_motivo' => 'Consumo de Combustible (Interno)',
                    'transaccion_referencia_id' => $refId, // Null si es tercero
                    'transaccion_referencia_type' => $refType,
                    'transaccion_notas' => $notas,
                ]);
            }

            $registro = RegistroCombustible::create([
                'vehiculo_id' => $request->vehiculo_id, // Puede ser null
                'empleado_id' => $request->empleado_id,
                'tercero_nombre' => $request->tercero_nombre,
                'tipo_destino' => $request->tipo_destino ?? 'vehiculo',
                'usuario_id' => $request->user()->id,
                'fecha' => Carbon::now(),
                'cantidad_galones' => $request->cantidad_galones,
                'valor_total' => $request->valor_total,
                'horometro_actual' => $request->horometro_actual,
                'kilometraje_actual' => $request->kilometraje_actual,
                'estacion_servicio' => $request->estacion_servicio ?? 'Tanque Interno',
                'placa_manual' => $request->placa_manual,
                'notas' => $request->notas,
            ]);

            return response()->json([
                'message' => 'Registro de combustible creado con éxito',
                'registro' => $registro->load(['vehiculo', 'usuario']) // Cargar relaciones si existen
            ], 201);
        });
    }
}
