<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Empleado;
use App\Models\OrdenTrabajo;
use App\Models\PrestamoHerramienta;
use App\Models\Producto;
use App\Models\TransaccionInventario;
use App\Models\User;
use App\Services\MediaService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class OrdenTrabajoApiController extends Controller
{
    private function isAdmin($user): bool
    {
        return strtolower((string) $user->role) === 'admin';
    }

    private function getEmpleadoIdForUser(int $userId): ?int
    {
        return Empleado::where('user_id', $userId)->value('id');
    }

    private function canAccessOrden(User $user, OrdenTrabajo $orden): bool
    {
        if ($this->isAdmin($user)) {
            return true;
        }

        $assignedId = (int) $orden->mecanico_asignado_id;

        $empleadoId = $this->getEmpleadoIdForUser((int) $user->id);
        return $empleadoId !== null && $assignedId === $empleadoId;
    }

    public function index(Request $request)
    {
        // Si es un mecanico, solo ve sus ordenes asignadas. Si es admin, ve todas.
        $user = $request->user();
        $query = OrdenTrabajo::with(['vehiculo', 'mecanico', 'movimientos_inventario.producto', 'sesiones']);

        if (!$this->isAdmin($user)) {
            $ids = [(int) $user->id];
            $empleadoId = $this->getEmpleadoIdForUser((int) $user->id);
            if ($empleadoId !== null) {
                $ids[] = $empleadoId;
            }

            $query->whereIn('mecanico_asignado_id', $ids);
        }

        return response()->json($query->orderBy('fecha_inicio', 'desc')->get());
    }

    public function show(Request $request, $id)
    {
        $user = $request->user();
        // Cargar orden con todas las relaciones incluyendo sesiones
        $orden = OrdenTrabajo::with([
            'vehiculo',
            'mecanico',
            'movimientos_inventario.producto',
            'sesiones.user',
            'sesiones.empleado'
        ])->find($id);

        if (!$orden) {
            return response()->json(['message' => 'Orden de trabajo no encontrada'], 404);
        }

        if (!$this->canAccessOrden($user, $orden)) {
            return response()->json(['message' => 'No autorizado para ver esta orden'], 403);
        }

        // Debug: Log para verificar sesiones
        \Log::info('OrdenTrabajo show: ID=' . $id . ', Sesiones count=' . $orden->sesiones->count());

        return response()->json($orden);
    }

    public function store(Request $request, MediaService $mediaService)
    {
        $request->validate([
            'vehiculo_id' => 'required|exists:vehiculos,vehiculo_id',
            'mecanico_asignado_id' => 'nullable|integer',
            'prioridad' => 'required|in:Alta,Media,Baja',
            'descripcion' => 'required|string',
            'repuestos' => 'nullable|array',
            'repuestos.*.producto_id' => 'required_with:repuestos|exists:productos,producto_id',
            'repuestos.*.cantidad' => 'required_with:repuestos|numeric|min:1',
            'herramientas' => 'nullable|array',
            'herramientas.*.producto_id' => 'required_with:herramientas|exists:productos,producto_id',
            'herramientas.*.cantidad' => 'nullable|numeric|min:1',
            'foto_evidencia' => 'nullable|image|max:5120',
        ]);

        try {
            DB::beginTransaction();
            // Resuelve mecanico: el frontend puede enviar empleado_id o user_id
            // Fase 1: mecanicos no tienen usuario → se guarda null
            // Fase 2: cuando tengan cuenta → se usa su user_id automáticamente
            $mecanicoAsignadoId = null;
            if ($request->mecanico_asignado_id) {
                $inputId = (int) $request->mecanico_asignado_id;
                // Primero buscar si es un empleado_id
                $empleado = Empleado::find($inputId);
                if ($empleado) {
                    $mecanicoAsignadoId = $empleado->user_id; // puede ser null
                } else {
                    // Si no es empleado, podría ser un user_id directo (Flutter)
                    $mecanicoAsignadoId = User::find($inputId) ? $inputId : null;
                }
            }

            // 1. Crear la orden de trabajo base (sin foto aun)
            $orden = new OrdenTrabajo();
            $orden->vehiculo_id = $request->vehiculo_id;
            $orden->mecanico_asignado_id = $mecanicoAsignadoId;
            $orden->prioridad = $request->prioridad;
            $orden->descripcion = $request->descripcion;
            $orden->estado = 'Abierta';
            
            // Usar fecha y hora actual de Bogotá - now() ya está configurado en America/Bogota
            // Importante: Asignar DESPUES de setear los otros campos y ANTES del save()
            $currentDateTime = now();
            \Log::info('Creando OT - Fecha actual: ' . $currentDateTime->toIso8601String());
            
            $orden->fecha_inicio = $currentDateTime;
            $orden->save();
            
            \Log::info('OT Creada - ID: ' . $orden->orden_trabajo_id . ' - Fecha guardada: ' . $orden->fecha_inicio->toIso8601String());

            // 2. Procesar repuestos (salidas de inventario)
            if ($request->has('repuestos')) {
                foreach ($request->repuestos as $repuesto) {
                    $cantidad = (float) $repuesto['cantidad'];
                    $producto = Producto::lockForUpdate()->find($repuesto['producto_id']);

                    if (!$producto || $producto->producto_stock_actual < $cantidad) {
                        throw ValidationException::withMessages([
                            'repuestos' => ["Stock insuficiente para el producto ID {$repuesto['producto_id']}"],
                        ]);
                    }

                    TransaccionInventario::create([
                        'producto_id' => $repuesto['producto_id'],
                        'usuario_id' => $request->user()->id,
                        'transaccion_tipo' => 'salida',
                        'transaccion_cantidad' => $cantidad,
                        'transaccion_motivo' => 'Repuesto para Orden de Trabajo',
                        'transaccion_referencia_id' => $orden->orden_trabajo_id,
                        'transaccion_referencia_type' => 'OrdenTrabajo',
                        'transaccion_notas' => "Repuesto para OT #{$orden->orden_trabajo_id}",
                    ]);
                }
            }

            // 3. Procesar prestamos de herramientas
            if ($request->has('herramientas')) {
                foreach ($request->herramientas as $tool) {
                    $cantidad = isset($tool['cantidad']) ? (float) $tool['cantidad'] : 1.0;
                    $producto = Producto::lockForUpdate()->find($tool['producto_id']);
                    $mecanicoPrestamoId = $orden->mecanico_asignado_id ?: $this->getEmpleadoIdForUser((int) $request->user()->id);

                    if (!$producto || $producto->producto_stock_actual < $cantidad) {
                        throw ValidationException::withMessages([
                            'herramientas' => ["Stock insuficiente para herramienta ID {$tool['producto_id']}"],
                        ]);
                    }

                    $prestamo = PrestamoHerramienta::create([
                        'producto_id' => $tool['producto_id'],
                        'mecanico_id' => $mecanicoPrestamoId,
                        'admin_id' => $request->user()->id,
                        'prestamo_cantidad' => $cantidad,
                        'fecha_prestamo' => now(),
                        'estado' => 'prestado',
                        'notas' => "Herramienta usada en OT #{$orden->orden_trabajo_id}",
                    ]);

                    TransaccionInventario::create([
                        'producto_id' => $tool['producto_id'],
                        'usuario_id' => $request->user()->id,
                        'transaccion_tipo' => 'salida',
                        'transaccion_cantidad' => $cantidad,
                        'transaccion_motivo' => 'Prestamo de herramienta para OT',
                        'transaccion_referencia_id' => $prestamo->prestamo_id,
                        'transaccion_referencia_type' => 'PrestamoHerramienta',
                        'transaccion_notas' => "Prestamo #{$prestamo->prestamo_id} asociado a OT #{$orden->orden_trabajo_id}",
                    ]);
                }
            }

            // 4. Procesar foto de evidencia con el sistema de media
            if ($request->hasFile('foto_evidencia')) {
                $media = $mediaService->storeUploadedFile(
                    $request->file('foto_evidencia'),
                    module: 'taller',
                    entityType: 'orden_trabajo',
                    entityId: $orden->orden_trabajo_id,
                    userId: $request->user()->id
                );

                // Mantener compatibilidad con el campo existente en la tabla
                $orden->foto_evidencia = $media->path;
                $orden->save();
            }

            DB::commit();

            return response()->json([
                'message' => 'Orden de trabajo creada correctamente con items asociados',
                'orden' => $orden->load(['vehiculo', 'movimientos_inventario.producto'])
            ], 201);
        } catch (ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Error de validacion al crear la orden',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al crear la orden: ' . $e->getMessage()], 500);
        }
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'estado' => 'required|in:Abierta,En Progreso,Cerrada',
        ]);

        $user = $request->user();
        $orden = OrdenTrabajo::find($id);

        if (!$orden) {
            return response()->json(['message' => 'Orden de trabajo no encontrada'], 404);
        }

        if (!$this->canAccessOrden($user, $orden)) {
            return response()->json(['message' => 'No autorizado para actualizar esta orden'], 403);
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

    public function destroy(Request $request, $id)
    {
        $user = $request->user();

        if (!$this->isAdmin($user)) {
            return response()->json(['message' => 'No autorizado para eliminar órdenes de trabajo'], 403);
        }

        return DB::transaction(function () use ($id) {
            $orden = OrdenTrabajo::find($id);

            if (!$orden) {
                return response()->json(['message' => 'Orden de trabajo no encontrada'], 404);
            }

            if (in_array($orden->estado, ['Abierta', 'En Progreso'])) {
                return response()->json([
                    'message' => 'No se puede eliminar: la orden de trabajo está activa',
                ], 409);
            }

            $orden->sesiones()->delete();
            $orden->movimientos_inventario()->delete();
            $orden->delete();

            return response()->json(['message' => 'Orden de trabajo eliminada correctamente']);
        });
    }
}
