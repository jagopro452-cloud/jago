<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('shared_trip_passengers', function (Blueprint $table) {
            if (!Schema::hasColumn('shared_trip_passengers', 'distance_km')) {
                $table->decimal('distance_km', 10, 2)->default(0)->after('fare_amount');
            }
            if (!Schema::hasColumn('shared_trip_passengers', 'picked_up_at')) {
                $table->timestamp('picked_up_at')->nullable()->after('status');
            }
            if (!Schema::hasColumn('shared_trip_passengers', 'dropped_off_at')) {
                $table->timestamp('dropped_off_at')->nullable()->after('picked_up_at');
            }
        });
    }

    public function down(): void
    {
        Schema::table('shared_trip_passengers', function (Blueprint $table) {
            $table->dropColumn(['distance_km', 'picked_up_at', 'dropped_off_at']);
        });
    }
};
