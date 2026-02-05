<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RegistroCombustible;
use App\Models\TransaccionInventario;
use App\Models\Vehiculo;
use App\Models\OrdenTrabajo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AnalyticsApiController extends Controller
{
    public function getSummary()
    {
        $totalFuel = RegistroCombustible::sum('valor_total');
        
        // Costo de repuestos (salidas de inventario vinculadas a OT)
        $totalMaintenance = DB::table('transaccion_inventarios')
            ->join('productos', 'transaccion_inventarios.producto_id', '=', 'productos.producto_id')
            ->where('transaccion_referencia_type', 'like', '%OrdenTrabajo%')
            ->select(DB::raw('SUM(transaccion_cantidad * producto_precio_costo) as total'))
            ->first()->total ?? 0;

        return response()->json([
            'total_fuel_cost' => (float)$totalFuel,
            'total_maintenance_cost' => (float)$totalMaintenance,
            'vehicle_count' => Vehiculo::count(),
            'open_orders' => OrdenTrabajo::where('estado', '!=', 'Cerrada')->count(),
        ]);
    }

    public function getFuelMonthly()
    {
        $stats = RegistroCombustible::select(
            DB::raw('MONTH(fecha) as month'),
            DB::raw('YEAR(fecha) as year'),
            DB::raw('SUM(cantidad_galones) as gallons'),
            DB::raw('SUM(valor_total) as cost')
        )
        ->where('fecha', '>=', Carbon::now()->subMonths(6))
        ->groupBy('year', 'month')
        ->orderBy('year', 'asc')
        ->orderBy('month', 'asc')
        ->get();

        return response()->json($stats);
    }

    public function getMaintenanceByVehicle()
    {
        $stats = DB::table('transaccion_inventarios')
            ->join('productos', 'transaccion_inventarios.producto_id', '=', 'productos.producto_id')
            ->join('orden_trabajos', 'transaccion_inventarios.transaccion_referencia_id', '=', 'orden_trabajos.orden_trabajo_id')
            ->join('vehiculos', 'orden_trabajos.vehiculo_id', '=', 'vehiculos.vehiculo_id')
            ->where('transaccion_referencia_type', 'like', '%OrdenTrabajo%')
            ->select(
                'vehiculos.placa',
                DB::raw('SUM(transaccion_cantidad * producto_precio_costo) as total_cost')
            )
            ->groupBy('vehiculos.placa')
            ->orderBy('total_cost', 'desc')
            ->take(5)
            ->get();

        return response()->json($stats);
    }
}
