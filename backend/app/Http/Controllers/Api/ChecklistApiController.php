<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empleado;
use App\Models\ListaChequeo;
use App\Models\RespuestaListaChequeo;
use App\Models\Vehiculo;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ChecklistApiController extends Controller
{
    // Removed resolveOperadorUserId as we now strictly use empleado_id in payloads

    // Obtener listas de chequeo activas con sus items
    public function index(Request $request)
    {
        $query = ListaChequeo::with('items')->where('activo', true);

        if ($request->has('tipo_vehiculo')) {
            $query->where('tipo_vehiculo', $request->tipo_vehiculo);
        }

        $listas = $query->get();

        return response()->json($listas);
    }

    // Guardar una respuesta de lista de chequeo (preoperacional)
    public function store(Request $request)
    {
        $request->validate([
            'lista_chequeo_id' => 'required|exists:listas_chequeo,id',
            'vehiculo_id' => 'required|exists:vehiculos,vehiculo_id',
            'operador_id' => 'required|exists:empleados,id',
            'respuestas' => 'required|array', // { item_id: valor }
            'observaciones_generales' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request) {
            $operadorId = (int) $request->operador_id;

            $lista = ListaChequeo::with('items')->find($request->lista_chequeo_id);
            $estado = 'aprobado';
            
            // Validar respuestas críticas
            foreach ($lista->items as $item) {
                if ($item->es_critico && isset($request->respuestas[$item->id])) {
                    $respuesta = $request->respuestas[$item->id];
                    if ($respuesta === 'falla' || $respuesta === false || $respuesta === 0) {
                        $estado = 'rechazado';
                    }
                }
            }

            $respuesta = RespuestaListaChequeo::create([
                'lista_chequeo_id' => $request->lista_chequeo_id,
                'vehiculo_id' => $request->vehiculo_id,
                'operador_id' => $operadorId,
                'fecha' => Carbon::now(),
                'respuestas' => $request->respuestas,
                'estado' => $estado,
                'observaciones_generales' => $request->observaciones_generales,
            ]);

            return response()->json([
                'message' => 'Lista de chequeo guardada exitosamente',
                'data' => $respuesta,
                'estado_final' => $estado
            ], 201);
        });
    }

    // Obtener historial de respuestas (opcional, para consultas)
    public function history(Request $request) {
         $query = RespuestaListaChequeo::with(['listaChequeo', 'vehiculo', 'operador'])
                    ->orderBy('fecha', 'desc');

         if ($request->has('vehiculo_id')) {
             $query->where('vehiculo_id', $request->vehiculo_id);
         }
         
         return response()->json($query->paginate(20));
    }
}
