<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChecklistPreoperacional;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class ChecklistApiController extends Controller
{
    public function index(Request $request)
    {
        $query = ChecklistPreoperacional::with(['vehiculo', 'usuario'])
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
            'horometro_actual' => 'nullable|numeric',
            'checklist_data' => 'required', // Can be stringified JSON or array
            'estado' => 'required|in:aprobado,rechazado,pendiente',
            'observaciones' => 'nullable|string',
            'foto_evidencia' => 'nullable|image|max:5120', // Max 5MB
        ]);

        try {
            $fotoPath = null;
            if ($request->hasFile('foto_evidencia')) {
                $fotoPath = $request->file('foto_evidencia')->store('checklists/fotos', 'public');
            }

            // If checklist_data is sent as string (Multipart Form-Data)
            $checklistData = $request->checklist_data;
            if (is_string($checklistData)) {
                $checklistData = json_decode($checklistData, true);
            }

            $checklist = ChecklistPreoperacional::create([
                'vehiculo_id' => $request->vehiculo_id,
                'usuario_id' => $request->user()->id,
                'fecha' => Carbon::now(),
                'horometro_actual' => $request->horometro_actual,
                'checklist_data' => $checklistData,
                'estado' => $request->estado,
                'observaciones' => $request->observaciones,
                'foto_evidencia' => $fotoPath,
            ]);

            return response()->json([
                'message' => 'Checklist registrado correctamente',
                'checklist' => $checklist
            ], 201);
        } catch (\Exception $e) {
            Log::error('Error creating checklist: ' . $e->getMessage());
            return response()->json(['message' => 'Error al registrar checklist'], 500);
        }
    }
}
