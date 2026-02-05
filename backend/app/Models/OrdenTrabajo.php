<?php

namespace App\Models;

use Backpack\CRUD\app\Models\Traits\CrudTrait;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrdenTrabajo extends Model
{
    use CrudTrait;
    protected $primaryKey = 'orden_trabajo_id';

    protected $fillable = [
        'vehiculo_id',
        'mecanico_asignado_id',
        'fecha_inicio',
        'fecha_fin',
        'estado',
        'prioridad',
        'descripcion',
        'foto_evidencia',
    ];

    public function vehiculo(): BelongsTo
    {
        return $this->belongsTo(Vehiculo::class, 'vehiculo_id', 'vehiculo_id');
    }

    public function movimientos_inventario()
    {
        return $this->hasMany(TransaccionInventario::class, 'transaccion_referencia_id', 'orden_trabajo_id')
                    ->where('transaccion_referencia_type', 'OrdenTrabajo');
    }

    public function mecanico(): BelongsTo
    {
        return $this->belongsTo(User::class, 'mecanico_asignado_id', 'id');
    }

    public function sesiones()
    {
        return $this->hasMany(WorkSession::class, 'orden_trabajo_id', 'orden_trabajo_id');
    }
}
