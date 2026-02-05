<?php

namespace App\Http\Controllers;

use App\Models\OrdenTrabajo;
use App\Models\Vehiculo;
use App\Models\User;
use App\Http\Requests\OrdenTrabajoRequest;
use Illuminate\Http\Request;

class OrdenTrabajoController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $ordenesTrabajo = OrdenTrabajo::with('vehiculo', 'mecanico')->get();
        return view('ordenes-trabajo.index', compact('ordenesTrabajo'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $vehiculos = Vehiculo::all();
        $mecanicos = User::all(); // Assuming users are mechanics
        return view('ordenes-trabajo.create', compact('vehiculos', 'mecanicos'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(OrdenTrabajoRequest $request)
    {
        OrdenTrabajo::create($request->validated());

        return redirect()->route('ordenes-trabajo.index')->with('success', 'Orden de Trabajo creada exitosamente.');
    }

    /**
     * Display the specified resource.
     */
    public function show(OrdenTrabajo $ordenTrabajo)
    {
        $ordenTrabajo->load('vehiculo', 'mecanico');
        return view('ordenes-trabajo.show', compact('ordenTrabajo'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(OrdenTrabajo $ordenTrabajo)
    {
        $vehiculos = Vehiculo::all();
        $mecanicos = User::all();
        return view('ordenes-trabajo.edit', compact('ordenTrabajo', 'vehiculos', 'mecanicos'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(OrdenTrabajoRequest $request, OrdenTrabajo $ordenTrabajo)
    {
        $ordenTrabajo->update($request->validated());

        return redirect()->route('ordenes-trabajo.index')->with('success', 'Orden de Trabajo actualizada exitosamente.');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(OrdenTrabajo $ordenTrabajo)
    {
        $ordenTrabajo->delete();

        return redirect()->route('ordenes-trabajo.index')->with('success', 'Orden de Trabajo eliminada exitosamente.');
    }
}
