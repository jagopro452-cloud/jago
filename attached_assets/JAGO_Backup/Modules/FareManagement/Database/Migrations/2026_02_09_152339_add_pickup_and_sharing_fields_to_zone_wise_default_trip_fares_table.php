<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('zone_wise_default_trip_fares', function (Blueprint $table) {
            if (!Schema::hasColumn('zone_wise_default_trip_fares', 'pickup_charge_per_km')) {
                $table->decimal('pickup_charge_per_km', 24, 2)->default(0)->after('trip_delay_fee_per_min');
            }
            if (!Schema::hasColumn('zone_wise_default_trip_fares', 'pickup_free_distance')) {
                $table->decimal('pickup_free_distance', 24, 2)->default(0.5)->after('pickup_charge_per_km');
            }
            if (!Schema::hasColumn('zone_wise_default_trip_fares', 'shared_discount_percent')) {
                $table->decimal('shared_discount_percent', 5, 2)->default(30)->after('pickup_free_distance');
            }
        });
    }

    public function down(): void
    {
        Schema::table('zone_wise_default_trip_fares', function (Blueprint $table) {
            $table->dropColumn(['pickup_charge_per_km', 'pickup_free_distance', 'shared_discount_percent']);
        });
    }
};
