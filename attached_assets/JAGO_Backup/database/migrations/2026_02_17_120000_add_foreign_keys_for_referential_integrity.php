<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    private array $results = [];

    public function up(): void
    {
        $foreignKeys = [
            ['trip_requests', 'customer_id', 'users', 'id'],
            ['trip_requests', 'driver_id', 'users', 'id'],
            ['trip_requests', 'zone_id', 'zones', 'id'],
            ['trip_requests', 'vehicle_category_id', 'vehicle_categories', 'id'],

            ['trip_request_coordinates', 'trip_request_id', 'trip_requests', 'id'],
            ['trip_request_fees', 'trip_request_id', 'trip_requests', 'id'],
            ['trip_request_times', 'trip_request_id', 'trip_requests', 'id'],
            ['trip_routes', 'trip_request_id', 'trip_requests', 'id'],
            ['trip_status', 'trip_request_id', 'trip_requests', 'id'],
            ['trip_status', 'customer_id', 'users', 'id'],
            ['trip_status', 'driver_id', 'users', 'id'],

            ['transactions', 'user_id', 'users', 'id'],
            ['user_accounts', 'user_id', 'users', 'id'],
            ['user_last_locations', 'user_id', 'users', 'id'],
            ['user_last_locations', 'zone_id', 'zones', 'id'],
            ['user_address', 'user_id', 'users', 'id'],
            ['user_address', 'zone_id', 'zones', 'id'],
            ['user_level_histories', 'user_id', 'users', 'id'],

            ['driver_details', 'user_id', 'users', 'id'],
            ['driver_time_logs', 'driver_id', 'users', 'id'],
            ['vehicles', 'driver_id', 'users', 'id'],

            ['reviews', 'trip_request_id', 'trip_requests', 'id'],
            ['rejected_driver_requests', 'trip_request_id', 'trip_requests', 'id'],
            ['rejected_driver_requests', 'user_id', 'users', 'id'],
            ['temp_trip_notifications', 'trip_request_id', 'trip_requests', 'id'],
            ['temp_trip_notifications', 'user_id', 'users', 'id'],

            ['fare_biddings', 'trip_request_id', 'trip_requests', 'id'],
            ['fare_biddings', 'customer_id', 'users', 'id'],
            ['fare_biddings', 'driver_id', 'users', 'id'],
            ['fare_bidding_logs', 'trip_request_id', 'trip_requests', 'id'],
            ['fare_bidding_logs', 'customer_id', 'users', 'id'],
            ['fare_bidding_logs', 'driver_id', 'users', 'id'],

            ['parcels', 'trip_request_id', 'trip_requests', 'id'],
            ['parcel_information', 'trip_request_id', 'trip_requests', 'id'],
            ['parcel_user_infomations', 'trip_request_id', 'trip_requests', 'id'],
            ['parcel_refunds', 'trip_request_id', 'trip_requests', 'id'],

            ['safety_alerts', 'trip_request_id', 'trip_requests', 'id'],
            ['late_return_penalty_notifications', 'trip_request_id', 'trip_requests', 'id'],

            ['applied_coupons', 'user_id', 'users', 'id'],
            ['loyalty_points_histories', 'user_id', 'users', 'id'],
            ['referral_customers', 'customer_id', 'users', 'id'],
            ['referral_drivers', 'driver_id', 'users', 'id'],
            ['milestone_setups', 'customer_id', 'users', 'id'],
            ['milestone_setups', 'driver_id', 'users', 'id'],

            ['channel_conversations', 'user_id', 'users', 'id'],
            ['channel_users', 'user_id', 'users', 'id'],

            ['app_notifications', 'user_id', 'users', 'id'],
            ['time_tracks', 'user_id', 'users', 'id'],
            ['recent_addresses', 'user_id', 'users', 'id'],
            ['recent_addresses', 'zone_id', 'zones', 'id'],

            ['withdraw_requests', 'user_id', 'users', 'id'],
            ['user_withdraw_method_infos', 'user_id', 'users', 'id'],

            ['role_user', 'user_id', 'users', 'id'],
            ['module_accesses', 'user_id', 'users', 'id'],
            ['customer_coupon_setups', 'user_id', 'users', 'id'],
            ['customer_discount_setups', 'user_id', 'users', 'id'],
            ['bonus_setups', 'user_id', 'users', 'id'],

            ['trip_fares', 'zone_id', 'zones', 'id'],
            ['trip_fares', 'vehicle_category_id', 'vehicle_categories', 'id'],
            ['vehicle_category_zone', 'zone_id', 'zones', 'id'],
            ['vehicle_category_zone', 'vehicle_category_id', 'vehicle_categories', 'id'],
            ['areas', 'zone_id', 'zones', 'id'],
            ['parcel_fares', 'zone_id', 'zones', 'id'],
            ['parcel_fares_parcel_weights', 'zone_id', 'zones', 'id'],
            ['pick_hours', 'zone_id', 'zones', 'id'],
            ['zone_wise_default_trip_fares', 'zone_id', 'zones', 'id'],

            ['bonus_setup_vehicle_category', 'vehicle_category_id', 'vehicle_categories', 'id'],
            ['coupon_setup_vehicle_category', 'vehicle_category_id', 'vehicle_categories', 'id'],
            ['discount_setup_vehicle_category', 'vehicle_category_id', 'vehicle_categories', 'id'],

            ['driver_identity_verifications', 'driver_id', 'users', 'id'],
        ];

        foreach ($foreignKeys as $fk) {
            [$table, $column, $refTable, $refColumn] = $fk;
            $constraintName = "fk_{$table}_{$column}";

            try {
                $exists = DB::select("
                    SELECT 1 FROM information_schema.table_constraints 
                    WHERE constraint_name = ? AND table_name = ?
                ", [$constraintName, $table]);

                if (!empty($exists)) {
                    $this->results[] = "SKIP: {$constraintName} already exists";
                    continue;
                }

                $tableExists = Schema::hasTable($table);
                $refTableExists = Schema::hasTable($refTable);
                if (!$tableExists || !$refTableExists) {
                    $this->results[] = "SKIP: {$constraintName} - table missing";
                    continue;
                }

                DB::statement("
                    ALTER TABLE \"{$table}\" 
                    ADD CONSTRAINT \"{$constraintName}\" 
                    FOREIGN KEY (\"{$column}\") 
                    REFERENCES \"{$refTable}\" (\"{$refColumn}\") 
                    ON DELETE RESTRICT 
                    ON UPDATE CASCADE
                    NOT VALID
                ");

                DB::statement("ALTER TABLE \"{$table}\" VALIDATE CONSTRAINT \"{$constraintName}\"");

                $this->results[] = "OK: {$constraintName}";
            } catch (\Exception $e) {
                $this->results[] = "FAIL: {$constraintName} - " . $e->getMessage();
            }
        }

        foreach ($this->results as $r) {
            echo $r . "\n";
        }
    }

    public function down(): void
    {
        $tables = DB::select("
            SELECT tc.table_name, tc.constraint_name
            FROM information_schema.table_constraints tc
            WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.constraint_name LIKE 'fk_%'
            AND tc.table_schema = 'public'
        ");

        foreach ($tables as $t) {
            try {
                DB::statement("ALTER TABLE \"{$t->table_name}\" DROP CONSTRAINT IF EXISTS \"{$t->constraint_name}\"");
            } catch (\Exception $e) {
            }
        }
    }
};
