<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('corporate_accounts')) {
            Schema::create('corporate_accounts', function (Blueprint $table) {
                $table->string('id')->primary();
                $table->string('company_name');
                $table->string('company_code')->unique();
                $table->string('contact_person');
                $table->string('contact_email');
                $table->string('contact_phone');
                $table->string('gst_number')->nullable();
                $table->string('address')->nullable();
                $table->string('city')->nullable();
                $table->string('state')->nullable();
                $table->enum('plan_type', ['basic', 'standard', 'premium', 'enterprise'])->default('basic');
                $table->decimal('discount_percent', 5, 2)->default(0);
                $table->decimal('credit_limit', 12, 2)->default(0);
                $table->decimal('used_credit', 12, 2)->default(0);
                $table->enum('billing_cycle', ['monthly', 'quarterly', 'annual'])->default('monthly');
                $table->boolean('ride_allowed')->default(true);
                $table->boolean('parcel_allowed')->default(false);
                $table->integer('max_employees')->default(50);
                $table->integer('active_employees')->default(0);
                $table->boolean('is_active')->default(true);
                $table->date('contract_start')->nullable();
                $table->date('contract_end')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();
                $table->softDeletes();
            });
        }

        if (!Schema::hasTable('b2b_parcel_plans')) {
            Schema::create('b2b_parcel_plans', function (Blueprint $table) {
                $table->string('id')->primary();
                $table->string('plan_name');
                $table->string('plan_code')->unique();
                $table->text('description')->nullable();
                $table->decimal('monthly_fee', 10, 2)->default(0);
                $table->integer('included_deliveries')->default(0);
                $table->decimal('per_delivery_rate', 8, 2)->default(0);
                $table->decimal('discount_percent', 5, 2)->default(0);
                $table->boolean('priority_pickup')->default(false);
                $table->boolean('dedicated_support')->default(false);
                $table->boolean('api_access')->default(false);
                $table->integer('max_weight_kg')->default(50);
                $table->boolean('is_active')->default(true);
                $table->integer('sort_order')->default(0);
                $table->timestamps();
                $table->softDeletes();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('b2b_parcel_plans');
        Schema::dropIfExists('corporate_accounts');
    }
};
