<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('subscription_plans') && Schema::hasTable('driver_subscriptions')) {
            return;
        }
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('duration_type');
            $table->integer('duration_days');
            $table->decimal('price', 10, 2);
            $table->integer('max_rides');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('driver_subscriptions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('driver_id');
            $table->uuid('plan_id')->nullable();
            $table->string('plan_name');
            $table->string('duration_type');
            $table->decimal('price_paid', 10, 2);
            $table->decimal('gst_amount', 10, 2)->default(0);
            $table->integer('max_rides');
            $table->integer('rides_used')->default(0);
            $table->boolean('is_locked')->default(false);
            $table->string('status')->default('active');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->uuid('payment_transaction_id')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('driver_subscriptions');
        Schema::dropIfExists('subscription_plans');
    }
};
