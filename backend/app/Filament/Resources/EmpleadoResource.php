<?php

namespace App\Filament\Resources;

use App\Filament\Resources\EmpleadoResource\Pages;
use App\Models\Empleado;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Table;
use BackedEnum;

class EmpleadoResource extends Resource
{
    protected static ?string $model = Empleado::class;

    protected static string | BackedEnum | null $navigationIcon = 'heroicon-o-users';

    protected static ?string $navigationLabel = 'Empleados';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                Forms\Components\TextInput::make('nombres')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('apellidos')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('documento')
                    ->maxLength(20)
                    ->unique(ignorable: fn ($record) => $record),
                Forms\Components\TextInput::make('telefono')
                    ->tel()
                    ->maxLength(20),
                Forms\Components\TextInput::make('cargo')
                    ->maxLength(255),
                Forms\Components\Select::make('estado')
                    ->options([
                        'activo' => 'Activo',
                        'inactivo' => 'Inactivo',
                        'retirado' => 'Retirado',
                    ])
                    ->default('activo')
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('nombres')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('apellidos')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('documento')
                    ->searchable(),
                Tables\Columns\TextColumn::make('cargo')
                    ->searchable(),
                Tables\Columns\TextColumn::make('estado')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'activo' => 'success',
                        'inactivo' => 'warning',
                        'retirado' => 'danger',
                        default => 'gray',
                    }),
            ])
            ->filters([])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListEmpleados::route('/'),
            'create' => Pages\CreateEmpleado::route('/create'),
            'edit' => Pages\EditEmpleado::route('/{record}/edit'),
        ];
    }
}
