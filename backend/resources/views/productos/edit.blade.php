@extends('layouts.app')

@section('content')
<div class="py-12">
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
            <div class="p-6 text-gray-900">
                <h1 class="text-2xl font-bold mb-4">Editar Producto</h1>
                <form method="POST" action="{{ route('productos.update', $producto) }}">
                    @csrf
                    @method('PUT')
                    <div class="mb-4">
                        <label for="categoria_id" class="block text-sm font-medium text-gray-700">Categoría</label>
                        <select name="categoria_id" id="categoria_id" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                            <option value="">Seleccionar Categoría</option>
                            @foreach($categorias as $categoria)
                                <option value="{{ $categoria->categoria_id }}" {{ old('categoria_id', $producto->categoria_id) == $categoria->categoria_id ? 'selected' : '' }}>
                                    {{ $categoria->categoria_nombre }}
                                </option>
                            @endforeach
                        </select>
                        @error('categoria_id')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="producto_sku" class="block text-sm font-medium text-gray-700">SKU</label>
                        <input type="text" name="producto_sku" id="producto_sku" value="{{ old('producto_sku', $producto->producto_sku) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                        @error('producto_sku')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="producto_nombre" class="block text-sm font-medium text-gray-700">Nombre</label>
                        <input type="text" name="producto_nombre" id="producto_nombre" value="{{ old('producto_nombre', $producto->producto_nombre) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                        @error('producto_nombre')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="producto_unidad_medida" class="block text-sm font-medium text-gray-700">Unidad de Medida</label>
                        <input type="text" name="producto_unidad_medida" id="producto_unidad_medida" value="{{ old('producto_unidad_medida', $producto->producto_unidad_medida) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                        @error('producto_unidad_medida')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="producto_stock_actual" class="block text-sm font-medium text-gray-700">Stock Actual</label>
                        <input type="number" name="producto_stock_actual" id="producto_stock_actual" value="{{ old('producto_stock_actual', $producto->producto_stock_actual) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" step="0.01">
                        @error('producto_stock_actual')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="producto_alerta_stock_minimo" class="block text-sm font-medium text-gray-700">Alerta Stock Mínimo</label>
                        <input type="number" name="producto_alerta_stock_minimo" id="producto_alerta_stock_minimo" value="{{ old('producto_alerta_stock_minimo', $producto->producto_alerta_stock_minimo) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" step="0.01">
                        @error('producto_alerta_stock_minimo')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="producto_precio_costo" class="block text-sm font-medium text-gray-700">Precio Costo</label>
                        <input type="number" name="producto_precio_costo" id="producto_precio_costo" value="{{ old('producto_precio_costo', $producto->producto_precio_costo) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" step="0.01" required>
                        @error('producto_precio_costo')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="producto_ubicacion" class="block text-sm font-medium text-gray-700">Ubicación</label>
                        <input type="text" name="producto_ubicacion" id="producto_ubicacion" value="{{ old('producto_ubicacion', $producto->producto_ubicacion) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">
                        @error('producto_ubicacion')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Actualizar</button>
                    <a href="{{ route('productos.index') }}" class="ml-2 bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">Cancelar</a>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection