<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

$email = 'admin@semanur.com';
$password = 'admin123'; // Password temporal

$user = User::where('email', $email)->first();

if ($user) {
    echo "Usuario encontrado. Actualizando contraseña...\n";
    $user->password = Hash::make($password);
    $user->save();
} else {
    echo "Usuario no encontrado. Creando...\n";
    User::create([
        'name' => 'Admin Semanur',
        'email' => $email,
        'password' => Hash::make($password),
    ]);
}

echo "Proceso terminado. Credenciales: $email / $password\n";
