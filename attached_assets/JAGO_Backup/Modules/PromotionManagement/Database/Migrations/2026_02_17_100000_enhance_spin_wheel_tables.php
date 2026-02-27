<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('spin_wheel_segments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('spin_wheel_config_id');
            $table->string('label', 50);
            $table->decimal('amount', 10, 2);
            $table->string('color', 9)->default('#2563EB');
            $table->integer('weight')->default(1);
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        if (!Schema::hasColumn('spin_wheel_configs', 'max_total_per_user')) {
            Schema::table('spin_wheel_configs', function (Blueprint $table) {
                $table->decimal('max_total_per_user', 10, 2)->default(500)->after('spins_per_day');
                $table->boolean('ride_completion_required')->default(true)->after('max_total_per_user');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('spin_wheel_segments');
        Schema::table('spin_wheel_configs', function (Blueprint $table) {
            $table->dropColumn(['max_total_per_user', 'ride_completion_required']);
        });
    }
};
