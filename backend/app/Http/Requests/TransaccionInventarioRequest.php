<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TransaccionInventarioRequest extends FormRequest
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
            'producto_id' => 'required|exists:productos,producto_id',
            'usuario_id' => 'required|exists:users,id',
            'transaccion_tipo' => 'required|in:entrada,salida,ajuste',
            'transaccion_cantidad' => 'required|numeric|min:0.01',
            'transaccion_motivo' => 'nullable|string|max:255',
            'transaccion_referencia_type' => 'nullable|string|max:50',
            'transaccion_referencia_id' => 'nullable|integer',
            'transaccion_notas' => 'nullable|string',
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
