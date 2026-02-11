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
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
            'skip_duplicates' => 'boolean',
        ]);

        $file = $request->file('file');
        $skipDuplicates = $request->boolean('skip_duplicates');

        $handle = fopen($file->getPathname(), "r");
        $header = fgetcsv($handle, 1000, ","); // Assuming header: codigo, nombre

        $newProducts = [];
        $duplicates = [];
        $errors = [];
        $rowNumber = 1;

        while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
            $rowNumber++;
            // Simple mapping: 0 -> codigo (sku), 1 -> nombre
            if (count($data) < 2) {
                $errors[] = "Fila $rowNumber: Datos incompletos.";
                continue;
            }

            $sku = trim($data[0]);
            $nombre = trim($data[1]);

            if (empty($sku) || empty($nombre)) {
                $errors[] = "Fila $rowNumber: Código o nombre vacíos.";
                continue;
            }

            // Check duplicate in DB
            $exists = Producto::where('producto_sku', $sku)->exists();

            if ($exists) {
                $duplicates[] = ['codigo' => $sku, 'nombre' => $nombre];
            } else {
                $newProducts[] = [
                    'producto_sku' => $sku,
                    'producto_nombre' => $nombre,
                    'stock_actual' => 0, // Default
                    'precio_costo' => 0, // Default
                    // 'categoria_id' => null, // Default
                ];
            }
        }
        fclose($handle);

        if (!$skipDuplicates && count($duplicates) > 0) {
            return response()->json([
                'message' => 'Se encontraron duplicados.',
                'duplicates' => $duplicates,
                'new_count' => count($newProducts),
                'requires_confirmation' => true
            ], 409);
        }

        // Insert new products
        $insertedValid = 0;
        foreach ($newProducts as $prodData) {
            try {
                Producto::create($prodData);
                $insertedValid++;
            } catch (\Exception $e) {
                $errors[] = "Error insertando {$prodData['producto_sku']}: " . $e->getMessage();
            }
        }

        return response()->json([
            'message' => 'Importación completada.',
            'inserted_count' => $insertedValid,
            'skipped_count' => count($duplicates),
            'errors' => $errors,
        ]);
    }
}
