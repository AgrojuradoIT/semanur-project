@extends('layouts.app')

@section('content')
<div class="py-12">
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
            <div class="p-6 text-gray-900">
                <h1 class="text-2xl font-bold mb-4">Detalles del Vehículo</h1>
                <div class="mb-4">
                    <strong>Placa:</strong> {{ $vehiculo->placa }}
                </div>
                <div class="mb-4">
                    <strong>Tipo:</strong> {{ $vehiculo->tipo }}
                </div>
                <div class="mb-4">
                    <strong>Marca:</strong> {{ $vehiculo->marca }}
                </div>
                <div class="mb-4">
                    <strong>Modelo:</strong> {{ $vehiculo->modelo }}
                </div>
                <a href="{{ route('vehiculos.index') }}" class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">Volver</a>
                <a href="{{ route('vehiculos.edit', $vehiculo) }}" class="ml-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Editar</a>
            </div>
        </div>
    </div>
</div>
@endsection