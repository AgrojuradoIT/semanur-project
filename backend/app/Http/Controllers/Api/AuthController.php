<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    private function canViewUsers(User $user): bool
    {
        $role = strtolower((string) $user->role);
        return in_array($role, ['admin', 'almacenista'], true);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'device_name' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Las credenciales proporcionadas son incorrectas.'],
            ]);
        }

        return response()->json([
            'token' => $user->createToken($request->device_name)->plainTextToken,
            'user' => $user,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Sesion cerrada correctamente']);
    }

    public function refresh(Request $request)
    {
        $user = $request->user();
        $currentToken = $user->currentAccessToken();

        $tokenName = $request->input('device_name', $currentToken?->name ?? 'flutter_app');
        $currentToken?->delete();

        return response()->json([
            'token' => $user->createToken($tokenName)->plainTextToken,
            'user' => $user,
        ]);
    }

    public function logoutAll(Request $request)
    {
        $request->user()->tokens()->delete();

        return response()->json(['message' => 'Todas las sesiones fueron cerradas']);
    }

    public function user(Request $request)
    {
        return response()->json($request->user());
    }

    public function index(Request $request)
    {
        $authUser = $request->user();

        if (!$this->canViewUsers($authUser)) {
            return response()->json(['message' => 'No autorizado para consultar usuarios'], 403);
        }

        return response()->json(
            User::query()
                ->select(['id', 'name', 'email', 'role', 'phone', 'license_number', 'cargo', 'dependencia'])
                ->orderBy('name')
                ->get()
        );
    }
}
