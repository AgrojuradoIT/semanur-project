<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Producto;
use Illuminate\Http\Request;

class ProductoApiController extends Controller
{
    public function index()
    {
        $productos = Producto::with('categoria')->get();
        return response()->json($productos);
    }

    public function show($id)
    {
        $producto = Producto::with('categoria')->find($id);
        
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }

        return response()->json($producto);
    }

    public function search(Request $request)
    {
        $query = $request->get('q');
        $productos = Producto::with('categoria')
            ->where('producto_nombre', 'LIKE', "%{$query}%")
            ->orWhere('producto_sku', 'LIKE', "%{$query}%")
            ->get();

        return response()->json($productos);
    }
}
