<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name', 'Laravel') }}</title>
    <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=instrument-sans:400,500,600" rel="stylesheet" />
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="antialiased">
    <div class="min-h-screen bg-gray-100 flex items-center justify-center">
        <div class="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
            <div class="text-center">
                <h1 class="text-3xl font-bold text-gray-900 mb-4">{{ config('app.name', 'Laravel') }}</h1>
                <p class="text-gray-600 mb-8">Sistema de Gestión Semanur</p>

                @auth
                    <a href="{{ route('dashboard') }}" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded w-full block text-center">
                        Ir al Dashboard
                    </a>
                @else
                    <div class="space-y-4">
                        <a href="{{ route('login') }}" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded w-full block text-center">
                            Iniciar Sesión
                        </a>
                        <a href="{{ route('register') }}" class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded w-full block text-center">
                            Registrarse
                        </a>
                    </div>
                @endauth
            </div>
        </div>
    </div>
</body>
</html>
