<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('trip_request_fees', function (Blueprint $table) {
            if (!Schema::hasColumn('trip_request_fees', 'special_discount_amount')) {
                $table->decimal('special_discount_amount', 10, 2)->default(0)->after('delay_fee');
            }
            if (!Schema::hasColumn('trip_request_fees', 'special_discount_type')) {
                $table->string('special_discount_type')->nullable()->after('special_discount_amount');
            }
        });
    }

    public function down(): void
    {
        Schema::table('trip_request_fees', function (Blueprint $table) {
            $table->dropColumn(['special_discount_amount', 'special_discount_type']);
        });
    }
};
