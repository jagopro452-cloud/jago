<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('parcel_fares', function (Blueprint $table) {
            if (!Schema::hasColumn('parcel_fares', 'pickup_charge_per_km')) {
                $table->double('pickup_charge_per_km')->default(0)->after('base_fare_per_km');
            }
            if (!Schema::hasColumn('parcel_fares', 'pickup_free_distance')) {
                $table->double('pickup_free_distance')->default(0.5)->after('pickup_charge_per_km');
            }
            if (!Schema::hasColumn('parcel_fares', 'waiting_fee_per_min')) {
                $table->double('waiting_fee_per_min')->default(0)->after('pickup_free_distance');
            }
        });
    }

    public function down(): void
    {
        Schema::table('parcel_fares', function (Blueprint $table) {
            $table->dropColumn(['pickup_charge_per_km', 'pickup_free_distance', 'waiting_fee_per_min']);
        });
    }
};
