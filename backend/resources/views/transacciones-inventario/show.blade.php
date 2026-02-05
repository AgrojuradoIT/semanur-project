@extends('layouts.app')

@section('content')
<div class="py-12">
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
            <div class="p-6 text-gray-900">
                <h1 class="text-2xl font-bold mb-4">Detalles de Transacción de Inventario</h1>
                <div class="mb-4">
                    <strong>ID:</strong> {{ $transaccion->transaccion_id }}
                </div>
                <div class="mb-4">
                    <strong>Producto:</strong> {{ $transaccion->producto->producto_sku }} - {{ $transaccion->producto->producto_nombre }}
                </div>
                <div class="mb-4">
                    <strong>Usuario:</strong> {{ $transaccion->usuario->name }}
                </div>
                <div class="mb-4">
                    <strong>Tipo de Transacción:</strong> {{ ucfirst($transaccion->transaccion_tipo) }}
                </div>
                <div class="mb-4">
                    <strong>Cantidad:</strong> {{ $transaccion->transaccion_cantidad }}
                </div>
                <div class="mb-4">
                    <strong>Motivo:</strong> {{ $transaccion->transaccion_motivo ?: 'N/A' }}
                </div>
                <div class="mb-4">
                    <strong>Tipo de Referencia:</strong> {{ $transaccion->transaccion_referencia_type ?: 'N/A' }}
                </div>
                <div class="mb-4">
                    <strong>ID de Referencia:</strong> {{ $transaccion->transaccion_referencia_id ?: 'N/A' }}
                </div>
                <div class="mb-4">
                    <strong>Notas:</strong> {{ $transaccion->transaccion_notas ?: 'N/A' }}
                </div>
                <div class="mb-4">
                    <strong>Fecha de Creación:</strong> {{ $transaccion->created_at->format('d/m/Y H:i') }}
                </div>
                <div class="mb-4">
                    <strong>Última Actualización:</strong> {{ $transaccion->updated_at->format('d/m/Y H:i') }}
                </div>
                <a href="{{ route('transacciones-inventario.index') }}" class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">Volver</a>
                <a href="{{ route('transacciones-inventario.edit', $transaccion->transaccion_id) }}" class="ml-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Editar</a>
                <form method="POST" action="{{ route('transacciones-inventario.destroy', $transaccion->transaccion_id) }}" class="inline">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="ml-2 bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded" onclick="return confirm('¿Estás seguro de que quieres eliminar esta transacción?')">Eliminar</button>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection