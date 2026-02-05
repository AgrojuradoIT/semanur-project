<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OrdenTrabajo;
use Illuminate\Http\Request;

class OrdenTrabajoApiController extends Controller
{
    public function index(Request $request)
    {
        // Si es un mecánico, solo ve sus órdenes asignadas. Si es admin, ve todas.
        $user = $request->user();
        $query = OrdenTrabajo::with(['vehiculo', 'mecanico', 'movimientos_inventario.producto', 'sesiones']);

        if ($user->email !== 'admin@semanur.com') {
            $query->where('mecanico_asignado_id', $user->id);
        }

        return response()->json($query->orderBy('fecha_inicio', 'desc')->get());
    }

    public function show($id)
    {
        $orden = OrdenTrabajo::with(['vehiculo', 'mecanico', 'movimientos_inventario.producto', 'sesiones.user'])->find($id);

        if (!$orden) {
            return response()->json(['message' => 'Orden de trabajo no encontrada'], 404);
        }

        return response()->json($orden);
    }

    public function store(Request $request)
    {
        $request->validate([
            'vehiculo_id' => 'required|exists:vehiculos,vehiculo_id',
            'prioridad' => 'required|in:Alta,Media,Baja',
            'descripcion' => 'required|string',
            'repuestos' => 'nullable|array',
            'repuestos.*.producto_id' => 'required_with:repuestos|exists:productos,producto_id',
            'repuestos.*.cantidad' => 'required_with:repuestos|numeric|min:1',
            'herramientas' => 'nullable|array',
            'herramientas.*.producto_id' => 'required_with:herramientas|exists:productos,producto_id',
            'foto_evidencia' => 'nullable|image|max:5120',
        ]);

        try {
            \Illuminate\Support\Facades\DB::beginTransaction();

            $fotoPath = null;
            if ($request->hasFile('foto_evidencia')) {
                $fotoPath = $request->file('foto_evidencia')->store('ordenes/fotos', 'public');
            }

            $orden = new OrdenTrabajo();
            $orden->vehiculo_id = $request->vehiculo_id;
            $orden->prioridad = $request->prioridad;
            $orden->descripcion = $request->descripcion;
            $orden->estado = 'Abierta';
            $orden->fecha_inicio = now();
            $orden->foto_evidencia = $fotoPath;
            $orden->save();

            // Procesar Repuestos (Salidas de Inventario)
            if ($request->has('repuestos')) {
                foreach ($request->repuestos as $repuesto) {
                    \App\Models\TransaccionInventario::create([
                        'producto_id' => $repuesto['producto_id'],
                        'tipo_transaccion' => 'salida',
                        'cantidad' => $repuesto['cantidad'],
                        'fecha_transaccion' => now(),
                        'transaccion_referencia_id' => $orden->orden_trabajo_id,
                        'transaccion_referencia_type' => 'App\Models\OrdenTrabajo',
                        'usuario_id' => $request->user()->id,
                        'notas' => "Repuesto para OT #{$orden->orden_trabajo_id}"
                    ]);
                    
                    // Descontar stock
                    $prod = \App\Models\Producto::find($repuesto['producto_id']);
                    $prod->decrement('producto_stock_actual', $repuesto['cantidad']);
                }
            }

            // Procesar Préstamos de Herramientas
            if ($request->has('herramientas')) {
                foreach ($request->herramientas as $tool) {
                    \App\Models\PrestamoHerramienta::create([
                        'producto_id' => $tool['producto_id'],
                        'usuario_id' => $request->user()->id, // Mecánico que la solicita/usa
                        'fecha_prestamo' => now(),
                        'estado' => 'prestado',
                        'observaciones' => "Herramienta usada en OT #{$orden->orden_trabajo_id}"
                    ]);
                    
                    // Si el préstamo descuenta stock global o no, depende de la lógica de negocio.
                    // Generalmente herramientas son activos fijos, pero marcaremos 1 como "en uso".
                    // Asumiremos que PrestamoHerramienta maneja su propia lógica o no afecta stock numérico directo si son activos únicos.
                    // Pero para consistencia con el sistema actual:
                     $prod = \App\Models\Producto::find($tool['producto_id']);
                     if($prod->producto_stock_actual > 0) {
                         $prod->decrement('producto_stock_actual', 1);
                     }
                }
            }

            \Illuminate\Support\Facades\DB::commit();

            return response()->json([
                'message' => 'Orden de trabajo creada correctamente con items asociados',
                'orden' => $orden->load(['vehiculo', 'movimientos_inventario.producto'])
            ], 201);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            return response()->json(['message' => 'Error al crear la orden: ' . $e->getMessage()], 500);
        }
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'estado' => 'required|in:Abierta,En Progreso,Cerrada',
        ]);

        $orden = OrdenTrabajo::find($id);

        if (!$orden) {
            return response()->json(['message' => 'Orden de trabajo no encontrada'], 404);
        }

        $orden->estado = $request->estado;
        
        if ($request->estado === 'Cerrada') {
            $orden->fecha_fin = now();
        }

        $orden->save();

        return response()->json([
            'message' => 'Estado actualizado correctamente',
            'orden' => $orden
        ]);
    }
}
