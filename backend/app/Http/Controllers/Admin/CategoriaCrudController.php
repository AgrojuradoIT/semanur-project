<?php

namespace App\Http\Controllers\Admin;

use App\Http\Requests\CategoriaRequest;
use Backpack\CRUD\app\Http\Controllers\CrudController;
use Backpack\CRUD\app\Library\CrudPanel\CrudPanelFacade as CRUD;

/**
 * Class CategoriaCrudController
 * @package App\Http\Controllers\Admin
 * @property-read \Backpack\CRUD\app\Library\CrudPanel\CrudPanel $crud
 */
class CategoriaCrudController extends CrudController
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
        CRUD::setModel(\App\Models\Categoria::class);
        CRUD::setRoute(config('backpack.base.route_prefix') . '/categoria');
        CRUD::setEntityNameStrings('categoria', 'categorias');
    }

    /**
     * Define what happens when the List operation is loaded.
     * 
     * @see  https://backpackforlaravel.com/docs/crud-operation-list-entries
     * @return void
     */
    protected function setupListOperation()
    {
        CRUD::column('categoria_nombre')->label('Nombre');
        CRUD::column('categoria_tipo')->label('Tipo');
        CRUD::column('categoria_descripcion')->label('Descripción');
    }

    /**
     * Define what happens when the Create operation is loaded.
     * 
     * @see https://backpackforlaravel.com/docs/crud-operation-create
     * @return void
     */
    protected function setupCreateOperation()
    {
        CRUD::setValidation(CategoriaRequest::class);

        CRUD::field('categoria_nombre')
            ->type('text')
            ->label('Nombre')
            ->required();

        CRUD::field('categoria_tipo')
            ->type('select')
            ->label('Tipo')
            ->options(['Producto' => 'Producto', 'Servicio' => 'Servicio'])
            ->required();

        CRUD::field('categoria_descripcion')
            ->type('textarea')
            ->label('Descripción');
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
