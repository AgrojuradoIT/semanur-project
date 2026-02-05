@extends('layouts.app')

@section('content')
<div class="py-12">
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
            <div class="p-6 text-gray-900">
                <h1 class="text-2xl font-bold mb-4">Detalles de la Orden de Trabajo</h1>
                <div class="mb-4">
                    <strong>Vehículo:</strong> {{ $ordenTrabajo->vehiculo ? $ordenTrabajo->vehiculo->placa . ' - ' . $ordenTrabajo->vehiculo->marca . ' ' . $ordenTrabajo->vehiculo->modelo : 'N/A' }}
                </div>
                <div class="mb-4">
                    <strong>Mecánico Asignado:</strong> {{ $ordenTrabajo->mecanico ? $ordenTrabajo->mecanico->name : 'N/A' }}
                </div>
                <div class="mb-4">
                    <strong>Fecha Inicio:</strong> {{ $ordenTrabajo->fecha_inicio }}
                </div>
                <div class="mb-4">
                    <strong>Fecha Fin:</strong> {{ $ordenTrabajo->fecha_fin ?: 'No definida' }}
                </div>
                <div class="mb-4">
                    <strong>Estado:</strong> {{ $ordenTrabajo->estado }}
                </div>
                <div class="mb-4">
                    <strong>Prioridad:</strong> {{ $ordenTrabajo->prioridad }}
                </div>
                <div class="mb-4">
                    <strong>Descripción:</strong> {{ $ordenTrabajo->descripcion ?: 'Sin descripción' }}
                </div>
                <a href="{{ route('ordenes-trabajo.index') }}" class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">Volver</a>
                <a href="{{ route('ordenes-trabajo.edit', $ordenTrabajo) }}" class="ml-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Editar</a>
            </div>
        </div>
    </div>
</div>
@endsection