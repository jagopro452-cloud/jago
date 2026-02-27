<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        $settings = [
            ['key_name' => 'earning_model', 'value' => 'commission', 'settings_type' => 'business_settings'],
            ['key_name' => 'platform_fee_amount', 'value' => '0', 'settings_type' => 'business_settings'],
        ];

        foreach ($settings as $setting) {
            $exists = DB::table('business_settings')
                ->where('key_name', $setting['key_name'])
                ->where('settings_type', $setting['settings_type'])
                ->exists();

            if (!$exists) {
                DB::table('business_settings')->insert(array_merge($setting, [
                    'id' => Str::uuid()->toString(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]));
            }
        }
    }

    public function down(): void
    {
        DB::table('business_settings')
            ->where('settings_type', 'business_settings')
            ->whereIn('key_name', ['earning_model', 'platform_fee_amount'])
            ->delete();
    }
};
