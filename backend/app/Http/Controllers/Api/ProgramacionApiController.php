<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Programacion;
use App\Models\OrdenTrabajo;
use App\Models\Novedad;
use App\Services\MediaService;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class ProgramacionApiController extends Controller
{
    public function index(Request $request)
    {
        $request->validate([
            'fecha_inicio' => 'required|date',
            'fecha_fin' => 'required|date',
        ]);

        $programacion = Programacion::with(['empleado', 'vehiculo', 'ordenTrabajo'])
            ->whereBetween('fecha', [$request->fecha_inicio, $request->fecha_fin])
            ->orderBy('fecha', 'asc')
            ->get();

        return response()->json($programacion);
    }

    public function store(Request $request)
    {
        $request->validate([
            'fecha' => 'required|date',
            'empleado_id' => 'required|exists:empleados,id',
            'vehiculo_id' => 'nullable|exists:vehiculos,vehiculo_id',
            'labor' => 'required|string',
            'ubicacion' => 'nullable|string',
            'crear_orden_trabajo' => 'boolean' // Opcional, si se quiere forzar OT
        ]);

        return DB::transaction(function () use ($request) {
            $programacion = Programacion::create([
                'fecha' => $request->fecha,
                'empleado_id' => $request->empleado_id,
                'vehiculo_id' => $request->vehiculo_id,
                'labor' => $request->labor,
                'ubicacion' => $request->ubicacion,
                'estado' => 'pendiente',
            ]);

            // Si se requiere OT automática (lógica de negocio o flag)
            if ($request->crear_orden_trabajo) {
                // Crear OT básica
                $ot = OrdenTrabajo::create([
                    'vehiculo_id' => $request->vehiculo_id,
                    'mecanico_asignado_id' => null, // Ya no apunta a users, requiere lógica diferente si se asigna
                    'fecha_inicio' => $request->fecha,
                    'estado' => 'abierta',
                    'prioridad' => 'media',
                    'descripcion' => "Programación: " . $request->labor,
                ]);
                
                $programacion->orden_trabajo_id = $ot->orden_trabajo_id;
                $programacion->save();
            }

            return response()->json($programacion, 201);
        });
    }

    public function novedad(Request $request, MediaService $mediaService)
    {
        $request->validate([
            'fecha' => 'required|date',
            'empleado_id' => 'required|exists:empleados,id',
            'vehiculo_id' => 'nullable|exists:vehiculos,vehiculo_id',
            'descripcion' => 'required|string',
            'prioridad' => 'nullable|string',
            'pausar_actividad' => 'nullable|boolean',
            'foto' => 'nullable|image|max:5120',
        ]);

        return DB::transaction(function () use ($request, $mediaService) {
            // 1. Pausar programación actual si se solicita
            if ($request->boolean('pausar_actividad')) {
                Programacion::where('empleado_id', $request->empleado_id)
                    ->where('fecha', $request->fecha)
                    ->where('estado', 'pendiente')
                    ->update(['estado' => 'pausado']);
            }

            // 2. Registrar la Novedad en la tabla dedicada
            $novedad = Novedad::create([
                'fecha' => $request->fecha,
                'empleado_id' => $request->empleado_id,
                'vehiculo_id' => $request->vehiculo_id,
                'descripcion' => $request->descripcion,
                'prioridad' => $request->prioridad ?? 'Normal',
                'pausar_actividad' => $request->boolean('pausar_actividad'),
            ]);

            // 3. Crear Orden de Trabajo si hay vehículo
            $ot = null;
            if ($request->vehiculo_id) {
                $ot = OrdenTrabajo::create([
                    'vehiculo_id' => $request->vehiculo_id,
                    'mecanico_asignado_id' => null,
                    'fecha_inicio' => Carbon::now(),
                    'estado' => 'abierta',
                    'prioridad' => (strtoupper($request->prioridad ?? '') === 'URGENTE') ? 'alta' : 'media',
                    'descripcion' => "NOVEDAD (" . ($request->prioridad ?? 'NORMAL') . "): " . $request->descripcion,
                ]);

                $novedad->orden_trabajo_id = $ot->orden_trabajo_id;
                $novedad->save();
            }

            // 4. Si viene una foto, guardarla asociada a la novedad
            $media = null;
            if ($request->hasFile('foto')) {
                $media = $mediaService->storeUploadedFile(
                    $request->file('foto'),
                    module: 'programacion',
                    entityType: 'novedad',
                    entityId: $novedad->id,
                    userId: $request->user()?->id
                );
            }

            return response()->json([
                'message' => 'Novedad registrada exitosamente.',
                'novedad' => $novedad,
                'ot' => $ot,
                'media' => $media,
            ], 201);
        });
    }
}
