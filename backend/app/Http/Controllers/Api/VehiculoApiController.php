<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vehiculo;
use App\Models\TransaccionInventario;
use Illuminate\Http\Request;

class VehiculoApiController extends Controller
{
    public function index()
    {
        return response()->json(Vehiculo::all());
    }

    public function show($id)
    {
        $vehiculo = Vehiculo::with([
            'ordenesTrabajo' => function($query) {
                $query->orderBy('created_at', 'desc');
            },
            'ordenesTrabajo.movimientos_inventario.producto', // Repuestos usados en cada OT
            'operador',
            'mecanico'
        ])->find($id);

        if (!$vehiculo) {
            return response()->json(['message' => 'Vehículo no encontrado'], 404);
        }

        // También cargar movimientos directos al vehículo (entrega directa/combustible)
        $vehiculo->movimientos_directos = TransaccionInventario::with('producto')
            ->where('transaccion_referencia_id', $id)
            ->where('transaccion_referencia_type', 'Vehiculo')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($vehiculo);
    }

    public function update(Request $request, $id)
    {
        $vehiculo = Vehiculo::find($id);

        if (!$vehiculo) {
            return response()->json(['message' => 'Vehículo no encontrado'], 404);
        }

        $validated = $request->validate([
            'fecha_vencimiento_soat' => 'nullable|date',
            'fecha_vencimiento_tecnomecanica' => 'nullable|date',
            'horometro_proximo_mantenimiento' => 'nullable|numeric|min:0',
            'kilometraje_proximo_mantenimiento' => 'nullable|numeric|min:0',
            'operador_asignado_id' => 'nullable|exists:users,id',
            'mecanico_asignado_id' => 'nullable|exists:users,id',
        ]);

        $vehiculo->update($validated);
        
        // Recargar relaciones para devolver objeto completo
        $vehiculo->load(['operador', 'mecanico']);

        return response()->json([
            'message' => 'Vehículo actualizado correctamente',
            'vehiculo' => $vehiculo
        ]);
    }
}
