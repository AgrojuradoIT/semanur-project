<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ProductoRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize()
    {
        // only allow updates if the user is logged in
        return backpack_auth()->check();
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array
     */
    public function rules()
    {
        return [
            'categoria_id' => 'required|exists:categorias,categoria_id',
            'producto_sku' => 'required|string|max:255|unique:productos,producto_sku,' . $this->route('id'),
            'producto_nombre' => 'required|string|max:255',
            'producto_unidad_medida' => 'required|string|max:50',
            'producto_stock_actual' => 'required|integer|min:0',
            'producto_alerta_stock_minimo' => 'required|integer|min:0',
            'producto_precio_costo' => 'nullable|numeric|min:0',
            'producto_ubicacion' => 'nullable|string|max:255',
        ];
    }

    /**
     * Get the validation attributes that apply to the request.
     *
     * @return array
     */
    public function attributes()
    {
        return [
            //
        ];
    }

    /**
     * Get the validation messages that apply to the request.
     *
     * @return array
     */
    public function messages()
    {
        return [
            //
        ];
    }
}
