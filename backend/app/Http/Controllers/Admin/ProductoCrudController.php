<?php

namespace App\Http\Controllers\Admin;

use App\Http\Requests\ProductoRequest;
use Backpack\CRUD\app\Http\Controllers\CrudController;
use Backpack\CRUD\app\Library\CrudPanel\CrudPanelFacade as CRUD;

/**
 * Class ProductoCrudController
 * @package App\Http\Controllers\Admin
 * @property-read \Backpack\CRUD\app\Library\CrudPanel\CrudPanel $crud
 */
class ProductoCrudController extends CrudController
{
    use \Backpack\CRUD\app\Http\Controllers\Operations\ListOperation;
    use \Backpack\CRUD\app\Http\Controllers\Operations\CreateOperation;
    use \Backpack\CRUD\app\Http\Controllers\Operations\UpdateOperation;
    use \Backpack\CRUD\app\Http\Controllers\Operations\DeleteOperation;
    use \Backpack\CRUD\app\Http\Controllers\Operations\ShowOperation;

    /**
     * Configure the CrudPanel object. Apply settings to all operations.
     * 
     * @return void
     */
    public function setup()
    {
        CRUD::setModel(\App\Models\Producto::class);
        CRUD::setRoute(config('backpack.base.route_prefix') . '/producto');
        CRUD::setEntityNameStrings('producto', 'productos');
        CRUD::with(['categoria']);
    }

    /**
     * Define what happens when the List operation is loaded.
     * 
     * @see  https://backpackforlaravel.com/docs/crud-operation-list-entries
     * @return void
     */
    protected function setupListOperation()
    {
        CRUD::column('producto_sku')->label('SKU');
        CRUD::column('producto_nombre')->label('Nombre');
        CRUD::column('categoria')->type('relationship')->attribute('categoria_nombre')->label('Categoría');
        CRUD::column('producto_stock_actual')->label('Stock Actual');
        CRUD::column('producto_precio_costo')->label('Precio Costo')->type('number');
        CRUD::column('producto_ubicacion')->label('Ubicación');

        // Filtros
        CRUD::filter('categoria_id')
            ->type('select')
            ->label('Categoría')
            ->options(\App\Models\Categoria::pluck('categoria_nombre', 'categoria_id')->toArray());
    }

    /**
     * Define what happens when the Create operation is loaded.
     * 
     * @see https://backpackforlaravel.com/docs/crud-operation-create
     * @return void
     */
    protected function setupCreateOperation()
    {
        CRUD::setValidation(ProductoRequest::class);

        CRUD::field('categoria_id')
            ->type('select')
            ->label('Categoría')
            ->options(\App\Models\Categoria::pluck('categoria_nombre', 'categoria_id')->toArray())
            ->required();

        CRUD::field('producto_sku')
            ->type('text')
            ->label('SKU')
            ->required();

        CRUD::field('producto_nombre')
            ->type('text')
            ->label('Nombre')
            ->required();

        CRUD::field('producto_unidad_medida')
            ->type('text')
            ->label('Unidad de Medida')
            ->required();

        CRUD::field('producto_stock_actual')
            ->type('number')
            ->label('Stock Actual')
            ->default(0);

        CRUD::field('producto_alerta_stock_minimo')
            ->type('number')
            ->label('Alerta Stock Mínimo')
            ->default(0);

        CRUD::field('producto_precio_costo')
            ->type('number')
            ->label('Precio Costo')
            ->attributes(['step' => '0.01']);

        CRUD::field('producto_ubicacion')
            ->type('text')
            ->label('Ubicación');
    }

    /**
     * Define what happens when the Update operation is loaded.
     * 
     * @see https://backpackforlaravel.com/docs/crud-operation-update
     * @return void
     */
    protected function setupUpdateOperation()
    {
        $this->setupCreateOperation();
    }
}
