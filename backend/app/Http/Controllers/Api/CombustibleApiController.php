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
            'vehiculo_id' => 'required|exists:vehiculos,vehiculo_id',
            'cantidad_galones' => 'required|numeric|min:0.01',
            'valor_total' => 'required|numeric|min:0',
            'horometro_actual' => 'nullable|numeric',
            'kilometraje_actual' => 'nullable|numeric',
            'estacion_servicio' => 'nullable|string',
            'notas' => 'nullable|string',
            'producto_id' => 'nullable|exists:productos,producto_id', // Para combustible interno
        ]);

        return DB::transaction(function () use ($request) {
            // Si es interno, manejar inventario
            if ($request->has('producto_id') && $request->producto_id) {
                $producto = Producto::find($request->producto_id);

                if ($producto->producto_stock_actual < $request->cantidad_galones) {
                    return response()->json(['message' => 'Stock insuficiente de combustible'], 422);
                }

                $producto->producto_stock_actual -= $request->cantidad_galones;
                $producto->save();

                // Registrar transacción de salida
                TransaccionInventario::create([
                    'producto_id' => $request->producto_id,
                    'usuario_id' => $request->user()->id,
                    'transaccion_tipo' => 'salida',
                    'transaccion_cantidad' => $request->cantidad_galones,
                    'transaccion_motivo' => 'Consumo de Combustible (Interno)',
                    'transaccion_referencia_id' => $request->vehiculo_id,
                    'transaccion_referencia_type' => 'Vehiculo',
                    'transaccion_notas' => "Tanqueo interno para vehículo ID {$request->vehiculo_id}",
                ]);
            }

            $registro = RegistroCombustible::create([
                'vehiculo_id' => $request->vehiculo_id,
                'usuario_id' => $request->user()->id,
                'fecha' => Carbon::now(),
                'cantidad_galones' => $request->cantidad_galones,
                'valor_total' => $request->valor_total,
                'horometro_actual' => $request->horometro_actual,
                'kilometraje_actual' => $request->kilometraje_actual,
                'estacion_servicio' => $request->estacion_servicio ?? 'Tanque Interno',
                'notas' => $request->notas,
            ]);

            return response()->json([
                'message' => 'Registro de combustible creado con éxito',
                'registro' => $registro->load('vehiculo')
            ], 201);
        });
    }
}
