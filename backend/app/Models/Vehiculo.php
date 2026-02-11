<?php

namespace App\Models;

use Backpack\CRUD\app\Models\Traits\CrudTrait;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Vehiculo extends Model
{
    use CrudTrait;
    protected $primaryKey = 'vehiculo_id';

    protected $fillable = [
        'placa',
        'tipo',
        'marca',
        'modelo',
        'horometro_actual',
        'horometro_proximo_mantenimiento',
        'kilometraje_actual',
        'kilometraje_proximo_mantenimiento',
        'fecha_vencimiento_soat',
        'fecha_vencimiento_tecnomecanica',
        'operador_asignado_id',
        'mecanico_asignado_id',
    ];

    protected $casts = [
        'fecha_vencimiento_soat' => 'date',
        'fecha_vencimiento_tecnomecanica' => 'date',
    ];

    public function ordenesTrabajo(): HasMany
    {
        return $this->hasMany(OrdenTrabajo::class, 'vehiculo_id', 'vehiculo_id');
    }

    public function registrosHorometro(): HasMany
    {
        return $this->hasMany(RegistroHorometro::class, 'vehiculo_id', 'vehiculo_id');
    }

    public function movimientosDirectos(): HasMany
    {
        return $this->hasMany(TransaccionInventario::class, 'transaccion_referencia_id', 'vehiculo_id')
                    ->where('transaccion_referencia_type', 'Vehiculo');
    }

    public function operador()
    {
        return $this->belongsTo(User::class, 'operador_asignado_id');
    }

    public function mecanico()
    {
        return $this->belongsTo(User::class, 'mecanico_asignado_id');
    }
}
