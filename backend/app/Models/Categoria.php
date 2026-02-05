<?php

namespace App\Models;

use Backpack\CRUD\app\Models\Traits\CrudTrait;
use Illuminate\Database\Eloquent\Model;

class Categoria extends Model
{
    use CrudTrait;
    protected $primaryKey = 'categoria_id';

    protected $fillable = [
        'categoria_nombre',
        'categoria_tipo',
        'categoria_descripcion',
    ];

    public function productos()
    {
        return $this->hasMany(Producto::class, 'categoria_id', 'categoria_id');
    }
}
