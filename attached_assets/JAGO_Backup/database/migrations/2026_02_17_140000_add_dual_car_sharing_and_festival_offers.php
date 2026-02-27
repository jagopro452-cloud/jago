<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('trip_requests', 'sharing_type')) {
            Schema::table('trip_requests', function (Blueprint $table) {
                $table->string('sharing_type', 20)->nullable()->after('ride_mode');
            });
        }

        if (!Schema::hasColumn('shared_trip_passengers', 'sharing_type')) {
            Schema::table('shared_trip_passengers', function (Blueprint $table) {
                $table->string('sharing_type', 20)->nullable()->after('shared_group_id');
            });
        }

        if (!Schema::hasTable('sharing_fare_profiles')) {
            Schema::create('sharing_fare_profiles', function (Blueprint $table) {
                $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
                $table->char('zone_id', 36);
                $table->char('vehicle_category_id', 36);
                $table->string('sharing_type', 20);
                $table->decimal('base_fare_per_seat', 10, 2)->default(0);
                $table->decimal('per_km_fare_per_seat', 10, 2)->default(0);
                $table->decimal('discount_percent', 5, 2)->default(30);
                $table->decimal('commission_percent', 5, 2)->default(20);
                $table->decimal('gst_percent', 5, 2)->default(5);
                $table->decimal('min_fare_per_seat', 10, 2)->default(0);
                $table->decimal('max_detour_km', 5, 2)->default(3);
                $table->decimal('min_distance_km', 8, 2)->default(0);
                $table->decimal('max_distance_km', 8, 2)->default(0);
                $table->boolean('is_active')->default(true);
                $table->timestamps();

                $table->unique(['zone_id', 'vehicle_category_id', 'sharing_type'], 'sharing_fare_unique');
                $table->index('sharing_type');
                $table->index('is_active');
            });
        }

        if (!Schema::hasTable('festival_offers')) {
            Schema::create('festival_offers', function (Blueprint $table) {
                $table->uuid('id')->primary()->default(DB::raw('gen_random_uuid()'));
                $table->string('name', 100);
                $table->text('description')->nullable();
                $table->string('sharing_type', 20)->nullable();
                $table->char('zone_id', 36)->nullable();
                $table->char('vehicle_category_id', 36)->nullable();
                $table->string('offer_type', 30)->default('discount_percent');
                $table->decimal('offer_value', 10, 2)->default(0);
                $table->decimal('max_discount_amount', 10, 2)->default(0);
                $table->decimal('min_fare_amount', 10, 2)->default(0);
                $table->integer('max_uses_total')->default(0);
                $table->integer('max_uses_per_user')->default(1);
                $table->integer('current_uses')->default(0);
                $table->timestamp('starts_at');
                $table->timestamp('ends_at');
                $table->boolean('is_active')->default(true);
                $table->string('banner_image', 255)->nullable();
                $table->timestamps();

                $table->index('sharing_type');
                $table->index('is_active');
                $table->index(['starts_at', 'ends_at']);
            });
        }

        $sharingSettings = [
            ['key_name' => 'city_sharing_enabled', 'value' => '1', 'settings_type' => 'business_settings'],
            ['key_name' => 'outstation_sharing_enabled', 'value' => '1', 'settings_type' => 'business_settings'],
            ['key_name' => 'city_sharing_commission_percent', 'value' => '20', 'settings_type' => 'business_settings'],
            ['key_name' => 'outstation_sharing_commission_percent', 'value' => '15', 'settings_type' => 'business_settings'],
            ['key_name' => 'city_sharing_gst_percent', 'value' => '5', 'settings_type' => 'business_settings'],
            ['key_name' => 'outstation_sharing_gst_percent', 'value' => '5', 'settings_type' => 'business_settings'],
            ['key_name' => 'outstation_min_distance_km', 'value' => '30', 'settings_type' => 'business_settings'],
            ['key_name' => 'city_sharing_max_detour_km', 'value' => '3', 'settings_type' => 'business_settings'],
            ['key_name' => 'outstation_sharing_max_detour_km', 'value' => '10', 'settings_type' => 'business_settings'],
        ];

        foreach ($sharingSettings as $setting) {
            $exists = DB::table('business_settings')->where('key_name', $setting['key_name'])->exists();
            if (!$exists) {
                DB::table('business_settings')->insert(array_merge(
                    ['id' => \Illuminate\Support\Str::uuid()->toString()],
                    $setting,
                    ['created_at' => now(), 'updated_at' => now()]
                ));
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('festival_offers');
        Schema::dropIfExists('sharing_fare_profiles');

        Schema::table('trip_requests', function (Blueprint $table) {
            $table->dropColumn('sharing_type');
        });
        Schema::table('shared_trip_passengers', function (Blueprint $table) {
            $table->dropColumn('sharing_type');
        });

        DB::table('business_settings')->whereIn('key_name', [
            'city_sharing_enabled', 'outstation_sharing_enabled',
            'city_sharing_commission_percent', 'outstation_sharing_commission_percent',
            'city_sharing_gst_percent', 'outstation_sharing_gst_percent',
            'outstation_min_distance_km', 'city_sharing_max_detour_km', 'outstation_sharing_max_detour_km',
        ])->delete();
    }
};
