<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RegistroCombustible extends Model
{
    protected $table = 'registros_combustible';
    protected $primaryKey = 'registro_id';

    protected $fillable = [
        'vehiculo_id',
        'usuario_id',
        'fecha',
        'cantidad_galones',
        'valor_total',
        'horometro_actual',
        'kilometraje_actual',
        'estacion_servicio',
        'notas',
    ];

    protected $casts = [
        'fecha' => 'datetime',
        'cantidad_galones' => 'double',
        'valor_total' => 'double',
        'horometro_actual' => 'double',
        'kilometraje_actual' => 'double',
    ];

    public function vehiculo()
    {
        return $this->belongsTo(Vehiculo::class, 'vehiculo_id', 'vehiculo_id');
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id', 'id');
    }
}
