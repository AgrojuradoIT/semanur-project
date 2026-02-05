@extends('layouts.app')

@section('content')
<div class="py-12">
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
            <div class="p-6 text-gray-900">
                <h1 class="text-2xl font-bold mb-4">Editar Orden de Trabajo</h1>
                <form method="POST" action="{{ route('ordenes-trabajo.update', $ordenTrabajo) }}">
                    @csrf
                    @method('PUT')
                    <div class="mb-4">
                        <label for="vehiculo_id" class="block text-sm font-medium text-gray-700">Vehículo</label>
                        <select name="vehiculo_id" id="vehiculo_id" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                            <option value="">Seleccionar Vehículo</option>
                            @foreach($vehiculos as $vehiculo)
                                <option value="{{ $vehiculo->vehiculo_id }}" {{ old('vehiculo_id', $ordenTrabajo->vehiculo_id) == $vehiculo->vehiculo_id ? 'selected' : '' }}>
                                    {{ $vehiculo->placa }} - {{ $vehiculo->marca }} {{ $vehiculo->modelo }}
                                </option>
                            @endforeach
                        </select>
                        @error('vehiculo_id')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="mecanico_asignado_id" class="block text-sm font-medium text-gray-700">Mecánico Asignado</label>
                        <select name="mecanico_asignado_id" id="mecanico_asignado_id" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">
                            <option value="">Seleccionar Mecánico</option>
                            @foreach($mecanicos as $mecanico)
                                <option value="{{ $mecanico->id }}" {{ old('mecanico_asignado_id', $ordenTrabajo->mecanico_asignado_id) == $mecanico->id ? 'selected' : '' }}>
                                    {{ $mecanico->name }}
                                </option>
                            @endforeach
                        </select>
                        @error('mecanico_asignado_id')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="fecha_inicio" class="block text-sm font-medium text-gray-700">Fecha Inicio</label>
                        <input type="date" name="fecha_inicio" id="fecha_inicio" value="{{ old('fecha_inicio', $ordenTrabajo->fecha_inicio) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                        @error('fecha_inicio')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="fecha_fin" class="block text-sm font-medium text-gray-700">Fecha Fin</label>
                        <input type="date" name="fecha_fin" id="fecha_fin" value="{{ old('fecha_fin', $ordenTrabajo->fecha_fin) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">
                        @error('fecha_fin')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="estado" class="block text-sm font-medium text-gray-700">Estado</label>
                        <select name="estado" id="estado" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                            <option value="">Seleccionar Estado</option>
                            <option value="pendiente" {{ old('estado', $ordenTrabajo->estado) == 'pendiente' ? 'selected' : '' }}>Pendiente</option>
                            <option value="en_progreso" {{ old('estado', $ordenTrabajo->estado) == 'en_progreso' ? 'selected' : '' }}>En Progreso</option>
                            <option value="completada" {{ old('estado', $ordenTrabajo->estado) == 'completada' ? 'selected' : '' }}>Completada</option>
                            <option value="cancelada" {{ old('estado', $ordenTrabajo->estado) == 'cancelada' ? 'selected' : '' }}>Cancelada</option>
                        </select>
                        @error('estado')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="prioridad" class="block text-sm font-medium text-gray-700">Prioridad</label>
                        <select name="prioridad" id="prioridad" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                            <option value="">Seleccionar Prioridad</option>
                            <option value="baja" {{ old('prioridad', $ordenTrabajo->prioridad) == 'baja' ? 'selected' : '' }}>Baja</option>
                            <option value="media" {{ old('prioridad', $ordenTrabajo->prioridad) == 'media' ? 'selected' : '' }}>Media</option>
                            <option value="alta" {{ old('prioridad', $ordenTrabajo->prioridad) == 'alta' ? 'selected' : '' }}>Alta</option>
                            <option value="urgente" {{ old('prioridad', $ordenTrabajo->prioridad) == 'urgente' ? 'selected' : '' }}>Urgente</option>
                        </select>
                        @error('prioridad')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="descripcion" class="block text-sm font-medium text-gray-700">Descripción</label>
                        <textarea name="descripcion" id="descripcion" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">{{ old('descripcion', $ordenTrabajo->descripcion) }}</textarea>
                        @error('descripcion')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Actualizar</button>
                    <a href="{{ route('ordenes-trabajo.index') }}" class="ml-2 bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">Cancelar</a>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection