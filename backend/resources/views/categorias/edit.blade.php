@extends('layouts.app')

@section('content')
<div class="py-12">
    <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
            <div class="p-6 text-gray-900">
                <h1 class="text-2xl font-bold mb-4">Editar Categoría</h1>
                <form method="POST" action="{{ route('categorias.update', $categoria) }}">
                    @csrf
                    @method('PUT')
                    <div class="mb-4">
                        <label for="categoria_nombre" class="block text-sm font-medium text-gray-700">Nombre</label>
                        <input type="text" name="categoria_nombre" id="categoria_nombre" value="{{ old('categoria_nombre', $categoria->categoria_nombre) }}" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                        @error('categoria_nombre')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="categoria_tipo" class="block text-sm font-medium text-gray-700">Tipo</label>
                        <select name="categoria_tipo" id="categoria_tipo" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm" required>
                            <option value="">Seleccionar Tipo</option>
                            <option value="repuesto" {{ old('categoria_tipo', $categoria->categoria_tipo) == 'repuesto' ? 'selected' : '' }}>Repuesto</option>
                            <option value="servicio" {{ old('categoria_tipo', $categoria->categoria_tipo) == 'servicio' ? 'selected' : '' }}>Servicio</option>
                            <option value="otro" {{ old('categoria_tipo', $categoria->categoria_tipo) == 'otro' ? 'selected' : '' }}>Otro</option>
                        </select>
                        @error('categoria_tipo')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <div class="mb-4">
                        <label for="categoria_descripcion" class="block text-sm font-medium text-gray-700">Descripción</label>
                        <textarea name="categoria_descripcion" id="categoria_descripcion" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">{{ old('categoria_descripcion', $categoria->categoria_descripcion) }}</textarea>
                        @error('categoria_descripcion')
                            <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
                        @enderror
                    </div>
                    <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Actualizar</button>
                    <a href="{{ route('categorias.index') }}" class="ml-2 bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">Cancelar</a>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection