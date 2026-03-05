<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('trip_request_fees', function (Blueprint $table) {
            $table->decimal('pickup_charge', 23, 2)->default(0)->after('cancellation_fee');
            $table->decimal('cancellation_fee_admin_share', 23, 2)->default(0)->after('cancelled_by');
            $table->decimal('cancellation_fee_driver_share', 23, 2)->default(0)->after('cancellation_fee_admin_share');
        });

        Schema::table('trip_requests', function (Blueprint $table) {
            $table->string('ride_mode', 20)->default('own')->after('type');
            $table->integer('seats_requested')->default(1)->after('ride_mode');
            $table->string('shared_group_id', 50)->nullable()->after('seats_requested');
        });

        Schema::table('trip_fares', function (Blueprint $table) {
            $table->decimal('pickup_charge_per_km', 23, 2)->default(0)->after('base_fare_per_km');
            $table->decimal('pickup_free_distance', 8, 2)->default(0.5)->after('pickup_charge_per_km');
            $table->decimal('shared_discount_percent', 8, 2)->default(30)->after('pickup_free_distance');
        });

        Schema::create('shared_trip_passengers', function (Blueprint $table) {
            $table->id();
            $table->string('trip_request_id', 50);
            $table->string('shared_group_id', 50);
            $table->string('user_id', 50);
            $table->integer('seats_booked')->default(1);
            $table->string('otp', 6)->nullable();
            $table->boolean('otp_verified')->default(false);
            $table->boolean('is_picked_up')->default(false);
            $table->boolean('is_dropped_off')->default(false);
            $table->decimal('pickup_lat', 15, 8)->nullable();
            $table->decimal('pickup_lng', 15, 8)->nullable();
            $table->string('pickup_address')->nullable();
            $table->decimal('drop_lat', 15, 8)->nullable();
            $table->decimal('drop_lng', 15, 8)->nullable();
            $table->string('drop_address')->nullable();
            $table->decimal('fare_amount', 23, 2)->default(0);
            $table->string('status', 20)->default('pending');
            $table->timestamps();

            $table->index('shared_group_id');
            $table->index('user_id');
            $table->index('trip_request_id');
        });
    }

    public function down(): void
    {
        Schema::table('trip_request_fees', function (Blueprint $table) {
            $table->dropColumn(['pickup_charge', 'cancellation_fee_admin_share', 'cancellation_fee_driver_share']);
        });

        Schema::table('trip_requests', function (Blueprint $table) {
            $table->dropColumn(['ride_mode', 'seats_requested', 'shared_group_id']);
        });

        Schema::table('trip_fares', function (Blueprint $table) {
            $table->dropColumn(['pickup_charge_per_km', 'pickup_free_distance', 'shared_discount_percent']);
        });

        Schema::dropIfExists('shared_trip_passengers');
    }
};
