<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Empleado extends Model
{
    use HasFactory;

    protected $table = 'empleados';

    protected $fillable = [
        'nombres',
        'apellidos',
        'documento',
        'telefono',
        'direccion',
        'cargo',
        'dependencia',
        'licencia_conduccion',
        'categoria_licencia',
        'vencimiento_licencia',
        'foto_url',
        'user_id',
        'resumen_profesional',
        'estado',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
