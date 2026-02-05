<?php

namespace App\Models;

use Backpack\CRUD\app\Models\Traits\CrudTrait;
use Illuminate\Database\Eloquent\Model;

class Producto extends Model
{
    use CrudTrait;
    protected $primaryKey = 'producto_id';

    protected $fillable = [
        'categoria_id',
        'producto_sku',
        'producto_nombre',
        'producto_unidad_medida',
        'producto_stock_actual',
        'producto_alerta_stock_minimo',
        'producto_precio_costo',
        'producto_ubicacion',
    ];

    public function categoria()
    {
        return $this->belongsTo(Categoria::class, 'categoria_id', 'categoria_id');
    }

    public function transacciones()
    {
        return $this->hasMany(TransaccionInventario::class, 'producto_id', 'producto_id');
    }
}
