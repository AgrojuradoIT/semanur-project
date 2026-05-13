<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/*
|--------------------------------------------------------------------------
| Notificaciones Programadas — 7:00 AM y 2:00 PM (Colombia)
|--------------------------------------------------------------------------
| Revisa stock bajo, vencimientos de documentos y mantenimientos próximos.
| Genera notificaciones en MySQL con deduplicación de 24 horas.
*/
Schedule::command('app:check-notifications')
    ->twiceDaily(7, 14)
    ->timezone('America/Bogota')
    ->withoutOverlapping();

// Limpieza semanal: elimina notificaciones leídas con más de 90 días
Schedule::command('app:purge-notifications')
    ->weeklyOn(0, '3:00') // Domingo 3am
    ->timezone('America/Bogota')
    ->withoutOverlapping();
