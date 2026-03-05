<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('spin_wheel_configs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->boolean('is_active')->default(false);
            $table->string('title', 100)->default('Spin & Win!');
            $table->string('subtitle', 255)->default('Spin the wheel to win wallet rewards!');
            $table->integer('min_discount')->default(5);
            $table->integer('max_discount')->default(100);
            $table->integer('spins_per_day')->default(1);
            $table->json('segments')->nullable();
            $table->json('segment_colors')->nullable();
            $table->timestamps();
        });

        Schema::create('spin_wheel_results', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->nullable();
            $table->foreignUuid('trip_request_id')->nullable();
            $table->integer('discount_value')->default(0);
            $table->decimal('wallet_amount', 10, 2)->default(0);
            $table->foreignUuid('transaction_id')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('spin_wheel_results');
        Schema::dropIfExists('spin_wheel_configs');
    }
};
