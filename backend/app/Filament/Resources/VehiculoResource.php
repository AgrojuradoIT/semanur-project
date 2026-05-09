<?php

namespace App\Filament\Resources;

use App\Filament\Resources\VehiculoResource\Pages;
use App\Models\Vehiculo;
use Filament\Forms;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Actions;
use Filament\Schemas\Schema;
use BackedEnum;

class VehiculoResource extends Resource
{
    protected static ?string $model = Vehiculo::class;

    protected static string | BackedEnum | null $navigationIcon = 'heroicon-o-truck';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                Forms\Components\TextInput::make('placa')
                    ->required()
                    ->maxLength(20),
                Forms\Components\TextInput::make('tipo')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('marca')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('modelo')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('imagen_url')
                    ->maxLength(255),
                Forms\Components\TextInput::make('horometro_actual')
                    ->numeric()
                    ->default(0),
                Forms\Components\TextInput::make('kilometraje_actual')
                    ->numeric()
                    ->default(0),
                Forms\Components\DatePicker::make('fecha_vencimiento_soat'),
                Forms\Components\DatePicker::make('fecha_vencimiento_tecnomecanica'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('placa')
                    ->searchable(),
                Tables\Columns\TextColumn::make('tipo')
                    ->searchable(),
                Tables\Columns\TextColumn::make('marca')
                    ->searchable(),
                Tables\Columns\TextColumn::make('modelo')
                    ->searchable(),
                Tables\Columns\TextColumn::make('horometro_actual')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->recordActions([
                Actions\EditAction::make(),
                Actions\DeleteAction::make(),
            ])
            ->toolbarActions([
                Actions\BulkActionGroup::make([
                    Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListVehiculos::route('/'),
            'create' => Pages\CreateVehiculo::route('/create'),
            'edit' => Pages\EditVehiculo::route('/{record}/edit'),
        ];
    }
}
