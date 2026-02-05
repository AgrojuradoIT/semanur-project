<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TransaccionInventarioResource\Pages;
use App\Filament\Resources\TransaccionInventarioResource\RelationManagers;
use App\Models\TransaccionInventario;
use Filament\Forms;
use BackedEnum;
use Filament\Schemas\Schema;
use Illuminate\Contracts\Support\Htmlable;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Actions;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class TransaccionInventarioResource extends Resource
{
    protected static ?string $model = TransaccionInventario::class;

    public static function getNavigationIcon(): string | BackedEnum | Htmlable | null
    {
        return 'heroicon-o-rectangle-stack';
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                //
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                //
            ])
            ->filters([
                //
            ])
            ->actions([
                Actions\EditAction::make(),
            ])
            ->bulkActions([
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
            'index' => Pages\ListTransaccionInventarios::route('/'),
            'create' => Pages\CreateTransaccionInventario::route('/create'),
            'edit' => Pages\EditTransaccionInventario::route('/{record}/edit'),
        ];
    }
}
