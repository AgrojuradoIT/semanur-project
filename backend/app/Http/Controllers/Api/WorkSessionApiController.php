<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WorkSession;
use Illuminate\Http\Request;
use Carbon\Carbon;

class WorkSessionApiController extends Controller
{
    public function start(Request $request)
    {
        $request->validate([
            'orden_trabajo_id' => 'required|exists:orden_trabajos,orden_trabajo_id',
        ]);

        $userId = $request->user()->id;

        // Verificar si ya tiene una sesión activa
        $activeSession = WorkSession::where('user_id', $userId)
            ->whereNull('fecha_fin')
            ->first();

        if ($activeSession) {
            return response()->json([
                'message' => 'Ya tienes una sesión activa en la orden #' . $activeSession->orden_trabajo_id,
                'session' => $activeSession
            ], 400);
        }

        $session = WorkSession::create([
            'user_id' => $userId,
            'orden_trabajo_id' => $request->orden_trabajo_id,
            'fecha_inicio' => Carbon::now(),
        ]);

        return response()->json([
            'message' => 'Sesión iniciada correctamente',
            'session' => $session
        ], 201);
    }

    public function stop(Request $request, $id)
    {
        $session = WorkSession::findOrFail($id);

        if ($session->fecha_fin) {
            return response()->json(['message' => 'La sesión ya está finalizada'], 400);
        }

        $session->update([
            'fecha_fin' => Carbon::now(),
            'notas' => $request->notas,
        ]);

        return response()->json([
            'message' => 'Sesión finalizada correctamente',
            'session' => $session
        ]);
    }

    public function activeSession(Request $request)
    {
        $session = WorkSession::where('user_id', $request->user()->id)
            ->whereNull('fecha_fin')
            ->with('ordenTrabajo.vehiculo')
            ->first();

        return response()->json($session);
    }
}
