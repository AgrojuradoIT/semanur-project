<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PrestamoHerramienta;
use App\Models\Producto;
use App\Models\TransaccionInventario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class PrestamoApiController extends Controller
{
    public function index(Request $request)
    {
        $query = PrestamoHerramienta::with(['producto', 'mecanico', 'admin'])
            ->orderBy('fecha_prestamo', 'desc');

        if ($request->has('estado')) {
            $query->where('estado', $request->estado);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'producto_id' => 'required|exists:productos,producto_id',
            'mecanico_id' => 'required|exists:users,id',
            'prestamo_cantidad' => 'required|numeric|min:0.01',
            'notas' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request) {
            $producto = Producto::find($request->producto_id);

            if ($producto->producto_stock_actual < $request->prestamo_cantidad) {
                return response()->json(['message' => 'Stock insuficiente para el préstamo'], 422);
            }

            // Crear el préstamo
            $prestamo = PrestamoHerramienta::create([
                'producto_id' => $request->producto_id,
                'mecanico_id' => $request->mecanico_id,
                'admin_id' => $request->user()->id,
                'prestamo_cantidad' => $request->prestamo_cantidad,
                'fecha_prestamo' => Carbon::now(),
                'estado' => 'prestado',
                'notas' => $request->notas,
            ]);

            // Registrar salida en inventario
            TransaccionInventario::create([
                'producto_id' => $request->producto_id,
                'usuario_id' => $request->user()->id,
                'transaccion_tipo' => 'salida',
                'transaccion_cantidad' => $request->prestamo_cantidad,
                'transaccion_motivo' => 'Préstamo de Herramienta',
                'transaccion_referencia_id' => $prestamo->prestamo_id,
                'transaccion_referencia_type' => 'PrestamoHerramienta',
                'transaccion_notas' => "Préstamo ID: {$prestamo->prestamo_id} a usuario ID: {$request->mecanico_id}",
            ]);

            // Descontar stock
            $producto->producto_stock_actual -= $request->prestamo_cantidad;
            $producto->save();

            return response()->json([
                'message' => 'Préstamo registrado correctamente',
                'prestamo' => $prestamo,
                'nuevo_stock' => $producto->producto_stock_actual
            ]);
        });
    }

    public function devolver(Request $request, $id)
    {
        $request->validate([
            'estado' => 'required|in:devuelto,dañado,perdido',
            'notas' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request, $id) {
            $prestamo = PrestamoHerramienta::findOrFail($id);

            if ($prestamo->estado !== 'prestado') {
                return response()->json(['message' => 'Este préstamo ya fue procesado'], 422);
            }

            $prestamo->estado = $request->estado;
            $prestamo->fecha_devolucion = Carbon::now();
            $prestamo->notas = $request->notas ?? $prestamo->notas;
            $prestamo->save();

            // Si se devuelve, el stock regresa. Si se pierde/daña, el stock ya salió cuando se prestó.
            if ($request->estado === 'devuelto') {
                $producto = Producto::find($prestamo->producto_id);
                
                // Registrar ingreso en inventario
                TransaccionInventario::create([
                    'producto_id' => $prestamo->producto_id,
                    'usuario_id' => $request->user()->id,
                    'transaccion_tipo' => 'ingreso',
                    'transaccion_cantidad' => $prestamo->prestamo_cantidad,
                    'transaccion_motivo' => 'Devolución de Herramienta',
                    'transaccion_referencia_id' => $prestamo->prestamo_id,
                    'transaccion_referencia_type' => 'PrestamoHerramienta',
                ]);

                $producto->producto_stock_actual += $prestamo->prestamo_cantidad;
                $producto->save();
            }

            return response()->json([
                'message' => 'Devolución procesada correctamente',
                'prestamo' => $prestamo
            ]);
        });
    }
}
