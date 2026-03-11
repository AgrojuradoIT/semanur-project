<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VehiculoDocumento extends Model
{
    protected $fillable = [
        'vehiculo_id',
        'tipo',
        'fecha_inicio',
        'fecha_vencimiento',
        'compania',
        'certificado_pdf',
        'estado',
    ];

    protected $casts = [
        'fecha_inicio' => 'date',
        'fecha_vencimiento' => 'date',
    ];

    public function vehiculo()
    {
        return $this->belongsTo(Vehiculo::class);
    }
}
