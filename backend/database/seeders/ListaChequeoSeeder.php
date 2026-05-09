<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\ListaChequeo;
use App\Models\ItemListaChequeo;

class ListaChequeoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // 1. Plantilla para Tractores Agrícolas (Tractor)
        $ractorAgricola = ListaChequeo::updateOrCreate(
            ['tipo_vehiculo' => 'tractor'],
            [
                'nombre' => 'Inspección Preoperacional de Tractor Agrícola',
                'descripcion' => 'Revisión estándar de niveles, hidráulico y mecánica para Tractores Agrícolas.',
                'activo' => true
            ]
        );

        $itemsTractor = [
            // Niveles y Fluidos
            ['pregunta' => 'Aceite de Motor', 'es_critico' => true, 'orden' => 1],
            ['pregunta' => 'Refrigerante / Agua', 'es_critico' => true, 'orden' => 2],
            ['pregunta' => 'Aceite Hidráulico', 'es_critico' => true, 'orden' => 3],
            ['pregunta' => 'Combustible (Drenaje de agua)', 'es_critico' => false, 'orden' => 4],
            // Sistema Eléctrico
            ['pregunta' => 'Batería y Bornes', 'es_critico' => false, 'orden' => 5],
            ['pregunta' => 'Luces de Trabajo', 'es_critico' => false, 'orden' => 6],
            ['pregunta' => 'Tablero de Instrumentos', 'es_critico' => false, 'orden' => 7],
            // Mecánica y Llantas
            ['pregunta' => 'Presión de Llantas', 'es_critico' => false, 'orden' => 8],
            ['pregunta' => 'Puntos de Engrase', 'es_critico' => false, 'orden' => 9],
            ['pregunta' => 'Frenos', 'es_critico' => true, 'orden' => 10],
        ];

        // Borrar actuales para evitar duplicados en desarrollo iterativo
        ItemListaChequeo::where('lista_chequeo_id', $ractorAgricola->id)->delete();
        foreach ($itemsTractor as $item) {
            ItemListaChequeo::create([
                'lista_chequeo_id' => $ractorAgricola->id,
                'pregunta' => $item['pregunta'],
                'es_critico' => $item['es_critico'],
                'orden' => $item['orden'],
                'tipo_respuesta' => 'cumple_falla',
            ]);
        }

        // 2. Plantilla para Tractor Aéreo
        $ractorAereo = ListaChequeo::updateOrCreate(
            ['tipo_vehiculo' => 'tractor aereo'],
            [
                'nombre' => 'Inspección Preoperacional de Tractor Aéreo',
                'descripcion' => 'Mantenimiento crítico enfocado en motor.',
                'activo' => true
            ]
        );

        $itemsAereo = [
            ['pregunta' => 'Nivel de Aceite de Motor', 'es_critico' => true, 'orden' => 1],
            ['pregunta' => 'Estado del Filtro de Aire', 'es_critico' => true, 'orden' => 2],
            ['pregunta' => 'Fugas de Aceite', 'es_critico' => true, 'orden' => 3],
        ];

        ItemListaChequeo::where('lista_chequeo_id', $ractorAereo->id)->delete();
        foreach ($itemsAereo as $item) {
            ItemListaChequeo::create([
                'lista_chequeo_id' => $ractorAereo->id,
                'pregunta' => $item['pregunta'],
                'es_critico' => $item['es_critico'],
                'orden' => $item['orden'],
                'tipo_respuesta' => 'cumple_falla',
            ]);
        }

        // 3. Plantilla Genérica para Volquetas, Camionetas y Vehículos Pesados
        $tiposPesados = ['volqueta', 'camioneta', 'moto', 'maquinaria', 'camion', 'trailer', 'minicargador', 'retroexcavadora'];

        foreach ($tiposPesados as $tipo) {
            $listaPesado = ListaChequeo::updateOrCreate(
                ['tipo_vehiculo' => $tipo],
                [
                    'nombre' => 'Inspección Preoperacional de ' . $tipo,
                    'descripcion' => 'Revisión de seguridad y niveles para vehículos comerciales de transporte/construcción.',
                    'activo' => true
                ]
            );

            ItemListaChequeo::where('lista_chequeo_id', $listaPesado->id)->delete();
            $itemsPesado = [
                ['pregunta' => 'Aceite de Motor', 'es_critico' => true, 'orden' => 1],
                ['pregunta' => 'Refrigerante', 'es_critico' => true, 'orden' => 2],
                ['pregunta' => 'Líquido de Frenos', 'es_critico' => true, 'orden' => 3],
                ['pregunta' => 'Dirección Hidráulica', 'es_critico' => true, 'orden' => 4],
                ['pregunta' => 'Presión y Estado Llantas Principales', 'es_critico' => true, 'orden' => 5],
                ['pregunta' => 'Pernos Completos', 'es_critico' => true, 'orden' => 6],
                ['pregunta' => 'Llanta de Repuesto', 'es_critico' => false, 'orden' => 7],
                ['pregunta' => 'Luces Altas y Bajas', 'es_critico' => false, 'orden' => 8],
                ['pregunta' => 'Stop y Direccionales', 'es_critico' => false, 'orden' => 9],
                ['pregunta' => 'Pito / Bocina', 'es_critico' => true, 'orden' => 10],
                ['pregunta' => 'Extintor Vigente', 'es_critico' => true, 'orden' => 11],
                ['pregunta' => 'Botiquín de Primeros Auxilios', 'es_critico' => false, 'orden' => 12],
                ['pregunta' => 'Cinturones de Seguridad Funcionales', 'es_critico' => true, 'orden' => 13],
            ];

            foreach ($itemsPesado as $item) {
                ItemListaChequeo::create([
                    'lista_chequeo_id' => $listaPesado->id,
                    'pregunta' => $item['pregunta'],
                    'es_critico' => $item['es_critico'],
                    'orden' => $item['orden'],
                    'tipo_respuesta' => 'cumple_falla',
                ]);
            }
        }
    }
}
