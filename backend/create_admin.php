<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;

echo "Current Users:\n";
foreach (User::all() as $u) {
    echo "- " . $u->email . "\n";
}

$email = 'admin@semanur.com';
$password = 'password';

$user = User::where('email', $email)->first();

if (!$user) {
    echo "\nCreating Admin User...\n";
    $user = User::create([
        'name' => 'Admin Semanur',
        'email' => $email,
        'password' => Hash::make($password),
    ]);
    echo "User created successfully.\n";
} else {
    echo "\nAdmin user already exists. Updating password...\n";
    $user->password = Hash::make($password);
    $user->save();
    echo "Password updated.\n";
}

echo "\nCREDENTIALS:\n";
echo "Email: " . $email . "\n";
echo "Password: " . $password . "\n";
