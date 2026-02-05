@extends('layouts.app')

@section('content')
<div class="py-12">
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
            <div class="p-6 text-gray-900">
                <h1 class="text-2xl font-bold mb-4">Detalles del Producto</h1>
                <div class="mb-4">
                    <strong>SKU:</strong> {{ $producto->producto_sku }}
                </div>
                <div class="mb-4">
                    <strong>Nombre:</strong> {{ $producto->producto_nombre }}
                </div>
                <div class="mb-4">
                    <strong>Categoría:</strong> {{ $producto->categoria ? $producto->categoria->categoria_nombre : 'N/A' }}
                </div>
                <div class="mb-4">
                    <strong>Unidad de Medida:</strong> {{ $producto->producto_unidad_medida }}
                </div>
                <div class="mb-4">
                    <strong>Stock Actual:</strong> {{ $producto->producto_stock_actual }}
                </div>
                <div class="mb-4">
                    <strong>Alerta Stock Mínimo:</strong> {{ $producto->producto_alerta_stock_minimo }}
                </div>
                <div class="mb-4">
                    <strong>Precio Costo:</strong> ${{ number_format($producto->producto_precio_costo, 2) }}
                </div>
                <div class="mb-4">
                    <strong>Ubicación:</strong> {{ $producto->producto_ubicacion }}
                </div>
                <a href="{{ route('productos.index') }}" class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">Volver</a>
                <a href="{{ route('productos.edit', $producto) }}" class="ml-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Editar</a>
            </div>
        </div>
    </div>
</div>
@endsection