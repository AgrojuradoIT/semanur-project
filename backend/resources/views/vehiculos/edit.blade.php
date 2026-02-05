@extends('layouts.app')

@section('content')
<div class="py-12">
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
            <div class="p-6 text-gray-900">
                <h1 class="text-2xl font-bold mb-4">Editar Vehículo</h1>
                <form method="POST" action="{{ route('vehiculos.update', $vehiculo) }}">
                    @csrf
                    @method('PUT')
                    <div class="mb-4">
                        <label for="placa" class="block text-sm font-medium text-gray-700">Placa</label>
                        <input type="text" name="placa" id="placa" value="{{ old('placa', $vehiculo->placa) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                        @error('placa')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="tipo" class="block text-sm font-medium text-gray-700">Tipo</label>
                        <input type="text" name="tipo" id="tipo" value="{{ old('tipo', $vehiculo->tipo) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                        @error('tipo')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="marca" class="block text-sm font-medium text-gray-700">Marca</label>
                        <input type="text" name="marca" id="marca" value="{{ old('marca', $vehiculo->marca) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                        @error('marca')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="modelo" class="block text-sm font-medium text-gray-700">Modelo</label>
                        <input type="text" name="modelo" id="modelo" value="{{ old('modelo', $vehiculo->modelo) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                        @error('modelo')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Actualizar</button>
                    <a href="{{ route('vehiculos.index') }}" class="ml-2 bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">Cancelar</a>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection