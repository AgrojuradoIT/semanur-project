<?php

use App\Models\User;
use Illuminate\Support\Facades\Hash;

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';

$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$user = User::updateOrCreate(
    ['email' => 'admin@semanur.com'],
    [
        'name' => 'Admin',
        'password' => Hash::make('admin123'),
        'email_verified_at' => now(),
    ]
);

echo "Usuario: " . $user->email . "\n";
echo "Password: admin123\n";
echo "Estado: Actualizado correctamente.\n";
