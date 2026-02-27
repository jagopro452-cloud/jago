<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $settings = [
            ['key_name' => 'subscription_model_enabled', 'value' => '0', 'settings_type' => 'business_settings'],
            ['key_name' => 'free_ride_limit', 'value' => '200', 'settings_type' => 'business_settings'],
            ['key_name' => 'negative_balance_limit', 'value' => '200', 'settings_type' => 'business_settings'],
        ];

        foreach ($settings as $setting) {
            DB::table('business_settings')->updateOrInsert(
                ['key_name' => $setting['key_name'], 'settings_type' => $setting['settings_type']],
                $setting
            );
        }
    }

    public function down(): void
    {
        DB::table('business_settings')
            ->whereIn('key_name', ['subscription_model_enabled', 'free_ride_limit', 'negative_balance_limit'])
            ->where('settings_type', 'business_settings')
            ->delete();
    }
};
