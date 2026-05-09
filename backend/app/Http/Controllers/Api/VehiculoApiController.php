<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empleado;
use App\Models\Vehiculo;
use App\Models\TransaccionInventario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class VehiculoApiController extends Controller
{
    // Removed resolveEmpleadoIdFromInput as we now strictly use empleado_id in payloads

    public function index()
    {
        return response()->json(
            Vehiculo::query()
                ->orderBy('placa')
                ->get()
        );
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'placa' => 'required|string|unique:vehiculos,placa',
            'tipo' => 'nullable|string',
            'marca' => 'nullable|string',
            'modelo' => 'nullable|string',
            'kilometraje_actual' => 'nullable|numeric|min:0',
            'horometro_actual' => 'nullable|numeric|min:0',
            'fecha_vencimiento_soat' => 'nullable|date',
            'fecha_vencimiento_tecnomecanica' => 'nullable|date',
            'horometro_proximo_mantenimiento' => 'nullable|numeric|min:0',
            'kilometraje_proximo_mantenimiento' => 'nullable|numeric|min:0',
            'operador_asignado_id' => 'nullable|integer|exists:empleados,id',
            'mecanico_asignado_id' => 'nullable|integer|exists:empleados,id',
        ]);

        if (array_key_exists('operador_asignado_id', $validated)) {
            $validated['operador_asignado_id'] = $validated['operador_asignado_id'] ? (int) $validated['operador_asignado_id'] : null;
        }

        if (array_key_exists('mecanico_asignado_id', $validated)) {
            $validated['mecanico_asignado_id'] = $validated['mecanico_asignado_id'] ? (int) $validated['mecanico_asignado_id'] : null;
        }

        if (array_key_exists('placa', $validated)) {
            $validated['placa'] = strtoupper(trim($validated['placa']));
        }

        $vehiculo = Vehiculo::create($validated);
        
        // Recargar relaciones
        $vehiculo->load(['operador', 'mecanico']);

        return response()->json([
            'message' => 'Vehículo creado correctamente',
            'vehiculo' => $vehiculo
        ], 201);
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
            'placa' => 'sometimes|string|unique:vehiculos,placa,'.$id.',vehiculo_id',
            'tipo' => 'nullable|string',
            'marca' => 'nullable|string',
            'modelo' => 'nullable|string',
            'kilometraje_actual' => 'nullable|numeric|min:0',
            'horometro_actual' => 'nullable|numeric|min:0',
            'fecha_vencimiento_soat' => 'nullable|date',
            'fecha_vencimiento_tecnomecanica' => 'nullable|date',
            'horometro_proximo_mantenimiento' => 'nullable|numeric|min:0',
            'kilometraje_proximo_mantenimiento' => 'nullable|numeric|min:0',
            'operador_asignado_id' => 'nullable|integer|exists:empleados,id',
            'mecanico_asignado_id' => 'nullable|integer|exists:empleados,id',
        ]);

        if (array_key_exists('operador_asignado_id', $validated)) {
            $validated['operador_asignado_id'] = $validated['operador_asignado_id'] ? (int) $validated['operador_asignado_id'] : null;
        }

        if (array_key_exists('mecanico_asignado_id', $validated)) {
            $validated['mecanico_asignado_id'] = $validated['mecanico_asignado_id'] ? (int) $validated['mecanico_asignado_id'] : null;
        }

        if (array_key_exists('placa', $validated)) {
            $validated['placa'] = strtoupper(trim($validated['placa']));
        }

        $vehiculo->update($validated);
        
        // Recargar relaciones para devolver objeto completo
        $vehiculo->load(['operador', 'mecanico']);

        return response()->json([
            'message' => 'Vehículo actualizado correctamente',
            'vehiculo' => $vehiculo
        ]);
    }

    public function destroy($id)
    {
        return DB::transaction(function () use ($id) {
            $vehiculo = Vehiculo::find($id);

            if (!$vehiculo) {
                return response()->json(['message' => 'Vehículo no encontrado'], 404);
            }

            $ordenesActivas = $vehiculo->ordenesTrabajo()
                ->whereIn('estado', ['Abierta', 'En Progreso'])
                ->count();

            if ($ordenesActivas > 0) {
                return response()->json([
                    'message' => 'No se puede eliminar: el vehículo tiene órdenes de trabajo activas',
                ], 409);
            }

            $vehiculo->ordenesTrabajo()->delete();
            $vehiculo->respuestasChecklist()->delete();
            $vehiculo->delete();

            return response()->json(['message' => 'Vehículo eliminado correctamente']);
        });
    }

    public function uploadImage(Request $request)
    {
        $request->validate([
            'vehiculo_id' => 'required|exists:vehiculos,vehiculo_id',
            'imagen' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:5120', // 5MB max
        ]);

        $vehiculo = Vehiculo::find($request->vehiculo_id);

        if ($request->hasFile('imagen')) {
            // Delete old image if it exists
            if ($vehiculo->imagen_url && \Illuminate\Support\Facades\Storage::disk('public')->exists($vehiculo->imagen_url)) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($vehiculo->imagen_url);
            }

            // Store new image
            $path = $request->file('imagen')->store('vehiculos', 'public');
            
            // Save path
            $vehiculo->imagen_url = $path;
            $vehiculo->save();

            // Refresh relations to return complete object
            $vehiculo->load(['operador', 'mecanico']);

            return response()->json([
                'message' => 'Imagen de vehículo subida exitosamente',
                'vehiculo' => $vehiculo
            ]);
        }

        return response()->json(['message' => 'No se recibió ninguna imagen'], 400);
    }
}
