<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Prestamos Herramientas
        Schema::table('prestamos_herramientas', function (Blueprint $table) {
            $table->unsignedBigInteger('temp_mecanico_id')->nullable()->after('mecanico_id');
        });

        // Migrate data for prestamos
        $prestamos = DB::table('prestamos_herramientas')->get();
        foreach ($prestamos as $p) {
            $empleado = DB::table('empleados')->where('user_id', $p->mecanico_id)->first();
            if ($empleado) {
                DB::table('prestamos_herramientas')->where('prestamo_id', $p->prestamo_id)->update(['temp_mecanico_id' => $empleado->id]);
            } else {
                // If orphaned, we just delete or link to first one. To be safe, we keep rows but they might be invalid if we make it non-nullable later.
                // For now, let's delete or assign to some default if user wants. For this project, let's delete orphans.
                DB::table('prestamos_herramientas')->where('prestamo_id', $p->prestamo_id)->delete();
            }
        }

        Schema::table('prestamos_herramientas', function (Blueprint $table) {
            $table->dropForeign(['mecanico_id']);
            $table->dropColumn('mecanico_id');
        });

        Schema::table('prestamos_herramientas', function (Blueprint $table) {
            $table->renameColumn('temp_mecanico_id', 'mecanico_id');
        });

        Schema::table('prestamos_herramientas', function (Blueprint $table) {
            $table->unsignedBigInteger('mecanico_id')->nullable(false)->change();
            $table->foreign('mecanico_id')->references('id')->on('empleados')->cascadeOnDelete();
        });

        // 2. Checklists Preoperacionales
        Schema::table('checklists_preoperacionales', function (Blueprint $table) {
            $table->unsignedBigInteger('empleado_id')->nullable()->after('usuario_id');
        });

        // Migrate data for checklists
        $checklists = DB::table('checklists_preoperacionales')->get();
        foreach ($checklists as $c) {
            $empleado = DB::table('empleados')->where('user_id', $c->usuario_id)->first();
            if ($empleado) {
                DB::table('checklists_preoperacionales')->where('id', $c->id)->update(['empleado_id' => $empleado->id]);
            } else {
                DB::table('checklists_preoperacionales')->where('id', $c->id)->delete();
            }
        }

        Schema::table('checklists_preoperacionales', function (Blueprint $table) {
            $table->dropForeign(['usuario_id']);
            $table->dropColumn('usuario_id');
        });

        Schema::table('checklists_preoperacionales', function (Blueprint $table) {
            $table->unsignedBigInteger('empleado_id')->nullable(false)->change();
            $table->foreign('empleado_id')->references('id')->on('empleados')->cascadeOnDelete();
        });

        // 3. Respuestas Lista Chequeo
        Schema::table('respuestas_lista_chequeo', function (Blueprint $table) {
            $table->unsignedBigInteger('temp_operador_id')->nullable()->after('operador_id');
        });

        foreach (DB::table('respuestas_lista_chequeo')->get() as $r) {
            $empleado = DB::table('empleados')->where('user_id', $r->operador_id)->first();
            if ($empleado) {
                DB::table('respuestas_lista_chequeo')->where('id', $r->id)->update(['temp_operador_id' => $empleado->id]);
            } else {
                DB::table('respuestas_lista_chequeo')->where('id', $r->id)->delete();
            }
        }

        Schema::table('respuestas_lista_chequeo', function (Blueprint $table) {
            $table->dropForeign(['operador_id']);
            $table->dropColumn('operador_id');
        });

        Schema::table('respuestas_lista_chequeo', function (Blueprint $table) {
            $table->renameColumn('temp_operador_id', 'operador_id');
        });

        Schema::table('respuestas_lista_chequeo', function (Blueprint $table) {
            $table->unsignedBigInteger('operador_id')->nullable(false)->change();
            $table->foreign('operador_id')->references('id')->on('empleados')->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert Respuestas
        Schema::table('respuestas_lista_chequeo', function (Blueprint $table) {
            $table->dropForeign(['operador_id']);
            $table->unsignedBigInteger('temp_user_id')->nullable()->after('operador_id');
        });

        foreach (DB::table('respuestas_lista_chequeo')->get() as $r) {
            $user_id = DB::table('empleados')->where('id', $r->operador_id)->value('user_id');
            if ($user_id) {
                DB::table('respuestas_lista_chequeo')->where('id', $r->id)->update(['temp_user_id' => $user_id]);
            }
        }

        Schema::table('respuestas_lista_chequeo', function (Blueprint $table) {
            $table->dropColumn('operador_id');
        });

        Schema::table('respuestas_lista_chequeo', function (Blueprint $table) {
            $table->renameColumn('temp_user_id', 'operador_id');
        });

        Schema::table('respuestas_lista_chequeo', function (Blueprint $table) {
            $table->unsignedBigInteger('operador_id')->nullable(false)->change();
            $table->foreign('operador_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // Revert Checklist
        Schema::table('checklists_preoperacionales', function (Blueprint $table) {
            $table->dropForeign(['empleado_id']);
            $table->unsignedBigInteger('usuario_id')->nullable()->after('empleado_id');
        });

        foreach (DB::table('checklists_preoperacionales')->get() as $c) {
            $user_id = DB::table('empleados')->where('id', $c->empleado_id)->value('user_id');
            if ($user_id) {
                DB::table('checklists_preoperacionales')->where('id', $c->id)->update(['usuario_id' => $user_id]);
            }
        }

        Schema::table('checklists_preoperacionales', function (Blueprint $table) {
            $table->dropColumn('empleado_id');
            $table->unsignedBigInteger('usuario_id')->nullable(false)->change();
            $table->foreign('usuario_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // Revert Prestamos
        Schema::table('prestamos_herramientas', function (Blueprint $table) {
            $table->dropForeign(['mecanico_id']);
            $table->unsignedBigInteger('temp_user_id')->nullable()->after('mecanico_id');
        });

        foreach (DB::table('prestamos_herramientas')->get() as $p) {
            $user_id = DB::table('empleados')->where('id', $p->mecanico_id)->value('user_id');
            if ($user_id) {
                DB::table('prestamos_herramientas')->where('prestamo_id', $p->prestamo_id)->update(['temp_user_id' => $user_id]);
            }
        }

        Schema::table('prestamos_herramientas', function (Blueprint $table) {
            $table->dropColumn('mecanico_id');
        });

        Schema::table('prestamos_herramientas', function (Blueprint $table) {
            $table->renameColumn('temp_user_id', 'mecanico_id');
        });

        Schema::table('prestamos_herramientas', function (Blueprint $table) {
            $table->unsignedBigInteger('mecanico_id')->nullable(false)->change();
            $table->foreign('mecanico_id')->references('id')->on('users')->cascadeOnDelete();
        });
    }
};
