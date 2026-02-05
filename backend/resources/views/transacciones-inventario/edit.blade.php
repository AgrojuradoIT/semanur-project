@extends('layouts.app')

@section('content')
<div class="py-12">
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
            <div class="p-6 text-gray-900">
                <h1 class="text-2xl font-bold mb-4">Editar Transacción de Inventario</h1>
                <form method="POST" action="{{ route('transacciones-inventario.update', $transaccion->transaccion_id) }}">
                    @csrf
                    @method('PUT')
                    <div class="mb-4">
                        <label for="producto_id" class="block text-sm font-medium text-gray-700">Producto</label>
                        <select name="producto_id" id="producto_id" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                            <option value="">Seleccionar Producto</option>
                            @foreach($productos as $producto)
                                <option value="{{ $producto->producto_id }}" {{ old('producto_id', $transaccion->producto_id) == $producto->producto_id ? 'selected' : '' }}>
                                    {{ $producto->producto_sku }} - {{ $producto->producto_nombre }}
                                </option>
                            @endforeach
                        </select>
                        @error('producto_id')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="usuario_id" class="block text-sm font-medium text-gray-700">Usuario</label>
                        <select name="usuario_id" id="usuario_id" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                            <option value="">Seleccionar Usuario</option>
                            @foreach($usuarios as $usuario)
                                <option value="{{ $usuario->id }}" {{ old('usuario_id', $transaccion->usuario_id) == $usuario->id ? 'selected' : '' }}>
                                    {{ $usuario->name }}
                                </option>
                            @endforeach
                        </select>
                        @error('usuario_id')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="transaccion_tipo" class="block text-sm font-medium text-gray-700">Tipo de Transacción</label>
                        <select name="transaccion_tipo" id="transaccion_tipo" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                            <option value="">Seleccionar Tipo</option>
                            <option value="entrada" {{ old('transaccion_tipo', $transaccion->transaccion_tipo) == 'entrada' ? 'selected' : '' }}>Entrada</option>
                            <option value="salida" {{ old('transaccion_tipo', $transaccion->transaccion_tipo) == 'salida' ? 'selected' : '' }}>Salida</option>
                            <option value="ajuste" {{ old('transaccion_tipo', $transaccion->transaccion_tipo) == 'ajuste' ? 'selected' : '' }}>Ajuste</option>
                        </select>
                        @error('transaccion_tipo')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="transaccion_cantidad" class="block text-sm font-medium text-gray-700">Cantidad</label>
                        <input type="number" name="transaccion_cantidad" id="transaccion_cantidad" value="{{ old('transaccion_cantidad', $transaccion->transaccion_cantidad) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" step="0.01" min="0.01" required>
                        @error('transaccion_cantidad')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="transaccion_motivo" class="block text-sm font-medium text-gray-700">Motivo</label>
                        <input type="text" name="transaccion_motivo" id="transaccion_motivo" value="{{ old('transaccion_motivo', $transaccion->transaccion_motivo) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">
                        @error('transaccion_motivo')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="transaccion_referencia_type" class="block text-sm font-medium text-gray-700">Tipo de Referencia</label>
                        <input type="text" name="transaccion_referencia_type" id="transaccion_referencia_type" value="{{ old('transaccion_referencia_type', $transaccion->transaccion_referencia_type) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">
                        @error('transaccion_referencia_type')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="transaccion_referencia_id" class="block text-sm font-medium text-gray-700">ID de Referencia</label>
                        <input type="number" name="transaccion_referencia_id" id="transaccion_referencia_id" value="{{ old('transaccion_referencia_id', $transaccion->transaccion_referencia_id) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">
                        @error('transaccion_referencia_id')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="transaccion_notas" class="block text-sm font-medium text-gray-700">Notas</label>
                        <textarea name="transaccion_notas" id="transaccion_notas" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">{{ old('transaccion_notas', $transaccion->transaccion_notas) }}</textarea>
                        @error('transaccion_notas')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Actualizar</button>
                    <a href="{{ route('transacciones-inventario.index') }}" class="ml-2 bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">Cancelar</a>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection