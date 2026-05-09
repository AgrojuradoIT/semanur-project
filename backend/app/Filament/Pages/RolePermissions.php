<?php

namespace App\Filament\Pages;

use App\Models\RolePermiso;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Forms\Components\CheckboxList;
use Filament\Forms\Components\Placeholder;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Concerns\InteractsWithSchemas;
use Filament\Schemas\Contracts\HasSchemas;
use Filament\Schemas\Schema;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Cache;
use BackedEnum;
use UnitEnum;

class RolePermissions extends Page implements HasSchemas
{
    use InteractsWithSchemas;

    protected static string | BackedEnum | null $navigationIcon = 'heroicon-o-shield-check';

    protected static ?string $navigationLabel = 'Permisos por Rol';

    protected static string | UnitEnum | null $navigationGroup = 'Administración';

    protected static ?string $title = 'Permisos por Rol';

    protected string $view = 'filament.pages.role-permissions';

    public ?array $data = [];

    public function mount(): void
    {
        $roles = RolePermiso::all()->keyBy('role');
        $modulos = array_keys(User::modulos());

        $defaults = [];
        foreach (['jefe_taller', 'auxiliar_bodega', 'operativo', 'visualizador'] as $role) {
            $defaults[$role] = $roles->get($role)?->permisos ?? [];
        }

        $this->form->fill([
            'roles' => $defaults,
        ]);
    }

    public function form(Schema $schema): Schema
    {
        $modulos = User::modulos();

        return $schema
            ->schema([
                Placeholder::make('info')
                    ->content('Configurá los permisos por defecto para cada rol. Los usuarios heredan estos módulos automáticamente. Los permisos individuales por usuario se agregan por encima de estos.')
                    ->hiddenLabel(),

                Section::make('Administrador')
                    ->description('El rol admin siempre tiene acceso total a todos los módulos. No es configurable.')
                    ->schema([
                        Placeholder::make('admin_info')
                            ->content('✅ Todos los módulos — acceso completo')
                            ->hiddenLabel(),
                    ]),

                Section::make('Jefe de Taller')
                    ->schema([
                        CheckboxList::make('roles.jefe_taller')
                            ->options($modulos)
                            ->columns(3)
                            ->hiddenLabel(),
                    ]),

                Section::make('Auxiliar de Bodega')
                    ->schema([
                        CheckboxList::make('roles.auxiliar_bodega')
                            ->options($modulos)
                            ->columns(3)
                            ->hiddenLabel(),
                    ]),

                Section::make('Operativo')
                    ->schema([
                        CheckboxList::make('roles.operativo')
                            ->options($modulos)
                            ->columns(3)
                            ->hiddenLabel(),
                    ]),

                Section::make('Visualizador')
                    ->schema([
                        CheckboxList::make('roles.visualizador')
                            ->options($modulos)
                            ->columns(3)
                            ->hiddenLabel(),
                    ]),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data['roles'] as $role => $permisos) {
            RolePermiso::updateOrCreate(
                ['role' => $role],
                ['permisos' => array_values($permisos ?? [])],
            );

            Cache::forget("role_permisos_{$role}");
        }

        Notification::make()
            ->title('¡Permisos guardados!')
            ->success()
            ->send();
    }

    protected function getFormActions(): array
    {
        return [
            Action::make('save')
                ->label('Guardar Cambios')
                ->submit('save'),
        ];
    }
}
