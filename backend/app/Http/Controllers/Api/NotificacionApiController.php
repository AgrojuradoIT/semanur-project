<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notificacion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificacionApiController extends Controller
{
    /**
     * Listar notificaciones del usuario autenticado
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['error' => 'No autorizado'], 401);
        }

        $query = Notificacion::where('user_id', $user->id);

        // Filtro por no leídas
        if ($request->has('unread_only')) {
            $query->whereNull('fecha_leido');
        }

        $notificaciones = $query->orderBy('created_at', 'desc')
            ->limit(50)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $notificaciones
        ]);
    }

    /**
     * Marcar notificación como leída
     */
    public function markAsRead($id)
    {
        $user = Auth::user();
        $notificacion = Notificacion::where('user_id', $user->id)
            ->where('id', $id)
            ->first();

        if (!$notificacion) {
            return response()->json(['error' => 'Notificacion no encontrada'], 404);
        }

        $notificacion->update([
            'fecha_leido' => now()
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Notificacion marcada como leida'
        ]);
    }

    /**
     * Marcar todas como leídas
     */
    public function markAllAsRead()
    {
        $user = Auth::user();
        Notificacion::where('user_id', $user->id)
            ->whereNull('fecha_leido')
            ->update(['fecha_leido' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'Todas las notificaciones marcadas como leidas'
        ]);
    }
}
