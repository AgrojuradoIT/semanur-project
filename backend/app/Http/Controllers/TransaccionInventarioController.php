<?php

namespace App\Http\Controllers;

use App\Models\TransaccionInventario;
use App\Models\Producto;
use App\Models\User;
use App\Http\Requests\TransaccionInventarioRequest;
use Illuminate\Http\Request;

class TransaccionInventarioController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $transacciones = TransaccionInventario::with('producto', 'usuario')->get();
        return view('transacciones-inventario.index', compact('transacciones'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $productos = Producto::all();
        $usuarios = User::all();
        return view('transacciones-inventario.create', compact('productos', 'usuarios'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(TransaccionInventarioRequest $request)
    {
        TransaccionInventario::create($request->validated());

        return redirect()->route('transacciones-inventario.index')->with('success', 'Transacción de Inventario creada exitosamente.');
    }

    /**
     * Display the specified resource.
     */
    public function show(TransaccionInventario $transaccionInventario)
    {
        $transaccionInventario->load('producto', 'usuario');
        return view('transacciones-inventario.show', compact('transaccionInventario'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(TransaccionInventario $transaccionInventario)
    {
        $productos = Producto::all();
        $usuarios = User::all();
        return view('transacciones-inventario.edit', compact('transaccionInventario', 'productos', 'usuarios'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(TransaccionInventarioRequest $request, TransaccionInventario $transaccionInventario)
    {
        $transaccionInventario->update($request->validated());

        return redirect()->route('transacciones-inventario.index')->with('success', 'Transacción de Inventario actualizada exitosamente.');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(TransaccionInventario $transaccionInventario)
    {
        $transaccionInventario->delete();

        return redirect()->route('transacciones-inventario.index')->with('success', 'Transacción de Inventario eliminada exitosamente.');
    }
}
