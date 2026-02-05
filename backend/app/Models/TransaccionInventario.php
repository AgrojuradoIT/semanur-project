<?php

namespace App\Models;

use Backpack\CRUD\app\Models\Traits\CrudTrait;
use Illuminate\Database\Eloquent\Model;

class TransaccionInventario extends Model
{
    use CrudTrait;
    protected $primaryKey = 'transaccion_id';

    protected $fillable = [
        'producto_id',
        'usuario_id',
        'transaccion_tipo',
        'transaccion_cantidad',
        'transaccion_motivo',
        'transaccion_referencia_type',
        'transaccion_referencia_id',
        'transaccion_notas',
    ];

    public function producto()
    {
        return $this->belongsTo(Producto::class, 'producto_id', 'producto_id');
    }

    public function usuario()
    {
        return $this->belongsTo(User::class, 'usuario_id', 'id');
    }

    public function referencia()
    {
        return $this->morphTo('transaccion_referencia');
    }
}
