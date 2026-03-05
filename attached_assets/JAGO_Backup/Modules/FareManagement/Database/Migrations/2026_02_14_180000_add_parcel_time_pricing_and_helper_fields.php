<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('parcel_fares', function (Blueprint $table) {
            $table->decimal('per_minute_rate', 8, 2)->default(0)->after('base_fare_per_km');
            $table->decimal('minimum_fare', 8, 2)->default(0)->after('per_minute_rate');
        });

        Schema::table('parcel_fares_parcel_weights', function (Blueprint $table) {
            $table->decimal('per_minute_rate', 8, 2)->default(0)->after('fare_per_km');
            $table->decimal('minimum_fare', 8, 2)->default(0)->after('per_minute_rate');
        });

        Schema::table('trip_requests', function (Blueprint $table) {
            $table->string('receiver_otp', 4)->nullable()->after('otp');
            $table->boolean('helper_required')->default(false)->after('map_screenshot');
            $table->decimal('helper_fee', 10, 2)->default(0)->after('helper_required');
            $table->decimal('time_based_fare', 10, 2)->default(0)->after('helper_fee');
            $table->integer('estimated_time_minutes')->default(0)->after('time_based_fare');
        });
    }

    public function down(): void
    {
        Schema::table('parcel_fares', function (Blueprint $table) {
            $table->dropColumn(['per_minute_rate', 'minimum_fare']);
        });

        Schema::table('parcel_fares_parcel_weights', function (Blueprint $table) {
            $table->dropColumn(['per_minute_rate', 'minimum_fare']);
        });

        Schema::table('trip_requests', function (Blueprint $table) {
            $table->dropColumn(['receiver_otp', 'helper_required', 'helper_fee', 'time_based_fare', 'estimated_time_minutes']);
        });
    }
};
