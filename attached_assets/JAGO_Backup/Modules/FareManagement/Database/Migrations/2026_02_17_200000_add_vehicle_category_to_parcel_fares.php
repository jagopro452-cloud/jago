<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('parcel_fares', 'vehicle_category_id')) {
            Schema::table('parcel_fares', function (Blueprint $table) {
                $table->char('vehicle_category_id', 36)->nullable()->after('zone_id');
                $table->foreign('vehicle_category_id')->references('id')->on('vehicle_categories')->nullOnDelete();
            });
        }

        if (!Schema::hasColumn('parcel_fares', 'vehicle_category_name')) {
            Schema::table('parcel_fares', function (Blueprint $table) {
                $table->string('vehicle_category_name')->nullable()->after('vehicle_category_id');
            });
        }
    }

    public function down(): void
    {
        Schema::table('parcel_fares', function (Blueprint $table) {
            $table->dropForeign(['vehicle_category_id']);
            $table->dropColumn(['vehicle_category_id', 'vehicle_category_name']);
        });
    }
};
