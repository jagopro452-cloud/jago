--
-- PostgreSQL database dump
--

\restrict iZa94sYt38ibBlViILr4R7r9TMwclskK2ZRnTrfAwtCa0Egza3gaAlGzXZI9maf

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.parcel_fares DROP CONSTRAINT IF EXISTS parcel_fares_vehicle_category_id_foreign;
ALTER TABLE IF EXISTS ONLY public.zone_wise_default_trip_fares DROP CONSTRAINT IF EXISTS fk_zone_wise_default_trip_fares_zone_id;
ALTER TABLE IF EXISTS ONLY public.withdraw_requests DROP CONSTRAINT IF EXISTS fk_withdraw_requests_user_id;
ALTER TABLE IF EXISTS ONLY public.vehicles DROP CONSTRAINT IF EXISTS fk_vehicles_driver_id;
ALTER TABLE IF EXISTS ONLY public.vehicle_category_zone DROP CONSTRAINT IF EXISTS fk_vehicle_category_zone_zone_id;
ALTER TABLE IF EXISTS ONLY public.vehicle_category_zone DROP CONSTRAINT IF EXISTS fk_vehicle_category_zone_vehicle_category_id;
ALTER TABLE IF EXISTS ONLY public.user_withdraw_method_infos DROP CONSTRAINT IF EXISTS fk_user_withdraw_method_infos_user_id;
ALTER TABLE IF EXISTS ONLY public.user_level_histories DROP CONSTRAINT IF EXISTS fk_user_level_histories_user_id;
ALTER TABLE IF EXISTS ONLY public.user_last_locations DROP CONSTRAINT IF EXISTS fk_user_last_locations_zone_id;
ALTER TABLE IF EXISTS ONLY public.user_last_locations DROP CONSTRAINT IF EXISTS fk_user_last_locations_user_id;
ALTER TABLE IF EXISTS ONLY public.user_address DROP CONSTRAINT IF EXISTS fk_user_address_zone_id;
ALTER TABLE IF EXISTS ONLY public.user_address DROP CONSTRAINT IF EXISTS fk_user_address_user_id;
ALTER TABLE IF EXISTS ONLY public.user_accounts DROP CONSTRAINT IF EXISTS fk_user_accounts_user_id;
ALTER TABLE IF EXISTS ONLY public.trip_status DROP CONSTRAINT IF EXISTS fk_trip_status_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.trip_status DROP CONSTRAINT IF EXISTS fk_trip_status_driver_id;
ALTER TABLE IF EXISTS ONLY public.trip_status DROP CONSTRAINT IF EXISTS fk_trip_status_customer_id;
ALTER TABLE IF EXISTS ONLY public.trip_routes DROP CONSTRAINT IF EXISTS fk_trip_routes_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.trip_requests DROP CONSTRAINT IF EXISTS fk_trip_requests_zone_id;
ALTER TABLE IF EXISTS ONLY public.trip_requests DROP CONSTRAINT IF EXISTS fk_trip_requests_vehicle_category_id;
ALTER TABLE IF EXISTS ONLY public.trip_requests DROP CONSTRAINT IF EXISTS fk_trip_requests_driver_id;
ALTER TABLE IF EXISTS ONLY public.trip_requests DROP CONSTRAINT IF EXISTS fk_trip_requests_customer_id;
ALTER TABLE IF EXISTS ONLY public.trip_request_times DROP CONSTRAINT IF EXISTS fk_trip_request_times_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.trip_request_fees DROP CONSTRAINT IF EXISTS fk_trip_request_fees_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.trip_request_coordinates DROP CONSTRAINT IF EXISTS fk_trip_request_coordinates_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.trip_fares DROP CONSTRAINT IF EXISTS fk_trip_fares_zone_id;
ALTER TABLE IF EXISTS ONLY public.trip_fares DROP CONSTRAINT IF EXISTS fk_trip_fares_vehicle_category_id;
ALTER TABLE IF EXISTS ONLY public.transactions DROP CONSTRAINT IF EXISTS fk_transactions_user_id;
ALTER TABLE IF EXISTS ONLY public.time_tracks DROP CONSTRAINT IF EXISTS fk_time_tracks_user_id;
ALTER TABLE IF EXISTS ONLY public.temp_trip_notifications DROP CONSTRAINT IF EXISTS fk_temp_trip_notifications_user_id;
ALTER TABLE IF EXISTS ONLY public.temp_trip_notifications DROP CONSTRAINT IF EXISTS fk_temp_trip_notifications_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.safety_alerts DROP CONSTRAINT IF EXISTS fk_safety_alerts_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.role_user DROP CONSTRAINT IF EXISTS fk_role_user_user_id;
ALTER TABLE IF EXISTS ONLY public.reviews DROP CONSTRAINT IF EXISTS fk_reviews_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.rejected_driver_requests DROP CONSTRAINT IF EXISTS fk_rejected_driver_requests_user_id;
ALTER TABLE IF EXISTS ONLY public.rejected_driver_requests DROP CONSTRAINT IF EXISTS fk_rejected_driver_requests_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.referral_drivers DROP CONSTRAINT IF EXISTS fk_referral_drivers_driver_id;
ALTER TABLE IF EXISTS ONLY public.referral_customers DROP CONSTRAINT IF EXISTS fk_referral_customers_customer_id;
ALTER TABLE IF EXISTS ONLY public.recent_addresses DROP CONSTRAINT IF EXISTS fk_recent_addresses_zone_id;
ALTER TABLE IF EXISTS ONLY public.recent_addresses DROP CONSTRAINT IF EXISTS fk_recent_addresses_user_id;
ALTER TABLE IF EXISTS ONLY public.pick_hours DROP CONSTRAINT IF EXISTS fk_pick_hours_zone_id;
ALTER TABLE IF EXISTS ONLY public.parcels DROP CONSTRAINT IF EXISTS fk_parcels_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.parcel_user_infomations DROP CONSTRAINT IF EXISTS fk_parcel_user_infomations_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.parcel_refunds DROP CONSTRAINT IF EXISTS fk_parcel_refunds_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.parcel_information DROP CONSTRAINT IF EXISTS fk_parcel_information_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.parcel_fares DROP CONSTRAINT IF EXISTS fk_parcel_fares_zone_id;
ALTER TABLE IF EXISTS ONLY public.parcel_fares_parcel_weights DROP CONSTRAINT IF EXISTS fk_parcel_fares_parcel_weights_zone_id;
ALTER TABLE IF EXISTS ONLY public.module_accesses DROP CONSTRAINT IF EXISTS fk_module_accesses_user_id;
ALTER TABLE IF EXISTS ONLY public.milestone_setups DROP CONSTRAINT IF EXISTS fk_milestone_setups_driver_id;
ALTER TABLE IF EXISTS ONLY public.milestone_setups DROP CONSTRAINT IF EXISTS fk_milestone_setups_customer_id;
ALTER TABLE IF EXISTS ONLY public.loyalty_points_histories DROP CONSTRAINT IF EXISTS fk_loyalty_points_histories_user_id;
ALTER TABLE IF EXISTS ONLY public.late_return_penalty_notifications DROP CONSTRAINT IF EXISTS fk_late_return_penalty_notifications_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.fare_biddings DROP CONSTRAINT IF EXISTS fk_fare_biddings_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.fare_biddings DROP CONSTRAINT IF EXISTS fk_fare_biddings_driver_id;
ALTER TABLE IF EXISTS ONLY public.fare_biddings DROP CONSTRAINT IF EXISTS fk_fare_biddings_customer_id;
ALTER TABLE IF EXISTS ONLY public.fare_bidding_logs DROP CONSTRAINT IF EXISTS fk_fare_bidding_logs_trip_request_id;
ALTER TABLE IF EXISTS ONLY public.fare_bidding_logs DROP CONSTRAINT IF EXISTS fk_fare_bidding_logs_driver_id;
ALTER TABLE IF EXISTS ONLY public.fare_bidding_logs DROP CONSTRAINT IF EXISTS fk_fare_bidding_logs_customer_id;
ALTER TABLE IF EXISTS ONLY public.driver_time_logs DROP CONSTRAINT IF EXISTS fk_driver_time_logs_driver_id;
ALTER TABLE IF EXISTS ONLY public.driver_identity_verifications DROP CONSTRAINT IF EXISTS fk_driver_identity_verifications_driver_id;
ALTER TABLE IF EXISTS ONLY public.driver_details DROP CONSTRAINT IF EXISTS fk_driver_details_user_id;
ALTER TABLE IF EXISTS ONLY public.discount_setup_vehicle_category DROP CONSTRAINT IF EXISTS fk_discount_setup_vehicle_category_vehicle_category_id;
ALTER TABLE IF EXISTS ONLY public.customer_discount_setups DROP CONSTRAINT IF EXISTS fk_customer_discount_setups_user_id;
ALTER TABLE IF EXISTS ONLY public.customer_coupon_setups DROP CONSTRAINT IF EXISTS fk_customer_coupon_setups_user_id;
ALTER TABLE IF EXISTS ONLY public.coupon_setup_vehicle_category DROP CONSTRAINT IF EXISTS fk_coupon_setup_vehicle_category_vehicle_category_id;
ALTER TABLE IF EXISTS ONLY public.channel_users DROP CONSTRAINT IF EXISTS fk_channel_users_user_id;
ALTER TABLE IF EXISTS ONLY public.channel_conversations DROP CONSTRAINT IF EXISTS fk_channel_conversations_user_id;
ALTER TABLE IF EXISTS ONLY public.bonus_setups DROP CONSTRAINT IF EXISTS fk_bonus_setups_user_id;
ALTER TABLE IF EXISTS ONLY public.bonus_setup_vehicle_category DROP CONSTRAINT IF EXISTS fk_bonus_setup_vehicle_category_vehicle_category_id;
ALTER TABLE IF EXISTS ONLY public.areas DROP CONSTRAINT IF EXISTS fk_areas_zone_id;
ALTER TABLE IF EXISTS ONLY public.applied_coupons DROP CONSTRAINT IF EXISTS fk_applied_coupons_user_id;
ALTER TABLE IF EXISTS ONLY public.app_notifications DROP CONSTRAINT IF EXISTS fk_app_notifications_user_id;
ALTER TABLE IF EXISTS ONLY public.call_signals DROP CONSTRAINT IF EXISTS call_signals_call_id_fkey;
ALTER TABLE IF EXISTS ONLY public.call_recordings DROP CONSTRAINT IF EXISTS call_recordings_call_id_fkey;
DROP INDEX IF EXISTS public.zones_name_unique;
DROP INDEX IF EXISTS public.vehicle_categories_name_unique;
DROP INDEX IF EXISTS public.vehicle_brands_name_unique;
DROP INDEX IF EXISTS public.users_ref_code_unique;
DROP INDEX IF EXISTS public.users_phone_unique;
DROP INDEX IF EXISTS public.users_email_unique;
DROP INDEX IF EXISTS public.surge_pricing_readable_id_unique;
DROP INDEX IF EXISTS public.sp_scat_scid_idx;
DROP INDEX IF EXISTS public.sharing_fare_profiles_sharing_type_index;
DROP INDEX IF EXISTS public.sharing_fare_profiles_is_active_index;
DROP INDEX IF EXISTS public.shared_trip_passengers_user_id_index;
DROP INDEX IF EXISTS public.shared_trip_passengers_trip_request_id_index;
DROP INDEX IF EXISTS public.shared_trip_passengers_shared_group_id_index;
DROP INDEX IF EXISTS public.personal_access_tokens_tokenable_type_tokenable_id_index;
DROP INDEX IF EXISTS public.personal_access_tokens_token_unique;
DROP INDEX IF EXISTS public.payment_settings_id_index;
DROP INDEX IF EXISTS public.parcel_categories_name_unique;
DROP INDEX IF EXISTS public.oauth_refresh_tokens_access_token_id_index;
DROP INDEX IF EXISTS public.oauth_clients_user_id_index;
DROP INDEX IF EXISTS public.oauth_auth_codes_user_id_index;
DROP INDEX IF EXISTS public.oauth_access_tokens_user_id_index;
DROP INDEX IF EXISTS public.newsletter_subscriptions_email_unique;
DROP INDEX IF EXISTS public.milestone_setups_id_unique;
DROP INDEX IF EXISTS public.jobs_queue_index;
DROP INDEX IF EXISTS public.idx_zone_wise_default_trip_fares_zone;
DROP INDEX IF EXISTS public.idx_vehicles_is_active;
DROP INDEX IF EXISTS public.idx_vehicles_driver_id;
DROP INDEX IF EXISTS public.idx_vehicle_categories_type_active;
DROP INDEX IF EXISTS public.idx_vehicle_categories_type;
DROP INDEX IF EXISTS public.idx_users_user_type;
DROP INDEX IF EXISTS public.idx_users_type_active;
DROP INDEX IF EXISTS public.idx_users_is_active;
DROP INDEX IF EXISTS public.idx_users_created_at;
DROP INDEX IF EXISTS public.idx_user_last_locations_zone_id;
DROP INDEX IF EXISTS public.idx_user_last_locations_user_id;
DROP INDEX IF EXISTS public.idx_user_last_locations_type;
DROP INDEX IF EXISTS public.idx_user_accounts_user_id;
DROP INDEX IF EXISTS public.idx_trip_status_trip_request_id;
DROP INDEX IF EXISTS public.idx_trip_routes_trip_request_id;
DROP INDEX IF EXISTS public.idx_trip_requests_zone_id;
DROP INDEX IF EXISTS public.idx_trip_requests_vehicle_category_id;
DROP INDEX IF EXISTS public.idx_trip_requests_type_status;
DROP INDEX IF EXISTS public.idx_trip_requests_type;
DROP INDEX IF EXISTS public.idx_trip_requests_status_zone;
DROP INDEX IF EXISTS public.idx_trip_requests_payment_status;
DROP INDEX IF EXISTS public.idx_trip_requests_driver_status;
DROP INDEX IF EXISTS public.idx_trip_requests_driver_id;
DROP INDEX IF EXISTS public.idx_trip_requests_customer_status_created;
DROP INDEX IF EXISTS public.idx_trip_requests_customer_status;
DROP INDEX IF EXISTS public.idx_trip_requests_customer_id;
DROP INDEX IF EXISTS public.idx_trip_requests_current_status;
DROP INDEX IF EXISTS public.idx_trip_requests_created_at;
DROP INDEX IF EXISTS public.idx_trip_request_times_trip_request_id;
DROP INDEX IF EXISTS public.idx_trip_request_fees_trip_request_id;
DROP INDEX IF EXISTS public.idx_trip_request_coordinates_trip_request_id;
DROP INDEX IF EXISTS public.idx_transactions_user_id;
DROP INDEX IF EXISTS public.idx_transactions_user_created;
DROP INDEX IF EXISTS public.idx_transactions_trx_ref_id;
DROP INDEX IF EXISTS public.idx_transactions_created_at;
DROP INDEX IF EXISTS public.idx_transactions_attribute_id;
DROP INDEX IF EXISTS public.idx_transactions_account;
DROP INDEX IF EXISTS public.idx_spin_wheel_results_user_id;
DROP INDEX IF EXISTS public.idx_spin_wheel_results_user_date;
DROP INDEX IF EXISTS public.idx_spin_wheel_results_trip;
DROP INDEX IF EXISTS public.idx_spin_wheel_results_created_at;
DROP INDEX IF EXISTS public.idx_shared_trip_unique_active_passenger;
DROP INDEX IF EXISTS public.idx_shared_trip_passengers_trip_request_id;
DROP INDEX IF EXISTS public.idx_sessions_user_id;
DROP INDEX IF EXISTS public.idx_sessions_last_activity;
DROP INDEX IF EXISTS public.idx_reviews_trip_request_id;
DROP INDEX IF EXISTS public.idx_parcel_information_trip_request_id;
DROP INDEX IF EXISTS public.idx_overcharge_status;
DROP INDEX IF EXISTS public.idx_overcharge_driver;
DROP INDEX IF EXISTS public.idx_jobs_queue;
DROP INDEX IF EXISTS public.idx_fare_biddings_trip_request_id;
DROP INDEX IF EXISTS public.idx_fare_biddings_driver_id;
DROP INDEX IF EXISTS public.idx_driver_subscriptions_status;
DROP INDEX IF EXISTS public.idx_driver_subscriptions_driver_id;
DROP INDEX IF EXISTS public.idx_driver_details_user_id;
DROP INDEX IF EXISTS public.idx_driver_details_online_availability;
DROP INDEX IF EXISTS public.idx_driver_details_is_online;
DROP INDEX IF EXISTS public.idx_channel_conversations_updated_at;
DROP INDEX IF EXISTS public.idx_calls_trip;
DROP INDEX IF EXISTS public.idx_calls_status;
DROP INDEX IF EXISTS public.idx_calls_created;
DROP INDEX IF EXISTS public.idx_calls_caller;
DROP INDEX IF EXISTS public.idx_calls_callee;
DROP INDEX IF EXISTS public.idx_call_signals_unconsumed;
DROP INDEX IF EXISTS public.idx_call_signals_call;
DROP INDEX IF EXISTS public.idx_call_recordings_call;
DROP INDEX IF EXISTS public.festival_offers_starts_at_ends_at_index;
DROP INDEX IF EXISTS public.festival_offers_sharing_type_index;
DROP INDEX IF EXISTS public.festival_offers_is_active_index;
DROP INDEX IF EXISTS public.failed_jobs_uuid_unique;
DROP INDEX IF EXISTS public.channel_lists_channelable_type_channelable_id_index;
DROP INDEX IF EXISTS public.channel_conversations_convable_type_convable_id_index;
DROP INDEX IF EXISTS public.blogs_slug_unique;
DROP INDEX IF EXISTS public.blogs_readable_id_unique;
DROP INDEX IF EXISTS public.blog_categories_slug_unique;
DROP INDEX IF EXISTS public.areas_name_unique;
ALTER TABLE IF EXISTS ONLY public.zones DROP CONSTRAINT IF EXISTS zones_pkey;
ALTER TABLE IF EXISTS ONLY public.zone_wise_default_trip_fares DROP CONSTRAINT IF EXISTS zone_wise_default_trip_fares_pkey;
ALTER TABLE IF EXISTS ONLY public.zone_discount_setups DROP CONSTRAINT IF EXISTS zone_discount_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.zone_coupon_setups DROP CONSTRAINT IF EXISTS zone_coupon_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.withdraw_requests DROP CONSTRAINT IF EXISTS withdraw_requests_pkey;
ALTER TABLE IF EXISTS ONLY public.withdraw_methods DROP CONSTRAINT IF EXISTS withdraw_methods_pkey;
ALTER TABLE IF EXISTS ONLY public.websockets_statistics_entries DROP CONSTRAINT IF EXISTS websockets_statistics_entries_pkey;
ALTER TABLE IF EXISTS ONLY public.wallet_bonuses DROP CONSTRAINT IF EXISTS wallet_bonuses_pkey;
ALTER TABLE IF EXISTS ONLY public.vehicles DROP CONSTRAINT IF EXISTS vehicles_pkey;
ALTER TABLE IF EXISTS ONLY public.vehicle_models DROP CONSTRAINT IF EXISTS vehicle_models_pkey;
ALTER TABLE IF EXISTS ONLY public.vehicle_category_zone DROP CONSTRAINT IF EXISTS vehicle_category_zone_pkey;
ALTER TABLE IF EXISTS ONLY public.vehicle_category_discount_setups DROP CONSTRAINT IF EXISTS vehicle_category_discount_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.vehicle_category_coupon_setups DROP CONSTRAINT IF EXISTS vehicle_category_coupon_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.vehicle_categories DROP CONSTRAINT IF EXISTS vehicle_categories_pkey;
ALTER TABLE IF EXISTS ONLY public.vehicle_brands DROP CONSTRAINT IF EXISTS vehicle_brands_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.user_withdraw_method_infos DROP CONSTRAINT IF EXISTS user_withdraw_method_infos_pkey;
ALTER TABLE IF EXISTS ONLY public.user_levels DROP CONSTRAINT IF EXISTS user_levels_pkey;
ALTER TABLE IF EXISTS ONLY public.user_level_histories DROP CONSTRAINT IF EXISTS user_level_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.user_last_locations DROP CONSTRAINT IF EXISTS user_last_locations_pkey;
ALTER TABLE IF EXISTS ONLY public.user_address DROP CONSTRAINT IF EXISTS user_address_pkey;
ALTER TABLE IF EXISTS ONLY public.user_accounts DROP CONSTRAINT IF EXISTS user_accounts_pkey;
ALTER TABLE IF EXISTS ONLY public.trip_status DROP CONSTRAINT IF EXISTS trip_status_pkey;
ALTER TABLE IF EXISTS ONLY public.trip_routes DROP CONSTRAINT IF EXISTS trip_routes_pkey;
ALTER TABLE IF EXISTS ONLY public.trip_requests DROP CONSTRAINT IF EXISTS trip_requests_pkey;
ALTER TABLE IF EXISTS ONLY public.trip_request_times DROP CONSTRAINT IF EXISTS trip_request_times_pkey;
ALTER TABLE IF EXISTS ONLY public.trip_request_fees DROP CONSTRAINT IF EXISTS trip_request_fees_pkey;
ALTER TABLE IF EXISTS ONLY public.trip_request_coordinates DROP CONSTRAINT IF EXISTS trip_request_coordinates_pkey;
ALTER TABLE IF EXISTS ONLY public.trip_fares DROP CONSTRAINT IF EXISTS trip_fares_pkey;
ALTER TABLE IF EXISTS ONLY public.transactions DROP CONSTRAINT IF EXISTS transactions_pkey;
ALTER TABLE IF EXISTS ONLY public.time_tracks DROP CONSTRAINT IF EXISTS time_tracks_pkey;
ALTER TABLE IF EXISTS ONLY public.time_logs DROP CONSTRAINT IF EXISTS time_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.temp_trip_notifications DROP CONSTRAINT IF EXISTS temp_trip_notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.surge_pricing_time_slots DROP CONSTRAINT IF EXISTS surge_pricing_time_slots_pkey;
ALTER TABLE IF EXISTS ONLY public.surge_pricing_service_categories DROP CONSTRAINT IF EXISTS surge_pricing_service_categories_pkey;
ALTER TABLE IF EXISTS ONLY public.surge_pricing DROP CONSTRAINT IF EXISTS surge_pricing_pkey;
ALTER TABLE IF EXISTS ONLY public.support_saved_replies DROP CONSTRAINT IF EXISTS support_saved_replies_pkey;
ALTER TABLE IF EXISTS ONLY public.subscription_plans DROP CONSTRAINT IF EXISTS subscription_plans_pkey;
ALTER TABLE IF EXISTS ONLY public.spin_wheel_segments DROP CONSTRAINT IF EXISTS spin_wheel_segments_pkey;
ALTER TABLE IF EXISTS ONLY public.spin_wheel_results DROP CONSTRAINT IF EXISTS spin_wheel_results_pkey;
ALTER TABLE IF EXISTS ONLY public.spin_wheel_configs DROP CONSTRAINT IF EXISTS spin_wheel_configs_pkey;
ALTER TABLE IF EXISTS ONLY public.social_links DROP CONSTRAINT IF EXISTS social_links_pkey;
ALTER TABLE IF EXISTS ONLY public.sharing_fare_profiles DROP CONSTRAINT IF EXISTS sharing_fare_unique;
ALTER TABLE IF EXISTS ONLY public.sharing_fare_profiles DROP CONSTRAINT IF EXISTS sharing_fare_profiles_pkey;
ALTER TABLE IF EXISTS ONLY public.shared_trip_passengers DROP CONSTRAINT IF EXISTS shared_trip_passengers_pkey;
ALTER TABLE IF EXISTS ONLY public.settings DROP CONSTRAINT IF EXISTS settings_pkey;
ALTER TABLE IF EXISTS ONLY public.sessions DROP CONSTRAINT IF EXISTS sessions_pkey;
ALTER TABLE IF EXISTS ONLY public.send_notifications DROP CONSTRAINT IF EXISTS send_notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.safety_precautions DROP CONSTRAINT IF EXISTS safety_precautions_pkey;
ALTER TABLE IF EXISTS ONLY public.safety_alerts DROP CONSTRAINT IF EXISTS safety_alerts_pkey;
ALTER TABLE IF EXISTS ONLY public.safety_alert_reasons DROP CONSTRAINT IF EXISTS safety_alert_reasons_pkey;
ALTER TABLE IF EXISTS ONLY public.roles DROP CONSTRAINT IF EXISTS roles_pkey;
ALTER TABLE IF EXISTS ONLY public.role_user DROP CONSTRAINT IF EXISTS role_user_pkey;
ALTER TABLE IF EXISTS ONLY public.reviews DROP CONSTRAINT IF EXISTS reviews_pkey;
ALTER TABLE IF EXISTS ONLY public.rejected_driver_requests DROP CONSTRAINT IF EXISTS rejected_driver_requests_pkey;
ALTER TABLE IF EXISTS ONLY public.referral_earning_settings DROP CONSTRAINT IF EXISTS referral_earning_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.referral_drivers DROP CONSTRAINT IF EXISTS referral_drivers_pkey;
ALTER TABLE IF EXISTS ONLY public.referral_customers DROP CONSTRAINT IF EXISTS referral_customers_pkey;
ALTER TABLE IF EXISTS ONLY public.recent_addresses DROP CONSTRAINT IF EXISTS recent_addresses_pkey;
ALTER TABLE IF EXISTS ONLY public.question_answers DROP CONSTRAINT IF EXISTS question_answers_pkey;
ALTER TABLE IF EXISTS ONLY public.pick_hours DROP CONSTRAINT IF EXISTS pick_hours_pkey;
ALTER TABLE IF EXISTS ONLY public.personal_access_tokens DROP CONSTRAINT IF EXISTS personal_access_tokens_pkey;
ALTER TABLE IF EXISTS ONLY public.payment_requests DROP CONSTRAINT IF EXISTS payment_requests_pkey;
ALTER TABLE IF EXISTS ONLY public.parcels DROP CONSTRAINT IF EXISTS parcels_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_weights DROP CONSTRAINT IF EXISTS parcel_weights_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_user_infomations DROP CONSTRAINT IF EXISTS parcel_user_infomations_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_refunds DROP CONSTRAINT IF EXISTS parcel_refunds_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_refund_reasons DROP CONSTRAINT IF EXISTS parcel_refund_reasons_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_refund_proofs DROP CONSTRAINT IF EXISTS parcel_refund_proofs_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_information DROP CONSTRAINT IF EXISTS parcel_information_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_fares DROP CONSTRAINT IF EXISTS parcel_fares_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_fares_parcel_weights DROP CONSTRAINT IF EXISTS parcel_fares_parcel_weights_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_categories DROP CONSTRAINT IF EXISTS parcel_categories_pkey;
ALTER TABLE IF EXISTS ONLY public.parcel_cancellation_reasons DROP CONSTRAINT IF EXISTS parcel_cancellation_reasons_pkey;
ALTER TABLE IF EXISTS ONLY public.otp_verifications DROP CONSTRAINT IF EXISTS otp_verifications_pkey;
ALTER TABLE IF EXISTS ONLY public.oauth_refresh_tokens DROP CONSTRAINT IF EXISTS oauth_refresh_tokens_pkey;
ALTER TABLE IF EXISTS ONLY public.oauth_personal_access_clients DROP CONSTRAINT IF EXISTS oauth_personal_access_clients_pkey;
ALTER TABLE IF EXISTS ONLY public.oauth_clients DROP CONSTRAINT IF EXISTS oauth_clients_pkey;
ALTER TABLE IF EXISTS ONLY public.oauth_auth_codes DROP CONSTRAINT IF EXISTS oauth_auth_codes_pkey;
ALTER TABLE IF EXISTS ONLY public.oauth_access_tokens DROP CONSTRAINT IF EXISTS oauth_access_tokens_pkey;
ALTER TABLE IF EXISTS ONLY public.notification_settings DROP CONSTRAINT IF EXISTS notification_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.newsletter_subscriptions DROP CONSTRAINT IF EXISTS newsletter_subscriptions_pkey;
ALTER TABLE IF EXISTS ONLY public.module_accesses DROP CONSTRAINT IF EXISTS module_accesses_pkey;
ALTER TABLE IF EXISTS ONLY public.migrations DROP CONSTRAINT IF EXISTS migrations_pkey;
ALTER TABLE IF EXISTS ONLY public.loyalty_points_histories DROP CONSTRAINT IF EXISTS loyalty_points_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.level_accesses DROP CONSTRAINT IF EXISTS level_accesses_pkey;
ALTER TABLE IF EXISTS ONLY public.late_return_penalty_notifications DROP CONSTRAINT IF EXISTS late_return_penalty_notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.landing_page_sections DROP CONSTRAINT IF EXISTS landing_page_sections_pkey;
ALTER TABLE IF EXISTS ONLY public.jobs DROP CONSTRAINT IF EXISTS jobs_pkey;
ALTER TABLE IF EXISTS ONLY public.job_batches DROP CONSTRAINT IF EXISTS job_batches_pkey;
ALTER TABLE IF EXISTS ONLY public.firebase_push_notifications DROP CONSTRAINT IF EXISTS firebase_push_notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.festival_offers DROP CONSTRAINT IF EXISTS festival_offers_pkey;
ALTER TABLE IF EXISTS ONLY public.fare_biddings DROP CONSTRAINT IF EXISTS fare_biddings_pkey;
ALTER TABLE IF EXISTS ONLY public.fare_bidding_logs DROP CONSTRAINT IF EXISTS fare_bidding_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.failed_jobs DROP CONSTRAINT IF EXISTS failed_jobs_pkey;
ALTER TABLE IF EXISTS ONLY public.external_configurations DROP CONSTRAINT IF EXISTS external_configurations_pkey;
ALTER TABLE IF EXISTS ONLY public.driver_time_logs DROP CONSTRAINT IF EXISTS driver_time_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.driver_subscriptions DROP CONSTRAINT IF EXISTS driver_subscriptions_pkey;
ALTER TABLE IF EXISTS ONLY public.driver_overcharge_reports DROP CONSTRAINT IF EXISTS driver_overcharge_reports_pkey;
ALTER TABLE IF EXISTS ONLY public.driver_identity_verifications DROP CONSTRAINT IF EXISTS driver_identity_verifications_pkey;
ALTER TABLE IF EXISTS ONLY public.driver_details DROP CONSTRAINT IF EXISTS driver_details_pkey;
ALTER TABLE IF EXISTS ONLY public.discount_setups DROP CONSTRAINT IF EXISTS discount_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.discount_setup_vehicle_category DROP CONSTRAINT IF EXISTS discount_setup_vehicle_category_pkey;
ALTER TABLE IF EXISTS ONLY public.customer_level_discount_setups DROP CONSTRAINT IF EXISTS customer_level_discount_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.customer_level_coupon_setups DROP CONSTRAINT IF EXISTS customer_level_coupon_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.customer_discount_setups DROP CONSTRAINT IF EXISTS customer_discount_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.customer_coupon_setups DROP CONSTRAINT IF EXISTS customer_coupon_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.coupon_setups DROP CONSTRAINT IF EXISTS coupon_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.coupon_setup_vehicle_category DROP CONSTRAINT IF EXISTS coupon_setup_vehicle_category_pkey;
ALTER TABLE IF EXISTS ONLY public.corporate_accounts DROP CONSTRAINT IF EXISTS corporate_accounts_pkey;
ALTER TABLE IF EXISTS ONLY public.corporate_accounts DROP CONSTRAINT IF EXISTS corporate_accounts_company_code_unique;
ALTER TABLE IF EXISTS ONLY public.conversation_files DROP CONSTRAINT IF EXISTS conversation_files_pkey;
ALTER TABLE IF EXISTS ONLY public.channel_users DROP CONSTRAINT IF EXISTS channel_users_pkey;
ALTER TABLE IF EXISTS ONLY public.channel_lists DROP CONSTRAINT IF EXISTS channel_lists_pkey;
ALTER TABLE IF EXISTS ONLY public.channel_conversations DROP CONSTRAINT IF EXISTS channel_conversations_pkey;
ALTER TABLE IF EXISTS ONLY public.cancellation_reasons DROP CONSTRAINT IF EXISTS cancellation_reasons_pkey;
ALTER TABLE IF EXISTS ONLY public.calls DROP CONSTRAINT IF EXISTS calls_pkey;
ALTER TABLE IF EXISTS ONLY public.call_signals DROP CONSTRAINT IF EXISTS call_signals_pkey;
ALTER TABLE IF EXISTS ONLY public.call_recordings DROP CONSTRAINT IF EXISTS call_recordings_pkey;
ALTER TABLE IF EXISTS ONLY public.cache DROP CONSTRAINT IF EXISTS cache_pkey;
ALTER TABLE IF EXISTS ONLY public.cache_locks DROP CONSTRAINT IF EXISTS cache_locks_pkey;
ALTER TABLE IF EXISTS ONLY public.business_settings DROP CONSTRAINT IF EXISTS business_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.bonus_setups DROP CONSTRAINT IF EXISTS bonus_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.bonus_setup_vehicle_category DROP CONSTRAINT IF EXISTS bonus_setup_vehicle_category_pkey;
ALTER TABLE IF EXISTS ONLY public.blogs DROP CONSTRAINT IF EXISTS blogs_pkey;
ALTER TABLE IF EXISTS ONLY public.blog_settings DROP CONSTRAINT IF EXISTS blog_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.blog_drafts DROP CONSTRAINT IF EXISTS blog_drafts_pkey;
ALTER TABLE IF EXISTS ONLY public.blog_categories DROP CONSTRAINT IF EXISTS blog_categories_pkey;
ALTER TABLE IF EXISTS ONLY public.banner_setups DROP CONSTRAINT IF EXISTS banner_setups_pkey;
ALTER TABLE IF EXISTS ONLY public.b2b_parcel_plans DROP CONSTRAINT IF EXISTS b2b_parcel_plans_plan_code_unique;
ALTER TABLE IF EXISTS ONLY public.b2b_parcel_plans DROP CONSTRAINT IF EXISTS b2b_parcel_plans_pkey;
ALTER TABLE IF EXISTS ONLY public.areas DROP CONSTRAINT IF EXISTS areas_pkey;
ALTER TABLE IF EXISTS ONLY public.area_pick_hour DROP CONSTRAINT IF EXISTS area_pick_hour_pkey;
ALTER TABLE IF EXISTS ONLY public.area_discount_setup DROP CONSTRAINT IF EXISTS area_discount_setup_pkey;
ALTER TABLE IF EXISTS ONLY public.area_coupon_setup DROP CONSTRAINT IF EXISTS area_coupon_setup_pkey;
ALTER TABLE IF EXISTS ONLY public.area_bonus_setup DROP CONSTRAINT IF EXISTS area_bonus_setup_pkey;
ALTER TABLE IF EXISTS ONLY public.app_notifications DROP CONSTRAINT IF EXISTS app_notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.ai_settings DROP CONSTRAINT IF EXISTS ai_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.admin_notifications DROP CONSTRAINT IF EXISTS admin_notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.activity_logs DROP CONSTRAINT IF EXISTS activity_logs_pkey;
ALTER TABLE IF EXISTS public.withdraw_requests ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.withdraw_methods ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.websockets_statistics_entries ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.user_level_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.user_last_locations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.user_address ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.trip_routes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.trip_request_times ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.trip_request_fees ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.trip_request_coordinates ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.time_tracks ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.time_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.temp_trip_notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.surge_pricing_time_slots ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.surge_pricing_service_categories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.shared_trip_passengers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.role_user ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.reviews ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.rejected_driver_requests ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.recent_addresses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.personal_access_tokens ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.parcel_user_infomations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.parcel_information ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.parcel_fares_parcel_weights ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.otp_verifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.oauth_personal_access_clients ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.notification_settings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.module_accesses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.migrations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.loyalty_points_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.level_accesses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.late_return_penalty_notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.landing_page_sections ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.jobs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.failed_jobs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.driver_time_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.driver_details ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.discount_setup_vehicle_category ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.coupon_setup_vehicle_category ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.conversation_files ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.channel_users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.channel_conversations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.bonus_setup_vehicle_category ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.blog_settings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.blog_drafts ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.area_pick_hour ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.area_discount_setup ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.area_coupon_setup ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.area_bonus_setup ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.app_notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.admin_notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.activity_logs ALTER COLUMN id DROP DEFAULT;
DROP TABLE IF EXISTS public.zones;
DROP TABLE IF EXISTS public.zone_wise_default_trip_fares;
DROP TABLE IF EXISTS public.zone_discount_setups;
DROP TABLE IF EXISTS public.zone_coupon_setups;
DROP SEQUENCE IF EXISTS public.withdraw_requests_id_seq;
DROP TABLE IF EXISTS public.withdraw_requests;
DROP SEQUENCE IF EXISTS public.withdraw_methods_id_seq;
DROP TABLE IF EXISTS public.withdraw_methods;
DROP SEQUENCE IF EXISTS public.websockets_statistics_entries_id_seq;
DROP TABLE IF EXISTS public.websockets_statistics_entries;
DROP TABLE IF EXISTS public.wallet_bonuses;
DROP TABLE IF EXISTS public.vehicles;
DROP TABLE IF EXISTS public.vehicle_models;
DROP TABLE IF EXISTS public.vehicle_category_zone;
DROP TABLE IF EXISTS public.vehicle_category_discount_setups;
DROP TABLE IF EXISTS public.vehicle_category_coupon_setups;
DROP TABLE IF EXISTS public.vehicle_categories;
DROP TABLE IF EXISTS public.vehicle_brands;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.user_withdraw_method_infos;
DROP TABLE IF EXISTS public.user_levels;
DROP SEQUENCE IF EXISTS public.user_level_histories_id_seq;
DROP TABLE IF EXISTS public.user_level_histories;
DROP SEQUENCE IF EXISTS public.user_last_locations_id_seq;
DROP TABLE IF EXISTS public.user_last_locations;
DROP SEQUENCE IF EXISTS public.user_address_id_seq;
DROP TABLE IF EXISTS public.user_address;
DROP TABLE IF EXISTS public.user_accounts;
DROP TABLE IF EXISTS public.trip_status;
DROP SEQUENCE IF EXISTS public.trip_status_id_seq;
DROP SEQUENCE IF EXISTS public.trip_routes_id_seq;
DROP TABLE IF EXISTS public.trip_routes;
DROP TABLE IF EXISTS public.trip_requests;
DROP SEQUENCE IF EXISTS public.trip_request_times_id_seq;
DROP TABLE IF EXISTS public.trip_request_times;
DROP SEQUENCE IF EXISTS public.trip_request_fees_id_seq;
DROP TABLE IF EXISTS public.trip_request_fees;
DROP SEQUENCE IF EXISTS public.trip_request_coordinates_id_seq;
DROP TABLE IF EXISTS public.trip_request_coordinates;
DROP TABLE IF EXISTS public.trip_fares;
DROP TABLE IF EXISTS public.transactions;
DROP SEQUENCE IF EXISTS public.time_tracks_id_seq;
DROP TABLE IF EXISTS public.time_tracks;
DROP SEQUENCE IF EXISTS public.time_logs_id_seq;
DROP TABLE IF EXISTS public.time_logs;
DROP SEQUENCE IF EXISTS public.temp_trip_notifications_id_seq;
DROP TABLE IF EXISTS public.temp_trip_notifications;
DROP TABLE IF EXISTS public.surge_pricing_zones;
DROP SEQUENCE IF EXISTS public.surge_pricing_time_slots_id_seq;
DROP TABLE IF EXISTS public.surge_pricing_time_slots;
DROP SEQUENCE IF EXISTS public.surge_pricing_service_categories_id_seq;
DROP TABLE IF EXISTS public.surge_pricing_service_categories;
DROP TABLE IF EXISTS public.surge_pricing;
DROP TABLE IF EXISTS public.support_saved_replies;
DROP TABLE IF EXISTS public.subscription_plans;
DROP TABLE IF EXISTS public.spin_wheel_segments;
DROP TABLE IF EXISTS public.spin_wheel_results;
DROP TABLE IF EXISTS public.spin_wheel_configs;
DROP TABLE IF EXISTS public.social_links;
DROP TABLE IF EXISTS public.sharing_fare_profiles;
DROP SEQUENCE IF EXISTS public.shared_trip_passengers_id_seq;
DROP TABLE IF EXISTS public.shared_trip_passengers;
DROP TABLE IF EXISTS public.settings;
DROP TABLE IF EXISTS public.sessions;
DROP TABLE IF EXISTS public.send_notifications;
DROP TABLE IF EXISTS public.safety_precautions;
DROP TABLE IF EXISTS public.safety_alerts;
DROP TABLE IF EXISTS public.safety_alert_reasons;
DROP TABLE IF EXISTS public.roles;
DROP SEQUENCE IF EXISTS public.role_user_id_seq;
DROP TABLE IF EXISTS public.role_user;
DROP SEQUENCE IF EXISTS public.reviews_id_seq;
DROP TABLE IF EXISTS public.reviews;
DROP SEQUENCE IF EXISTS public.rejected_driver_requests_id_seq;
DROP TABLE IF EXISTS public.rejected_driver_requests;
DROP TABLE IF EXISTS public.referral_earning_settings;
DROP TABLE IF EXISTS public.referral_drivers;
DROP TABLE IF EXISTS public.referral_customers;
DROP SEQUENCE IF EXISTS public.recent_addresses_id_seq;
DROP TABLE IF EXISTS public.recent_addresses;
DROP TABLE IF EXISTS public.question_answers;
DROP TABLE IF EXISTS public.pick_hours;
DROP SEQUENCE IF EXISTS public.personal_access_tokens_id_seq;
DROP TABLE IF EXISTS public.personal_access_tokens;
DROP TABLE IF EXISTS public.payment_requests;
DROP TABLE IF EXISTS public.parcels;
DROP TABLE IF EXISTS public.parcel_weights;
DROP SEQUENCE IF EXISTS public.parcel_user_infomations_id_seq;
DROP TABLE IF EXISTS public.parcel_user_infomations;
DROP TABLE IF EXISTS public.parcel_refunds;
DROP TABLE IF EXISTS public.parcel_refund_reasons;
DROP TABLE IF EXISTS public.parcel_refund_proofs;
DROP SEQUENCE IF EXISTS public.parcel_information_id_seq;
DROP TABLE IF EXISTS public.parcel_information;
DROP SEQUENCE IF EXISTS public.parcel_fares_parcel_weights_id_seq;
DROP TABLE IF EXISTS public.parcel_fares_parcel_weights;
DROP TABLE IF EXISTS public.parcel_fares;
DROP TABLE IF EXISTS public.parcel_categories;
DROP TABLE IF EXISTS public.parcel_cancellation_reasons;
DROP SEQUENCE IF EXISTS public.otp_verifications_id_seq;
DROP TABLE IF EXISTS public.otp_verifications;
DROP TABLE IF EXISTS public.oauth_refresh_tokens;
DROP SEQUENCE IF EXISTS public.oauth_personal_access_clients_id_seq;
DROP TABLE IF EXISTS public.oauth_personal_access_clients;
DROP TABLE IF EXISTS public.oauth_clients;
DROP TABLE IF EXISTS public.oauth_auth_codes;
DROP TABLE IF EXISTS public.oauth_access_tokens;
DROP SEQUENCE IF EXISTS public.notification_settings_id_seq;
DROP TABLE IF EXISTS public.notification_settings;
DROP TABLE IF EXISTS public.newsletter_subscriptions;
DROP SEQUENCE IF EXISTS public.module_accesses_id_seq;
DROP TABLE IF EXISTS public.module_accesses;
DROP TABLE IF EXISTS public.milestone_setups;
DROP SEQUENCE IF EXISTS public.migrations_id_seq;
DROP TABLE IF EXISTS public.migrations;
DROP SEQUENCE IF EXISTS public.loyalty_points_histories_id_seq;
DROP TABLE IF EXISTS public.loyalty_points_histories;
DROP SEQUENCE IF EXISTS public.level_accesses_id_seq;
DROP TABLE IF EXISTS public.level_accesses;
DROP SEQUENCE IF EXISTS public.late_return_penalty_notifications_id_seq;
DROP TABLE IF EXISTS public.late_return_penalty_notifications;
DROP SEQUENCE IF EXISTS public.landing_page_sections_id_seq;
DROP TABLE IF EXISTS public.landing_page_sections;
DROP SEQUENCE IF EXISTS public.jobs_id_seq;
DROP TABLE IF EXISTS public.jobs;
DROP TABLE IF EXISTS public.job_batches;
DROP TABLE IF EXISTS public.firebase_push_notifications;
DROP SEQUENCE IF EXISTS public.firebase_push_notifications_id_seq;
DROP TABLE IF EXISTS public.festival_offers;
DROP TABLE IF EXISTS public.fare_biddings;
DROP TABLE IF EXISTS public.fare_bidding_logs;
DROP SEQUENCE IF EXISTS public.failed_jobs_id_seq;
DROP TABLE IF EXISTS public.failed_jobs;
DROP TABLE IF EXISTS public.external_configurations;
DROP SEQUENCE IF EXISTS public.driver_time_logs_id_seq;
DROP TABLE IF EXISTS public.driver_time_logs;
DROP TABLE IF EXISTS public.driver_subscriptions;
DROP TABLE IF EXISTS public.driver_overcharge_reports;
DROP TABLE IF EXISTS public.driver_identity_verifications;
DROP SEQUENCE IF EXISTS public.driver_details_id_seq;
DROP TABLE IF EXISTS public.driver_details;
DROP TABLE IF EXISTS public.discount_setups;
DROP SEQUENCE IF EXISTS public.discount_setup_vehicle_category_id_seq;
DROP TABLE IF EXISTS public.discount_setup_vehicle_category;
DROP TABLE IF EXISTS public.customer_level_discount_setups;
DROP TABLE IF EXISTS public.customer_level_coupon_setups;
DROP TABLE IF EXISTS public.customer_discount_setups;
DROP TABLE IF EXISTS public.customer_coupon_setups;
DROP TABLE IF EXISTS public.coupon_setups;
DROP SEQUENCE IF EXISTS public.coupon_setup_vehicle_category_id_seq;
DROP TABLE IF EXISTS public.coupon_setup_vehicle_category;
DROP TABLE IF EXISTS public.corporate_accounts;
DROP SEQUENCE IF EXISTS public.conversation_files_id_seq;
DROP TABLE IF EXISTS public.conversation_files;
DROP SEQUENCE IF EXISTS public.channel_users_id_seq;
DROP TABLE IF EXISTS public.channel_users;
DROP TABLE IF EXISTS public.channel_lists;
DROP SEQUENCE IF EXISTS public.channel_conversations_id_seq;
DROP TABLE IF EXISTS public.channel_conversations;
DROP TABLE IF EXISTS public.cancellation_reasons;
DROP TABLE IF EXISTS public.calls;
DROP TABLE IF EXISTS public.call_signals;
DROP TABLE IF EXISTS public.call_recordings;
DROP TABLE IF EXISTS public.cache_locks;
DROP TABLE IF EXISTS public.cache;
DROP TABLE IF EXISTS public.business_settings;
DROP TABLE IF EXISTS public.bonus_setups;
DROP SEQUENCE IF EXISTS public.bonus_setup_vehicle_category_id_seq;
DROP TABLE IF EXISTS public.bonus_setup_vehicle_category;
DROP TABLE IF EXISTS public.blogs;
DROP SEQUENCE IF EXISTS public.blog_settings_id_seq;
DROP TABLE IF EXISTS public.blog_settings;
DROP SEQUENCE IF EXISTS public.blog_drafts_id_seq;
DROP TABLE IF EXISTS public.blog_drafts;
DROP TABLE IF EXISTS public.blog_categories;
DROP TABLE IF EXISTS public.banner_setups;
DROP TABLE IF EXISTS public.b2b_parcel_plans;
DROP TABLE IF EXISTS public.areas;
DROP SEQUENCE IF EXISTS public.area_pick_hour_id_seq;
DROP TABLE IF EXISTS public.area_pick_hour;
DROP SEQUENCE IF EXISTS public.area_discount_setup_id_seq;
DROP TABLE IF EXISTS public.area_discount_setup;
DROP SEQUENCE IF EXISTS public.area_coupon_setup_id_seq;
DROP TABLE IF EXISTS public.area_coupon_setup;
DROP SEQUENCE IF EXISTS public.area_bonus_setup_id_seq;
DROP TABLE IF EXISTS public.area_bonus_setup;
DROP TABLE IF EXISTS public.applied_coupons;
DROP SEQUENCE IF EXISTS public.app_notifications_id_seq;
DROP TABLE IF EXISTS public.app_notifications;
DROP TABLE IF EXISTS public.ai_settings;
DROP SEQUENCE IF EXISTS public.admin_notifications_id_seq;
DROP TABLE IF EXISTS public.admin_notifications;
DROP SEQUENCE IF EXISTS public.activity_logs_id_seq;
DROP TABLE IF EXISTS public.activity_logs;
DROP EXTENSION IF EXISTS postgis;
--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs (
    id bigint NOT NULL,
    logable_id character(36) NOT NULL,
    logable_type character varying(255) NOT NULL,
    edited_by character varying(255) NOT NULL,
    before text,
    after text,
    user_type character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- Name: admin_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_notifications (
    id bigint NOT NULL,
    model character varying(255) NOT NULL,
    model_id character(36) NOT NULL,
    message character varying(255) NOT NULL,
    is_seen boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: admin_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_notifications_id_seq OWNED BY public.admin_notifications.id;


--
-- Name: ai_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_settings (
    id character(36) NOT NULL,
    ai_name character varying(255) NOT NULL,
    base_url character varying(255) DEFAULT NULL::character varying,
    api_key text,
    organization_id character varying(255) DEFAULT NULL::character varying,
    status smallint DEFAULT '0'::smallint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: app_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_notifications (
    id bigint NOT NULL,
    user_id character(36) NOT NULL,
    ride_request_id character(36) DEFAULT NULL::bpchar,
    title character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    type character varying(255) DEFAULT NULL::character varying,
    notification_type character varying(255) DEFAULT NULL::character varying,
    action character varying(255) DEFAULT NULL::character varying,
    is_read boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: app_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.app_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.app_notifications_id_seq OWNED BY public.app_notifications.id;


--
-- Name: applied_coupons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applied_coupons (
    id character(36) NOT NULL,
    coupon_setup_id character(36) NOT NULL,
    user_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: area_bonus_setup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.area_bonus_setup (
    id bigint NOT NULL,
    area_id character(36) NOT NULL,
    bonus_setup_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: area_bonus_setup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.area_bonus_setup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: area_bonus_setup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.area_bonus_setup_id_seq OWNED BY public.area_bonus_setup.id;


--
-- Name: area_coupon_setup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.area_coupon_setup (
    id bigint NOT NULL,
    area_id character(36) NOT NULL,
    coupon_setup_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: area_coupon_setup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.area_coupon_setup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: area_coupon_setup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.area_coupon_setup_id_seq OWNED BY public.area_coupon_setup.id;


--
-- Name: area_discount_setup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.area_discount_setup (
    id bigint NOT NULL,
    area_id character(36) NOT NULL,
    discount_setup_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: area_discount_setup_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.area_discount_setup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: area_discount_setup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.area_discount_setup_id_seq OWNED BY public.area_discount_setup.id;


--
-- Name: area_pick_hour; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.area_pick_hour (
    id bigint NOT NULL,
    area_id character(36) NOT NULL,
    pick_hour_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: area_pick_hour_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.area_pick_hour_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: area_pick_hour_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.area_pick_hour_id_seq OWNED BY public.area_pick_hour.id;


--
-- Name: areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.areas (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    radius double precision NOT NULL,
    zone_id character(36) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: b2b_parcel_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.b2b_parcel_plans (
    id character varying(255) NOT NULL,
    plan_name character varying(255) NOT NULL,
    plan_code character varying(255) NOT NULL,
    description text,
    monthly_fee numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    included_deliveries integer DEFAULT 0 NOT NULL,
    per_delivery_rate numeric(8,2) DEFAULT '0'::numeric NOT NULL,
    discount_percent numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    priority_pickup boolean DEFAULT false NOT NULL,
    dedicated_support boolean DEFAULT false NOT NULL,
    api_access boolean DEFAULT false NOT NULL,
    max_weight_kg integer DEFAULT 50 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    deleted_at timestamp(0) without time zone
);


--
-- Name: banner_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.banner_setups (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    time_period character varying(255) DEFAULT NULL::character varying,
    display_position character varying(255) DEFAULT NULL::character varying,
    redirect_link character varying(255) DEFAULT NULL::character varying,
    banner_group character varying(255) DEFAULT NULL::character varying,
    start_date date,
    end_date date,
    image character varying(255) DEFAULT NULL::character varying,
    total_redirection numeric(8,2) DEFAULT 0.00 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: blog_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_categories (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    status smallint DEFAULT '1'::smallint NOT NULL,
    click_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: blog_drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_drafts (
    id bigint NOT NULL,
    blog_id character(36) NOT NULL,
    blog_category_id character(36) DEFAULT NULL::bpchar,
    writer character varying(255) DEFAULT NULL::character varying,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    thumbnail character varying(255) NOT NULL,
    published_at date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: blog_drafts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blog_drafts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blog_drafts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blog_drafts_id_seq OWNED BY public.blog_drafts.id;


--
-- Name: blog_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_settings (
    id bigint NOT NULL,
    key_name character varying(191) NOT NULL,
    value json NOT NULL,
    settings_type character varying(191) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: blog_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blog_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blog_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blog_settings_id_seq OWNED BY public.blog_settings.id;


--
-- Name: blogs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blogs (
    id character(36) NOT NULL,
    readable_id integer NOT NULL,
    slug character varying(255) NOT NULL,
    blog_category_id character(36) DEFAULT NULL::bpchar,
    writer character varying(255) DEFAULT NULL::character varying,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    thumbnail character varying(255) NOT NULL,
    status smallint DEFAULT '1'::smallint NOT NULL,
    click_count integer DEFAULT 0 NOT NULL,
    meta_title character varying(255) DEFAULT NULL::character varying,
    meta_description character varying(255) DEFAULT NULL::character varying,
    meta_image character varying(255) NOT NULL,
    is_drafted smallint DEFAULT '0'::smallint NOT NULL,
    is_published smallint DEFAULT '0'::smallint NOT NULL,
    published_at date NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: bonus_setup_vehicle_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bonus_setup_vehicle_category (
    id bigint NOT NULL,
    bonus_setup_id character(36) NOT NULL,
    vehicle_category_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: bonus_setup_vehicle_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bonus_setup_vehicle_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bonus_setup_vehicle_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bonus_setup_vehicle_category_id_seq OWNED BY public.bonus_setup_vehicle_category.id;


--
-- Name: bonus_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bonus_setups (
    id character(36) NOT NULL,
    name character varying(255) DEFAULT NULL::character varying,
    description text,
    user_id character(36) DEFAULT NULL::bpchar,
    user_level_id character(36) DEFAULT NULL::bpchar,
    min_trip_amount numeric(8,2) DEFAULT 0.00 NOT NULL,
    max_bonus numeric(8,2) DEFAULT 0.00 NOT NULL,
    bonus numeric(8,2) DEFAULT 0.00 NOT NULL,
    amount_type character varying(15) DEFAULT 'percentage'::character varying NOT NULL,
    bonus_type character varying(15) DEFAULT 'default'::character varying NOT NULL,
    "limit" integer,
    start_date date,
    end_date date,
    rules character varying(255) DEFAULT NULL::character varying,
    total_used numeric(8,2) DEFAULT 0.00 NOT NULL,
    total_amount numeric(8,2) DEFAULT 0.00 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: business_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_settings (
    id character(36) NOT NULL,
    key_name character varying(191) NOT NULL,
    value text NOT NULL,
    settings_type character varying(191) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


--
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


--
-- Name: call_recordings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.call_recordings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    call_id uuid NOT NULL,
    user_type character varying(20) NOT NULL,
    user_id uuid NOT NULL,
    file_path character varying(500) NOT NULL,
    file_size integer DEFAULT 0,
    duration_seconds integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: call_signals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.call_signals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    call_id uuid NOT NULL,
    sender_type character varying(20) NOT NULL,
    sender_id uuid NOT NULL,
    signal_type character varying(20) NOT NULL,
    payload jsonb NOT NULL,
    consumed_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: calls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calls (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    trip_request_id uuid,
    caller_type character varying(20) DEFAULT 'customer'::character varying NOT NULL,
    caller_id uuid NOT NULL,
    callee_type character varying(20) DEFAULT 'driver'::character varying NOT NULL,
    callee_id uuid NOT NULL,
    call_type character varying(20) DEFAULT 'trip'::character varying NOT NULL,
    status character varying(20) DEFAULT 'initiated'::character varying NOT NULL,
    started_at timestamp without time zone,
    ended_at timestamp without time zone,
    duration_seconds integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: cancellation_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cancellation_reasons (
    id character(36) NOT NULL,
    title text NOT NULL,
    cancellation_type character varying(255) NOT NULL,
    user_type character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: channel_conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.channel_conversations (
    id bigint NOT NULL,
    channel_id character(36) NOT NULL,
    user_id character(36) NOT NULL,
    message text,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    convable_type character varying(255) DEFAULT NULL::character varying,
    convable_id character(36) DEFAULT NULL::bpchar,
    is_read boolean DEFAULT true NOT NULL
);


--
-- Name: channel_conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.channel_conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: channel_conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.channel_conversations_id_seq OWNED BY public.channel_conversations.id;


--
-- Name: channel_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.channel_lists (
    id character(36) NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    channelable_type character varying(255) DEFAULT NULL::character varying,
    channelable_id character(36) DEFAULT NULL::bpchar
);


--
-- Name: channel_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.channel_users (
    id bigint NOT NULL,
    channel_id character(36) NOT NULL,
    user_id character(36) NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: channel_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.channel_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: channel_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.channel_users_id_seq OWNED BY public.channel_users.id;


--
-- Name: conversation_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_files (
    id bigint NOT NULL,
    conversation_id character(36) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_type character varying(255) NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: conversation_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_files_id_seq OWNED BY public.conversation_files.id;


--
-- Name: corporate_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.corporate_accounts (
    id character varying(255) NOT NULL,
    company_name character varying(255) NOT NULL,
    company_code character varying(255) NOT NULL,
    contact_person character varying(255) NOT NULL,
    contact_email character varying(255) NOT NULL,
    contact_phone character varying(255) NOT NULL,
    gst_number character varying(255),
    address character varying(255),
    city character varying(255),
    state character varying(255),
    plan_type character varying(255) DEFAULT 'basic'::character varying NOT NULL,
    discount_percent numeric(5,2) DEFAULT '0'::numeric NOT NULL,
    credit_limit numeric(12,2) DEFAULT '0'::numeric NOT NULL,
    used_credit numeric(12,2) DEFAULT '0'::numeric NOT NULL,
    billing_cycle character varying(255) DEFAULT 'monthly'::character varying NOT NULL,
    ride_allowed boolean DEFAULT true NOT NULL,
    parcel_allowed boolean DEFAULT false NOT NULL,
    max_employees integer DEFAULT 50 NOT NULL,
    active_employees integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    contract_start date,
    contract_end date,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    deleted_at timestamp(0) without time zone,
    CONSTRAINT corporate_accounts_billing_cycle_check CHECK (((billing_cycle)::text = ANY ((ARRAY['monthly'::character varying, 'quarterly'::character varying, 'annual'::character varying])::text[]))),
    CONSTRAINT corporate_accounts_plan_type_check CHECK (((plan_type)::text = ANY ((ARRAY['basic'::character varying, 'standard'::character varying, 'premium'::character varying, 'enterprise'::character varying])::text[])))
);


--
-- Name: coupon_setup_vehicle_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coupon_setup_vehicle_category (
    id bigint NOT NULL,
    coupon_setup_id character(36) NOT NULL,
    vehicle_category_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: coupon_setup_vehicle_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coupon_setup_vehicle_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coupon_setup_vehicle_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coupon_setup_vehicle_category_id_seq OWNED BY public.coupon_setup_vehicle_category.id;


--
-- Name: coupon_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coupon_setups (
    id character(36) NOT NULL,
    name character varying(50) DEFAULT NULL::character varying,
    description character varying(255) DEFAULT NULL::character varying,
    zone_coupon_type character varying(255) DEFAULT 'custom'::character varying NOT NULL,
    customer_level_coupon_type character varying(255) DEFAULT 'custom'::character varying NOT NULL,
    customer_coupon_type character varying(255) DEFAULT 'custom'::character varying NOT NULL,
    category_coupon_type text NOT NULL,
    min_trip_amount numeric(8,2) DEFAULT 0.00 NOT NULL,
    max_coupon_amount numeric(8,2) DEFAULT 0.00 NOT NULL,
    coupon numeric(8,2) DEFAULT 0.00 NOT NULL,
    amount_type character varying(15) DEFAULT 'percentage'::character varying NOT NULL,
    coupon_type character varying(15) DEFAULT 'default'::character varying NOT NULL,
    coupon_code character varying(255) DEFAULT NULL::character varying,
    "limit" integer,
    start_date date,
    end_date date,
    total_used numeric(8,2) DEFAULT 0.00 NOT NULL,
    total_amount numeric(8,2) DEFAULT 0.00 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: customer_coupon_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_coupon_setups (
    user_id character(36) NOT NULL,
    coupon_setup_id character(36) NOT NULL,
    limit_per_user integer DEFAULT 0 NOT NULL
);


--
-- Name: customer_discount_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_discount_setups (
    user_id character(36) NOT NULL,
    discount_setup_id character(36) NOT NULL,
    limit_per_user integer DEFAULT 0 NOT NULL
);


--
-- Name: customer_level_coupon_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_level_coupon_setups (
    user_level_id character(36) NOT NULL,
    coupon_setup_id character(36) NOT NULL
);


--
-- Name: customer_level_discount_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_level_discount_setups (
    user_level_id character(36) NOT NULL,
    discount_setup_id character(36) NOT NULL
);


--
-- Name: discount_setup_vehicle_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discount_setup_vehicle_category (
    id bigint NOT NULL,
    discount_setup_id character(36) NOT NULL,
    vehicle_category_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: discount_setup_vehicle_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discount_setup_vehicle_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discount_setup_vehicle_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discount_setup_vehicle_category_id_seq OWNED BY public.discount_setup_vehicle_category.id;


--
-- Name: discount_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discount_setups (
    id character(36) NOT NULL,
    title character varying(255) NOT NULL,
    short_description text NOT NULL,
    terms_conditions text NOT NULL,
    image text NOT NULL,
    zone_discount_type character varying(255) DEFAULT 'custom'::character varying NOT NULL,
    customer_level_discount_type character varying(255) DEFAULT 'custom'::character varying NOT NULL,
    customer_discount_type character varying(255) DEFAULT 'custom'::character varying NOT NULL,
    module_discount_type text NOT NULL,
    discount_amount_type character varying(255) NOT NULL,
    limit_per_user integer DEFAULT 0 NOT NULL,
    discount_amount double precision NOT NULL,
    max_discount_amount double precision DEFAULT '0'::double precision NOT NULL,
    min_trip_amount double precision NOT NULL,
    start_date date,
    end_date date,
    total_used integer DEFAULT 0 NOT NULL,
    total_amount double precision DEFAULT '0'::double precision NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: driver_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_details (
    id bigint NOT NULL,
    user_id character(36) NOT NULL,
    is_online character varying(255) DEFAULT '0'::character varying NOT NULL,
    availability_status character varying(255) DEFAULT 'unavailable'::character varying NOT NULL,
    online time without time zone,
    offline time without time zone,
    online_time double precision DEFAULT '0'::double precision NOT NULL,
    accepted time without time zone,
    completed time without time zone,
    start_driving time without time zone,
    on_driving_time double precision DEFAULT '0'::double precision NOT NULL,
    idle_time double precision DEFAULT '0'::double precision NOT NULL,
    service json,
    ride_count integer DEFAULT 0 NOT NULL,
    parcel_count integer DEFAULT 0 NOT NULL,
    is_verified smallint DEFAULT '0'::smallint NOT NULL,
    base_image character varying(255) DEFAULT NULL::character varying,
    verified_image character varying(255) DEFAULT NULL::character varying,
    is_suspended smallint DEFAULT '0'::smallint NOT NULL,
    suspend_reason character varying(255) DEFAULT NULL::character varying,
    trigger_verification_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: driver_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_details_id_seq OWNED BY public.driver_details.id;


--
-- Name: driver_identity_verifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_identity_verifications (
    id character(36) NOT NULL,
    driver_id character(36) NOT NULL,
    attempt_details json,
    current_status character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: driver_overcharge_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_overcharge_reports (
    id character varying DEFAULT (gen_random_uuid())::character varying NOT NULL,
    trip_request_id character varying NOT NULL,
    customer_id character varying NOT NULL,
    driver_id character varying NOT NULL,
    reported_amount numeric DEFAULT 0,
    description text,
    status character varying DEFAULT 'pending'::character varying,
    admin_action character varying,
    admin_notes text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: driver_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    driver_id uuid NOT NULL,
    plan_id uuid,
    plan_name character varying(100),
    duration_type character varying(20) DEFAULT 'monthly'::character varying NOT NULL,
    price_paid numeric(10,2) DEFAULT 0 NOT NULL,
    max_rides integer DEFAULT 0 NOT NULL,
    rides_used integer DEFAULT 0 NOT NULL,
    is_locked boolean DEFAULT false NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    started_at timestamp without time zone,
    expires_at timestamp without time zone,
    payment_transaction_id uuid,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    gst_amount numeric(10,2) DEFAULT 0
);


--
-- Name: driver_time_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver_time_logs (
    id bigint NOT NULL,
    driver_id character(36) NOT NULL,
    date date NOT NULL,
    online time without time zone,
    offline time without time zone,
    online_time double precision DEFAULT '0'::double precision NOT NULL,
    accepted time without time zone,
    completed time without time zone,
    start_driving time without time zone,
    on_driving_time double precision DEFAULT '0'::double precision NOT NULL,
    idle_time double precision DEFAULT '0'::double precision NOT NULL,
    on_time_completed character varying(255) DEFAULT '0'::character varying,
    late_completed character varying(255) DEFAULT '0'::character varying,
    late_pickup character varying(255) DEFAULT '0'::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: driver_time_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.driver_time_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: driver_time_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.driver_time_logs_id_seq OWNED BY public.driver_time_logs.id;


--
-- Name: external_configurations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_configurations (
    id character(36) NOT NULL,
    key character varying(191) NOT NULL,
    value json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: fare_bidding_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fare_bidding_logs (
    id character(36) NOT NULL,
    trip_request_id character(36) DEFAULT NULL::bpchar,
    driver_id character(36) DEFAULT NULL::bpchar,
    customer_id character(36) DEFAULT NULL::bpchar,
    bid_fare numeric(8,2) DEFAULT NULL::numeric,
    is_ignored boolean DEFAULT false NOT NULL,
    created_at character varying(255) DEFAULT NULL::character varying,
    updated_at character varying(255) DEFAULT NULL::character varying
);


--
-- Name: fare_biddings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fare_biddings (
    id character(36) NOT NULL,
    trip_request_id character(36) NOT NULL,
    driver_id character(36) NOT NULL,
    customer_id character(36) NOT NULL,
    bid_fare numeric(8,2) NOT NULL,
    is_ignored boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: festival_offers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.festival_offers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    sharing_type character varying(20),
    zone_id character(36),
    vehicle_category_id character(36),
    offer_type character varying(30) DEFAULT 'discount_percent'::character varying NOT NULL,
    offer_value numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    max_discount_amount numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    min_fare_amount numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    max_uses_total integer DEFAULT 0 NOT NULL,
    max_uses_per_user integer DEFAULT 1 NOT NULL,
    current_uses integer DEFAULT 0 NOT NULL,
    starts_at timestamp(0) without time zone NOT NULL,
    ends_at timestamp(0) without time zone NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    banner_image character varying(255),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: firebase_push_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.firebase_push_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: firebase_push_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.firebase_push_notifications (
    id bigint DEFAULT nextval('public.firebase_push_notifications_id_seq'::regclass) NOT NULL,
    name character varying(191) NOT NULL,
    value character varying(191) DEFAULT NULL::character varying,
    dynamic_values json,
    status boolean DEFAULT false NOT NULL,
    type character varying(255) NOT NULL,
    "group" character varying(255) NOT NULL,
    action character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: landing_page_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.landing_page_sections (
    id bigint NOT NULL,
    key_name character varying(191) NOT NULL,
    value json NOT NULL,
    settings_type character varying(191) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: landing_page_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.landing_page_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landing_page_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.landing_page_sections_id_seq OWNED BY public.landing_page_sections.id;


--
-- Name: late_return_penalty_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.late_return_penalty_notifications (
    id bigint NOT NULL,
    trip_request_id character(36) NOT NULL,
    sending_notification_at timestamp without time zone NOT NULL,
    is_notification_sent boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: late_return_penalty_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.late_return_penalty_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: late_return_penalty_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.late_return_penalty_notifications_id_seq OWNED BY public.late_return_penalty_notifications.id;


--
-- Name: level_accesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.level_accesses (
    id bigint NOT NULL,
    level_id character(36) NOT NULL,
    user_type character varying(50) NOT NULL,
    bid boolean DEFAULT false NOT NULL,
    see_destination boolean DEFAULT false NOT NULL,
    see_subtotal boolean DEFAULT false NOT NULL,
    see_level boolean DEFAULT false NOT NULL,
    create_hire_request boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: level_accesses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.level_accesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: level_accesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.level_accesses_id_seq OWNED BY public.level_accesses.id;


--
-- Name: loyalty_points_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loyalty_points_histories (
    id bigint NOT NULL,
    user_id character(36) DEFAULT NULL::bpchar,
    model character varying(255) NOT NULL,
    model_id character(36) DEFAULT NULL::bpchar,
    points double precision NOT NULL,
    type character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: loyalty_points_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loyalty_points_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loyalty_points_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loyalty_points_histories_id_seq OWNED BY public.loyalty_points_histories.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: milestone_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.milestone_setups (
    id character(36) NOT NULL,
    name character varying(191) NOT NULL,
    description text NOT NULL,
    customer_id character(36) DEFAULT NULL::bpchar,
    customer_level_id character(36) DEFAULT NULL::bpchar,
    driver_id character(36) DEFAULT NULL::bpchar,
    driver_level_id character(36) DEFAULT NULL::bpchar,
    thumbnail character varying(50) NOT NULL,
    banner character varying(50) NOT NULL,
    reward_type character varying(15) NOT NULL,
    reward_amount numeric(30,2) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    challenge_type character varying(15) NOT NULL,
    target_count numeric(5,2) NOT NULL,
    referral_code character varying(50) DEFAULT NULL::character varying,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: module_accesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.module_accesses (
    id bigint NOT NULL,
    user_id character(36) NOT NULL,
    role_id character(36) NOT NULL,
    module_name character varying(255) NOT NULL,
    view boolean DEFAULT false NOT NULL,
    add boolean DEFAULT false NOT NULL,
    update boolean DEFAULT false NOT NULL,
    delete boolean DEFAULT false NOT NULL,
    log boolean DEFAULT false NOT NULL,
    export boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: module_accesses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.module_accesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: module_accesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.module_accesses_id_seq OWNED BY public.module_accesses.id;


--
-- Name: newsletter_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.newsletter_subscriptions (
    id character(36) NOT NULL,
    email character varying(255) NOT NULL,
    status smallint DEFAULT '1'::smallint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: notification_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_settings (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    push boolean DEFAULT false NOT NULL,
    email boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: notification_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_settings_id_seq OWNED BY public.notification_settings.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    id character varying(100) NOT NULL,
    user_id character(36) DEFAULT NULL::bpchar,
    client_id character(36) NOT NULL,
    name character varying(255) DEFAULT NULL::character varying,
    scopes text,
    revoked boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    expires_at timestamp without time zone
);


--
-- Name: oauth_auth_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_auth_codes (
    id character varying(100) NOT NULL,
    user_id bigint NOT NULL,
    client_id character(36) NOT NULL,
    scopes text,
    revoked boolean NOT NULL,
    expires_at timestamp without time zone
);


--
-- Name: oauth_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_clients (
    id character(36) NOT NULL,
    user_id bigint,
    name character varying(255) NOT NULL,
    secret character varying(100) DEFAULT NULL::character varying,
    provider character varying(255) DEFAULT NULL::character varying,
    redirect text NOT NULL,
    personal_access_client boolean NOT NULL,
    password_client boolean NOT NULL,
    revoked boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: oauth_personal_access_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_personal_access_clients (
    id bigint NOT NULL,
    client_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: oauth_personal_access_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_personal_access_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_personal_access_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_personal_access_clients_id_seq OWNED BY public.oauth_personal_access_clients.id;


--
-- Name: oauth_refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_refresh_tokens (
    id character varying(100) NOT NULL,
    access_token_id character varying(100) NOT NULL,
    revoked boolean NOT NULL,
    expires_at timestamp without time zone
);


--
-- Name: otp_verifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otp_verifications (
    id bigint NOT NULL,
    phone_or_email character varying(255) NOT NULL,
    otp character varying(255) NOT NULL,
    is_temp_blocked boolean DEFAULT false NOT NULL,
    expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    failed_attempt integer DEFAULT 0 NOT NULL,
    blocked_at timestamp without time zone
);


--
-- Name: otp_verifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.otp_verifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: otp_verifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.otp_verifications_id_seq OWNED BY public.otp_verifications.id;


--
-- Name: parcel_cancellation_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_cancellation_reasons (
    id character(36) NOT NULL,
    title text NOT NULL,
    cancellation_type character varying(255) NOT NULL,
    user_type character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parcel_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_categories (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    description text NOT NULL,
    image character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parcel_fares; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_fares (
    id character(36) NOT NULL,
    zone_id character(36) DEFAULT NULL::bpchar,
    base_fare numeric(8,2) NOT NULL,
    return_fee double precision DEFAULT '0'::double precision NOT NULL,
    cancellation_fee double precision DEFAULT '0'::double precision NOT NULL,
    base_fare_per_km numeric(8,2) NOT NULL,
    cancellation_fee_percent numeric(8,2) NOT NULL,
    min_cancellation_fee numeric(8,2) NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    per_minute_rate numeric(8,2) DEFAULT '0'::numeric NOT NULL,
    minimum_fare numeric(8,2) DEFAULT '0'::numeric NOT NULL,
    pickup_charge_per_km double precision DEFAULT '0'::double precision NOT NULL,
    pickup_free_distance double precision DEFAULT '0.5'::double precision NOT NULL,
    waiting_fee_per_min double precision DEFAULT '0'::double precision NOT NULL,
    vehicle_category_id character(36),
    vehicle_category_name character varying(255)
);


--
-- Name: parcel_fares_parcel_weights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_fares_parcel_weights (
    id bigint NOT NULL,
    parcel_fare_id character(36) NOT NULL,
    parcel_weight_id character(36) NOT NULL,
    parcel_category_id character(36) NOT NULL,
    base_fare double precision DEFAULT '0'::double precision NOT NULL,
    return_fee double precision DEFAULT '0'::double precision NOT NULL,
    cancellation_fee double precision DEFAULT '0'::double precision NOT NULL,
    fare_per_km numeric(8,2) NOT NULL,
    zone_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    per_minute_rate numeric(8,2) DEFAULT '0'::numeric NOT NULL,
    minimum_fare numeric(8,2) DEFAULT '0'::numeric NOT NULL
);


--
-- Name: parcel_fares_parcel_weights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parcel_fares_parcel_weights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parcel_fares_parcel_weights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parcel_fares_parcel_weights_id_seq OWNED BY public.parcel_fares_parcel_weights.id;


--
-- Name: parcel_information; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_information (
    id bigint NOT NULL,
    parcel_category_id character(36) NOT NULL,
    trip_request_id character(36) NOT NULL,
    payer character varying(255) DEFAULT NULL::character varying,
    weight double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parcel_information_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parcel_information_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parcel_information_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parcel_information_id_seq OWNED BY public.parcel_information.id;


--
-- Name: parcel_refund_proofs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_refund_proofs (
    id character(36) NOT NULL,
    parcel_refund_id character(36) NOT NULL,
    attachment character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parcel_refund_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_refund_reasons (
    id character(36) NOT NULL,
    title text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parcel_refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_refunds (
    id character(36) NOT NULL,
    readable_id character varying(255) DEFAULT NULL::character varying,
    trip_request_id character(36) NOT NULL,
    coupon_setup_id character(36) DEFAULT NULL::bpchar,
    parcel_approximate_price numeric(23,6) DEFAULT 0.000000 NOT NULL,
    refund_amount_by_admin numeric(23,6) DEFAULT 0.000000 NOT NULL,
    reason character varying(255) DEFAULT NULL::character varying,
    approval_note character varying(255) DEFAULT NULL::character varying,
    deny_note character varying(255) DEFAULT NULL::character varying,
    note character varying(255) DEFAULT NULL::character varying,
    customer_note character varying(255) DEFAULT NULL::character varying,
    refund_method character varying(255) DEFAULT NULL::character varying,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parcel_user_infomations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_user_infomations (
    id bigint NOT NULL,
    trip_request_id character(36) NOT NULL,
    contact_number character varying(20) NOT NULL,
    name character varying(255) DEFAULT NULL::character varying,
    address character varying(255) DEFAULT NULL::character varying,
    user_type character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parcel_user_infomations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parcel_user_infomations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parcel_user_infomations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parcel_user_infomations_id_seq OWNED BY public.parcel_user_infomations.id;


--
-- Name: parcel_weights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcel_weights (
    id character(36) NOT NULL,
    min_weight numeric(10,2) DEFAULT 0.00 NOT NULL,
    max_weight numeric(10,2) DEFAULT 0.00 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: parcels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parcels (
    id character(36) NOT NULL,
    trip_request_id character(36) DEFAULT NULL::bpchar,
    sender_person_name character varying(255) DEFAULT NULL::character varying,
    sender_person_phone character varying(255) DEFAULT NULL::character varying,
    sender_address character varying(255) DEFAULT NULL::character varying,
    receiver_person_name character varying(255) DEFAULT NULL::character varying,
    receiver_person_phone character varying(255) DEFAULT NULL::character varying,
    receiver_address character varying(255) DEFAULT NULL::character varying,
    parcel_category_id character(36) DEFAULT NULL::bpchar,
    parcel_weight_id character(36) DEFAULT NULL::bpchar,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: payment_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_requests (
    id character(36) NOT NULL,
    payer_id character varying(64) DEFAULT NULL::character varying,
    receiver_id character varying(64) DEFAULT NULL::character varying,
    payment_amount numeric(24,2) DEFAULT 0.00 NOT NULL,
    gateway_callback_url character varying(191) DEFAULT NULL::character varying,
    hook character varying(100) DEFAULT NULL::character varying,
    transaction_id character varying(100) DEFAULT NULL::character varying,
    currency_code character varying(20) DEFAULT 'USD'::character varying NOT NULL,
    payment_method character varying(50) DEFAULT NULL::character varying,
    additional_data text,
    is_paid boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    payer_information text,
    external_redirect_link character varying(255) DEFAULT NULL::character varying,
    receiver_information text,
    attribute_id character varying(64) DEFAULT NULL::character varying,
    attribute character varying(255) DEFAULT NULL::character varying,
    payment_platform character varying(255) DEFAULT NULL::character varying
);


--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- Name: pick_hours; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pick_hours (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    duration_type character varying(255) DEFAULT NULL::character varying,
    extra_charge integer,
    start_date date,
    end_date date,
    start_time time without time zone,
    end_time time without time zone,
    week_days text,
    zone_id character(36) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: question_answers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_answers (
    id character(36) NOT NULL,
    question character varying(255) NOT NULL,
    answer text NOT NULL,
    question_answer_for character varying(255) DEFAULT 'driver'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: recent_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recent_addresses (
    id bigint NOT NULL,
    user_id character(36) DEFAULT NULL::bpchar,
    zone_id character(36) DEFAULT NULL::bpchar,
    pickup_coordinates point,
    pickup_address character varying(255) DEFAULT NULL::character varying,
    destination_coordinates point,
    destination_address character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: recent_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recent_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recent_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recent_addresses_id_seq OWNED BY public.recent_addresses.id;


--
-- Name: referral_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referral_customers (
    id character(36) NOT NULL,
    customer_id character(36) NOT NULL,
    ref_by character(36) NOT NULL,
    ref_by_earning_amount double precision DEFAULT '0'::double precision NOT NULL,
    customer_discount_amount double precision DEFAULT '0'::double precision NOT NULL,
    customer_discount_amount_type character varying(255) DEFAULT NULL::character varying,
    customer_discount_validity integer DEFAULT 0 NOT NULL,
    customer_discount_validity_type character varying(255) DEFAULT NULL::character varying,
    is_used boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: referral_drivers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referral_drivers (
    id character(36) NOT NULL,
    driver_id character(36) NOT NULL,
    ref_by character(36) NOT NULL,
    ref_by_earning_amount double precision DEFAULT '0'::double precision NOT NULL,
    driver_earning_amount double precision DEFAULT '0'::double precision NOT NULL,
    is_used boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: referral_earning_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referral_earning_settings (
    id character(36) NOT NULL,
    key_name character varying(191) NOT NULL,
    value json NOT NULL,
    settings_type character varying(191) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: rejected_driver_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rejected_driver_requests (
    id bigint NOT NULL,
    trip_request_id character(36) NOT NULL,
    user_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: rejected_driver_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rejected_driver_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rejected_driver_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rejected_driver_requests_id_seq OWNED BY public.rejected_driver_requests.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id bigint NOT NULL,
    trip_request_id character(36) DEFAULT NULL::bpchar,
    given_by character(36) DEFAULT NULL::bpchar,
    received_by character(36) DEFAULT NULL::bpchar,
    trip_type character varying(255) DEFAULT NULL::character varying,
    rating integer DEFAULT 1 NOT NULL,
    feedback text,
    images character varying(255) DEFAULT NULL::character varying,
    is_saved boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: role_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_user (
    id bigint NOT NULL,
    role_id character(36) NOT NULL,
    user_id character(36) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: role_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.role_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.role_user_id_seq OWNED BY public.role_user.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id character(36) NOT NULL,
    readable_id integer,
    name character varying(255) NOT NULL,
    modules text NOT NULL,
    is_active character varying(255) DEFAULT '1'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: safety_alert_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.safety_alert_reasons (
    id character(36) NOT NULL,
    reason character varying(255) NOT NULL,
    reason_for_whom character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: safety_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.safety_alerts (
    id character(36) NOT NULL,
    trip_request_id character(36) NOT NULL,
    sent_by character(36) NOT NULL,
    reason json,
    comment text,
    alert_location text NOT NULL,
    resolved_location text,
    number_of_alert integer DEFAULT 1 NOT NULL,
    resolved_by character(36) DEFAULT NULL::bpchar,
    trip_status_when_make_alert character varying(255) NOT NULL,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: safety_precautions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.safety_precautions (
    id character(36) NOT NULL,
    for_whom json NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: send_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.send_notifications (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) DEFAULT NULL::character varying,
    targeted_users json NOT NULL,
    image text,
    is_active smallint DEFAULT '1'::smallint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    user_id character varying(36),
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id character(36) NOT NULL,
    key_name character varying(191) DEFAULT NULL::character varying,
    live_values text,
    test_values text,
    settings_type character varying(255) DEFAULT NULL::character varying,
    mode character varying(20) DEFAULT 'live'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    additional_data text
);


--
-- Name: shared_trip_passengers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shared_trip_passengers (
    id bigint NOT NULL,
    trip_request_id character varying(50) NOT NULL,
    shared_group_id character varying(50) NOT NULL,
    user_id character varying(50) NOT NULL,
    seats_booked integer DEFAULT 1 NOT NULL,
    otp character varying(6),
    otp_verified boolean DEFAULT false NOT NULL,
    is_picked_up boolean DEFAULT false NOT NULL,
    is_dropped_off boolean DEFAULT false NOT NULL,
    pickup_lat numeric(15,8),
    pickup_lng numeric(15,8),
    pickup_address character varying(255),
    drop_lat numeric(15,8),
    drop_lng numeric(15,8),
    drop_address character varying(255),
    fare_amount numeric(23,2) DEFAULT '0'::numeric NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    distance_km numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    picked_up_at timestamp(0) without time zone,
    dropped_off_at timestamp(0) without time zone,
    cancelled_at timestamp without time zone,
    sharing_type character varying(20)
);


--
-- Name: shared_trip_passengers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shared_trip_passengers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shared_trip_passengers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shared_trip_passengers_id_seq OWNED BY public.shared_trip_passengers.id;


--
-- Name: sharing_fare_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sharing_fare_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    zone_id character(36) NOT NULL,
    vehicle_category_id character(36) NOT NULL,
    sharing_type character varying(20) NOT NULL,
    base_fare_per_seat numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    per_km_fare_per_seat numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    discount_percent numeric(5,2) DEFAULT '30'::numeric NOT NULL,
    commission_percent numeric(5,2) DEFAULT '20'::numeric NOT NULL,
    gst_percent numeric(5,2) DEFAULT '5'::numeric NOT NULL,
    min_fare_per_seat numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    max_detour_km numeric(5,2) DEFAULT '3'::numeric NOT NULL,
    min_distance_km numeric(8,2) DEFAULT '0'::numeric NOT NULL,
    max_distance_km numeric(8,2) DEFAULT '0'::numeric NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: social_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_links (
    id character(36) NOT NULL,
    name character varying(191) NOT NULL,
    link character varying(191) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: spin_wheel_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spin_wheel_configs (
    id uuid NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    title character varying(100) DEFAULT 'Spin & Win!'::character varying NOT NULL,
    subtitle character varying(255) DEFAULT 'Congratulations on completing your ride! Spin the wheel to win a discount coupon.'::character varying NOT NULL,
    min_discount integer DEFAULT 5 NOT NULL,
    max_discount integer DEFAULT 100 NOT NULL,
    spins_per_day integer DEFAULT 1 NOT NULL,
    segments json,
    segment_colors json,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    max_total_per_user numeric(10,2) DEFAULT '500'::numeric NOT NULL,
    ride_completion_required boolean DEFAULT true NOT NULL
);


--
-- Name: spin_wheel_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spin_wheel_results (
    id uuid NOT NULL,
    user_id uuid,
    trip_request_id uuid,
    discount_value integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    wallet_amount numeric(10,2) DEFAULT 0,
    transaction_id uuid
);


--
-- Name: spin_wheel_segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spin_wheel_segments (
    id uuid NOT NULL,
    spin_wheel_config_id uuid NOT NULL,
    label character varying(50) NOT NULL,
    amount numeric(10,2) NOT NULL,
    color character varying(9) DEFAULT '#2563EB'::character varying NOT NULL,
    weight integer DEFAULT 1 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: subscription_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    duration_type character varying(20) DEFAULT 'monthly'::character varying NOT NULL,
    duration_days integer DEFAULT 30 NOT NULL,
    price numeric(10,2) DEFAULT 0 NOT NULL,
    max_rides integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: support_saved_replies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_saved_replies (
    id character(36) NOT NULL,
    topic character varying(255) NOT NULL,
    answer text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: surge_pricing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.surge_pricing (
    id character(36) NOT NULL,
    readable_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    surge_pricing_for character varying(255) NOT NULL,
    increase_for_all_vehicles boolean DEFAULT true NOT NULL,
    all_vehicle_surge_percent double precision,
    increase_for_all_parcels boolean DEFAULT true NOT NULL,
    all_parcel_surge_percent double precision,
    zone_setup_type character varying(255) DEFAULT NULL::character varying,
    schedule character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    customer_note character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: surge_pricing_service_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.surge_pricing_service_categories (
    id bigint NOT NULL,
    surge_pricing_id character(36) NOT NULL,
    service_category_type character varying(100) NOT NULL,
    service_category_id character(36) NOT NULL,
    surge_multiplier double precision NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: surge_pricing_service_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.surge_pricing_service_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: surge_pricing_service_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.surge_pricing_service_categories_id_seq OWNED BY public.surge_pricing_service_categories.id;


--
-- Name: surge_pricing_time_slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.surge_pricing_time_slots (
    id bigint NOT NULL,
    surge_pricing_id character(36) NOT NULL,
    start_date character varying(255) NOT NULL,
    end_date character varying(255) NOT NULL,
    selected_days json,
    slots json NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: surge_pricing_time_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.surge_pricing_time_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: surge_pricing_time_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.surge_pricing_time_slots_id_seq OWNED BY public.surge_pricing_time_slots.id;


--
-- Name: surge_pricing_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.surge_pricing_zones (
    surge_pricing_id character(36) NOT NULL,
    zone_id character(36) NOT NULL
);


--
-- Name: temp_trip_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.temp_trip_notifications (
    id bigint NOT NULL,
    trip_request_id character(36) DEFAULT NULL::bpchar,
    user_id character(36) DEFAULT NULL::bpchar
);


--
-- Name: temp_trip_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.temp_trip_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: temp_trip_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.temp_trip_notifications_id_seq OWNED BY public.temp_trip_notifications.id;


--
-- Name: time_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.time_logs (
    id bigint NOT NULL,
    time_track_id bigint NOT NULL,
    online_at time without time zone NOT NULL,
    offline_at time without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: time_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.time_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: time_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.time_logs_id_seq OWNED BY public.time_logs.id;


--
-- Name: time_tracks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.time_tracks (
    id bigint NOT NULL,
    user_id character(36) NOT NULL,
    date date NOT NULL,
    total_online integer DEFAULT 0 NOT NULL,
    total_offline integer DEFAULT 0 NOT NULL,
    total_idle integer DEFAULT 0 NOT NULL,
    total_driving integer DEFAULT 0 NOT NULL,
    last_ride_started_at time without time zone,
    last_ride_completed_at time without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: time_tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.time_tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: time_tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.time_tracks_id_seq OWNED BY public.time_tracks.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id character(36) NOT NULL,
    readable_id integer,
    attribute_id character(36) DEFAULT NULL::bpchar,
    attribute character varying(255) DEFAULT NULL::character varying,
    debit numeric(24,2) DEFAULT 0.00 NOT NULL,
    credit numeric(24,2) DEFAULT 0.00 NOT NULL,
    balance numeric(24,2) DEFAULT 0.00 NOT NULL,
    added_bonus numeric(24,2) DEFAULT 0.00 NOT NULL,
    user_id character(36) DEFAULT NULL::bpchar,
    account character varying(255) DEFAULT NULL::character varying,
    transaction_type character varying(255) DEFAULT NULL::character varying,
    reference text,
    trx_ref_id character(36) DEFAULT NULL::bpchar,
    trx_type character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: trip_fares; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_fares (
    id character(36) NOT NULL,
    zone_wise_default_trip_fare_id character(36) NOT NULL,
    zone_id character(36) NOT NULL,
    vehicle_category_id character(36) NOT NULL,
    base_fare numeric(8,2) NOT NULL,
    base_fare_per_km numeric(8,2) NOT NULL,
    waiting_fee_per_min numeric(8,2) NOT NULL,
    cancellation_fee_percent numeric(8,2) NOT NULL,
    min_cancellation_fee numeric(8,2) NOT NULL,
    idle_fee_per_min numeric(8,2) NOT NULL,
    trip_delay_fee_per_min numeric(8,2) NOT NULL,
    penalty_fee_for_cancel numeric(8,2) NOT NULL,
    fee_add_to_next numeric(8,2) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    pickup_charge_per_km numeric(23,2) DEFAULT '0'::numeric NOT NULL,
    pickup_free_distance numeric(8,2) DEFAULT 0.5 NOT NULL,
    shared_discount_percent numeric(8,2) DEFAULT '30'::numeric NOT NULL
);


--
-- Name: trip_request_coordinates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_request_coordinates (
    id bigint NOT NULL,
    trip_request_id character(36) NOT NULL,
    pickup_coordinates point,
    pickup_address character varying(255) DEFAULT NULL::character varying,
    destination_coordinates point,
    is_reached_destination boolean DEFAULT false NOT NULL,
    destination_address character varying(255) DEFAULT NULL::character varying,
    intermediate_coordinates text,
    int_coordinate_1 point,
    is_reached_1 boolean DEFAULT false NOT NULL,
    int_coordinate_2 point,
    is_reached_2 boolean DEFAULT false NOT NULL,
    intermediate_addresses text,
    start_coordinates point,
    drop_coordinates point,
    driver_accept_coordinates point,
    customer_request_coordinates point,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: trip_request_coordinates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_request_coordinates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_request_coordinates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_request_coordinates_id_seq OWNED BY public.trip_request_coordinates.id;


--
-- Name: trip_request_fees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_request_fees (
    id bigint NOT NULL,
    trip_request_id character(36) NOT NULL,
    cancellation_fee numeric(23,3) DEFAULT 0.000 NOT NULL,
    return_fee numeric(23,3) DEFAULT 0.000 NOT NULL,
    cancelled_by character varying(20) DEFAULT NULL::character varying,
    waiting_fee numeric(23,3) DEFAULT 0.000 NOT NULL,
    waited_by character varying(20) DEFAULT NULL::character varying,
    idle_fee numeric(23,3) DEFAULT 0.000 NOT NULL,
    delay_fee numeric(23,3) DEFAULT 0.000 NOT NULL,
    delayed_by character varying(20) DEFAULT NULL::character varying,
    vat_tax numeric(23,3) DEFAULT 0.000 NOT NULL,
    tips numeric(23,3) DEFAULT 0.000 NOT NULL,
    admin_commission numeric(23,3) DEFAULT 0.000 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    pickup_charge numeric(23,2) DEFAULT '0'::numeric NOT NULL,
    cancellation_fee_admin_share numeric(23,2) DEFAULT '0'::numeric NOT NULL,
    cancellation_fee_driver_share numeric(23,2) DEFAULT '0'::numeric NOT NULL,
    special_discount_amount numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    special_discount_type character varying(255)
);


--
-- Name: trip_request_fees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_request_fees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_request_fees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_request_fees_id_seq OWNED BY public.trip_request_fees.id;


--
-- Name: trip_request_times; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_request_times (
    id bigint NOT NULL,
    trip_request_id character(36) NOT NULL,
    estimated_time double precision NOT NULL,
    actual_time double precision,
    waiting_time double precision,
    delay_time double precision,
    idle_timestamp timestamp without time zone,
    idle_time double precision,
    driver_arrival_time double precision,
    driver_arrival_timestamp timestamp without time zone,
    driver_arrives_at timestamp without time zone,
    customer_arrives_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: trip_request_times_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_request_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_request_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_request_times_id_seq OWNED BY public.trip_request_times.id;


--
-- Name: trip_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_requests (
    id character(36) NOT NULL,
    ref_id character varying(20) NOT NULL,
    customer_id character(36) DEFAULT NULL::bpchar,
    driver_id character(36) DEFAULT NULL::bpchar,
    vehicle_category_id character(36) DEFAULT NULL::bpchar,
    vehicle_id character(36) DEFAULT NULL::bpchar,
    zone_id character(36) DEFAULT NULL::bpchar,
    area_id character(36) DEFAULT NULL::bpchar,
    estimated_fare numeric(23,3) NOT NULL,
    actual_fare numeric(23,3) DEFAULT 0.000 NOT NULL,
    estimated_distance double precision NOT NULL,
    paid_fare numeric(23,3) DEFAULT 0.000 NOT NULL,
    return_fee numeric(23,3) DEFAULT 0.000 NOT NULL,
    cancellation_fee numeric(23,3) DEFAULT 0.000 NOT NULL,
    extra_fare_fee numeric(23,3) DEFAULT 0.000 NOT NULL,
    extra_fare_amount numeric(23,3) DEFAULT 0.000 NOT NULL,
    surge_percentage double precision DEFAULT '0'::double precision,
    return_time timestamp without time zone,
    due_amount numeric(23,3) DEFAULT 0.000 NOT NULL,
    actual_distance double precision,
    encoded_polyline text,
    accepted_by character varying(255) DEFAULT NULL::character varying,
    payment_method character varying(255) DEFAULT NULL::character varying,
    payment_status character varying(255) DEFAULT 'unpaid'::character varying,
    coupon_id character(36) DEFAULT NULL::bpchar,
    coupon_amount numeric(23,3) DEFAULT NULL::numeric,
    discount_id character(36) DEFAULT NULL::bpchar,
    discount_amount numeric(23,3) DEFAULT NULL::numeric,
    note text,
    entrance character varying(255) DEFAULT NULL::character varying,
    otp character varying(255) DEFAULT NULL::character varying,
    rise_request_count integer DEFAULT 0 NOT NULL,
    type character varying(255) DEFAULT NULL::character varying,
    ride_request_type character varying(255) DEFAULT NULL::character varying,
    scheduled_at character varying(255) DEFAULT NULL::character varying,
    current_status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    is_notification_sent boolean DEFAULT true NOT NULL,
    sending_notification_at character varying(255) DEFAULT NULL::character varying,
    checked boolean DEFAULT false NOT NULL,
    tips double precision DEFAULT '0'::double precision NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_paused boolean DEFAULT false NOT NULL,
    map_screenshot character varying(255) DEFAULT NULL::character varying,
    trip_cancellation_reason text,
    ride_mode character varying(20) DEFAULT 'own'::character varying NOT NULL,
    seats_requested integer DEFAULT 1 NOT NULL,
    shared_group_id character varying(50),
    receiver_otp character varying(4),
    helper_required boolean DEFAULT false NOT NULL,
    helper_fee numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    time_based_fare numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    estimated_time_minutes integer DEFAULT 0 NOT NULL,
    sharing_type character varying(20)
);


--
-- Name: trip_routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_routes (
    id bigint NOT NULL,
    trip_request_id character(36) NOT NULL,
    coordinates point NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: trip_routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trip_routes_id_seq OWNED BY public.trip_routes.id;


--
-- Name: trip_status_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trip_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trip_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trip_status (
    id bigint DEFAULT nextval('public.trip_status_id_seq'::regclass) NOT NULL,
    trip_request_id character(36) NOT NULL,
    customer_id character(36) NOT NULL,
    driver_id character(36) DEFAULT NULL::bpchar,
    pending timestamp without time zone,
    accepted timestamp without time zone,
    out_for_pickup timestamp without time zone,
    picked_up timestamp without time zone,
    ongoing timestamp without time zone,
    completed timestamp without time zone,
    cancelled timestamp without time zone,
    failed timestamp without time zone,
    note text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "returning" timestamp without time zone,
    returned timestamp without time zone
);


--
-- Name: user_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_accounts (
    id character(36) NOT NULL,
    user_id character(36) DEFAULT NULL::bpchar,
    payable_balance numeric(24,2) DEFAULT 0.00 NOT NULL,
    receivable_balance numeric(24,2) DEFAULT 0.00 NOT NULL,
    received_balance numeric(24,2) DEFAULT 0.00 NOT NULL,
    pending_balance numeric(24,2) DEFAULT 0.00 NOT NULL,
    wallet_balance numeric(24,2) DEFAULT 0.00 NOT NULL,
    total_withdrawn numeric(24,2) DEFAULT 0.00 NOT NULL,
    referral_earn double precision DEFAULT '0'::double precision NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_address; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_address (
    id bigint NOT NULL,
    user_id character(36) DEFAULT NULL::bpchar,
    zone_id character(36) DEFAULT NULL::bpchar,
    latitude character varying(191) DEFAULT NULL::character varying,
    longitude character varying(191) DEFAULT NULL::character varying,
    city character varying(191) DEFAULT NULL::character varying,
    street character varying(191) DEFAULT NULL::character varying,
    house character varying(191) DEFAULT NULL::character varying,
    zip_code character varying(255) DEFAULT NULL::character varying,
    country character varying(255) DEFAULT NULL::character varying,
    contact_person_name character varying(255) DEFAULT NULL::character varying,
    contact_person_phone character varying(255) DEFAULT NULL::character varying,
    address text,
    address_label character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_address_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_address_id_seq OWNED BY public.user_address.id;


--
-- Name: user_last_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_last_locations (
    id bigint NOT NULL,
    user_id character(36) DEFAULT NULL::bpchar,
    type character varying(255) DEFAULT NULL::character varying,
    latitude character varying(191) DEFAULT NULL::character varying,
    longitude character varying(191) DEFAULT NULL::character varying,
    zone_id character(36) DEFAULT NULL::bpchar,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_last_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_last_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_last_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_last_locations_id_seq OWNED BY public.user_last_locations.id;


--
-- Name: user_level_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_level_histories (
    id bigint NOT NULL,
    user_level_id character(36) NOT NULL,
    user_id character(36) NOT NULL,
    user_type character varying(255) NOT NULL,
    completed_ride integer DEFAULT 0 NOT NULL,
    ride_reward_status boolean DEFAULT false NOT NULL,
    total_amount numeric(8,2) DEFAULT 0.00 NOT NULL,
    amount_reward_status boolean DEFAULT false NOT NULL,
    cancellation_rate numeric(8,2) DEFAULT 0.00 NOT NULL,
    cancellation_reward_status boolean DEFAULT false NOT NULL,
    reviews integer DEFAULT 0 NOT NULL,
    reviews_reward_status boolean DEFAULT false NOT NULL,
    is_level_reward_granted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_level_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_level_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_level_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_level_histories_id_seq OWNED BY public.user_level_histories.id;


--
-- Name: user_levels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_levels (
    id character(36) NOT NULL,
    sequence integer NOT NULL,
    name character varying(191) NOT NULL,
    reward_type character varying(20) NOT NULL,
    reward_amount numeric(8,2) DEFAULT NULL::numeric,
    image character varying(191) DEFAULT NULL::character varying,
    targeted_ride integer NOT NULL,
    targeted_ride_point integer NOT NULL,
    targeted_amount double precision NOT NULL,
    targeted_amount_point integer NOT NULL,
    targeted_cancel integer NOT NULL,
    targeted_cancel_point integer NOT NULL,
    targeted_review integer NOT NULL,
    targeted_review_point integer NOT NULL,
    user_type character varying(20) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_withdraw_method_infos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_withdraw_method_infos (
    id character(36) NOT NULL,
    method_name character varying(255) NOT NULL,
    user_id character(36) NOT NULL,
    withdraw_method_id bigint NOT NULL,
    method_info text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id character(36) NOT NULL,
    full_name character varying(255) DEFAULT NULL::character varying,
    user_level_id character(36) DEFAULT NULL::bpchar,
    first_name character varying(191) DEFAULT NULL::character varying,
    last_name character varying(191) DEFAULT NULL::character varying,
    email character varying(191) DEFAULT NULL::character varying,
    phone character varying(20) DEFAULT NULL::character varying,
    identification_number character varying(191) DEFAULT NULL::character varying,
    identification_type character varying(25) DEFAULT NULL::character varying,
    identification_image text,
    old_identification_image text,
    other_documents text,
    profile_image character varying(191) DEFAULT NULL::character varying,
    fcm_token character varying(191) DEFAULT NULL::character varying,
    phone_verified_at timestamp without time zone,
    email_verified_at timestamp without time zone,
    loyalty_points double precision DEFAULT '0'::double precision NOT NULL,
    password character varying(191) DEFAULT NULL::character varying,
    ref_code character varying(255) DEFAULT NULL::character varying,
    user_type character varying(25) DEFAULT 'customer'::character varying NOT NULL,
    role_id character(36) DEFAULT NULL::bpchar,
    remember_token character varying(100) DEFAULT NULL::character varying,
    is_active boolean DEFAULT false NOT NULL,
    current_language_key character varying(255) DEFAULT 'en'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    failed_attempt integer DEFAULT 0 NOT NULL,
    is_temp_blocked boolean DEFAULT false NOT NULL,
    blocked_at timestamp without time zone,
    date_of_birth date,
    is_senior_citizen boolean DEFAULT false NOT NULL,
    is_student boolean DEFAULT false NOT NULL,
    student_id character varying(255),
    corporate_account_id character varying(255),
    employee_id character varying(255),
    user_category character varying(255) DEFAULT 'regular'::character varying NOT NULL
);


--
-- Name: vehicle_brands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_brands (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    description text NOT NULL,
    image character varying(255) NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: vehicle_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_categories (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    description text NOT NULL,
    image character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: vehicle_category_coupon_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_category_coupon_setups (
    vehicle_category_id character(36) NOT NULL,
    coupon_setup_id character(36) NOT NULL
);


--
-- Name: vehicle_category_discount_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_category_discount_setups (
    vehicle_category_id character(36) NOT NULL,
    discount_setup_id character(36) NOT NULL
);


--
-- Name: vehicle_category_zone; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_category_zone (
    id character(36) NOT NULL,
    zone_id character(36) DEFAULT NULL::bpchar,
    vehicle_category_id character(36) DEFAULT NULL::bpchar,
    base_fare numeric(8,2) NOT NULL,
    base_fare_per_km numeric(8,2) NOT NULL,
    waiting_fee_per_min numeric(8,2) NOT NULL,
    cancellation_fee_percent numeric(8,2) NOT NULL,
    min_cancellation_fee numeric(8,2) NOT NULL,
    idle_fee_per_min numeric(8,2) NOT NULL,
    trip_delay_fee_per_min numeric(8,2) NOT NULL,
    penalty_fee_for_cancel numeric(8,2) NOT NULL,
    fee_add_to_next numeric(8,2) NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: vehicle_models; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_models (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    brand_id character(36) NOT NULL,
    seat_capacity integer NOT NULL,
    maximum_weight numeric(8,2) NOT NULL,
    hatch_bag_capacity integer NOT NULL,
    engine character varying(255) NOT NULL,
    description text NOT NULL,
    image character varying(255) NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicles (
    id character(36) NOT NULL,
    ref_id character varying(20) NOT NULL,
    brand_id character(36) NOT NULL,
    model_id character(36) NOT NULL,
    category_id character(36) NOT NULL,
    licence_plate_number character varying(255) NOT NULL,
    licence_expire_date date NOT NULL,
    vin_number character varying(255) DEFAULT NULL::character varying,
    transmission character varying(255) DEFAULT NULL::character varying,
    parcel_weight_capacity double precision,
    fuel_type character varying(255) NOT NULL,
    ownership character varying(255) NOT NULL,
    driver_id character(36) NOT NULL,
    documents text,
    is_active boolean DEFAULT false NOT NULL,
    draft json,
    vehicle_request_status character varying(255) DEFAULT 'approved'::character varying NOT NULL,
    deny_note text,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: wallet_bonuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallet_bonuses (
    id character(36) NOT NULL,
    name character varying(80) DEFAULT NULL::character varying,
    description character varying(255) DEFAULT NULL::character varying,
    bonus_amount numeric(8,2) DEFAULT 0.00 NOT NULL,
    amount_type character varying(15) DEFAULT 'amount'::character varying NOT NULL,
    min_add_amount numeric(8,2) DEFAULT 0.00 NOT NULL,
    max_bonus_amount numeric(8,2) DEFAULT 0.00 NOT NULL,
    start_date date,
    end_date date,
    user_type json NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: websockets_statistics_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.websockets_statistics_entries (
    id integer NOT NULL,
    app_id character varying(255) NOT NULL,
    peak_connection_count integer NOT NULL,
    websocket_message_count integer NOT NULL,
    api_message_count integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: websockets_statistics_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.websockets_statistics_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: websockets_statistics_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.websockets_statistics_entries_id_seq OWNED BY public.websockets_statistics_entries.id;


--
-- Name: withdraw_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.withdraw_methods (
    id bigint NOT NULL,
    method_name character varying(255) NOT NULL,
    method_fields text NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: withdraw_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.withdraw_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: withdraw_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.withdraw_methods_id_seq OWNED BY public.withdraw_methods.id;


--
-- Name: withdraw_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.withdraw_requests (
    id bigint NOT NULL,
    user_id character(36) NOT NULL,
    amount double precision DEFAULT '0'::double precision NOT NULL,
    method_id bigint NOT NULL,
    method_fields text NOT NULL,
    note text,
    driver_note text,
    approval_note text,
    denied_note text,
    rejection_cause text,
    is_approved boolean,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: withdraw_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.withdraw_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: withdraw_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.withdraw_requests_id_seq OWNED BY public.withdraw_requests.id;


--
-- Name: zone_coupon_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zone_coupon_setups (
    zone_id character(36) NOT NULL,
    coupon_setup_id character(36) NOT NULL
);


--
-- Name: zone_discount_setups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zone_discount_setups (
    zone_id character(36) NOT NULL,
    discount_setup_id character(36) NOT NULL
);


--
-- Name: zone_wise_default_trip_fares; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zone_wise_default_trip_fares (
    id character(36) NOT NULL,
    zone_id character(36) NOT NULL,
    base_fare double precision NOT NULL,
    base_fare_per_km double precision NOT NULL,
    waiting_fee_per_min double precision NOT NULL,
    cancellation_fee_percent double precision NOT NULL,
    min_cancellation_fee double precision NOT NULL,
    idle_fee_per_min double precision NOT NULL,
    trip_delay_fee_per_min double precision NOT NULL,
    penalty_fee_for_cancel double precision NOT NULL,
    fee_add_to_next double precision NOT NULL,
    category_wise_different_fare integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    pickup_charge_per_km numeric(24,2) DEFAULT 0,
    pickup_free_distance numeric(24,2) DEFAULT 0.5,
    shared_discount_percent numeric(5,2) DEFAULT 30
);


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zones (
    id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    readable_id integer,
    coordinates public.geometry(Polygon),
    is_active boolean DEFAULT true NOT NULL,
    extra_fare_status boolean DEFAULT false NOT NULL,
    extra_fare_fee double precision DEFAULT '0'::double precision NOT NULL,
    extra_fare_reason character varying(255) DEFAULT NULL::character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: admin_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_notifications ALTER COLUMN id SET DEFAULT nextval('public.admin_notifications_id_seq'::regclass);


--
-- Name: app_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_notifications ALTER COLUMN id SET DEFAULT nextval('public.app_notifications_id_seq'::regclass);


--
-- Name: area_bonus_setup id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_bonus_setup ALTER COLUMN id SET DEFAULT nextval('public.area_bonus_setup_id_seq'::regclass);


--
-- Name: area_coupon_setup id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_coupon_setup ALTER COLUMN id SET DEFAULT nextval('public.area_coupon_setup_id_seq'::regclass);


--
-- Name: area_discount_setup id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_discount_setup ALTER COLUMN id SET DEFAULT nextval('public.area_discount_setup_id_seq'::regclass);


--
-- Name: area_pick_hour id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_pick_hour ALTER COLUMN id SET DEFAULT nextval('public.area_pick_hour_id_seq'::regclass);


--
-- Name: blog_drafts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_drafts ALTER COLUMN id SET DEFAULT nextval('public.blog_drafts_id_seq'::regclass);


--
-- Name: blog_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_settings ALTER COLUMN id SET DEFAULT nextval('public.blog_settings_id_seq'::regclass);


--
-- Name: bonus_setup_vehicle_category id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bonus_setup_vehicle_category ALTER COLUMN id SET DEFAULT nextval('public.bonus_setup_vehicle_category_id_seq'::regclass);


--
-- Name: channel_conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_conversations ALTER COLUMN id SET DEFAULT nextval('public.channel_conversations_id_seq'::regclass);


--
-- Name: channel_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_users ALTER COLUMN id SET DEFAULT nextval('public.channel_users_id_seq'::regclass);


--
-- Name: conversation_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_files ALTER COLUMN id SET DEFAULT nextval('public.conversation_files_id_seq'::regclass);


--
-- Name: coupon_setup_vehicle_category id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_setup_vehicle_category ALTER COLUMN id SET DEFAULT nextval('public.coupon_setup_vehicle_category_id_seq'::regclass);


--
-- Name: discount_setup_vehicle_category id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount_setup_vehicle_category ALTER COLUMN id SET DEFAULT nextval('public.discount_setup_vehicle_category_id_seq'::regclass);


--
-- Name: driver_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_details ALTER COLUMN id SET DEFAULT nextval('public.driver_details_id_seq'::regclass);


--
-- Name: driver_time_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_time_logs ALTER COLUMN id SET DEFAULT nextval('public.driver_time_logs_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: landing_page_sections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page_sections ALTER COLUMN id SET DEFAULT nextval('public.landing_page_sections_id_seq'::regclass);


--
-- Name: late_return_penalty_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.late_return_penalty_notifications ALTER COLUMN id SET DEFAULT nextval('public.late_return_penalty_notifications_id_seq'::regclass);


--
-- Name: level_accesses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.level_accesses ALTER COLUMN id SET DEFAULT nextval('public.level_accesses_id_seq'::regclass);


--
-- Name: loyalty_points_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loyalty_points_histories ALTER COLUMN id SET DEFAULT nextval('public.loyalty_points_histories_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: module_accesses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.module_accesses ALTER COLUMN id SET DEFAULT nextval('public.module_accesses_id_seq'::regclass);


--
-- Name: notification_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_settings ALTER COLUMN id SET DEFAULT nextval('public.notification_settings_id_seq'::regclass);


--
-- Name: oauth_personal_access_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_personal_access_clients ALTER COLUMN id SET DEFAULT nextval('public.oauth_personal_access_clients_id_seq'::regclass);


--
-- Name: otp_verifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_verifications ALTER COLUMN id SET DEFAULT nextval('public.otp_verifications_id_seq'::regclass);


--
-- Name: parcel_fares_parcel_weights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_fares_parcel_weights ALTER COLUMN id SET DEFAULT nextval('public.parcel_fares_parcel_weights_id_seq'::regclass);


--
-- Name: parcel_information id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_information ALTER COLUMN id SET DEFAULT nextval('public.parcel_information_id_seq'::regclass);


--
-- Name: parcel_user_infomations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_user_infomations ALTER COLUMN id SET DEFAULT nextval('public.parcel_user_infomations_id_seq'::regclass);


--
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- Name: recent_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recent_addresses ALTER COLUMN id SET DEFAULT nextval('public.recent_addresses_id_seq'::regclass);


--
-- Name: rejected_driver_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejected_driver_requests ALTER COLUMN id SET DEFAULT nextval('public.rejected_driver_requests_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: role_user id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_user ALTER COLUMN id SET DEFAULT nextval('public.role_user_id_seq'::regclass);


--
-- Name: shared_trip_passengers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_trip_passengers ALTER COLUMN id SET DEFAULT nextval('public.shared_trip_passengers_id_seq'::regclass);


--
-- Name: surge_pricing_service_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surge_pricing_service_categories ALTER COLUMN id SET DEFAULT nextval('public.surge_pricing_service_categories_id_seq'::regclass);


--
-- Name: surge_pricing_time_slots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surge_pricing_time_slots ALTER COLUMN id SET DEFAULT nextval('public.surge_pricing_time_slots_id_seq'::regclass);


--
-- Name: temp_trip_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temp_trip_notifications ALTER COLUMN id SET DEFAULT nextval('public.temp_trip_notifications_id_seq'::regclass);


--
-- Name: time_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.time_logs ALTER COLUMN id SET DEFAULT nextval('public.time_logs_id_seq'::regclass);


--
-- Name: time_tracks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.time_tracks ALTER COLUMN id SET DEFAULT nextval('public.time_tracks_id_seq'::regclass);


--
-- Name: trip_request_coordinates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_request_coordinates ALTER COLUMN id SET DEFAULT nextval('public.trip_request_coordinates_id_seq'::regclass);


--
-- Name: trip_request_fees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_request_fees ALTER COLUMN id SET DEFAULT nextval('public.trip_request_fees_id_seq'::regclass);


--
-- Name: trip_request_times id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_request_times ALTER COLUMN id SET DEFAULT nextval('public.trip_request_times_id_seq'::regclass);


--
-- Name: trip_routes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_routes ALTER COLUMN id SET DEFAULT nextval('public.trip_routes_id_seq'::regclass);


--
-- Name: user_address id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address ALTER COLUMN id SET DEFAULT nextval('public.user_address_id_seq'::regclass);


--
-- Name: user_last_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_last_locations ALTER COLUMN id SET DEFAULT nextval('public.user_last_locations_id_seq'::regclass);


--
-- Name: user_level_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_level_histories ALTER COLUMN id SET DEFAULT nextval('public.user_level_histories_id_seq'::regclass);


--
-- Name: websockets_statistics_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.websockets_statistics_entries ALTER COLUMN id SET DEFAULT nextval('public.websockets_statistics_entries_id_seq'::regclass);


--
-- Name: withdraw_methods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraw_methods ALTER COLUMN id SET DEFAULT nextval('public.withdraw_methods_id_seq'::regclass);


--
-- Name: withdraw_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraw_requests ALTER COLUMN id SET DEFAULT nextval('public.withdraw_requests_id_seq'::regclass);


--
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.activity_logs (id, logable_id, logable_type, edited_by, before, after, user_type, created_at, updated_at) FROM stdin;
2	3aaa1fef-3e50-45cc-9b53-696835ce85c5	Modules\\UserManagement\\Entities\\User	3aaa1fef-3e50-45cc-9b53-696835ce85c5	{"remember_token":"0k7hMs3BOKfoyzPE0z8D4uDy9saZf1PG3Nsd7KXgagHdZPqwkiwqx1z6RjzR"}	{"remember_token":"NRQwyNmTssZoc57WLHlCCQAeuXulhcSWBR21xxTqXwCEFK2sT98otGIMXiyC"}	super-admin	2026-02-14 09:52:38	2026-02-14 09:52:38
3	879a7709-2451-4f6e-969f-5250b3991ccb	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-14 18:27:17","is_temp_blocked":false}	{"updated_at":"2026-02-14 18:27:40","is_temp_blocked":0}	customer	2026-02-14 18:27:40	2026-02-14 18:27:40
4	879a7709-2451-4f6e-969f-5250b3991ccb	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-14 18:27:40","is_temp_blocked":false}	{"updated_at":"2026-02-14 18:27:56","is_temp_blocked":0}	customer	2026-02-14 18:27:56	2026-02-14 18:27:56
5	879a7709-2451-4f6e-969f-5250b3991ccb	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-14 18:27:56","is_temp_blocked":false}	{"updated_at":"2026-02-14 18:28:30","is_temp_blocked":0}	customer	2026-02-14 18:28:30	2026-02-14 18:28:30
6	00757917-1231-423e-aa60-c0e956f0ef0a	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-14 18:30:48","is_temp_blocked":false}	{"updated_at":"2026-02-14 18:30:56","is_temp_blocked":0}	driver	2026-02-14 18:30:56	2026-02-14 18:30:56
7	879a7709-2451-4f6e-969f-5250b3991ccb	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-14 18:28:30","is_temp_blocked":false}	{"updated_at":"2026-02-14 18:31:19","is_temp_blocked":0}	customer	2026-02-14 18:31:19	2026-02-14 18:31:19
8	879a7709-2451-4f6e-969f-5250b3991ccb	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-14 18:31:19","is_temp_blocked":false}	{"updated_at":"2026-02-14 18:32:47","is_temp_blocked":0}	customer	2026-02-14 18:32:47	2026-02-14 18:32:47
9	879a7709-2451-4f6e-969f-5250b3991ccb	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-14 18:32:47","is_temp_blocked":false}	{"updated_at":"2026-02-14 18:33:02","is_temp_blocked":0}	customer	2026-02-14 18:33:02	2026-02-14 18:33:02
10	879a7709-2451-4f6e-969f-5250b3991ccb	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-14 18:33:02","is_temp_blocked":false}	{"updated_at":"2026-02-15 02:00:38","is_temp_blocked":0}	customer	2026-02-15 02:00:38	2026-02-15 02:00:38
11	879a7709-2451-4f6e-969f-5250b3991ccb	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-15 02:00:38","is_temp_blocked":false}	{"updated_at":"2026-02-15 02:19:58","is_temp_blocked":0}	customer	2026-02-15 02:19:58	2026-02-15 02:19:58
12	00757917-1231-423e-aa60-c0e956f0ef0a	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-14 18:30:56","is_temp_blocked":false}	{"updated_at":"2026-02-15 02:21:17","is_temp_blocked":0}	driver	2026-02-15 02:21:17	2026-02-15 02:21:17
13	879a7709-2451-4f6e-969f-5250b3991ccb	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-15 02:19:58","is_temp_blocked":false}	{"updated_at":"2026-02-15 02:21:42","is_temp_blocked":0}	customer	2026-02-15 02:21:42	2026-02-15 02:21:42
14	00757917-1231-423e-aa60-c0e956f0ef0a	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-15 02:21:17","is_temp_blocked":false}	{"updated_at":"2026-02-15 02:21:42","is_temp_blocked":0}	driver	2026-02-15 02:21:42	2026-02-15 02:21:42
15	8de7e4bf-0483-4a72-895b-bcf79594bfd2	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:22:09","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:24:39","is_temp_blocked":0}	customer	2026-02-16 15:24:39	2026-02-16 15:24:39
16	1b81af34-c972-49df-b816-ca2e925e9b9b	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:22:09","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:24:52","is_temp_blocked":0}	driver	2026-02-16 15:24:52	2026-02-16 15:24:52
17	b8dd794f-b7de-4bab-b53d-43d06dd45e52	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:23:24","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:24:52","is_temp_blocked":0}	driver	2026-02-16 15:24:52	2026-02-16 15:24:52
18	62e81720-2260-4b67-bf44-fa8c558a116f	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:23:24","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:24:52","is_temp_blocked":0}	driver	2026-02-16 15:24:52	2026-02-16 15:24:52
19	8de7e4bf-0483-4a72-895b-bcf79594bfd2	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:24:39","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:44:56","is_temp_blocked":0}	customer	2026-02-16 15:44:56	2026-02-16 15:44:56
20	1b81af34-c972-49df-b816-ca2e925e9b9b	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:24:52","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:44:56","is_temp_blocked":0}	driver	2026-02-16 15:44:56	2026-02-16 15:44:56
21	b8dd794f-b7de-4bab-b53d-43d06dd45e52	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:24:52","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:44:57","is_temp_blocked":0}	driver	2026-02-16 15:44:57	2026-02-16 15:44:57
22	62e81720-2260-4b67-bf44-fa8c558a116f	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:24:52","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:44:57","is_temp_blocked":0}	driver	2026-02-16 15:44:57	2026-02-16 15:44:57
23	8de7e4bf-0483-4a72-895b-bcf79594bfd2	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:44:56","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:47:44","is_temp_blocked":0}	customer	2026-02-16 15:47:44	2026-02-16 15:47:44
24	8de7e4bf-0483-4a72-895b-bcf79594bfd2	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:47:44","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:47:53","is_temp_blocked":0}	customer	2026-02-16 15:47:53	2026-02-16 15:47:53
25	8de7e4bf-0483-4a72-895b-bcf79594bfd2	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:47:53","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:48:02","is_temp_blocked":0}	customer	2026-02-16 15:48:02	2026-02-16 15:48:02
26	8de7e4bf-0483-4a72-895b-bcf79594bfd2	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:48:02","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:49:53","is_temp_blocked":0}	customer	2026-02-16 15:49:53	2026-02-16 15:49:53
27	8de7e4bf-0483-4a72-895b-bcf79594bfd2	Modules\\UserManagement\\Entities\\User	user_update	{"updated_at":"2026-02-16 15:49:53","is_temp_blocked":false}	{"updated_at":"2026-02-16 15:50:06","is_temp_blocked":0}	customer	2026-02-16 15:50:06	2026-02-16 15:50:06
28	3aaa1fef-3e50-45cc-9b53-696835ce85c5	Modules\\UserManagement\\Entities\\User	3aaa1fef-3e50-45cc-9b53-696835ce85c5	{"remember_token":"NRQwyNmTssZoc57WLHlCCQAeuXulhcSWBR21xxTqXwCEFK2sT98otGIMXiyC"}	{"remember_token":"cKzPQlbV8MZ05AWAqA85YwIyxdko2UH7E81E7MOMnO8AeJFotq7RTkC6alXJ"}	super-admin	2026-02-16 17:24:52	2026-02-16 17:24:52
\.


--
-- Data for Name: admin_notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_notifications (id, model, model_id, message, is_seen, created_at, updated_at) FROM stdin;
2	user	30ba60f2-6cbc-4d48-8e06-7064fc919075	new_customer_registered	f	2026-02-14 18:26:15	2026-02-14 18:26:15
3	user	879a7709-2451-4f6e-969f-5250b3991ccb	new_customer_registered	f	2026-02-14 18:27:17	2026-02-14 18:27:17
4	user	00757917-1231-423e-aa60-c0e956f0ef0a	new_driver_registered	f	2026-02-14 18:30:48	2026-02-14 18:30:48
\.


--
-- Data for Name: ai_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ai_settings (id, ai_name, base_url, api_key, organization_id, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: app_notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_notifications (id, user_id, ride_request_id, title, description, type, notification_type, action, is_read, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: applied_coupons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.applied_coupons (id, coupon_setup_id, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: area_bonus_setup; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.area_bonus_setup (id, area_id, bonus_setup_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: area_coupon_setup; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.area_coupon_setup (id, area_id, coupon_setup_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: area_discount_setup; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.area_discount_setup (id, area_id, discount_setup_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: area_pick_hour; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.area_pick_hour (id, area_id, pick_hour_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: areas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.areas (id, name, latitude, longitude, radius, zone_id, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: b2b_parcel_plans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.b2b_parcel_plans (id, plan_name, plan_code, description, monthly_fee, included_deliveries, per_delivery_rate, discount_percent, priority_pickup, dedicated_support, api_access, max_weight_kg, is_active, sort_order, created_at, updated_at, deleted_at) FROM stdin;
9a9c0211-c0e3-4441-a9b7-5cdb7e56dc2a	Starter	B2B_STARTER	Ideal for small businesses with basic delivery needs	2999.00	100	25.00	5.00	f	f	f	25	t	1	2026-02-15 08:30:30	2026-02-15 08:30:30	\N
7bebd567-d7bf-44f0-ac4f-7cbe6f8b08e8	Growth	B2B_GROWTH	For growing businesses with medium delivery volume	7999.00	300	20.00	10.00	t	f	f	50	t	2	2026-02-15 08:30:30	2026-02-15 08:30:30	\N
4db65f59-bd2c-472a-a99d-44169b796fdf	Enterprise	B2B_ENTERPRISE	Full-featured plan for high-volume businesses	19999.00	1000	12.00	20.00	t	t	t	100	t	3	2026-02-15 08:30:30	2026-02-15 08:30:30	\N
\.


--
-- Data for Name: banner_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.banner_setups (id, name, description, time_period, display_position, redirect_link, banner_group, start_date, end_date, image, total_redirection, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: blog_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.blog_categories (id, name, slug, status, click_count, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: blog_drafts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.blog_drafts (id, blog_id, blog_category_id, writer, title, description, thumbnail, published_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: blog_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.blog_settings (id, key_name, value, settings_type, created_at, updated_at) FROM stdin;
2	is_enabled	"1"	blog_page	2026-02-17 14:13:28.504073	2026-02-17 14:13:28.504073
3	title	"Blog"	blog_page	2026-02-17 14:13:28.504073	2026-02-17 14:13:28.504073
4	subtitle	"Latest news and updates"	blog_page	2026-02-17 14:13:28.504073	2026-02-17 14:13:28.504073
\.


--
-- Data for Name: blogs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.blogs (id, readable_id, slug, blog_category_id, writer, title, description, thumbnail, status, click_count, meta_title, meta_description, meta_image, is_drafted, is_published, published_at, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: bonus_setup_vehicle_category; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bonus_setup_vehicle_category (id, bonus_setup_id, vehicle_category_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: bonus_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bonus_setups (id, name, description, user_id, user_level_id, min_trip_amount, max_bonus, bonus, amount_type, bonus_type, "limit", start_date, end_date, rules, total_used, total_amount, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: business_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.business_settings (id, key_name, value, settings_type, created_at, updated_at) FROM stdin;
0a21956c-46f7-4bc3-be9f-5c5bee4aded9	parcel_refund_validity	2	parcel_settings	2024-11-04 07:12:48	2024-11-04 07:12:48
3d8e3eea-556a-4707-bd0b-208c02b5e048	return_time_for_driver	24	parcel_settings	2024-11-04 07:12:48	2024-11-04 07:12:48
647146d1-ee1a-4ba5-9588-a0225fbcb64b	return_fee_for_driver_time_exceed	0	parcel_settings	2024-11-04 07:12:48	2024-11-04 07:12:48
9c0991cc-6b7f-454a-8e0a-72ffb04f1ea6	return_time_type_for_driver	"hour"	parcel_settings	2024-11-04 07:12:48	2024-11-04 07:12:48
b6308a75-5017-44bf-847c-0c09004a459f	parcel_refund_validity_type	"day"	parcel_settings	2024-11-04 07:12:48	2024-11-04 07:12:48
d9002a88-0046-4530-9ebc-ba753462af5c	parcel_tracking_message	"Dear {CustomerName}\\nParcel ID is {ParcelId} You can track this parcel from this link {TrackingLink}"	parcel_settings	2024-11-04 07:12:48	2024-11-04 07:12:48
19bcc2b4-2cab-46fc-966f-396532a94d19	website_color	{"primary":"#2563EB","secondary":"#DBEAFE","background":"#F1F5F9"}	landing_page_settings	2026-02-13 04:58:59.360905	2026-02-13 04:58:59.360905
5aec0994-5aea-41d8-bd5b-0ab48e909123	text_color	{"primary":"#0F172A","light":"#64748B"}	landing_page_settings	2026-02-13 04:58:59.360905	2026-02-13 04:58:59.360905
ed153559-5a5f-44d9-8f4d-b8745fa847a4	header_logo	"jago-logo-new.png"	business_information	2026-02-13 04:58:59.360905	2026-02-13 04:58:59.360905
35a31110-936a-4037-9e34-c799ffda6184	footer_logo	"jago-logo-new.png"	business_information	\N	\N
99e700aa-e089-4897-931b-f7381885718a	business_name	"JAGO"	business_information	2026-02-13 04:58:59.360905	2026-02-13 04:58:59.360905
18b0616f-e07a-4dd2-a8a9-b7ea1ac1942f	favicon	"jago-logo-new.png"	business_information	2026-02-13 04:58:59.360905	2026-02-13 04:58:59.360905
9c7de5d9-d904-4f0b-9ea3-84a73671ccae	system_language	[{"id":1,"direction":"ltr","code":"en","status":1,"default":true},{"id":2,"direction":"ltr","code":"te","status":1,"default":false},{"id":3,"direction":"ltr","code":"hi","status":1,"default":false}]	language_settings	2026-02-14 05:55:20	2026-02-14 06:48:13
d203babb-034d-4744-8dcc-dc9bc420931a	about_us	{"image": null, "long_description": "<h2>About JAGO</h2><p><strong>Effective Date:</strong> February 15, 2026</p><p>JAGO is a next-generation smart mobility and logistics platform proudly developed and operated by <strong>Mindwhile IT Solutions Pvt Ltd</strong>, a registered Indian technology company headquartered in Hyderabad, Telangana. We are on a mission to revolutionise urban transportation and last-mile delivery across India — making every journey safer, faster, and more affordable.</p><h2>Our Vision</h2><p>To become India's most trusted and innovative mobility ecosystem — empowering millions of riders, drivers, and businesses with intelligent, technology-driven transportation and logistics solutions that transform the way people and parcels move.</p><h2>Our Mission</h2><p>At JAGO, our mission is clear:</p><ul><li>Deliver safe, reliable, and affordable ride-sharing services for daily commuters across Indian cities</li><li>Enable fast, transparent, and trackable parcel delivery from doorstep to doorstep</li><li>Offer flexible car-sharing solutions that reduce congestion and promote sustainable urban mobility</li><li>Empower driver-partners with fair earnings, flexible schedules, subscription options, and career growth opportunities</li><li>Leverage cutting-edge technology — including AI-powered route optimisation, real-time GPS tracking, and smart fare algorithms — to deliver a world-class user experience</li><li>Build a sustainable, inclusive mobility ecosystem that creates value for communities, cities, and the environment</li></ul><h2>Our Story</h2><p>JAGO was born out of a simple observation: India's rapidly growing cities need smarter, more efficient mobility solutions. Founded by a team of passionate technologists and mobility enthusiasts at Mindwhile IT Solutions Pvt Ltd, JAGO was conceived to bridge the gap between technology and everyday transportation needs.</p><p>Starting from Hyderabad, we set out to build a platform that doesn't just move people — it moves communities forward. Our name, <strong>JAGO</strong>, meaning \\"awaken\\" in Hindi, reflects our belief that it's time to wake up to a new era of intelligent, connected, and accessible urban mobility.</p><p>Today, JAGO serves thousands of riders and driver-partners, processing rides and deliveries with industry-leading speed and reliability. We continue to expand our footprint across Indian cities, driven by the conviction that everyone deserves access to safe, affordable, and efficient transportation.</p><h2>Our Services</h2><h3>Ride Sharing</h3><p>Book two-wheeler, auto, or car rides instantly with AI-powered driver matching, real-time tracking, and transparent upfront pricing. Whether it's your daily commute, an airport transfer, or a late-night ride home — JAGO gets you there safely and affordably.</p><h3>Parcel Delivery</h3><p>Send parcels across the city with real-time tracking, secure handling, proof of delivery, and doorstep convenience. From documents and small packages to bulky items — JAGO's delivery network ensures your parcel reaches its destination on time, every time.</p><h3>Car Sharing</h3><p>Share rides with fellow commuters heading in the same direction. Our intelligent carpooling system reduces your travel costs, lowers carbon emissions, and helps ease urban congestion — all while connecting you with verified co-travellers.</p><h2>Our Technology Platform</h2><p>At the heart of JAGO lies a sophisticated technology stack built for scale, speed, and reliability:</p><ul><li><strong>AI-Powered Matching:</strong> Our proprietary algorithms match riders with the nearest and best-suited drivers in seconds, minimising wait times and optimising fleet utilisation</li><li><strong>Real-Time GPS Tracking:</strong> Track your ride or parcel on a live map with pinpoint accuracy, powered by advanced geolocation services</li><li><strong>Smart Fare Engine:</strong> Our dynamic pricing algorithm calculates fares transparently based on distance, time, demand patterns, and route conditions — no hidden charges, ever</li><li><strong>Safety Infrastructure:</strong> In-app SOS button, emergency contacts, ride-sharing with trusted contacts, driver verification, and 24/7 safety monitoring</li><li><strong>Secure Payments:</strong> Multiple payment options including UPI, credit/debit cards, net banking, digital wallets, and cash — all processed through PCI-DSS compliant payment gateways</li><li><strong>Intelligent Notifications:</strong> Real-time updates on ride status, driver arrival, parcel tracking, promotions, and account activity</li></ul><h2>India Market Focus</h2><p>JAGO is built exclusively for the Indian market. We understand the unique challenges and opportunities of Indian urban mobility — from diverse traffic conditions and varied road infrastructure to multilingual users and region-specific payment preferences. Our platform is optimised for:</p><ul><li>Indian road networks and traffic patterns</li><li>Regional language support for wider accessibility</li><li>UPI and domestic payment integration</li><li>Compliance with Indian regulatory frameworks including the Motor Vehicles Act, IT Act 2000, and Digital Personal Data Protection Act 2023</li><li>Partnerships with local authorities, transport departments, and smart city initiatives</li></ul><h2>Our Values</h2><ul><li><strong>Innovation:</strong> We constantly push the boundaries of technology to deliver smarter, faster, and more intuitive mobility experiences</li><li><strong>Safety:</strong> The safety of our riders, drivers, and parcels is our highest priority — built into every feature, every algorithm, and every decision</li><li><strong>Integrity:</strong> Transparent pricing, honest communication, ethical business practices, and respect for user privacy define how we operate</li><li><strong>Inclusivity:</strong> We build solutions that work for everyone — riders of all backgrounds, drivers across experience levels, and businesses of every size</li><li><strong>Sustainability:</strong> Through carpooling, route optimisation, and efficient fleet management, we are committed to reducing the environmental impact of urban transportation</li><li><strong>Excellence:</strong> We hold ourselves to the highest standards of quality, reliability, and customer service in everything we do</li></ul><h2>About Mindwhile IT Solutions Pvt Ltd</h2><p><strong>Mindwhile IT Solutions Pvt Ltd</strong> is a registered Indian Private Limited Company incorporated under the Companies Act, 2013. Headquartered in Hyderabad, Telangana, India, the company specialises in building scalable digital platforms for mobility, logistics, and enterprise technology solutions.</p><p>With a team of experienced software engineers, data scientists, product designers, and business strategists, Mindwhile IT Solutions is committed to delivering world-class technology products that solve real-world problems for Indian consumers and businesses.</p><h3>Company Registration Details</h3><ul><li><strong>Company Name:</strong> Mindwhile IT Solutions Pvt Ltd</li><li><strong>Type:</strong> Private Limited Company</li><li><strong>Registered Under:</strong> Companies Act, 2013 (Ministry of Corporate Affairs, Government of India)</li><li><strong>Registered Office:</strong> Hyderabad, Telangana, India</li><li><strong>GST Registered:</strong> Yes</li><li><strong>Contact Email:</strong> support@jagoapp.in</li><li><strong>Contact Phone:</strong> +91-9876543210</li></ul><p><strong>JAGO — Move Smarter. Live Better.</strong></p><p><em>A proud product of Mindwhile IT Solutions Pvt Ltd, Hyderabad, India.</em></p>", "short_description": "JAGO is India's smart mobility and logistics platform — powered by Mindwhile IT Solutions Pvt Ltd, delivering seamless ride-sharing, parcel delivery, and car-sharing services across the nation."}	pages_settings	2026-02-14 07:22:58.542877	2026-02-14 07:22:58.542877
cad48d7c-c070-4cef-b33c-61704e7627d9	privacy_policy	{"image": null, "long_description": "<h2>Privacy Policy</h2><p><strong>Effective Date:</strong> February 15, 2026</p><p>This Privacy Policy (\\"Policy\\") describes how <strong>JAGO</strong>, operated by <strong>Mindwhile IT Solutions Pvt Ltd</strong> (hereinafter referred to as \\"Company\\", \\"we\\", \\"us\\", or \\"our\\"), collects, uses, stores, shares, and protects the personal data and information of users (\\"you\\" or \\"your\\") who access or use our mobile applications, website, and services (collectively, the \\"Platform\\").</p><p>This Policy is published in compliance with the <strong>Information Technology Act, 2000</strong>, the <strong>Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011</strong>, and the <strong>Digital Personal Data Protection Act, 2023</strong> (DPDP Act) of India.</p><p>By accessing or using the JAGO Platform, you acknowledge that you have read, understood, and agree to the collection and use of your information as described in this Privacy Policy. If you do not agree with any part of this Policy, please discontinue use of our Platform immediately.</p><h2 id=\\"info-collect\\">1. Information We Collect</h2><p>We collect the following categories of information to provide, improve, and secure our services:</p><h3>a) Personal Information</h3><ul><li>Full name, date of birth, gender</li><li>Email address and mobile phone number</li><li>Profile photograph (optional)</li><li>Postal address and city of residence</li><li>Emergency contact details</li></ul><h3>b) Identity Verification Data (for Driver-Partners)</h3><ul><li>Government-issued photo identification (Aadhaar, PAN, Voter ID, Passport)</li><li>Valid driving licence details</li><li>Vehicle registration certificate (RC) and insurance documents</li><li>Bank account details for payment disbursement</li><li>Background verification information</li></ul><h3>c) Location Data</h3><ul><li>Real-time GPS location during active rides and deliveries</li><li>Pickup and drop-off locations for each trip</li><li>Route data and navigation history</li><li>Location data collected in the background when the driver app is active (for driver-partners only)</li></ul><h3>d) Financial and Transaction Data</h3><ul><li>Payment method details (credit/debit card numbers, UPI IDs, wallet information)</li><li>Ride and delivery fare history</li><li>Wallet balance, top-up history, and transaction records</li><li>Invoice and billing information</li><li>Refund and cancellation records</li></ul><h3>e) Device and Technical Data</h3><ul><li>Device type, model, manufacturer, and operating system version</li><li>Unique device identifiers (IMEI, advertising ID)</li><li>IP address, browser type, and language preferences</li><li>App version, crash reports, and performance diagnostics</li><li>Network information (mobile operator, Wi-Fi connection status)</li></ul><h3>f) Usage and Behavioural Data</h3><ul><li>In-app activity, feature usage patterns, and session duration</li><li>Search queries and booking history</li><li>Customer support interactions and feedback</li><li>Ratings and reviews provided by or about you</li><li>Referral activity and promotional code usage</li></ul><h3>g) Communications Data</h3><ul><li>In-app chat messages between riders and drivers</li><li>Customer support correspondence (email, phone, in-app)</li><li>Push notification preferences and interaction history</li></ul><h2 id=\\"how-use\\">2. How We Use Your Information</h2><p>We use the information we collect for the following purposes:</p><h3>a) Service Delivery</h3><ul><li>Facilitate ride-sharing bookings, parcel delivery, and car-sharing services</li><li>Match riders with the most suitable nearby driver-partners</li><li>Calculate fares, process payments, and generate invoices</li><li>Provide real-time ride and parcel tracking</li><li>Enable in-app communication between riders and drivers</li></ul><h3>b) Safety and Security</h3><ul><li>Verify the identity of users and driver-partners</li><li>Monitor rides in real-time for safety compliance</li><li>Operate the SOS and emergency response system</li><li>Detect and prevent fraud, abuse, and unauthorised access</li><li>Conduct background verification of driver-partners</li></ul><h3>c) Platform Improvement</h3><ul><li>Analyse usage patterns to improve app performance and features</li><li>Conduct research and development for new services</li><li>Optimise route algorithms and fare calculation models</li><li>Personalise the user experience based on preferences and behaviour</li></ul><h3>d) Communication</h3><ul><li>Send service-related notifications (ride updates, payment confirmations, delivery status)</li><li>Deliver promotional offers, discounts, and loyalty rewards (with your consent)</li><li>Respond to customer support inquiries and feedback</li><li>Communicate policy changes and important updates</li></ul><h3>e) Legal and Regulatory Compliance</h3><ul><li>Comply with applicable Indian laws, regulations, and legal processes</li><li>Respond to requests from law enforcement and government authorities</li><li>Enforce our Terms and Conditions and other agreements</li><li>Resolve disputes and exercise our legal rights</li></ul><h2 id=\\"info-sharing\\">3. Information Sharing and Disclosure</h2><p>We may share your personal information in the following circumstances:</p><h3>a) With Other Users</h3><p>When you book a ride or delivery, we share limited information with the assigned driver-partner (such as your name, pickup/drop-off location, and phone number) to facilitate the service. Similarly, rider information such as the driver's name, vehicle details, photo, and rating are shared with riders.</p><h3>b) With Service Providers</h3><p>We engage trusted third-party service providers who assist us in operating the Platform, including:</p><ul><li>Payment gateway providers (Razorpay, Cashfree, Paytm, etc.) for transaction processing</li><li>Cloud infrastructure providers for data hosting and storage</li><li>Analytics providers for usage analysis and performance monitoring</li><li>SMS and push notification service providers</li><li>Map and navigation service providers</li><li>Background verification agencies for driver-partner screening</li></ul><h3>c) With Legal Authorities</h3><p>We may disclose your information when required by law, subpoena, court order, or government regulation, or when we believe in good faith that disclosure is necessary to protect our rights, your safety, or the safety of others, investigate fraud or security incidents, or comply with a judicial proceeding or legal process served on our Company.</p><h3>d) Business Transfers</h3><p>In the event of a merger, acquisition, reorganisation, or sale of assets, your personal information may be transferred as part of the transaction. We will notify you of any such change and ensure the successor entity honours this Privacy Policy.</p><p><strong>We do not sell, rent, or trade your personal information to third parties for their marketing purposes.</strong></p><h2 id=\\"data-security\\">4. Data Security</h2><p>We implement comprehensive, industry-standard security measures to protect your personal information from unauthorised access, alteration, disclosure, or destruction:</p><ul><li><strong>Encryption:</strong> All data transmitted between your device and our servers is encrypted using 256-bit SSL/TLS encryption. Sensitive data at rest is encrypted using AES-256 standards</li><li><strong>Payment Security:</strong> All payment transactions are processed through PCI-DSS Level 1 compliant payment gateways. We do not store complete credit/debit card numbers on our servers</li><li><strong>Access Controls:</strong> Strict role-based access controls ensure that only authorised personnel can access personal data, and only to the extent necessary for their job functions</li><li><strong>Infrastructure Security:</strong> Our servers are hosted in ISO 27001 certified data centres located in India, with 24/7 monitoring, intrusion detection systems, and regular security audits</li><li><strong>Vulnerability Management:</strong> We conduct regular penetration testing, code reviews, and vulnerability assessments to identify and remediate potential security risks</li><li><strong>Incident Response:</strong> We maintain a dedicated incident response team and documented procedures to promptly address any data security breach in accordance with the DPDP Act, 2023</li></ul><p>While we take all reasonable measures to protect your data, no method of electronic transmission or storage is 100% secure. We encourage you to use strong passwords, keep your credentials confidential, and report any suspicious activity immediately.</p><h2 id=\\"data-retention\\">5. Data Retention</h2><p>We retain your personal information only for as long as necessary to fulfil the purposes described in this Policy:</p><ul><li><strong>Active Accounts:</strong> Your data is retained for the duration your account remains active on the Platform</li><li><strong>Post-Deletion:</strong> Upon account deletion request, we will delete or anonymise your personal data within 90 days, except where retention is required by law</li><li><strong>Legal Obligations:</strong> Certain data (transaction records, tax information, dispute-related correspondence) may be retained for up to 8 years as required under Indian tax laws, the Companies Act, and other applicable regulations</li><li><strong>Safety Records:</strong> Ride safety data, SOS incident reports, and accident records may be retained for up to 5 years for legal compliance and insurance purposes</li><li><strong>Anonymised Data:</strong> We may retain anonymised, aggregated data indefinitely for analytics, research, and service improvement purposes. Such data cannot be used to identify you personally</li></ul><h2 id=\\"your-rights\\">6. Your Rights</h2><p>Under the Digital Personal Data Protection Act, 2023 and applicable Indian laws, you have the following rights regarding your personal data:</p><ul><li><strong>Right to Access:</strong> You may request a copy of the personal data we hold about you</li><li><strong>Right to Correction:</strong> You may request correction of any inaccurate, incomplete, or outdated personal data</li><li><strong>Right to Erasure:</strong> You may request deletion of your personal data, subject to legal retention obligations</li><li><strong>Right to Withdraw Consent:</strong> You may withdraw your consent for data processing at any time. Withdrawal of consent will not affect the lawfulness of processing carried out before withdrawal</li><li><strong>Right to Nominate:</strong> You may nominate another individual to exercise your data rights in the event of your death or incapacity, as provided under the DPDP Act, 2023</li><li><strong>Right to Grievance Redressal:</strong> You have the right to lodge a complaint with our Grievance Officer or the Data Protection Board of India if you believe your data rights have been violated</li></ul><p>To exercise any of these rights, please contact our Grievance Officer using the details provided in Section 10 below.</p><h2 id=\\"cookies\\">7. Cookies and Tracking Technologies</h2><p>Our website and Platform may use cookies, web beacons, pixels, and similar tracking technologies to:</p><ul><li>Authenticate users and maintain session security</li><li>Remember your preferences and settings</li><li>Analyse website traffic and usage patterns</li><li>Deliver relevant advertisements and measure ad effectiveness</li><li>Improve Platform performance and user experience</li></ul><h3>Types of Cookies We Use</h3><ul><li><strong>Essential Cookies:</strong> Required for the Platform to function properly (authentication, security, load balancing)</li><li><strong>Analytics Cookies:</strong> Help us understand how users interact with our Platform (page views, session duration, bounce rates)</li><li><strong>Functional Cookies:</strong> Remember your preferences such as language, region, and display settings</li><li><strong>Advertising Cookies:</strong> Used to deliver personalised advertisements and measure campaign performance</li></ul><p>You can manage your cookie preferences through your browser settings. Please note that disabling essential cookies may affect the functionality of the Platform.</p><h2 id=\\"children\\">8. Children's Privacy</h2><p>The JAGO Platform and its services are intended solely for individuals who are 18 years of age or older. We do not knowingly collect, process, or store personal data from children under the age of 18.</p><p>If we become aware that we have inadvertently collected personal information from a minor, we will take immediate steps to delete such information from our systems. If you are a parent or guardian and believe that your child has provided personal information to us, please contact us immediately at <strong>support@jagoapp.in</strong> so that we can take appropriate action.</p><p>In accordance with the Digital Personal Data Protection Act, 2023, processing of personal data of children requires verifiable consent from a parent or legal guardian.</p><h2 id=\\"changes\\">9. Changes to This Privacy Policy</h2><p>We may update this Privacy Policy from time to time to reflect changes in our practices, technology, legal requirements, or for other operational reasons. When we make material changes:</p><ul><li>We will update the \\"Effective Date\\" at the top of this Policy</li><li>We will notify you through in-app notifications, email, or prominent notice on our Platform</li><li>For significant changes, we may seek your renewed consent as required under the DPDP Act, 2023</li></ul><p>We encourage you to review this Privacy Policy periodically to stay informed about how we are protecting your data. Your continued use of the Platform after the posting of changes constitutes your acceptance of the updated Policy.</p><h2 id=\\"contact-privacy\\">10. Contact Us</h2><p>For any privacy-related questions, concerns, or requests, you may contact us through the following channels:</p><h3>Grievance Officer</h3><p>In accordance with the Information Technology Act, 2000 and the rules made thereunder, we have appointed a Grievance Officer to address any concerns or grievances regarding the processing of your personal data:</p><ul><li><strong>Name:</strong> Grievance Officer, JAGO</li><li><strong>Company:</strong> Mindwhile IT Solutions Pvt Ltd</li><li><strong>Email:</strong> grievance@jagoapp.in</li><li><strong>Phone:</strong> +91-9876543210</li><li><strong>Address:</strong> Mindwhile IT Solutions Pvt Ltd, Hyderabad, Telangana 500081, India</li></ul><p>The Grievance Officer shall acknowledge your complaint within 24 hours and resolve it within 30 days from the date of receipt, in accordance with applicable law.</p><h3>General Contact</h3><ul><li><strong>Email:</strong> support@jagoapp.in</li><li><strong>Phone:</strong> +91-9876543210</li><li><strong>Website:</strong> www.jagoapp.in</li><li><strong>Address:</strong> Mindwhile IT Solutions Pvt Ltd, Hyderabad, Telangana 500081, India</li></ul><h3>Data Protection Board of India</h3><p>If you are not satisfied with our response to your privacy concern, you may lodge a complaint with the <strong>Data Protection Board of India</strong> as constituted under the Digital Personal Data Protection Act, 2023.</p><p><em>This Privacy Policy is governed by and construed in accordance with the laws of India. Any disputes arising under this Policy shall be subject to the exclusive jurisdiction of the courts in Hyderabad, Telangana, India.</em></p>", "short_description": "Your privacy is our priority. This policy explains how JAGO, operated by Mindwhile IT Solutions Pvt Ltd, collects, uses, protects, and handles your personal data in compliance with Indian data protection laws."}	pages_settings	2026-02-14 07:22:58.542877	2026-02-14 07:38:17.6527
6c3e9b28-9f47-46a3-a133-9df854c9ddf3	terms_and_conditions	{"image": null, "long_description": "<h2>Terms and Conditions</h2><p><strong>Effective Date:</strong> February 15, 2026</p><p>These Terms and Conditions (\\"Terms\\") constitute a legally binding agreement between you (\\"User\\", \\"you\\", or \\"your\\") and <strong>Mindwhile IT Solutions Pvt Ltd</strong> (\\"Company\\", \\"we\\", \\"us\\", or \\"our\\"), a company incorporated under the Companies Act, 2013, with its registered office in Hyderabad, Telangana, India. The Company owns and operates the <strong>JAGO</strong> platform (\\"Platform\\"), which includes our mobile applications, website (www.jagoapp.in), and all related services.</p><p>By accessing, downloading, installing, or using the JAGO Platform, you acknowledge that you have read, understood, and agree to be bound by these Terms, our Privacy Policy, and any other policies or guidelines referenced herein. If you do not agree to these Terms, you must not access or use the Platform.</p><h2 id=\\"definitions\\">1. Definitions</h2><p>For the purposes of these Terms, the following definitions shall apply:</p><ul><li><strong>\\"Platform\\"</strong> means the JAGO mobile applications (for Android and iOS), the JAGO website (www.jagoapp.in), the JAGO driver application (JAGO Pilot), and all associated software, APIs, and services operated by the Company</li><li><strong>\\"User\\"</strong> means any individual who accesses, registers on, or uses the Platform, including Riders, Senders, and Driver-Partners</li><li><strong>\\"Rider\\"</strong> means a User who requests ride-sharing or car-sharing services through the Platform</li><li><strong>\\"Sender\\"</strong> means a User who requests parcel delivery services through the Platform</li><li><strong>\\"Driver-Partner\\"</strong> means an independent contractor who provides transportation or delivery services through the Platform using their own vehicle</li><li><strong>\\"Services\\"</strong> means all services offered through the Platform, including ride-sharing, parcel delivery, car-sharing, and any future services introduced by JAGO</li><li><strong>\\"Ride\\"</strong> means a transportation service from a pickup location to a drop-off location facilitated through the Platform</li><li><strong>\\"Delivery\\"</strong> means a parcel pickup and delivery service facilitated through the Platform</li><li><strong>\\"Fare\\"</strong> means the total amount payable by the User for a Ride or Delivery, as calculated by the Platform's fare engine</li><li><strong>\\"JAGO Wallet\\"</strong> means the in-app digital wallet provided to Users for making payments and receiving refunds on the Platform</li><li><strong>\\"Content\\"</strong> means all text, images, graphics, logos, trademarks, software, data, and other materials available on or through the Platform</li></ul><h2 id=\\"eligibility\\">2. Eligibility</h2><p>To access and use the JAGO Platform, you must meet the following eligibility criteria:</p><h3>For All Users</h3><ul><li>Be at least 18 years of age as on the date of registration</li><li>Possess a valid government-issued photo identification (Aadhaar Card, PAN Card, Passport, Voter ID, or Driving Licence)</li><li>Have the legal capacity to enter into a binding contract under the Indian Contract Act, 1872</li><li>Possess a valid Indian mobile phone number for OTP-based verification</li><li>Not have been previously suspended or permanently banned from the Platform</li></ul><h3>Additional Requirements for Driver-Partners</h3><ul><li>Possess a valid driving licence issued by an Indian Regional Transport Office (RTO), appropriate for the vehicle category being operated</li><li>Own or have authorised access to a vehicle with valid registration certificate (RC), insurance, fitness certificate, and pollution under control (PUC) certificate</li><li>Obtain a valid commercial driving permit or badge where required by local transport authorities</li><li>Successfully complete JAGO's background verification and identity validation process</li><li>Meet the minimum age requirement of 21 years for four-wheeler services</li><li>Maintain all required permits and licences throughout the duration of their engagement with the Platform</li></ul><h2 id=\\"account\\">3. Account Registration and Security</h2><p>To use the Platform, you must create an account by providing accurate, complete, and current information. You agree to:</p><ul><li>Provide truthful and accurate information during the registration process</li><li>Maintain and promptly update your account information to keep it current and complete</li><li>Maintain the confidentiality of your login credentials and not share them with any third party</li><li>Accept full responsibility for all activities that occur under your account</li><li>Notify us immediately at <strong>support@jagoapp.in</strong> of any unauthorised use of your account or any other breach of security</li><li>Not create multiple accounts or use another person's account without authorisation</li><li>Not use automated means (bots, scripts, crawlers) to access or interact with the Platform</li></ul><p>We reserve the right to suspend or terminate accounts that contain false or misleading information, or that violate these Terms.</p><h2 id=\\"services\\">4. Services</h2><h3>a) Nature of the Platform</h3><p>JAGO provides a technology platform that connects Users seeking transportation or delivery services with independent Driver-Partners who provide such services. <strong>The Company does not itself provide transportation, courier, or delivery services.</strong> Driver-Partners are independent contractors and are not employees, agents, or representatives of Mindwhile IT Solutions Pvt Ltd or JAGO.</p><h3>b) Ride-Sharing Services</h3><p>Users may book rides in various vehicle categories (two-wheelers, auto-rickshaws, hatchbacks, sedans, SUVs, and premium vehicles, as available in your city). The Platform displays estimated fares before booking confirmation. Actual fares may vary based on the route taken, traffic conditions, waiting time, and applicable surge pricing.</p><h3>c) Parcel Delivery Services</h3><p>Users may send parcels through the Platform by specifying pickup and delivery addresses, parcel dimensions, and weight category. The following conditions apply to parcel delivery:</p><ul><li>Maximum parcel weight and dimension limits as specified in the app must be adhered to</li><li>Prohibited items include hazardous materials, illegal substances, perishable goods (unless specified), live animals, firearms, and any items prohibited under Indian law</li><li>The Sender is responsible for proper packaging and accurate description of parcel contents</li><li>JAGO's liability for parcel damage or loss is limited as specified in Section 10 of these Terms</li><li>Proof of delivery (OTP verification or digital signature) will be required at the delivery location</li></ul><h3>d) Car-Sharing Services</h3><p>JAGO may offer car-sharing or carpooling services where multiple riders heading in similar directions can share a vehicle. Fares for car-sharing rides are divided among co-travellers as calculated by the Platform. All car-sharing participants are verified JAGO users.</p><h3>e) Service Availability</h3><p>Services are subject to availability and may vary by city, time, and operational capacity. We reserve the right to modify, suspend, or discontinue any service category at any time with or without notice.</p><h2 id=\\"payments\\">5. Payments and Pricing</h2><h3>a) Fare Calculation</h3><p>Fares for rides and deliveries are calculated by JAGO's proprietary fare engine based on the following factors:</p><ul><li><strong>Base Fare:</strong> A fixed starting charge applicable to each ride or delivery</li><li><strong>Distance Charge:</strong> Per-kilometre rate based on the distance travelled (calculated via GPS)</li><li><strong>Time Charge:</strong> Per-minute charge for the duration of the ride, including waiting time</li><li><strong>Surge Pricing:</strong> Dynamic pricing multiplier applied during periods of high demand (peak hours, rain, festivals, etc.). Surge pricing will be clearly displayed and requires your confirmation before booking</li><li><strong>Toll Charges:</strong> Any applicable toll, parking, or road-use fees incurred during the ride (passed through to the rider)</li><li><strong>Taxes:</strong> Applicable Goods and Services Tax (GST) at the rate prescribed by the Government of India</li></ul><p>An estimated fare will be displayed before booking. The final fare may differ from the estimate due to route changes, traffic conditions, or additional stops requested during the ride.</p><h3>b) Payment Methods</h3><p>JAGO accepts the following payment methods:</p><ul><li>Cash payment to the Driver-Partner</li><li>UPI (Unified Payments Interface) — Google Pay, PhonePe, Paytm, BHIM, etc.</li><li>Credit and debit cards (Visa, Mastercard, RuPay)</li><li>Net banking</li><li>JAGO Wallet (prepaid in-app wallet)</li><li>Other payment methods as introduced from time to time</li></ul><h3>c) JAGO Wallet</h3><p>The JAGO Wallet is a prepaid digital wallet that can be topped up using any supported payment method. Wallet balances are non-transferable and cannot be withdrawn as cash except as required by applicable law. Promotional credits added to the wallet may have expiry dates and usage restrictions.</p><h3>d) Invoices and Receipts</h3><p>Digital invoices and receipts for all transactions are generated automatically and available in the app. GST-compliant invoices will include the Company's GSTIN and all details as required under GST regulations.</p><h2 id=\\"cancellation\\">6. Cancellation and Refund Policy</h2><h3>a) Rider Cancellations</h3><ul><li>Riders may cancel a booking at any time before the ride or delivery commences</li><li>Free cancellation is permitted within 2 minutes of booking or before the Driver-Partner has been assigned (whichever is later)</li><li>A cancellation fee will be charged if cancellation occurs after the Driver-Partner has been assigned and is en route to the pickup location. The cancellation fee amount is displayed in the app before confirmation</li><li>Cancellation fee distribution: 60% retained by the Company as platform fee and 40% paid to the Driver-Partner as compensation for their time and fuel</li></ul><h3>b) Driver-Partner Cancellations</h3><ul><li>Driver-Partners who accept a ride request are expected to complete the trip</li><li>Repeated cancellations by Driver-Partners may result in temporary suspension, reduced ride allocation priority, or permanent deactivation</li><li>Cancellation due to safety concerns, vehicle breakdown, or rider no-show (after the designated waiting period) will not attract penalties</li></ul><h3>c) Refunds</h3><ul><li>Refunds for overcharges, duplicate payments, or service failures will be processed within 5-7 business days</li><li>Refunds will be credited to the original payment method or to the JAGO Wallet, at the Company's discretion</li><li>Refund requests must be raised within 48 hours of the completed trip through the app or by contacting support@jagoapp.in</li><li>The Company reserves the right to investigate refund claims and deny refunds found to be fraudulent or in violation of these Terms</li></ul><h2 id=\\"user-conduct\\">7. User Conduct</h2><p>By using the JAGO Platform, all Users agree to:</p><ul><li>Use the Platform only for lawful purposes and in compliance with all applicable Indian laws and regulations</li><li>Treat Driver-Partners, co-riders, and support staff with courtesy, dignity, and respect at all times</li><li>Not engage in any form of harassment, discrimination, verbal abuse, physical violence, or threatening behaviour</li><li>Not use the Platform for any fraudulent, deceptive, or illegal activity</li><li>Not attempt to manipulate fares, ratings, or referral programmes through dishonest means</li><li>Not consume alcohol or illegal substances during a ride</li><li>Wear a helmet when travelling on two-wheelers (as mandated by the Motor Vehicles Act, 1988)</li><li>Wear seatbelts when travelling in four-wheelers</li><li>Not carry prohibited items including weapons, explosives, illegal drugs, or hazardous materials</li><li>Not interfere with the Driver-Partner's ability to drive safely</li><li>Ensure that children under 12 years of age are accompanied by a responsible adult during rides</li><li>Not copy, reverse-engineer, decompile, or attempt to extract the source code of the Platform</li><li>Not use the Platform to transmit spam, malware, or any harmful content</li></ul><p>Violation of these conduct standards may result in warnings, temporary suspension, permanent account termination, and/or reporting to law enforcement authorities.</p><h2 id=\\"driver-obligations\\">8. Driver-Partner Obligations</h2><p>Driver-Partners who provide services through the JAGO Platform agree to the following obligations:</p><h3>a) Documentation and Compliance</h3><ul><li>Maintain a valid driving licence appropriate for the vehicle category at all times</li><li>Ensure the vehicle has current registration (RC), comprehensive insurance, fitness certificate, and PUC certificate</li><li>Obtain and maintain any commercial permits or badges required by local transport authorities</li><li>Comply with all applicable provisions of the Motor Vehicles Act, 1988, and state transport regulations</li></ul><h3>b) Service Standards</h3><ul><li>Provide rides and deliveries in a safe, professional, and timely manner</li><li>Follow the route suggested by the Platform unless a different route is agreed upon with the rider</li><li>Keep the vehicle clean, well-maintained, and in safe operating condition</li><li>Not refuse rides based on the rider's destination, gender, caste, religion, or any discriminatory criteria</li><li>Not demand cash payments when the rider has selected a digital payment method</li><li>Maintain a minimum service quality rating as specified by the Platform</li></ul><h3>c) Safety Obligations</h3><ul><li>Follow all traffic rules and speed limits</li><li>Not operate the vehicle under the influence of alcohol or drugs</li><li>Ensure helmet availability for two-wheeler rides (for both rider and pillion)</li><li>Immediately report any accident, safety incident, or emergency through the Platform</li><li>Cooperate with JAGO's safety team during incident investigations</li></ul><h3>d) Financial Obligations</h3><ul><li>Pay the applicable platform commission or subscription fee as agreed</li><li>Maintain accurate records of cash collections and settle balances with the Platform as required</li><li>File all required tax returns and maintain GST registration where applicable</li></ul><h2 id=\\"intellectual-property\\">9. Intellectual Property</h2><p>All intellectual property rights in and to the Platform, including but not limited to:</p><ul><li>The JAGO name, logo, and brand identity</li><li>Software, source code, algorithms, and technical infrastructure</li><li>Website and app design, layout, user interface, and user experience elements</li><li>Text, graphics, images, audio, video, and other content</li><li>Trademarks, service marks, trade dress, and trade names</li><li>Patents, trade secrets, and proprietary methodologies</li></ul><p>are the exclusive property of <strong>Mindwhile IT Solutions Pvt Ltd</strong> and are protected under the Copyright Act, 1957, the Trade Marks Act, 1999, the Patents Act, 1970, the Information Technology Act, 2000, and other applicable Indian and international intellectual property laws.</p><p>You are granted a limited, non-exclusive, non-transferable, revocable licence to access and use the Platform solely for your personal, non-commercial use in accordance with these Terms. You may not:</p><ul><li>Copy, modify, distribute, sell, or lease any part of the Platform</li><li>Reverse-engineer, decompile, or disassemble the Platform's software</li><li>Use the JAGO name, logo, or any trademarks without prior written consent</li><li>Create derivative works based on the Platform's content or functionality</li><li>Scrape, data-mine, or extract data from the Platform using automated tools</li></ul><h2 id=\\"liability\\">10. Limitation of Liability</h2><p>To the maximum extent permitted by applicable Indian law:</p><ul><li>The Platform is provided on an \\"as-is\\" and \\"as-available\\" basis without warranties of any kind, whether express or implied</li><li>The Company does not guarantee uninterrupted, error-free, or secure operation of the Platform</li><li>The Company is not liable for the conduct, actions, or omissions of Driver-Partners, Riders, or other Users</li><li>The Company shall not be held responsible for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of profits, data, goodwill, or business opportunities</li><li>The Company's total aggregate liability for any claims arising from or related to your use of the Platform shall not exceed the amount paid by you to the Company in the 12 months preceding the claim</li><li>The Company is not liable for delays, cancellations, or service failures caused by force majeure events including natural disasters, pandemics, government actions, strikes, wars, riots, or infrastructure failures</li><li>For parcel delivery services, the Company's liability for loss or damage to parcels is limited to the declared value of the parcel or ₹5,000 (Indian Rupees Five Thousand), whichever is lower, unless additional insurance coverage has been purchased</li></ul><h2 id=\\"indemnification\\">11. Indemnification</h2><p>You agree to indemnify, defend, and hold harmless Mindwhile IT Solutions Pvt Ltd, its directors, officers, employees, contractors, agents, affiliates, and partners from and against any and all claims, demands, actions, damages, losses, liabilities, costs, and expenses (including reasonable legal fees) arising out of or in connection with:</p><ul><li>Your use of or access to the Platform</li><li>Your breach of any provision of these Terms</li><li>Your violation of any applicable Indian law, rule, or regulation</li><li>Your infringement of any third-party rights, including intellectual property rights, privacy rights, or contractual rights</li><li>Any content, material, or information you submit, post, or transmit through the Platform</li><li>Any dispute between you and another User of the Platform</li><li>Any damage to persons or property arising from your use of the Services</li></ul><p>This indemnification obligation shall survive the termination of your account and these Terms.</p><h2 id=\\"termination\\">12. Termination</h2><h3>a) Termination by the Company</h3><p>We reserve the right to suspend, restrict, or terminate your access to the Platform at our sole discretion, with or without notice, for reasons including but not limited to:</p><ul><li>Violation of any provision of these Terms</li><li>Engagement in fraudulent, illegal, or abusive activity</li><li>Receipt of consistent low ratings or multiple verified complaints</li><li>Failure to maintain required documentation (for Driver-Partners)</li><li>Non-payment of outstanding dues or settlement obligations</li><li>Request or order from law enforcement or government authorities</li><li>Extended period of account inactivity (exceeding 12 months)</li></ul><h3>b) Termination by User</h3><p>You may terminate your account at any time by:</p><ul><li>Using the account deletion feature in the app settings</li><li>Contacting our support team at <strong>support@jagoapp.in</strong></li></ul><p>Upon termination, any outstanding payments owed by you to the Company or Driver-Partners shall remain due and payable. Any remaining JAGO Wallet balance (excluding promotional credits) shall be refunded to your linked bank account within 30 business days.</p><h3>c) Effect of Termination</h3><p>Upon termination, your right to access and use the Platform ceases immediately. The Company may retain your data as required by law and as described in our Privacy Policy. Sections of these Terms that by their nature should survive termination (including but not limited to Limitation of Liability, Indemnification, Intellectual Property, and Governing Law) shall continue to apply.</p><h2 id=\\"governing-law\\">13. Governing Law and Dispute Resolution</h2><h3>a) Governing Law</h3><p>These Terms shall be governed by, construed, and enforced in accordance with the laws of the Republic of India, without regard to its conflict of law provisions. All applicable Indian laws including the Information Technology Act, 2000, the Consumer Protection Act, 2019, the Indian Contract Act, 1872, and the Motor Vehicles Act, 1988 shall apply.</p><h3>b) Dispute Resolution</h3><p>In the event of any dispute, controversy, or claim arising out of or relating to these Terms or the use of the Platform:</p><ul><li><strong>Step 1 — Informal Resolution:</strong> The parties shall first attempt to resolve the dispute amicably through good-faith negotiation within 30 days of written notice</li><li><strong>Step 2 — Mediation:</strong> If the dispute is not resolved through negotiation, the parties may agree to submit the dispute to mediation under the rules of the Indian Council of Arbitration</li><li><strong>Step 3 — Arbitration:</strong> If mediation fails, the dispute shall be referred to and finally resolved by arbitration in accordance with the Arbitration and Conciliation Act, 1996. The arbitration shall be conducted by a sole arbitrator appointed mutually by the parties, with the seat of arbitration in Hyderabad, Telangana, India. The language of arbitration shall be English</li></ul><h3>c) Jurisdiction</h3><p>Subject to the arbitration clause above, the courts of competent jurisdiction in <strong>Hyderabad, Telangana, India</strong> (including the Hon'ble High Court of Telangana) shall have exclusive jurisdiction over any legal proceedings arising out of or relating to these Terms.</p><h3>d) Consumer Grievance</h3><p>Nothing in these Terms shall limit your right to file a complaint with the Consumer Disputes Redressal Forum or Commission under the Consumer Protection Act, 2019, or to approach any other statutory forum or authority as provided under Indian law.</p><h2 id=\\"contact-terms\\">14. Contact Information</h2><p>For any questions, concerns, or feedback regarding these Terms and Conditions, please contact us:</p><ul><li><strong>Company:</strong> Mindwhile IT Solutions Pvt Ltd</li><li><strong>Platform:</strong> JAGO</li><li><strong>Email:</strong> support@jagoapp.in</li><li><strong>Legal Email:</strong> legal@jagoapp.in</li><li><strong>Phone:</strong> +91-9876543210</li><li><strong>Website:</strong> www.jagoapp.in</li><li><strong>Address:</strong> Mindwhile IT Solutions Pvt Ltd, Hyderabad, Telangana 500081, India</li></ul><p>For legal notices and formal correspondence, please send written communication to our registered office address or email legal@jagoapp.in.</p><p><em>These Terms and Conditions were last updated on February 15, 2026, and are effective immediately upon publication.</em></p>", "short_description": "These Terms and Conditions govern your access to and use of the JAGO platform and services. By using JAGO, you agree to be bound by these terms."}	pages_settings	2026-02-14 07:22:58.542877	2026-02-14 07:39:22.77365
25ccc3cd-ff56-42f0-9c28-09cb10958a32	google_map_api	{"map_api_key":"AIzaSyBOkqwbMyZssa9a2vrJxg40Bo3IBwlBJTw","map_api_key_server":"AIzaSyA34fb2p62TQhNqh8lWdbz86GMCFjBo2iM"}	google_map_api	2026-02-14 06:37:23	2026-02-15 12:50:00
981fba95-a445-4690-9f39-1b9f2913dc5f	business_contact_email	"support@jagoapp.in"	business_information	2026-02-14 07:23:22.082409	2026-02-14 07:23:22.082409
f0439f8c-ce5b-4d36-bc0e-fc306d488307	business_contact_phone	"+91-9876543210"	business_information	2026-02-14 07:23:22.082409	2026-02-14 07:23:22.082409
9b0bdb02-6c49-4c87-a471-f6be0930ba55	business_address	"Hyderabad, Telangana, India"	business_information	2026-02-14 07:23:22.082409	2026-02-14 07:23:22.082409
0320e792-d1ab-4359-a8f2-f8012fe4e0bc	copyright_text	"© 2026 JAGO. A product of Mindwhile IT Solutions Pvt Ltd. All rights reserved."	business_information	2026-02-14 07:23:22.082409	2026-02-14 07:23:22.082409
5e45a77c-412e-4c50-8986-c682e68e79a0	country_code	"IN"	business_information	2026-02-14 09:05:19.995738	2026-02-14 09:05:19.995738
e79239e8-5d60-4518-988d-ff33d3503d31	currency_code	"INR"	business_information	2026-02-14 09:05:19.995738	2026-02-14 09:05:19.995738
d3c657ca-1ef3-4acb-af6d-6700459d2f60	currency_symbol	"₹"	business_information	2026-02-14 09:05:19.995738	2026-02-14 09:05:19.995738
1de04021-6837-4122-b353-7f5494731e2f	currency_symbol_position	"left"	business_information	2026-02-14 09:05:19.995738	2026-02-14 09:05:19.995738
bac6db66-5a70-4046-b35b-a9c0b6c12562	currency_decimal_point	"2"	business_information	2026-02-14 09:05:19.995738	2026-02-14 09:05:19.995738
64776b6c-5d32-435f-98e1-f3175a727c93	safety_feature_status	"1"	safety_feature_settings	2026-02-14 10:49:36	2026-02-14 10:49:36
4fe3d4cd-adab-432f-a89f-cbc32ee6d0f3	chatting_setup_status	"1"	chatting_settings	2026-02-14 10:50:04	2026-02-14 10:50:04
abc1bea2-f525-410e-9cd2-3555a552b291	driver_question_answer_status	"1"	chatting_settings	2026-02-14 10:50:15	2026-02-14 10:50:15
b7081d5f-fbcf-4db3-9e7b-93d12917bd09	subscription_model_enabled	0	business_settings	2026-02-14 14:23:06.024015	2026-02-14 14:23:06.024015
ca1a098c-14b7-468e-a8ea-7220d0a8335f	free_ride_limit	200	business_settings	2026-02-14 14:23:06.024015	2026-02-14 14:23:06.024015
50f7eb2d-045e-4933-993b-eac360117bf1	negative_balance_limit	200	business_settings	2026-02-14 14:23:06.024015	2026-02-14 14:23:06.024015
6877dd90-2a82-4fab-8cea-0c56d7f6c296	helper_service_enabled	1	trip_settings	2026-02-14 17:41:58.852487	2026-02-14 17:41:58.852487
2412743c-17b4-4050-864b-ebf61dc30379	helper_rate_per_hour	100	trip_settings	2026-02-14 17:41:58.852487	2026-02-14 17:41:58.852487
a9b62580-8350-46ba-b3d7-616e756244d2	parcel_receiver_otp_verification	1	parcel_settings	2026-02-14 17:41:58.852487	2026-02-14 17:41:58.852487
ff9b67ee-2b6e-42fe-a2db-9942079f71a7	driver_self_registration	1	driver_settings	2026-02-14 18:29:55.524218	2026-02-14 18:29:55.524218
73bcece2-d55d-47a0-9b7e-91e8ecc0f562	vat_percent	18	business_settings	2026-02-15 07:53:42.400612	2026-02-15 07:53:42.400612
e85bc32b-65ff-4e4e-8aca-380d8fd3b4c3	trip_commission	15	business_settings	2026-02-15 07:53:42.400612	2026-02-15 07:53:42.400612
dbeb69e5-5a67-427e-a6c4-520c3e3c3c92	parcel_commission_enabled	1	business_settings	2026-02-15 02:31:03.977529	2026-02-15 02:31:03.977529
68a4b32a-f247-4ca2-a6a4-d35e8f6100bd	parcel_commission_percent	15	business_settings	2026-02-15 02:31:03.977529	2026-02-15 02:31:03.977529
9553435a-c0de-4e7b-9cec-9f7c96609fc1	car_sharing_enabled	1	business_settings	2026-02-15 08:30:17	2026-02-15 08:30:17
89efaa2e-4420-4a96-8d38-58ffe7acf57c	senior_citizen_discount_enabled	0	parcel_settings	2026-02-15 08:41:30	2026-02-15 08:41:30
8c8ec9b3-fca4-4c1d-8cbc-8ce543064e56	senior_citizen_discount_percent	10	parcel_settings	2026-02-15 08:41:30	2026-02-15 08:41:30
2a68e695-c9ae-48dc-bc1a-d4e7642a78ad	senior_citizen_min_age	60	parcel_settings	2026-02-15 08:41:30	2026-02-15 08:41:30
2c1e2f74-e0b2-4d1b-b43b-759a66658661	student_discount_enabled	0	parcel_settings	2026-02-15 08:41:30	2026-02-15 08:41:30
69f5fa3c-75f2-4891-8093-950cdf8ed5eb	student_discount_percent	15	parcel_settings	2026-02-15 08:41:30	2026-02-15 08:41:30
5fcac153-7ccb-4968-bf83-aa7d4976de4e	outstation_service_enabled	0	parcel_settings	2026-02-15 08:41:30	2026-02-15 08:41:30
a49de91b-1030-4648-ad4e-42b16cc2538b	outstation_min_distance_km	50	parcel_settings	2026-02-15 08:41:30	2026-02-15 08:41:30
8485f2e2-d5f0-4af9-ba3e-39b11b2bc38b	outstation_fare_multiplier	1.5	parcel_settings	2026-02-15 08:41:30	2026-02-15 08:41:30
173b704e-2216-4257-8726-b4025a8957c9	firebase_otp_verification_status	1	firebase_otp	2026-02-15 12:49:29	2026-02-15 12:49:29
60752063-d6bf-4682-9347-74efa2094703	firebase_otp_web_api_key	"AIzaSyCckhJY3NMZTjOkXWMJhor_GIMmQflo1U8"	firebase_otp	2026-02-15 12:49:29	2026-02-15 12:49:29
521cc616-f31f-4509-9360-9d44178f1461	legal	{"image":"","name":"legal","short_description":"Legal information and disclosures for JAGO, a product of Mindwhile IT Solutions Pvt Ltd.","long_description":"<h2>Legal Information<\\/h2><h3>Company Information<\\/h3><p><strong>JAGO<\\/strong> is a registered trademark and product of:<\\/p><p><strong>Mindwhile IT Solutions Pvt Ltd<\\/strong><br>Registered under the Companies Act, 2013<br>Hyderabad, Telangana, India<\\/p><h3>Nature of Business<\\/h3><p>Mindwhile IT Solutions Pvt Ltd operates JAGO as a technology platform that connects customers with independent driver partners for ride-sharing and parcel delivery services. The Company acts as an intermediary technology service provider and does not directly provide transportation or delivery services.<\\/p><h3>Regulatory Compliance<\\/h3><p>JAGO operates in compliance with:<\\/p><ul><li>Information Technology Act, 2000 and IT Rules, 2011<\\/li><li>Motor Vehicles Act, 1988 (as applicable to aggregator platforms)<\\/li><li>Consumer Protection Act, 2019<\\/li><li>Payment and Settlement Systems Act, 2007 (for digital payments)<\\/li><li>Goods and Services Tax (GST) regulations<\\/li><li>Applicable state-level transportation and aggregator regulations<\\/li><\\/ul><h3>Intellectual Property<\\/h3><p>The JAGO name, logo, brand identity, mobile applications, website, and all associated intellectual property are owned by Mindwhile IT Solutions Pvt Ltd. Any unauthorized use, reproduction, modification, or distribution of these assets is strictly prohibited and may result in legal action.<\\/p><h3>Disclaimer<\\/h3><ul><li>The information provided on this Platform is for general informational purposes only<\\/li><li>While we strive to keep information accurate and up-to-date, we make no warranties about the completeness, reliability, or accuracy of this information<\\/li><li>Any action you take based on the information on this Platform is strictly at your own risk<\\/li><li>JAGO shall not be liable for any losses or damages in connection with the use of the Platform<\\/li><\\/ul><h3>Grievance Redressal<\\/h3><p>In compliance with the Information Technology Act, 2000 and applicable rules, the Grievance Officer for JAGO is:<\\/p><p><strong>Grievance Officer<\\/strong><br>Mindwhile IT Solutions Pvt Ltd<br>Email: grievance@jagoapp.in<br>Response Time: Within 48 hours of receiving the complaint<br>Resolution Time: Within 30 days as per applicable regulations<\\/p><h3>Refund Policy<\\/h3><ul><li>Refunds for cancelled rides are processed as per the cancellation policy<\\/li><li>Refund requests are reviewed on a case-by-case basis<\\/li><li>Approved refunds are credited to the original payment method within 5-7 business days<\\/li><li>Wallet refunds are processed instantly<\\/li><\\/ul><h3>Dispute Resolution<\\/h3><p>In case of any dispute arising from the use of JAGO services:<\\/p><ol><li>Users are encouraged to first contact our customer support team<\\/li><li>If unresolved, a formal complaint can be filed with the Grievance Officer<\\/li><li>Disputes shall be subject to arbitration under the Arbitration and Conciliation Act, 1996<\\/li><li>The seat of arbitration shall be Hyderabad, Telangana, India<\\/li><\\/ol><p><em>This legal page is subject to periodic updates. Please check back regularly for the latest information.<\\/em><\\/p><p><strong>Mindwhile IT Solutions Pvt Ltd<\\/strong><br>www.jagoapp.in<\\/p>"}	pages_settings	2026-02-14 07:22:58.542877	2026-02-15 12:54:24
fd44b9e2-9190-4cb8-9959-abb948bfc617	server_key	{"project_id":"","private_key":"","client_email":"","type":"service_account"}	notification_settings	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
3aad231b-7d1d-4845-a19c-1f65c4f87e50	search_radius	5	trip_settings	2026-02-15 13:40:39.691522	2026-02-15 13:40:39.691522
b0193aa6-f00c-49ab-939e-eb5a102751be	city_sharing_enabled	1	business_settings	2026-02-17 12:13:01	2026-02-17 12:13:01
57d069fe-917e-459a-be0f-1c2cd9013b84	outstation_sharing_enabled	1	business_settings	2026-02-17 12:13:01	2026-02-17 12:13:01
bff4d860-9d29-4499-a2d2-dbdade39ae88	city_sharing_commission_percent	20	business_settings	2026-02-17 12:13:01	2026-02-17 12:13:01
049c10b0-7396-4646-a43e-b15f66dccc98	outstation_sharing_commission_percent	15	business_settings	2026-02-17 12:13:01	2026-02-17 12:13:01
d21e90fa-db54-4c7d-a32c-e95707db5f91	city_sharing_gst_percent	5	business_settings	2026-02-17 12:13:01	2026-02-17 12:13:01
4a167813-fa29-43d7-a133-9282cf4b446c	outstation_sharing_gst_percent	5	business_settings	2026-02-17 12:13:01	2026-02-17 12:13:01
e344f148-d12d-43ff-87a1-63332ee4bde4	city_sharing_max_detour_km	3	business_settings	2026-02-17 12:13:01	2026-02-17 12:13:01
b6f8bd55-defb-4d63-93f9-5e07db4809c4	outstation_sharing_max_detour_km	10	business_settings	2026-02-17 12:13:01	2026-02-17 12:13:01
4e983ee3-0cd8-475e-8235-07e7e7bc099f	parcel_weight_unit	"kg"	parcel_settings	2026-02-17 14:45:31	2026-02-17 14:45:31
26e8f0cf-9f9c-4420-9165-57822bb6a5fb	parcel_commission	"10"	parcel_settings	2026-02-17 14:45:31	2026-02-17 14:45:31
df4f277a-b898-4e5e-b545-29a12eec9701	parcel_active	"1"	parcel_settings	2026-02-17 14:45:31	2026-02-17 14:45:31
daa20312-e06e-4996-b041-5a9320b7da8a	earning_model	subscription	business_settings	2026-02-15 10:01:08	2026-02-15 10:01:08
763402b9-ade0-4263-8de3-b56ecf10c503	platform_fee_amount	20	business_settings	2026-02-15 10:01:08	2026-02-15 10:01:08
\.


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cache (key, value, expiration) FROM stdin;
drivemond_cachebiz_cfg_system_language_language_settings	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiI5YzdkZTVkOS1kOTA0LTRmMGItOWVhMy04NGE3MzY3MWNjYWUiO3M6ODoia2V5X25hbWUiO3M6MTU6InN5c3RlbV9sYW5ndWFnZSI7czo1OiJ2YWx1ZSI7czoxOTg6Ilt7ImlkIjoxLCJkaXJlY3Rpb24iOiJsdHIiLCJjb2RlIjoiZW4iLCJzdGF0dXMiOjEsImRlZmF1bHQiOnRydWV9LHsiaWQiOjIsImRpcmVjdGlvbiI6Imx0ciIsImNvZGUiOiJ0ZSIsInN0YXR1cyI6MSwiZGVmYXVsdCI6ZmFsc2V9LHsiaWQiOjMsImRpcmVjdGlvbiI6Imx0ciIsImNvZGUiOiJoaSIsInN0YXR1cyI6MSwiZGVmYXVsdCI6ZmFsc2V9XSI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoxNzoibGFuZ3VhZ2Vfc2V0dGluZ3MiO3M6MTA6ImNyZWF0ZWRfYXQiO3M6MTk6IjIwMjYtMDItMTQgMDU6NTU6MjAiO3M6MTA6InVwZGF0ZWRfYXQiO3M6MTk6IjIwMjYtMDItMTQgMDY6NDg6MTMiO31zOjExOiIAKgBvcmlnaW5hbCI7YTo2OntzOjI6ImlkIjtzOjM2OiI5YzdkZTVkOS1kOTA0LTRmMGItOWVhMy04NGE3MzY3MWNjYWUiO3M6ODoia2V5X25hbWUiO3M6MTU6InN5c3RlbV9sYW5ndWFnZSI7czo1OiJ2YWx1ZSI7czoxOTg6Ilt7ImlkIjoxLCJkaXJlY3Rpb24iOiJsdHIiLCJjb2RlIjoiZW4iLCJzdGF0dXMiOjEsImRlZmF1bHQiOnRydWV9LHsiaWQiOjIsImRpcmVjdGlvbiI6Imx0ciIsImNvZGUiOiJ0ZSIsInN0YXR1cyI6MSwiZGVmYXVsdCI6ZmFsc2V9LHsiaWQiOjMsImRpcmVjdGlvbiI6Imx0ciIsImNvZGUiOiJoaSIsInN0YXR1cyI6MSwiZGVmYXVsdCI6ZmFsc2V9XSI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoxNzoibGFuZ3VhZ2Vfc2V0dGluZ3MiO3M6MTA6ImNyZWF0ZWRfYXQiO3M6MTk6IjIwMjYtMDItMTQgMDU6NTU6MjAiO3M6MTA6InVwZGF0ZWRfYXQiO3M6MTk6IjIwMjYtMDItMTQgMDY6NDg6MTMiO31zOjEwOiIAKgBjaGFuZ2VzIjthOjA6e31zOjExOiIAKgBwcmV2aW91cyI7YTowOnt9czo4OiIAKgBjYXN0cyI7YToxOntzOjU6InZhbHVlIjtzOjU6ImFycmF5Ijt9czoxNzoiACoAY2xhc3NDYXN0Q2FjaGUiO2E6MDp7fXM6MjE6IgAqAGF0dHJpYnV0ZUNhc3RDYWNoZSI7YTowOnt9czoxMzoiACoAZGF0ZUZvcm1hdCI7TjtzOjEwOiIAKgBhcHBlbmRzIjthOjA6e31zOjE5OiIAKgBkaXNwYXRjaGVzRXZlbnRzIjthOjA6e31zOjE0OiIAKgBvYnNlcnZhYmxlcyI7YTowOnt9czoxMjoiACoAcmVsYXRpb25zIjthOjA6e31zOjEwOiIAKgB0b3VjaGVzIjthOjA6e31zOjI3OiIAKgByZWxhdGlvbkF1dG9sb2FkQ2FsbGJhY2siO047czoyNjoiACoAcmVsYXRpb25BdXRvbG9hZENvbnRleHQiO047czoxMDoidGltZXN0YW1wcyI7YjoxO3M6MTM6InVzZXNVbmlxdWVJZHMiO2I6MDtzOjk6IgAqAGhpZGRlbiI7YTowOnt9czoxMDoiACoAdmlzaWJsZSI7YTowOnt9czoxMToiACoAZmlsbGFibGUiO2E6NTp7aTowO3M6ODoia2V5X25hbWUiO2k6MTtzOjU6InZhbHVlIjtpOjI7czoxMzoic2V0dGluZ3NfdHlwZSI7aTozO3M6MTA6ImNyZWF0ZWRfYXQiO2k6NDtzOjEwOiJ1cGRhdGVkX2F0Ijt9czoxMDoiACoAZ3VhcmRlZCI7YToxOntpOjA7czoxOiIqIjt9fQ==	1771352036
drivemond_cachebiz_cfg_customer_app_version_control_for_android_app_version	N;	1771352227
drivemond_cachebiz_cfg_email_config_email_config	N;	1771352395
drivemond_cachebiz_cfg_time_zone_business_information	N;	1771352395
drivemond_cachebiz_cfg_header_logo_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiJlZDE1MzU1OS01YTVmLTQ0ZDktOGY0ZC1iODc0NWZhODQ3YTQiO3M6ODoia2V5X25hbWUiO3M6MTE6ImhlYWRlcl9sb2dvIjtzOjU6InZhbHVlIjtzOjE5OiIiamFnby1sb2dvLW5ldy5wbmciIjtzOjEzOiJzZXR0aW5nc190eXBlIjtzOjIwOiJidXNpbmVzc19pbmZvcm1hdGlvbiI7czoxMDoiY3JlYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xMyAwNDo1ODo1OS4zNjA5MDUiO3M6MTA6InVwZGF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTMgMDQ6NTg6NTkuMzYwOTA1Ijt9czoxMToiACoAb3JpZ2luYWwiO2E6Njp7czoyOiJpZCI7czozNjoiZWQxNTM1NTktNWE1Zi00NGQ5LThmNGQtYjg3NDVmYTg0N2E0IjtzOjg6ImtleV9uYW1lIjtzOjExOiJoZWFkZXJfbG9nbyI7czo1OiJ2YWx1ZSI7czoxOToiImphZ28tbG9nby1uZXcucG5nIiI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMDoiYnVzaW5lc3NfaW5mb3JtYXRpb24iO3M6MTA6ImNyZWF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTMgMDQ6NTg6NTkuMzYwOTA1IjtzOjEwOiJ1cGRhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTEzIDA0OjU4OjU5LjM2MDkwNSI7fXM6MTA6IgAqAGNoYW5nZXMiO2E6MDp7fXM6MTE6IgAqAHByZXZpb3VzIjthOjA6e31zOjg6IgAqAGNhc3RzIjthOjE6e3M6NToidmFsdWUiO3M6NToiYXJyYXkiO31zOjE3OiIAKgBjbGFzc0Nhc3RDYWNoZSI7YTowOnt9czoyMToiACoAYXR0cmlidXRlQ2FzdENhY2hlIjthOjA6e31zOjEzOiIAKgBkYXRlRm9ybWF0IjtOO3M6MTA6IgAqAGFwcGVuZHMiO2E6MDp7fXM6MTk6IgAqAGRpc3BhdGNoZXNFdmVudHMiO2E6MDp7fXM6MTQ6IgAqAG9ic2VydmFibGVzIjthOjA6e31zOjEyOiIAKgByZWxhdGlvbnMiO2E6MDp7fXM6MTA6IgAqAHRvdWNoZXMiO2E6MDp7fXM6Mjc6IgAqAHJlbGF0aW9uQXV0b2xvYWRDYWxsYmFjayI7TjtzOjI2OiIAKgByZWxhdGlvbkF1dG9sb2FkQ29udGV4dCI7TjtzOjEwOiJ0aW1lc3RhbXBzIjtiOjE7czoxMzoidXNlc1VuaXF1ZUlkcyI7YjowO3M6OToiACoAaGlkZGVuIjthOjA6e31zOjEwOiIAKgB2aXNpYmxlIjthOjA6e31zOjExOiIAKgBmaWxsYWJsZSI7YTo1OntpOjA7czo4OiJrZXlfbmFtZSI7aToxO3M6NToidmFsdWUiO2k6MjtzOjEzOiJzZXR0aW5nc190eXBlIjtpOjM7czoxMDoiY3JlYXRlZF9hdCI7aTo0O3M6MTA6InVwZGF0ZWRfYXQiO31zOjEwOiIAKgBndWFyZGVkIjthOjE6e2k6MDtzOjE6IioiO319	1771352036
drivemond_cachebiz_cfg_favicon_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiIxOGIwNjE2Zi1lMDdhLTRkZDItYThhOS1iN2VhMWFjMTk0MmYiO3M6ODoia2V5X25hbWUiO3M6NzoiZmF2aWNvbiI7czo1OiJ2YWx1ZSI7czoxOToiImphZ28tbG9nby1uZXcucG5nIiI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMDoiYnVzaW5lc3NfaW5mb3JtYXRpb24iO3M6MTA6ImNyZWF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTMgMDQ6NTg6NTkuMzYwOTA1IjtzOjEwOiJ1cGRhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTEzIDA0OjU4OjU5LjM2MDkwNSI7fXM6MTE6IgAqAG9yaWdpbmFsIjthOjY6e3M6MjoiaWQiO3M6MzY6IjE4YjA2MTZmLWUwN2EtNGRkMi1hOGE5LWI3ZWExYWMxOTQyZiI7czo4OiJrZXlfbmFtZSI7czo3OiJmYXZpY29uIjtzOjU6InZhbHVlIjtzOjE5OiIiamFnby1sb2dvLW5ldy5wbmciIjtzOjEzOiJzZXR0aW5nc190eXBlIjtzOjIwOiJidXNpbmVzc19pbmZvcm1hdGlvbiI7czoxMDoiY3JlYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xMyAwNDo1ODo1OS4zNjA5MDUiO3M6MTA6InVwZGF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTMgMDQ6NTg6NTkuMzYwOTA1Ijt9czoxMDoiACoAY2hhbmdlcyI7YTowOnt9czoxMToiACoAcHJldmlvdXMiO2E6MDp7fXM6ODoiACoAY2FzdHMiO2E6MTp7czo1OiJ2YWx1ZSI7czo1OiJhcnJheSI7fXM6MTc6IgAqAGNsYXNzQ2FzdENhY2hlIjthOjA6e31zOjIxOiIAKgBhdHRyaWJ1dGVDYXN0Q2FjaGUiO2E6MDp7fXM6MTM6IgAqAGRhdGVGb3JtYXQiO047czoxMDoiACoAYXBwZW5kcyI7YTowOnt9czoxOToiACoAZGlzcGF0Y2hlc0V2ZW50cyI7YTowOnt9czoxNDoiACoAb2JzZXJ2YWJsZXMiO2E6MDp7fXM6MTI6IgAqAHJlbGF0aW9ucyI7YTowOnt9czoxMDoiACoAdG91Y2hlcyI7YTowOnt9czoyNzoiACoAcmVsYXRpb25BdXRvbG9hZENhbGxiYWNrIjtOO3M6MjY6IgAqAHJlbGF0aW9uQXV0b2xvYWRDb250ZXh0IjtOO3M6MTA6InRpbWVzdGFtcHMiO2I6MTtzOjEzOiJ1c2VzVW5pcXVlSWRzIjtiOjA7czo5OiIAKgBoaWRkZW4iO2E6MDp7fXM6MTA6IgAqAHZpc2libGUiO2E6MDp7fXM6MTE6IgAqAGZpbGxhYmxlIjthOjU6e2k6MDtzOjg6ImtleV9uYW1lIjtpOjE7czo1OiJ2YWx1ZSI7aToyO3M6MTM6InNldHRpbmdzX3R5cGUiO2k6MztzOjEwOiJjcmVhdGVkX2F0IjtpOjQ7czoxMDoidXBkYXRlZF9hdCI7fXM6MTA6IgAqAGd1YXJkZWQiO2E6MTp7aTowO3M6MToiKiI7fX0=	1771352036
drivemond_cachebiz_cfg_driver_app_version_control_for_android_app_version	N;	1771352227
drivemond_cachebiz_cfg_preloader_all	N;	1771352395
drivemond_cachebiz_cfg_driver_app_version_control_for_ios_app_version	N;	1771352227
drivemond_cachebiz_cfg_customer_app_version_control_for_ios_app_version	N;	1771352228
drivemond_cachebiz_cfg_recaptcha_all	N;	1771352395
drivemond_cachebiz_cfg_business_name_business_information	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiI5OWU3MDBhYS1lMDg5LTQ4OTctOTMxYi1mNzM4MTg4NTcxOGEiO3M6ODoia2V5X25hbWUiO3M6MTM6ImJ1c2luZXNzX25hbWUiO3M6NToidmFsdWUiO3M6NjoiIkpBR08iIjtzOjEzOiJzZXR0aW5nc190eXBlIjtzOjIwOiJidXNpbmVzc19pbmZvcm1hdGlvbiI7czoxMDoiY3JlYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xMyAwNDo1ODo1OS4zNjA5MDUiO3M6MTA6InVwZGF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTMgMDQ6NTg6NTkuMzYwOTA1Ijt9czoxMToiACoAb3JpZ2luYWwiO2E6Njp7czoyOiJpZCI7czozNjoiOTllNzAwYWEtZTA4OS00ODk3LTkzMWItZjczODE4ODU3MThhIjtzOjg6ImtleV9uYW1lIjtzOjEzOiJidXNpbmVzc19uYW1lIjtzOjU6InZhbHVlIjtzOjY6IiJKQUdPIiI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMDoiYnVzaW5lc3NfaW5mb3JtYXRpb24iO3M6MTA6ImNyZWF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTMgMDQ6NTg6NTkuMzYwOTA1IjtzOjEwOiJ1cGRhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTEzIDA0OjU4OjU5LjM2MDkwNSI7fXM6MTA6IgAqAGNoYW5nZXMiO2E6MDp7fXM6MTE6IgAqAHByZXZpb3VzIjthOjA6e31zOjg6IgAqAGNhc3RzIjthOjE6e3M6NToidmFsdWUiO3M6NToiYXJyYXkiO31zOjE3OiIAKgBjbGFzc0Nhc3RDYWNoZSI7YTowOnt9czoyMToiACoAYXR0cmlidXRlQ2FzdENhY2hlIjthOjA6e31zOjEzOiIAKgBkYXRlRm9ybWF0IjtOO3M6MTA6IgAqAGFwcGVuZHMiO2E6MDp7fXM6MTk6IgAqAGRpc3BhdGNoZXNFdmVudHMiO2E6MDp7fXM6MTQ6IgAqAG9ic2VydmFibGVzIjthOjA6e31zOjEyOiIAKgByZWxhdGlvbnMiO2E6MDp7fXM6MTA6IgAqAHRvdWNoZXMiO2E6MDp7fXM6Mjc6IgAqAHJlbGF0aW9uQXV0b2xvYWRDYWxsYmFjayI7TjtzOjI2OiIAKgByZWxhdGlvbkF1dG9sb2FkQ29udGV4dCI7TjtzOjEwOiJ0aW1lc3RhbXBzIjtiOjE7czoxMzoidXNlc1VuaXF1ZUlkcyI7YjowO3M6OToiACoAaGlkZGVuIjthOjA6e31zOjEwOiIAKgB2aXNpYmxlIjthOjA6e31zOjExOiIAKgBmaWxsYWJsZSI7YTo1OntpOjA7czo4OiJrZXlfbmFtZSI7aToxO3M6NToidmFsdWUiO2k6MjtzOjEzOiJzZXR0aW5nc190eXBlIjtpOjM7czoxMDoiY3JlYXRlZF9hdCI7aTo0O3M6MTA6InVwZGF0ZWRfYXQiO31zOjEwOiIAKgBndWFyZGVkIjthOjE6e2k6MDtzOjE6IioiO319	1771352049
drivemond_cachebiz_cfg_website_color_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiIxOWJjYzJiNC0yY2FiLTQ2ZmMtOTY2Zi0zOTY1MzJhOTRkMTkiO3M6ODoia2V5X25hbWUiO3M6MTM6IndlYnNpdGVfY29sb3IiO3M6NToidmFsdWUiO3M6NjY6InsicHJpbWFyeSI6IiMyNTYzRUIiLCJzZWNvbmRhcnkiOiIjREJFQUZFIiwiYmFja2dyb3VuZCI6IiNGMUY1RjkifSI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMToibGFuZGluZ19wYWdlX3NldHRpbmdzIjtzOjEwOiJjcmVhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTEzIDA0OjU4OjU5LjM2MDkwNSI7czoxMDoidXBkYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xMyAwNDo1ODo1OS4zNjA5MDUiO31zOjExOiIAKgBvcmlnaW5hbCI7YTo2OntzOjI6ImlkIjtzOjM2OiIxOWJjYzJiNC0yY2FiLTQ2ZmMtOTY2Zi0zOTY1MzJhOTRkMTkiO3M6ODoia2V5X25hbWUiO3M6MTM6IndlYnNpdGVfY29sb3IiO3M6NToidmFsdWUiO3M6NjY6InsicHJpbWFyeSI6IiMyNTYzRUIiLCJzZWNvbmRhcnkiOiIjREJFQUZFIiwiYmFja2dyb3VuZCI6IiNGMUY1RjkifSI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMToibGFuZGluZ19wYWdlX3NldHRpbmdzIjtzOjEwOiJjcmVhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTEzIDA0OjU4OjU5LjM2MDkwNSI7czoxMDoidXBkYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xMyAwNDo1ODo1OS4zNjA5MDUiO31zOjEwOiIAKgBjaGFuZ2VzIjthOjA6e31zOjExOiIAKgBwcmV2aW91cyI7YTowOnt9czo4OiIAKgBjYXN0cyI7YToxOntzOjU6InZhbHVlIjtzOjU6ImFycmF5Ijt9czoxNzoiACoAY2xhc3NDYXN0Q2FjaGUiO2E6MDp7fXM6MjE6IgAqAGF0dHJpYnV0ZUNhc3RDYWNoZSI7YTowOnt9czoxMzoiACoAZGF0ZUZvcm1hdCI7TjtzOjEwOiIAKgBhcHBlbmRzIjthOjA6e31zOjE5OiIAKgBkaXNwYXRjaGVzRXZlbnRzIjthOjA6e31zOjE0OiIAKgBvYnNlcnZhYmxlcyI7YTowOnt9czoxMjoiACoAcmVsYXRpb25zIjthOjA6e31zOjEwOiIAKgB0b3VjaGVzIjthOjA6e31zOjI3OiIAKgByZWxhdGlvbkF1dG9sb2FkQ2FsbGJhY2siO047czoyNjoiACoAcmVsYXRpb25BdXRvbG9hZENvbnRleHQiO047czoxMDoidGltZXN0YW1wcyI7YjoxO3M6MTM6InVzZXNVbmlxdWVJZHMiO2I6MDtzOjk6IgAqAGhpZGRlbiI7YTowOnt9czoxMDoiACoAdmlzaWJsZSI7YTowOnt9czoxMToiACoAZmlsbGFibGUiO2E6NTp7aTowO3M6ODoia2V5X25hbWUiO2k6MTtzOjU6InZhbHVlIjtpOjI7czoxMzoic2V0dGluZ3NfdHlwZSI7aTozO3M6MTA6ImNyZWF0ZWRfYXQiO2k6NDtzOjEwOiJ1cGRhdGVkX2F0Ijt9czoxMDoiACoAZ3VhcmRlZCI7YToxOntpOjA7czoxOiIqIjt9fQ==	1771352049
drivemond_cachebiz_cfg_text_color_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiI1YWVjMDk5NC01YWVhLTQxZDgtYmQ1Yi0wYWI0OGU5MDkxMjMiO3M6ODoia2V5X25hbWUiO3M6MTA6InRleHRfY29sb3IiO3M6NToidmFsdWUiO3M6Mzk6InsicHJpbWFyeSI6IiMwRjE3MkEiLCJsaWdodCI6IiM2NDc0OEIifSI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMToibGFuZGluZ19wYWdlX3NldHRpbmdzIjtzOjEwOiJjcmVhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTEzIDA0OjU4OjU5LjM2MDkwNSI7czoxMDoidXBkYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xMyAwNDo1ODo1OS4zNjA5MDUiO31zOjExOiIAKgBvcmlnaW5hbCI7YTo2OntzOjI6ImlkIjtzOjM2OiI1YWVjMDk5NC01YWVhLTQxZDgtYmQ1Yi0wYWI0OGU5MDkxMjMiO3M6ODoia2V5X25hbWUiO3M6MTA6InRleHRfY29sb3IiO3M6NToidmFsdWUiO3M6Mzk6InsicHJpbWFyeSI6IiMwRjE3MkEiLCJsaWdodCI6IiM2NDc0OEIifSI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMToibGFuZGluZ19wYWdlX3NldHRpbmdzIjtzOjEwOiJjcmVhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTEzIDA0OjU4OjU5LjM2MDkwNSI7czoxMDoidXBkYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xMyAwNDo1ODo1OS4zNjA5MDUiO31zOjEwOiIAKgBjaGFuZ2VzIjthOjA6e31zOjExOiIAKgBwcmV2aW91cyI7YTowOnt9czo4OiIAKgBjYXN0cyI7YToxOntzOjU6InZhbHVlIjtzOjU6ImFycmF5Ijt9czoxNzoiACoAY2xhc3NDYXN0Q2FjaGUiO2E6MDp7fXM6MjE6IgAqAGF0dHJpYnV0ZUNhc3RDYWNoZSI7YTowOnt9czoxMzoiACoAZGF0ZUZvcm1hdCI7TjtzOjEwOiIAKgBhcHBlbmRzIjthOjA6e31zOjE5OiIAKgBkaXNwYXRjaGVzRXZlbnRzIjthOjA6e31zOjE0OiIAKgBvYnNlcnZhYmxlcyI7YTowOnt9czoxMjoiACoAcmVsYXRpb25zIjthOjA6e31zOjEwOiIAKgB0b3VjaGVzIjthOjA6e31zOjI3OiIAKgByZWxhdGlvbkF1dG9sb2FkQ2FsbGJhY2siO047czoyNjoiACoAcmVsYXRpb25BdXRvbG9hZENvbnRleHQiO047czoxMDoidGltZXN0YW1wcyI7YjoxO3M6MTM6InVzZXNVbmlxdWVJZHMiO2I6MDtzOjk6IgAqAGhpZGRlbiI7YTowOnt9czoxMDoiACoAdmlzaWJsZSI7YTowOnt9czoxMToiACoAZmlsbGFibGUiO2E6NTp7aTowO3M6ODoia2V5X25hbWUiO2k6MTtzOjU6InZhbHVlIjtpOjI7czoxMzoic2V0dGluZ3NfdHlwZSI7aTozO3M6MTA6ImNyZWF0ZWRfYXQiO2k6NDtzOjEwOiJ1cGRhdGVkX2F0Ijt9czoxMDoiACoAZ3VhcmRlZCI7YToxOntpOjA7czoxOiIqIjt9fQ==	1771352049
drivemond_cachebiz_cfg_footer_logo_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiIzNWEzMTExMC05MzZhLTQwMzctOWUzNC1jNzk5ZmZkYTYxODQiO3M6ODoia2V5X25hbWUiO3M6MTE6ImZvb3Rlcl9sb2dvIjtzOjU6InZhbHVlIjtzOjE5OiIiamFnby1sb2dvLW5ldy5wbmciIjtzOjEzOiJzZXR0aW5nc190eXBlIjtzOjIwOiJidXNpbmVzc19pbmZvcm1hdGlvbiI7czoxMDoiY3JlYXRlZF9hdCI7TjtzOjEwOiJ1cGRhdGVkX2F0IjtOO31zOjExOiIAKgBvcmlnaW5hbCI7YTo2OntzOjI6ImlkIjtzOjM2OiIzNWEzMTExMC05MzZhLTQwMzctOWUzNC1jNzk5ZmZkYTYxODQiO3M6ODoia2V5X25hbWUiO3M6MTE6ImZvb3Rlcl9sb2dvIjtzOjU6InZhbHVlIjtzOjE5OiIiamFnby1sb2dvLW5ldy5wbmciIjtzOjEzOiJzZXR0aW5nc190eXBlIjtzOjIwOiJidXNpbmVzc19pbmZvcm1hdGlvbiI7czoxMDoiY3JlYXRlZF9hdCI7TjtzOjEwOiJ1cGRhdGVkX2F0IjtOO31zOjEwOiIAKgBjaGFuZ2VzIjthOjA6e31zOjExOiIAKgBwcmV2aW91cyI7YTowOnt9czo4OiIAKgBjYXN0cyI7YToxOntzOjU6InZhbHVlIjtzOjU6ImFycmF5Ijt9czoxNzoiACoAY2xhc3NDYXN0Q2FjaGUiO2E6MDp7fXM6MjE6IgAqAGF0dHJpYnV0ZUNhc3RDYWNoZSI7YTowOnt9czoxMzoiACoAZGF0ZUZvcm1hdCI7TjtzOjEwOiIAKgBhcHBlbmRzIjthOjA6e31zOjE5OiIAKgBkaXNwYXRjaGVzRXZlbnRzIjthOjA6e31zOjE0OiIAKgBvYnNlcnZhYmxlcyI7YTowOnt9czoxMjoiACoAcmVsYXRpb25zIjthOjA6e31zOjEwOiIAKgB0b3VjaGVzIjthOjA6e31zOjI3OiIAKgByZWxhdGlvbkF1dG9sb2FkQ2FsbGJhY2siO047czoyNjoiACoAcmVsYXRpb25BdXRvbG9hZENvbnRleHQiO047czoxMDoidGltZXN0YW1wcyI7YjoxO3M6MTM6InVzZXNVbmlxdWVJZHMiO2I6MDtzOjk6IgAqAGhpZGRlbiI7YTowOnt9czoxMDoiACoAdmlzaWJsZSI7YTowOnt9czoxMToiACoAZmlsbGFibGUiO2E6NTp7aTowO3M6ODoia2V5X25hbWUiO2k6MTtzOjU6InZhbHVlIjtpOjI7czoxMzoic2V0dGluZ3NfdHlwZSI7aTozO3M6MTA6ImNyZWF0ZWRfYXQiO2k6NDtzOjEwOiJ1cGRhdGVkX2F0Ijt9czoxMDoiACoAZ3VhcmRlZCI7YToxOntpOjA7czoxOiIqIjt9fQ==	1771352049
drivemond_cachebiz_cfg_business_contact_email_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiI5ODFmYmE5NS1hNDQ1LTQ2OTAtOWYzOS0xYjlmMjkxM2RjNWYiO3M6ODoia2V5X25hbWUiO3M6MjI6ImJ1c2luZXNzX2NvbnRhY3RfZW1haWwiO3M6NToidmFsdWUiO3M6MjA6IiJzdXBwb3J0QGphZ29hcHAuaW4iIjtzOjEzOiJzZXR0aW5nc190eXBlIjtzOjIwOiJidXNpbmVzc19pbmZvcm1hdGlvbiI7czoxMDoiY3JlYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xNCAwNzoyMzoyMi4wODI0MDkiO3M6MTA6InVwZGF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTQgMDc6MjM6MjIuMDgyNDA5Ijt9czoxMToiACoAb3JpZ2luYWwiO2E6Njp7czoyOiJpZCI7czozNjoiOTgxZmJhOTUtYTQ0NS00NjkwLTlmMzktMWI5ZjI5MTNkYzVmIjtzOjg6ImtleV9uYW1lIjtzOjIyOiJidXNpbmVzc19jb250YWN0X2VtYWlsIjtzOjU6InZhbHVlIjtzOjIwOiIic3VwcG9ydEBqYWdvYXBwLmluIiI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMDoiYnVzaW5lc3NfaW5mb3JtYXRpb24iO3M6MTA6ImNyZWF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTQgMDc6MjM6MjIuMDgyNDA5IjtzOjEwOiJ1cGRhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTE0IDA3OjIzOjIyLjA4MjQwOSI7fXM6MTA6IgAqAGNoYW5nZXMiO2E6MDp7fXM6MTE6IgAqAHByZXZpb3VzIjthOjA6e31zOjg6IgAqAGNhc3RzIjthOjE6e3M6NToidmFsdWUiO3M6NToiYXJyYXkiO31zOjE3OiIAKgBjbGFzc0Nhc3RDYWNoZSI7YTowOnt9czoyMToiACoAYXR0cmlidXRlQ2FzdENhY2hlIjthOjA6e31zOjEzOiIAKgBkYXRlRm9ybWF0IjtOO3M6MTA6IgAqAGFwcGVuZHMiO2E6MDp7fXM6MTk6IgAqAGRpc3BhdGNoZXNFdmVudHMiO2E6MDp7fXM6MTQ6IgAqAG9ic2VydmFibGVzIjthOjA6e31zOjEyOiIAKgByZWxhdGlvbnMiO2E6MDp7fXM6MTA6IgAqAHRvdWNoZXMiO2E6MDp7fXM6Mjc6IgAqAHJlbGF0aW9uQXV0b2xvYWRDYWxsYmFjayI7TjtzOjI2OiIAKgByZWxhdGlvbkF1dG9sb2FkQ29udGV4dCI7TjtzOjEwOiJ0aW1lc3RhbXBzIjtiOjE7czoxMzoidXNlc1VuaXF1ZUlkcyI7YjowO3M6OToiACoAaGlkZGVuIjthOjA6e31zOjEwOiIAKgB2aXNpYmxlIjthOjA6e31zOjExOiIAKgBmaWxsYWJsZSI7YTo1OntpOjA7czo4OiJrZXlfbmFtZSI7aToxO3M6NToidmFsdWUiO2k6MjtzOjEzOiJzZXR0aW5nc190eXBlIjtpOjM7czoxMDoiY3JlYXRlZF9hdCI7aTo0O3M6MTA6InVwZGF0ZWRfYXQiO31zOjEwOiIAKgBndWFyZGVkIjthOjE6e2k6MDtzOjE6IioiO319	1771352049
drivemond_cachebiz_cfg_business_contact_phone_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiJmMDQzOWY4Yy1jZTViLTRkMzYtYmMwZS1mYzMwNmQ0ODgzMDciO3M6ODoia2V5X25hbWUiO3M6MjI6ImJ1c2luZXNzX2NvbnRhY3RfcGhvbmUiO3M6NToidmFsdWUiO3M6MTY6IiIrOTEtOTg3NjU0MzIxMCIiO3M6MTM6InNldHRpbmdzX3R5cGUiO3M6MjA6ImJ1c2luZXNzX2luZm9ybWF0aW9uIjtzOjEwOiJjcmVhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTE0IDA3OjIzOjIyLjA4MjQwOSI7czoxMDoidXBkYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xNCAwNzoyMzoyMi4wODI0MDkiO31zOjExOiIAKgBvcmlnaW5hbCI7YTo2OntzOjI6ImlkIjtzOjM2OiJmMDQzOWY4Yy1jZTViLTRkMzYtYmMwZS1mYzMwNmQ0ODgzMDciO3M6ODoia2V5X25hbWUiO3M6MjI6ImJ1c2luZXNzX2NvbnRhY3RfcGhvbmUiO3M6NToidmFsdWUiO3M6MTY6IiIrOTEtOTg3NjU0MzIxMCIiO3M6MTM6InNldHRpbmdzX3R5cGUiO3M6MjA6ImJ1c2luZXNzX2luZm9ybWF0aW9uIjtzOjEwOiJjcmVhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTE0IDA3OjIzOjIyLjA4MjQwOSI7czoxMDoidXBkYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xNCAwNzoyMzoyMi4wODI0MDkiO31zOjEwOiIAKgBjaGFuZ2VzIjthOjA6e31zOjExOiIAKgBwcmV2aW91cyI7YTowOnt9czo4OiIAKgBjYXN0cyI7YToxOntzOjU6InZhbHVlIjtzOjU6ImFycmF5Ijt9czoxNzoiACoAY2xhc3NDYXN0Q2FjaGUiO2E6MDp7fXM6MjE6IgAqAGF0dHJpYnV0ZUNhc3RDYWNoZSI7YTowOnt9czoxMzoiACoAZGF0ZUZvcm1hdCI7TjtzOjEwOiIAKgBhcHBlbmRzIjthOjA6e31zOjE5OiIAKgBkaXNwYXRjaGVzRXZlbnRzIjthOjA6e31zOjE0OiIAKgBvYnNlcnZhYmxlcyI7YTowOnt9czoxMjoiACoAcmVsYXRpb25zIjthOjA6e31zOjEwOiIAKgB0b3VjaGVzIjthOjA6e31zOjI3OiIAKgByZWxhdGlvbkF1dG9sb2FkQ2FsbGJhY2siO047czoyNjoiACoAcmVsYXRpb25BdXRvbG9hZENvbnRleHQiO047czoxMDoidGltZXN0YW1wcyI7YjoxO3M6MTM6InVzZXNVbmlxdWVJZHMiO2I6MDtzOjk6IgAqAGhpZGRlbiI7YTowOnt9czoxMDoiACoAdmlzaWJsZSI7YTowOnt9czoxMToiACoAZmlsbGFibGUiO2E6NTp7aTowO3M6ODoia2V5X25hbWUiO2k6MTtzOjU6InZhbHVlIjtpOjI7czoxMzoic2V0dGluZ3NfdHlwZSI7aTozO3M6MTA6ImNyZWF0ZWRfYXQiO2k6NDtzOjEwOiJ1cGRhdGVkX2F0Ijt9czoxMDoiACoAZ3VhcmRlZCI7YToxOntpOjA7czoxOiIqIjt9fQ==	1771352049
drivemond_cachebiz_cfg_business_address_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiI5YjBiZGIwMi02YzQ5LTRjODctYTQ3MS1mNmJlMDkzMGJhNTUiO3M6ODoia2V5X25hbWUiO3M6MTY6ImJ1c2luZXNzX2FkZHJlc3MiO3M6NToidmFsdWUiO3M6Mjk6IiJIeWRlcmFiYWQsIFRlbGFuZ2FuYSwgSW5kaWEiIjtzOjEzOiJzZXR0aW5nc190eXBlIjtzOjIwOiJidXNpbmVzc19pbmZvcm1hdGlvbiI7czoxMDoiY3JlYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xNCAwNzoyMzoyMi4wODI0MDkiO3M6MTA6InVwZGF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTQgMDc6MjM6MjIuMDgyNDA5Ijt9czoxMToiACoAb3JpZ2luYWwiO2E6Njp7czoyOiJpZCI7czozNjoiOWIwYmRiMDItNmM0OS00Yzg3LWE0NzEtZjZiZTA5MzBiYTU1IjtzOjg6ImtleV9uYW1lIjtzOjE2OiJidXNpbmVzc19hZGRyZXNzIjtzOjU6InZhbHVlIjtzOjI5OiIiSHlkZXJhYmFkLCBUZWxhbmdhbmEsIEluZGlhIiI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMDoiYnVzaW5lc3NfaW5mb3JtYXRpb24iO3M6MTA6ImNyZWF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTQgMDc6MjM6MjIuMDgyNDA5IjtzOjEwOiJ1cGRhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTE0IDA3OjIzOjIyLjA4MjQwOSI7fXM6MTA6IgAqAGNoYW5nZXMiO2E6MDp7fXM6MTE6IgAqAHByZXZpb3VzIjthOjA6e31zOjg6IgAqAGNhc3RzIjthOjE6e3M6NToidmFsdWUiO3M6NToiYXJyYXkiO31zOjE3OiIAKgBjbGFzc0Nhc3RDYWNoZSI7YTowOnt9czoyMToiACoAYXR0cmlidXRlQ2FzdENhY2hlIjthOjA6e31zOjEzOiIAKgBkYXRlRm9ybWF0IjtOO3M6MTA6IgAqAGFwcGVuZHMiO2E6MDp7fXM6MTk6IgAqAGRpc3BhdGNoZXNFdmVudHMiO2E6MDp7fXM6MTQ6IgAqAG9ic2VydmFibGVzIjthOjA6e31zOjEyOiIAKgByZWxhdGlvbnMiO2E6MDp7fXM6MTA6IgAqAHRvdWNoZXMiO2E6MDp7fXM6Mjc6IgAqAHJlbGF0aW9uQXV0b2xvYWRDYWxsYmFjayI7TjtzOjI2OiIAKgByZWxhdGlvbkF1dG9sb2FkQ29udGV4dCI7TjtzOjEwOiJ0aW1lc3RhbXBzIjtiOjE7czoxMzoidXNlc1VuaXF1ZUlkcyI7YjowO3M6OToiACoAaGlkZGVuIjthOjA6e31zOjEwOiIAKgB2aXNpYmxlIjthOjA6e31zOjExOiIAKgBmaWxsYWJsZSI7YTo1OntpOjA7czo4OiJrZXlfbmFtZSI7aToxO3M6NToidmFsdWUiO2k6MjtzOjEzOiJzZXR0aW5nc190eXBlIjtpOjM7czoxMDoiY3JlYXRlZF9hdCI7aTo0O3M6MTA6InVwZGF0ZWRfYXQiO31zOjEwOiIAKgBndWFyZGVkIjthOjE6e2k6MDtzOjE6IioiO319	1771352049
drivemond_cachebiz_cfg_business_name_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiI5OWU3MDBhYS1lMDg5LTQ4OTctOTMxYi1mNzM4MTg4NTcxOGEiO3M6ODoia2V5X25hbWUiO3M6MTM6ImJ1c2luZXNzX25hbWUiO3M6NToidmFsdWUiO3M6NjoiIkpBR08iIjtzOjEzOiJzZXR0aW5nc190eXBlIjtzOjIwOiJidXNpbmVzc19pbmZvcm1hdGlvbiI7czoxMDoiY3JlYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xMyAwNDo1ODo1OS4zNjA5MDUiO3M6MTA6InVwZGF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTMgMDQ6NTg6NTkuMzYwOTA1Ijt9czoxMToiACoAb3JpZ2luYWwiO2E6Njp7czoyOiJpZCI7czozNjoiOTllNzAwYWEtZTA4OS00ODk3LTkzMWItZjczODE4ODU3MThhIjtzOjg6ImtleV9uYW1lIjtzOjEzOiJidXNpbmVzc19uYW1lIjtzOjU6InZhbHVlIjtzOjY6IiJKQUdPIiI7czoxMzoic2V0dGluZ3NfdHlwZSI7czoyMDoiYnVzaW5lc3NfaW5mb3JtYXRpb24iO3M6MTA6ImNyZWF0ZWRfYXQiO3M6MjY6IjIwMjYtMDItMTMgMDQ6NTg6NTkuMzYwOTA1IjtzOjEwOiJ1cGRhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTEzIDA0OjU4OjU5LjM2MDkwNSI7fXM6MTA6IgAqAGNoYW5nZXMiO2E6MDp7fXM6MTE6IgAqAHByZXZpb3VzIjthOjA6e31zOjg6IgAqAGNhc3RzIjthOjE6e3M6NToidmFsdWUiO3M6NToiYXJyYXkiO31zOjE3OiIAKgBjbGFzc0Nhc3RDYWNoZSI7YTowOnt9czoyMToiACoAYXR0cmlidXRlQ2FzdENhY2hlIjthOjA6e31zOjEzOiIAKgBkYXRlRm9ybWF0IjtOO3M6MTA6IgAqAGFwcGVuZHMiO2E6MDp7fXM6MTk6IgAqAGRpc3BhdGNoZXNFdmVudHMiO2E6MDp7fXM6MTQ6IgAqAG9ic2VydmFibGVzIjthOjA6e31zOjEyOiIAKgByZWxhdGlvbnMiO2E6MDp7fXM6MTA6IgAqAHRvdWNoZXMiO2E6MDp7fXM6Mjc6IgAqAHJlbGF0aW9uQXV0b2xvYWRDYWxsYmFjayI7TjtzOjI2OiIAKgByZWxhdGlvbkF1dG9sb2FkQ29udGV4dCI7TjtzOjEwOiJ0aW1lc3RhbXBzIjtiOjE7czoxMzoidXNlc1VuaXF1ZUlkcyI7YjowO3M6OToiACoAaGlkZGVuIjthOjA6e31zOjEwOiIAKgB2aXNpYmxlIjthOjA6e31zOjExOiIAKgBmaWxsYWJsZSI7YTo1OntpOjA7czo4OiJrZXlfbmFtZSI7aToxO3M6NToidmFsdWUiO2k6MjtzOjEzOiJzZXR0aW5nc190eXBlIjtpOjM7czoxMDoiY3JlYXRlZF9hdCI7aTo0O3M6MTA6InVwZGF0ZWRfYXQiO31zOjEwOiIAKgBndWFyZGVkIjthOjE6e2k6MDtzOjE6IioiO319	1771352049
drivemond_cachebiz_cfg_copyright_text_all	Tzo1MToiTW9kdWxlc1xCdXNpbmVzc01hbmFnZW1lbnRcRW50aXRpZXNcQnVzaW5lc3NTZXR0aW5nIjozMzp7czoxMzoiACoAY29ubmVjdGlvbiI7czo1OiJwZ3NxbCI7czo4OiIAKgB0YWJsZSI7czoxNzoiYnVzaW5lc3Nfc2V0dGluZ3MiO3M6MTM6IgAqAHByaW1hcnlLZXkiO3M6MjoiaWQiO3M6MTA6IgAqAGtleVR5cGUiO3M6Njoic3RyaW5nIjtzOjEyOiJpbmNyZW1lbnRpbmciO2I6MTtzOjc6IgAqAHdpdGgiO2E6MDp7fXM6MTI6IgAqAHdpdGhDb3VudCI7YTowOnt9czoxOToicHJldmVudHNMYXp5TG9hZGluZyI7YjowO3M6MTA6IgAqAHBlclBhZ2UiO2k6MTU7czo2OiJleGlzdHMiO2I6MTtzOjE4OiJ3YXNSZWNlbnRseUNyZWF0ZWQiO2I6MDtzOjI4OiIAKgBlc2NhcGVXaGVuQ2FzdGluZ1RvU3RyaW5nIjtiOjA7czoxMzoiACoAYXR0cmlidXRlcyI7YTo2OntzOjI6ImlkIjtzOjM2OiIwMzIwZTc5Mi1kMWFiLTQzNTktYThmMi1mODAxMmZlNGUwYmMiO3M6ODoia2V5X25hbWUiO3M6MTQ6ImNvcHlyaWdodF90ZXh0IjtzOjU6InZhbHVlIjtzOjgxOiIiwqkgMjAyNiBKQUdPLiBBIHByb2R1Y3Qgb2YgTWluZHdoaWxlIElUIFNvbHV0aW9ucyBQdnQgTHRkLiBBbGwgcmlnaHRzIHJlc2VydmVkLiIiO3M6MTM6InNldHRpbmdzX3R5cGUiO3M6MjA6ImJ1c2luZXNzX2luZm9ybWF0aW9uIjtzOjEwOiJjcmVhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTE0IDA3OjIzOjIyLjA4MjQwOSI7czoxMDoidXBkYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xNCAwNzoyMzoyMi4wODI0MDkiO31zOjExOiIAKgBvcmlnaW5hbCI7YTo2OntzOjI6ImlkIjtzOjM2OiIwMzIwZTc5Mi1kMWFiLTQzNTktYThmMi1mODAxMmZlNGUwYmMiO3M6ODoia2V5X25hbWUiO3M6MTQ6ImNvcHlyaWdodF90ZXh0IjtzOjU6InZhbHVlIjtzOjgxOiIiwqkgMjAyNiBKQUdPLiBBIHByb2R1Y3Qgb2YgTWluZHdoaWxlIElUIFNvbHV0aW9ucyBQdnQgTHRkLiBBbGwgcmlnaHRzIHJlc2VydmVkLiIiO3M6MTM6InNldHRpbmdzX3R5cGUiO3M6MjA6ImJ1c2luZXNzX2luZm9ybWF0aW9uIjtzOjEwOiJjcmVhdGVkX2F0IjtzOjI2OiIyMDI2LTAyLTE0IDA3OjIzOjIyLjA4MjQwOSI7czoxMDoidXBkYXRlZF9hdCI7czoyNjoiMjAyNi0wMi0xNCAwNzoyMzoyMi4wODI0MDkiO31zOjEwOiIAKgBjaGFuZ2VzIjthOjA6e31zOjExOiIAKgBwcmV2aW91cyI7YTowOnt9czo4OiIAKgBjYXN0cyI7YToxOntzOjU6InZhbHVlIjtzOjU6ImFycmF5Ijt9czoxNzoiACoAY2xhc3NDYXN0Q2FjaGUiO2E6MDp7fXM6MjE6IgAqAGF0dHJpYnV0ZUNhc3RDYWNoZSI7YTowOnt9czoxMzoiACoAZGF0ZUZvcm1hdCI7TjtzOjEwOiIAKgBhcHBlbmRzIjthOjA6e31zOjE5OiIAKgBkaXNwYXRjaGVzRXZlbnRzIjthOjA6e31zOjE0OiIAKgBvYnNlcnZhYmxlcyI7YTowOnt9czoxMjoiACoAcmVsYXRpb25zIjthOjA6e31zOjEwOiIAKgB0b3VjaGVzIjthOjA6e31zOjI3OiIAKgByZWxhdGlvbkF1dG9sb2FkQ2FsbGJhY2siO047czoyNjoiACoAcmVsYXRpb25BdXRvbG9hZENvbnRleHQiO047czoxMDoidGltZXN0YW1wcyI7YjoxO3M6MTM6InVzZXNVbmlxdWVJZHMiO2I6MDtzOjk6IgAqAGhpZGRlbiI7YTowOnt9czoxMDoiACoAdmlzaWJsZSI7YTowOnt9czoxMToiACoAZmlsbGFibGUiO2E6NTp7aTowO3M6ODoia2V5X25hbWUiO2k6MTtzOjU6InZhbHVlIjtpOjI7czoxMzoic2V0dGluZ3NfdHlwZSI7aTozO3M6MTA6ImNyZWF0ZWRfYXQiO2k6NDtzOjEwOiJ1cGRhdGVkX2F0Ijt9czoxMDoiACoAZ3VhcmRlZCI7YToxOntpOjA7czoxOiIqIjt9fQ==	1771352049
\.


--
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- Data for Name: call_recordings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.call_recordings (id, call_id, user_type, user_id, file_path, file_size, duration_seconds, created_at) FROM stdin;
\.


--
-- Data for Name: call_signals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.call_signals (id, call_id, sender_type, sender_id, signal_type, payload, consumed_at, created_at) FROM stdin;
\.


--
-- Data for Name: calls; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.calls (id, trip_request_id, caller_type, caller_id, callee_type, callee_id, call_type, status, started_at, ended_at, duration_seconds, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cancellation_reasons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cancellation_reasons (id, title, cancellation_type, user_type, is_active, created_at, updated_at) FROM stdin;
7a06339a-cd06-4d7c-be77-758cd12a3bcb	Driver is too far away	accepted_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
2a32cee9-dbc3-437c-a111-9acdf114702d	Driver asked me to cancel	accepted_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
39b7e950-0184-4f28-b949-22036cc4d0b8	Changed my plans	accepted_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
78103b7b-72bf-477e-a4d9-f7f757b2691e	Wrong pickup location	accepted_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
a30b0d80-7c17-40ee-aa9b-cd6c2eb35b01	Found another ride	accepted_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
c8f99bff-6cc0-4bcd-aa05-ada41fb32fa0	Expected a different vehicle	accepted_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
a6d737a1-dd0b-4fba-80d0-2180048b1558	Driver is taking a wrong route	ongoing_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
726d1196-40e1-4989-ba32-fed914e5055f	Safety concern	ongoing_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
ad5c3cc7-ff9e-44b8-9d37-556f166819c8	Driver is rude or unprofessional	ongoing_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
5cf77813-a55b-4a31-84e1-0265477fbd65	Vehicle condition is poor	ongoing_ride	customer	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
40dd0f85-a25a-4c36-b46a-b6d04e34745f	Customer is unreachable	accepted_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
f328f504-33d2-4991-a79d-2cebfbebdf51	Customer asked to cancel	accepted_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
9beecd7e-154e-4328-8143-44aa1876f83d	Vehicle breakdown	accepted_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
d645e504-53bb-48a1-ab65-7ef9c483745c	Pickup location is inaccessible	accepted_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
7e86c87f-57a3-40fa-9775-a8043dff2d9a	Long wait at pickup point	accepted_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
de29215d-0d66-4a83-9cb1-2290950f1d78	Personal emergency	accepted_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
185d70ad-1728-486d-9e27-65bba3f5d8aa	Customer misbehaviour	ongoing_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
f95a10aa-d6df-4d79-9b7f-f5139ff139d3	Road blocked or accident ahead	ongoing_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
abf58553-0b8f-4834-89e6-8d3ee437b134	Vehicle issue during trip	ongoing_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
ef2f5bcf-2e1c-4084-921d-de0e7bca5c22	Customer changed destination significantly	ongoing_ride	driver	t	2026-02-15 15:09:03.945453	2026-02-15 15:09:03.945453
\.


--
-- Data for Name: channel_conversations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.channel_conversations (id, channel_id, user_id, message, deleted_at, created_at, updated_at, convable_type, convable_id, is_read) FROM stdin;
\.


--
-- Data for Name: channel_lists; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.channel_lists (id, deleted_at, created_at, updated_at, channelable_type, channelable_id) FROM stdin;
\.


--
-- Data for Name: channel_users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.channel_users (id, channel_id, user_id, is_read, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: conversation_files; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conversation_files (id, conversation_id, file_name, file_type, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: corporate_accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.corporate_accounts (id, company_name, company_code, contact_person, contact_email, contact_phone, gst_number, address, city, state, plan_type, discount_percent, credit_limit, used_credit, billing_cycle, ride_allowed, parcel_allowed, max_employees, active_employees, is_active, contract_start, contract_end, notes, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: coupon_setup_vehicle_category; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.coupon_setup_vehicle_category (id, coupon_setup_id, vehicle_category_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: coupon_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.coupon_setups (id, name, description, zone_coupon_type, customer_level_coupon_type, customer_coupon_type, category_coupon_type, min_trip_amount, max_coupon_amount, coupon, amount_type, coupon_type, coupon_code, "limit", start_date, end_date, total_used, total_amount, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: customer_coupon_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customer_coupon_setups (user_id, coupon_setup_id, limit_per_user) FROM stdin;
\.


--
-- Data for Name: customer_discount_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customer_discount_setups (user_id, discount_setup_id, limit_per_user) FROM stdin;
\.


--
-- Data for Name: customer_level_coupon_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customer_level_coupon_setups (user_level_id, coupon_setup_id) FROM stdin;
\.


--
-- Data for Name: customer_level_discount_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customer_level_discount_setups (user_level_id, discount_setup_id) FROM stdin;
\.


--
-- Data for Name: discount_setup_vehicle_category; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.discount_setup_vehicle_category (id, discount_setup_id, vehicle_category_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: discount_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.discount_setups (id, title, short_description, terms_conditions, image, zone_discount_type, customer_level_discount_type, customer_discount_type, module_discount_type, discount_amount_type, limit_per_user, discount_amount, max_discount_amount, min_trip_amount, start_date, end_date, total_used, total_amount, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: driver_details; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.driver_details (id, user_id, is_online, availability_status, online, offline, online_time, accepted, completed, start_driving, on_driving_time, idle_time, service, ride_count, parcel_count, is_verified, base_image, verified_image, is_suspended, suspend_reason, trigger_verification_at, created_at, updated_at) FROM stdin;
2	00757917-1231-423e-aa60-c0e956f0ef0a	0	unavailable	\N	\N	0	\N	\N	\N	0	0	\N	0	0	0	\N	\N	0	\N	\N	2026-02-14 18:30:48	2026-02-14 18:30:48
3	1b81af34-c972-49df-b816-ca2e925e9b9b	1	available	\N	\N	0	\N	\N	\N	0	0	\N	0	0	1	\N	\N	0	\N	\N	2026-02-16 15:22:09	2026-02-16 15:22:09
4	b8dd794f-b7de-4bab-b53d-43d06dd45e52	1	available	\N	\N	0	\N	\N	\N	0	0	\N	0	0	1	\N	\N	0	\N	\N	2026-02-16 15:23:24	2026-02-16 15:23:24
5	62e81720-2260-4b67-bf44-fa8c558a116f	1	available	\N	\N	0	\N	\N	\N	0	0	\N	0	0	1	\N	\N	0	\N	\N	2026-02-16 15:23:24	2026-02-16 15:23:24
\.


--
-- Data for Name: driver_identity_verifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.driver_identity_verifications (id, driver_id, attempt_details, current_status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: driver_overcharge_reports; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.driver_overcharge_reports (id, trip_request_id, customer_id, driver_id, reported_amount, description, status, admin_action, admin_notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: driver_subscriptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.driver_subscriptions (id, driver_id, plan_id, plan_name, duration_type, price_paid, max_rides, rides_used, is_locked, status, started_at, expires_at, payment_transaction_id, created_at, updated_at, gst_amount) FROM stdin;
\.


--
-- Data for Name: driver_time_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.driver_time_logs (id, driver_id, date, online, offline, online_time, accepted, completed, start_driving, on_driving_time, idle_time, on_time_completed, late_completed, late_pickup, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: external_configurations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.external_configurations (id, key, value, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- Data for Name: fare_bidding_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fare_bidding_logs (id, trip_request_id, driver_id, customer_id, bid_fare, is_ignored, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: fare_biddings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fare_biddings (id, trip_request_id, driver_id, customer_id, bid_fare, is_ignored, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: festival_offers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.festival_offers (id, name, description, sharing_type, zone_id, vehicle_category_id, offer_type, offer_value, max_discount_amount, min_fare_amount, max_uses_total, max_uses_per_user, current_uses, starts_at, ends_at, is_active, banner_image, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: firebase_push_notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.firebase_push_notifications (id, name, value, dynamic_values, status, type, "group", action, created_at, updated_at) FROM stdin;
56	schedule_trip_edited	Schedule trip edited.	["{tripId}", "{vehicleCategory}", "{pickUpLocation}", "{dropOffLocation}", "{sentTime}", "{approximateAmount}"]	t	schedule_trip	customer	trip_edited	2026-02-17 14:03:09	2026-02-17 14:03:09
57	schedule_trip_accepted_by_driver	Schedule trip accepted by driver.	["{tripId}", "{vehicleCategory}", "{sentTime}"]	t	schedule_trip	customer	trip_accepted	2026-02-17 14:03:09	2026-02-17 14:03:09
58	driver_on_the_way_to_pickup_location	Driver on the way to pickup location.	["{tripId}", "{vehicleCategory}", "{sentTime}"]	t	schedule_trip	customer	driver_on_the_way	2026-02-17 14:03:09	2026-02-17 14:03:09
59	schedule_ride_started	Schedule ride started.	["{tripId}", "{vehicleCategory}", "{sentTime}"]	t	schedule_trip	customer	trip_started	2026-02-17 14:03:09	2026-02-17 14:03:09
60	schedule_ride_completed	Schedule ride completed.	["{tripId}", "{paidAmount}", "{methodName}", "{sentTime}"]	t	schedule_trip	customer	trip_completed	2026-02-17 14:03:09	2026-02-17 14:03:09
61	schedule_ride_canceled	Schedule ride canceled.	["{tripId}", "{sentTime}"]	t	schedule_trip	customer	trip_canceled	2026-02-17 14:03:09	2026-02-17 14:03:09
62	schedule_ride_paused	Schedule ride paused.	["{tripId}", "{sentTime}"]	t	schedule_trip	customer	trip_paused	2026-02-17 14:03:09	2026-02-17 14:03:09
63	schedule_ride_resumed	Schedule ride resumed.	["{tripId}", "{sentTime}"]	t	schedule_trip	customer	trip_resumed	2026-02-17 14:03:09	2026-02-17 14:03:09
64	driver_canceled_schedule_trip_request	Driver canceled the schedule trip request.	["{tripId}", "{sentTime}"]	t	schedule_trip	customer	driver_canceled_ride_request	2026-02-17 14:03:09	2026-02-17 14:03:09
65	payment_successful	{paidAmount} payment successful on this trip by {methodName}.	["{tripId}", "{paidAmount}", "{methodName}", "{sentTime}"]	t	schedule_trip	customer	payment_successful	2026-02-17 14:03:09	2026-02-17 14:03:09
66	new_schedule_trip_request	New schedule trip request.	["{tripId}", "{vehicleCategory}", "{pickUpLocation}", "{dropOffLocation}", "{sentTime}", "{approximateAmount}"]	t	schedule_trip	driver	new_ride_request	2026-02-17 14:03:09	2026-02-17 14:03:09
67	pickup_time_started	Pickup time started.	["{tripId}", "{sentTime}"]	t	schedule_trip	driver	pickup_time_started	2026-02-17 14:03:09	2026-02-17 14:03:09
68	tips_from_customer	Customer has given the tips {tipsAmount} with payment.	["{tripId}", "{tipsAmount}", "{customerName}", "{sentTime}"]	t	schedule_trip	driver	tips_from_customer	2026-02-17 14:03:09	2026-02-17 14:03:09
69	customer_canceled_the_trip	Customer canceled the trip.	["{tripId}", "{sentTime}"]	t	schedule_trip	driver	customer_canceled_trip	2026-02-17 14:03:09	2026-02-17 14:03:09
70	new_parcel	You have a new parcel request.	["{parcelId}", "{pickUpLocation}", "{dropOffLocation}", "{sentTime}"]	t	parcel	customer	new_parcel	2026-02-17 14:03:33	2026-02-17 14:03:33
71	parcel_picked_up	Parcel Picked-up.	["{parcelId}", "{sentTime}"]	t	parcel	customer	parcel_picked_up	2026-02-17 14:03:33	2026-02-17 14:03:33
72	parcel_on_the_way	Parcel on the way.	["{parcelId}", "{sentTime}"]	t	parcel	customer	parcel_on_the_way	2026-02-17 14:03:33	2026-02-17 14:03:33
73	parcel_delivery_completed	Parcel delivered successfully.	["{parcelId}", "{sentTime}"]	t	parcel	customer	parcel_delivery_completed	2026-02-17 14:03:33	2026-02-17 14:03:33
74	parcel_canceled	Parcel Cancel.	["{parcelId}", "{sentTime}"]	t	parcel	customer	parcel_canceled	2026-02-17 14:03:33	2026-02-17 14:03:33
75	parcel_returned	Parcel returned successfully.	["{parcelId}", "{sentTime}"]	t	parcel	customer	parcel_returned	2026-02-17 14:03:33	2026-02-17 14:03:33
76	parcel_returning_otp	Your parcel returning OTP is {otp}.	["{parcelId}", "{otp}", "{sentTime}"]	t	parcel	customer	parcel_returning_otp	2026-02-17 14:03:33	2026-02-17 14:03:33
77	refund_accepted	For parcel ID #{parcelId} your refund request has been approved.	["{parcelId}", "{approximateAmount}", "{sentTime}"]	t	parcel	customer	refund_accepted	2026-02-17 14:03:33	2026-02-17 14:03:33
78	refund_denied	For parcel ID #{parcelId} your refund request has been denied.	["{parcelId}", "{approximateAmount}", "{sentTime}"]	t	parcel	customer	refund_denied	2026-02-17 14:03:33	2026-02-17 14:03:33
79	refunded_to_wallet	For parcel ID #{parcelId}, {approximateAmount} refunded to your Wallet.	["{parcelId}", "{approximateAmount}", "{sentTime}"]	t	parcel	customer	refunded_to_wallet	2026-02-17 14:03:33	2026-02-17 14:03:33
80	refunded_as_coupon	For parcel ID #{parcelId}, {approximateAmount} issued as a coupon.	["{parcelId}", "{approximateAmount}", "{sentTime}"]	t	parcel	customer	refunded_as_coupon	2026-02-17 14:03:33	2026-02-17 14:03:33
81	new_parcel_request	New Parcel Request.	["{parcelId}", "{pickUpLocation}", "{dropOffLocation}", "{sentTime}", "{approximateAmount}"]	t	parcel	driver	new_parcel_request	2026-02-17 14:03:33	2026-02-17 14:03:33
82	parcel_amount_deducted	Due to damaged parcel ID #{parcelId}, {approximateAmount} will be deducted.	["{parcelId}", "{approximateAmount}", "{sentTime}"]	t	parcel	driver	parcel_amount_deducted	2026-02-17 14:03:33	2026-02-17 14:03:33
83	refund_accepted	Refund request of parcel ID #{parcelId} approved by Admin.	["{parcelId}", "{sentTime}"]	t	parcel	driver	refund_accepted	2026-02-17 14:03:33	2026-02-17 14:03:33
84	refund_denied	Refund request of parcel ID #{parcelId} denied by Admin.	["{parcelId}", "{sentTime}"]	t	parcel	driver	refund_denied	2026-02-17 14:03:33	2026-02-17 14:03:33
85	parcel_amount_debited	Due to damaged parcel, {approximateAmount} deducted from your wallet.	["{parcelId}", "{approximateAmount}", "{sentTime}"]	t	parcel	driver	parcel_amount_debited	2026-02-17 14:03:33	2026-02-17 14:03:33
86	parcel_canceled	Parcel request has been cancelled.	["{parcelId}", "{sentTime}"]	t	parcel	driver	parcel_canceled	2026-02-17 14:03:33	2026-02-17 14:03:33
87	parcel_canceled_after_trip_started	Parcel request has been cancelled after trip started.	["{parcelId}", "{sentTime}"]	t	parcel	customer	parcel_canceled_after_trip_started	2026-02-17 14:03:33	2026-02-17 14:03:33
88	registration_approved	Admin approved your registration. You can login now.	["{userName}", "{sentTime}"]	t	driver_registration	driver	registration_approved	2026-02-17 14:03:46	2026-02-17 14:03:46
89	vehicle_request_approved	Your vehicle is approved by admin.	["{userName}", "{vehicleCategory}", "{sentTime}"]	t	driver_registration	driver	vehicle_request_approved	2026-02-17 14:03:46	2026-02-17 14:03:46
90	vehicle_request_denied	Your vehicle request is denied.	["{userName}", "{vehicleCategory}", "{sentTime}"]	t	driver_registration	driver	vehicle_request_denied	2026-02-17 14:03:46	2026-02-17 14:03:46
91	identity_image_rejected	Your identity image update request is rejected.	["{userName}", "{sentTime}"]	t	driver_registration	driver	identity_image_rejected	2026-02-17 14:03:46	2026-02-17 14:03:46
92	identity_image_approved	Your identity image update request is approved.	["{userName}", "{sentTime}"]	t	driver_registration	driver	identity_image_approved	2026-02-17 14:03:46	2026-02-17 14:03:46
93	vehicle_active	Your vehicle status has been activated by admin.	["{userName}", "{vehicleCategory}", "{sentTime}"]	t	driver_registration	driver	vehicle_active	2026-02-17 14:03:46	2026-02-17 14:03:46
94	coupon_applied	Customer got discount.	["{userName}", "{sentTime}"]	t	others	coupon	coupon_applied	2026-02-17 14:04:11	2026-02-17 14:04:11
95	coupon_removed	Customer removed previously applied coupon.	["{userName}", "{sentTime}"]	t	others	coupon	coupon_removed	2026-02-17 14:04:11	2026-02-17 14:04:11
37	trip_started	Your trip is started.	["{tripId}", "{vehicleCategory}", "{sentTime}"]	t	regular_trip	customer	trip_started	2026-02-17 14:02:49	2026-02-17 14:02:49
38	trip_completed	Your trip is completed.	["{tripId}", "{paidAmount}", "{methodName}", "{sentTime}"]	t	regular_trip	customer	trip_completed	2026-02-17 14:02:49	2026-02-17 14:02:49
39	trip_canceled	Your trip is cancelled.	["{tripId}", "{sentTime}"]	t	regular_trip	customer	trip_canceled	2026-02-17 14:02:49	2026-02-17 14:02:49
40	trip_paused	Trip request is paused.	["{tripId}", "{sentTime}"]	t	regular_trip	customer	trip_paused	2026-02-17 14:02:49	2026-02-17 14:02:49
41	trip_resumed	Trip request is resumed.	["{tripId}", "{sentTime}"]	t	regular_trip	customer	trip_resumed	2026-02-17 14:02:49	2026-02-17 14:02:49
42	another_driver_assigned	Another driver already accepted the trip request.	["{tripId}", "{vehicleCategory}", "{sentTime}"]	t	regular_trip	customer	another_driver_assigned	2026-02-17 14:02:49	2026-02-17 14:02:49
43	driver_on_the_way	Driver accepted your trip request.	["{tripId}", "{vehicleCategory}", "{sentTime}"]	t	regular_trip	customer	driver_on_the_way	2026-02-17 14:02:49	2026-02-17 14:02:49
44	bid_request_from_driver	Driver sent a bid request	["{tripId}", "{approximateAmount}", "{sentTime}"]	t	regular_trip	customer	bid_request_from_driver	2026-02-17 14:02:49	2026-02-17 14:02:49
45	driver_canceled_ride_request	Driver has canceled your ride.	["{tripId}", "{sentTime}"]	t	regular_trip	customer	driver_canceled_ride_request	2026-02-17 14:02:49	2026-02-17 14:02:49
46	payment_successful	{paidAmount} payment successful on this trip by {methodName}.	["{tripId}", "{paidAmount}", "{methodName}", "{sentTime}"]	t	regular_trip	customer	payment_successful	2026-02-17 14:02:49	2026-02-17 14:02:49
47	new_ride_request	You have a new ride request.	["{tripId}", "{vehicleCategory}", "{pickUpLocation}", "{dropOffLocation}", "{sentTime}", "{approximateAmount}"]	t	regular_trip	driver	new_ride_request	2026-02-17 14:02:49	2026-02-17 14:02:49
48	bid_accepted	Customer confirmed your bid.	["{tripId}", "{sentTime}"]	t	regular_trip	driver	bid_accepted	2026-02-17 14:02:49	2026-02-17 14:02:49
49	trip_request_canceled	A trip request is cancelled.	["{tripId}", "{sentTime}"]	t	regular_trip	driver	trip_request_canceled	2026-02-17 14:02:49	2026-02-17 14:02:49
50	customer_canceled_trip	Customer just declined a request.	["{tripId}", "{sentTime}"]	t	regular_trip	driver	customer_canceled_trip	2026-02-17 14:02:49	2026-02-17 14:02:49
51	bid_request_canceled_by_customer	Customer has canceled your bid request.	["{tripId}", "{sentTime}"]	t	regular_trip	driver	bid_request_canceled_by_customer	2026-02-17 14:02:49	2026-02-17 14:02:49
52	tips_from_customer	Customer has given the tips {tipsAmount} with payment.	["{tripId}", "{tipsAmount}", "{customerName}", "{sentTime}"]	t	regular_trip	driver	tips_from_customer	2026-02-17 14:02:49	2026-02-17 14:02:49
53	received_new_bid	Received a new bid request.	["{tripId}", "{approximateAmount}", "{sentTime}"]	t	regular_trip	driver	received_new_bid	2026-02-17 14:02:49	2026-02-17 14:02:49
54	customer_rejected_bid	We regret to inform you that your bid request for trip ID {tripId} has been rejected by the customer.	["{tripId}", "{sentTime}"]	t	regular_trip	driver	customer_rejected_bid	2026-02-17 14:02:49	2026-02-17 14:02:49
55	schedule_trip_booked	Schedule trip booked.	["{tripId}", "{vehicleCategory}", "{pickUpLocation}", "{dropOffLocation}", "{sentTime}", "{approximateAmount}"]	t	schedule_trip	customer	trip_booked	2026-02-17 14:03:09	2026-02-17 14:03:09
96	review_from_customer	New review from a customer!	["{customerName}"]	t	others	review	review_from_customer	2026-02-17 14:04:11	2026-02-17 14:04:11
97	review_from_driver	New review from a driver!	["{driverName}"]	t	others	review	review_from_driver	2026-02-17 14:04:11	2026-02-17 14:04:11
114	cash_in_hand_limit_exceeds	\N	["{driverName}"]	t	others	cash_in_hand	cash_in_hand_limit_exceeds	2026-02-17 14:12:14.989754	2026-02-17 14:12:14.989754
115	face_verification_completed_successfully	\N	["{businessName}"]	t	others	face_verification	face_verification_completed_successfully	2026-02-17 14:12:14.989754	2026-02-17 14:12:14.989754
116	digital_payment_successful	\N	["{paidAmount}"]	t	others	fund	digital_payment_successful	2026-02-17 14:15:06.402513	2026-02-17 14:15:06.402513
117	parcel_return_penalty	\N	["{approximateAmount}", "{parcelId}"]	t	parcel	driver	parcel_return_penalty	2026-02-17 14:15:06.402513	2026-02-17 14:15:06.402513
118	fund_added_digitally	\N	["{paidAmount}", "{bonusAmount}", "{totalAmount}"]	t	others	fund	fund_added_digitally	2026-02-17 14:15:06.402513	2026-02-17 14:15:06.402513
119	driver_arrived	Your pilot has arrived at pickup location.	["{tripId}"]	t	regular_trip	customer	driver_arrived	2026-02-17 16:51:25.107768	2026-02-17 16:51:25.107768
120	trip_accepted	Your trip request has been accepted by a pilot.	["{tripId}", "{vehicleCategory}"]	t	regular_trip	customer	trip_accepted	2026-02-17 16:51:25.107768	2026-02-17 16:51:25.107768
98	someone_used_your_code	Your code was successfully used by a friend.	["{userName}"]	t	others	referral	someone_used_your_code	2026-02-17 14:04:11	2026-02-17 14:04:11
99	referral_reward_received	You received {referralRewardAmount} reward.	["{referralRewardAmount}"]	t	others	referral	referral_reward_received	2026-02-17 14:04:11	2026-02-17 14:04:11
100	safety_alert_sent	Safety Alert Sent.	["{userName}", "{sentTime}", "{tripId}"]	t	others	safety_alert	safety_alert_sent	2026-02-17 14:04:11	2026-02-17 14:04:11
101	safety_problem_resolved	Safety Problem Resolved.	["{userName}", "{sentTime}", "{tripId}"]	t	others	safety_alert	safety_problem_resolved	2026-02-17 14:04:11	2026-02-17 14:04:11
102	terms_and_conditions_updated	Admin updated system terms and conditions.	["{businessName}"]	t	others	business_page	terms_and_conditions_updated	2026-02-17 14:04:11	2026-02-17 14:04:11
103	privacy_policy_updated	Admin updated our privacy policy.	["{businessName}"]	t	others	business_page	privacy_policy_updated	2026-02-17 14:04:11	2026-02-17 14:04:11
104	legal_updated	We have updated our legal.	["{businessName}"]	t	others	business_page	legal_updated	2026-02-17 14:04:11	2026-02-17 14:04:11
105	new_message	You got a new message from {userName}.	["{userName}"]	t	others	chatting	new_message	2026-02-17 14:04:11	2026-02-17 14:04:11
106	admin_message	You got a new message from admin.	["{sentTime}", "{driverName}"]	t	others	chatting	admin_message	2026-02-17 14:04:11	2026-02-17 14:04:11
107	level_up	You completed challenges and reached level {levelName}.	["{levelName}"]	t	others	level	level_up	2026-02-17 14:04:11	2026-02-17 14:04:11
108	fund_added_by_admin	Admin added {walletAmount} to your wallet.	["{walletAmount}"]	t	others	fund	fund_added_by_admin	2026-02-17 14:04:11	2026-02-17 14:04:11
109	admin_collected_cash	Admin collected cash.	["{paidAmount}"]	t	others	fund	admin_collected_cash	2026-02-17 14:04:11	2026-02-17 14:04:11
110	withdraw_request_rejected	Your withdrawal request has been rejected. {withdrawNote}.	["{withdrawNote}", "{userName}"]	t	others	withdraw_request	withdraw_request_rejected	2026-02-17 14:04:11	2026-02-17 14:04:11
111	withdraw_request_approved	Your withdrawal request has been approved.	["{userName}"]	t	others	withdraw_request	withdraw_request_approved	2026-02-17 14:04:11	2026-02-17 14:04:11
112	withdraw_request_settled	Your withdrawal request has been settled.	["{userName}"]	t	others	withdraw_request	withdraw_request_settled	2026-02-17 14:04:11	2026-02-17 14:04:11
113	withdraw_request_reversed	Your withdrawal request has been reversed.	["{userName}"]	t	others	withdraw_request	withdraw_request_reversed	2026-02-17 14:04:11	2026-02-17 14:04:11
\.


--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- Data for Name: landing_page_sections; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.landing_page_sections (id, key_name, value, settings_type, created_at, updated_at) FROM stdin;
2	total_download	{"image": "", "title": "40K+", "status": 1, "content": "Downloads"}	business_statistics	2026-01-29 16:43:31	2026-01-29 17:00:43
5	support	{"image": "", "title": "24/7hr", "status": 1, "content": "Support"}	business_statistics	2026-01-29 16:43:31	2026-01-29 17:03:38
11	service_3	{"image": "", "title": "Become a delivery **hero** and keep your city moving.", "status": 1, "tab_name": "Parcel Delivery", "description": "<p>Unlock a steady stream of income by delivering packages and essentials. It’s a flexible way to earn while exploring every corner of your neighborhood.</p><ul><li>Get optimized routes for multi-stop deliveries, ensuring you save time and fuel while maximizing earnings.</li><li>Use your bicycle, scooter, or car to handle everything from small envelopes to larger parcels.</li><li>Benefit from a consistent flow of delivery tasks, competitive base rates, and tips from satisfied customers.</li></ul><p></p><p>                                                \\r\\n                                            </p>"}	our_services	2026-01-29 16:43:31	2026-02-01 10:33:22
20	is_business_statistics_enabled	"1"	business_statistics	2026-01-29 17:04:03	2026-01-29 17:04:03
21	is_our_solutions_enabled	"1"	our_solutions	2026-01-29 17:07:06	2026-01-29 17:07:06
23	is_gallery_enabled	"1"	gallery	2026-01-29 17:17:45	2026-01-29 17:17:45
25	button_contents	{"image": "", "title": "Download the User App", "subtitle": "Start your Journey here"}	customer_app_download	2026-01-29 17:19:13	2026-01-29 17:19:13
26	is_customer_app_download_enabled	"1"	customer_app_download	2026-01-29 17:19:21	2026-01-29 17:19:21
27	button_contents	{"image": "", "title": "Download the Delivery / Driver App", "subtitle": "Start your earning Journey here"}	earn_money	2026-01-29 17:24:58	2026-01-29 17:24:58
28	is_earn_money_enabled	"1"	earn_money	2026-01-29 17:25:03	2026-01-29 17:25:03
29	intro_contents	{"title": "**2000+** People Share Their Love"}	testimonial	2026-01-29 17:25:58	2026-01-29 17:25:58
30	is_testimonial_enabled	"1"	testimonial	2026-01-29 17:26:04	2026-01-29 17:26:04
31	intro_contents	{"title": "GET ALL UPDATES & EXCITING NEWS", "subtitle": "Subscribe to out newsletters to receive all the latest activity we provide for you", "background_image": ""}	newsletter	2026-01-29 17:27:08	2026-01-29 17:27:08
32	is_newsletter_enabled	"1"	newsletter	2026-01-29 17:27:12	2026-01-29 17:27:12
6	intro_contents	{"title": "Our **Solutions**", "sub_title": "Smart logistics and mobility solutions for modern businesses and everyday life"}	our_solutions	2026-01-29 16:43:31	2026-02-01 09:09:14
22	intro_contents	{"title": "Our **Services**", "subtitle": "Comprehensive logistics, delivery, and ride-sharing services designed to move your world forward."}	our_services	2026-01-29 17:07:47	2026-01-29 17:07:47
3	complete_ride	{"image": "", "title": "20M+", "status": 1, "content": "Deliveries Completed"}	business_statistics	2026-01-29 16:43:31	2026-01-29 17:02:40
4	happy_customer	{"image": "", "title": "1M+", "status": 1, "content": "Happy Customers"}	business_statistics	2026-01-29 16:43:31	2026-01-29 17:03:25
13	card_2	{"image": "", "title": "Smart **Fleet** Solutions", "subtitle": "Manage vehicles, optimize routes, and track every delivery in real-time with JAGO's intelligent logistics platform."}	gallery	2026-01-29 16:43:31	2026-01-29 17:17:39
7	solutions	{"image": "", "title": "Parcel Delivery", "status": 1, "description": "Send parcels anywhere with real-time tracking, weight-based pricing, and OTP-verified handoffs. Fast, reliable, and transparent delivery every time."}	our_solutions	2026-01-29 16:43:31	2026-01-29 17:06:52
8	solutions	{"image": "", "title": "Ride Sharing", "status": 1, "description": "Book rides instantly with smart matching, fare estimation, and multiple vehicle options. Share rides to save costs and reduce your carbon footprint."}	our_solutions	2026-01-29 16:43:31	2026-01-29 17:07:00
33	footer_contents	{"title": "Your trusted logistics and mobility platform. Delivering parcels, connecting rides, and powering seamless transportation — anytime, anywhere."}	footer	2026-01-29 17:27:42	2026-01-29 17:27:42
34	is_our_services_enabled	"1"	our_services	2026-02-01 09:10:13	2026-02-01 09:10:13
9	service_1	{"image": "", "title": "Hit the road instantly and start **earning** on your own terms", "status": 1, "tab_name": "Regular Trip", "description": "<p>Join the JAGO community of drivers and turn every mile into a milestone with our seamless, real-time trip booking system.</p><ul><li>Accept trip requests that fit your current location and availability with just a single tap.</li><li>Whether you prefer the comfort of a car or the agility of a motorbike, we support your choice of ride.</li><li>Track your income in real-time with instant payouts and performance-based rewards after every ride.</li></ul>"}	our_services	2026-01-29 16:43:31	2026-02-01 10:33:10
10	service_2	{"image": "", "title": "Plan your next adventure with JAGO's trip **scheduling** features.", "status": 1, "tab_name": "Schedule Trip", "description": "<p>Discover endless opportunities to schedule trips that align with your skills and interests, transforming your time into a profitable venture.</p><ul><li>Discover endless opportunities to schedule trips that align with your skills and interests, transforming your time into a profitable venture.</li><li>Enjoy the freedom of scheduling trips that suit your personal timetable.</li><li>Enjoy the freedom of scheduling trips that suit your personal timetable.                                                \\r\\n                                            </li></ul>"}	our_services	2026-01-29 16:43:31	2026-02-01 09:31:47
15	reviews	{"rating": "5", "review": "\\"JAGO: Tactical Transport for Every Mission!\\"", "status": "1", "designation": "Officer", "reviewer_name": "Lois Nila", "reviewer_image": ""}	testimonial	2026-01-29 16:43:31	2026-01-29 16:43:31
16	reviews	{"rating": "4.9", "review": "\\"JAGO: Effortless Journeys for Busy Lives!\\"", "status": "1", "designation": "Engineer", "reviewer_name": "Mac Steven Moba", "reviewer_image": ""}	testimonial	2026-01-29 16:43:31	2026-01-29 16:43:31
17	reviews	{"rating": "4.5", "review": "\\"JAGO: Healing Journeys Every Day!\\"", "status": "1", "designation": "Doctor", "reviewer_name": "Jenny Klath", "reviewer_image": ""}	testimonial	2026-01-29 16:43:31	2026-01-29 16:43:31
18	reviews	{"rating": "5", "review": "\\"JAGO: Elevate Your Business Moves!\\"", "status": "1", "designation": "Businessman", "reviewer_name": "Sir Moba", "reviewer_image": ""}	testimonial	2026-01-29 16:43:31	2026-01-29 16:43:31
19	reviews	{"rating": "5", "review": "\\"JAGO: Student Rides Simplified!\\"", "status": "1", "designation": "Student", "reviewer_name": "Jhon Doe", "reviewer_image": ""}	testimonial	2026-01-29 16:43:31	2026-01-29 16:43:31
1	intro_contents	{"title": "JAGO — Your Smart **Logistics** & Mobility Platform", "sub_title": "From parcel delivery to ride sharing, JAGO powers seamless logistics with real-time tracking, smart fleet management, and reliable service — delivering convenience at your fingertips.", "background_image": ""}	intro_section	2026-01-29 16:43:31	2026-01-29 16:43:31
24	intro_contents	{"image": "", "title": "Your **Smart Logistics App**, Just a Tap Away", "subtitle": "Send parcels, book rides, and track deliveries in real-time with JAGO. Reliable logistics anytime, anywhere."}	customer_app_download	2026-01-29 17:18:48	2026-02-01 09:09:46
14	intro_contents	{"image": "", "title": "Earn Money with **JAGO** Logistics", "subtitle": "Join our fleet of delivery partners and drivers. Turn your vehicle into a steady income source with JAGO."}	earn_money	2026-01-29 16:43:31	2026-01-29 17:24:37
12	card_1	{"image": "", "title": "Deliveries Completed **On Time**", "subtitle": "From documents to large parcels, JAGO ensures every delivery reaches its destination safely with real-time tracking and verified handoffs."}	gallery	2026-01-29 16:43:31	2026-01-29 17:16:46
35	solutions	{"image": "", "title": "Scheduled Trips", "status": 1, "description": "Plan ahead with scheduled pickups and deliveries. Set your time, choose your vehicle, and JAGO handles the rest automatically."}	our_solutions	2026-02-01 09:26:17	2026-02-01 09:26:17
\.


--
-- Data for Name: late_return_penalty_notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.late_return_penalty_notifications (id, trip_request_id, sending_notification_at, is_notification_sent, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: level_accesses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.level_accesses (id, level_id, user_type, bid, see_destination, see_subtotal, see_level, create_hire_request, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: loyalty_points_histories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.loyalty_points_histories (id, user_id, model, model_id, points, type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	2016_06_01_000001_create_oauth_auth_codes_table	1
2	2016_06_01_000002_create_oauth_access_tokens_table	1
3	2016_06_01_000003_create_oauth_refresh_tokens_table	1
4	2016_06_01_000004_create_oauth_clients_table	1
5	2016_06_01_000005_create_oauth_personal_access_clients_table	1
6	2019_08_19_000000_create_failed_jobs_table	1
7	2019_12_14_000001_create_personal_access_tokens_table	1
8	2022_11_21_045555_create_payments_table	1
9	2022_11_21_085924_create_payment_settings_table	1
10	2023_01_10_114636_create_users_table	1
11	2023_01_10_115750_create_vehicles_table	1
12	2023_01_11_073558_create_vehicle_brands_table	1
13	2023_01_11_113737_create_vehicle_models_table	1
14	2023_01_12_062420_create_vehicle_categories_table	1
15	2023_01_16_043100_create_zones_table	1
16	2023_01_16_052732_create_vehicle_category_zone_table	1
17	2023_01_16_121122_create_user_levels_table	1
18	2023_01_17_034948_create_areas_table	1
19	2023_01_22_121648_create_business_settings_table	1
20	2023_01_24_070220_create_pick_hours_table	1
21	2023_01_24_102512_create_area_pick_hour_table	1
22	2023_01_26_091327_create_banner_setups_table	1
23	2023_01_26_110443_create_notification_settings_table	1
24	2023_01_26_111922_create_firebase_push_notifications_table	1
25	2023_01_28_041320_create_discount_setups_table	1
26	2023_01_28_103231_create_level_accesses_table	1
27	2023_01_29_115233_create_social_links_table	1
28	2023_01_30_063201_create_area_discount_setup_table	1
29	2023_01_30_114525_create_discount_setup_vehicle_category_table	1
30	2023_02_01_035306_create_milestone_setups_table	1
31	2023_02_01_042116_create_bonus_setups_table	1
32	2023_02_01_060559_create_area_bonus_setup_table	1
33	2023_02_01_060650_create_bonus_setup_vehicle_category_table	1
34	2023_02_05_035750_create_coupon_setups_table	1
35	2023_02_05_051702_create_area_coupon_setup_table	1
36	2023_02_05_052020_create_coupon_setup_vehicle_category_table	1
37	2023_02_08_065339_create_roles_table	1
38	2023_02_09_065343_create_role_user_table	1
39	2023_02_12_054054_create_trip_fares_table	1
40	2023_02_12_070009_create_parcel_categories_table	1
41	2023_02_12_092239_create_parcel_weights_table	1
42	2023_02_13_091841_create_parcel_fares_table	1
43	2023_02_15_101259_create_module_accesses_table	1
44	2023_02_16_093144_create_user_address_table	1
45	2023_02_19_043220_create_trip_requests_table	1
46	2023_02_19_070337_create_trip_status_table	1
47	2023_02_19_071606_create_trip_routes_table	1
48	2023_02_19_102134_create_fare_biddings_table	1
49	2023_02_20_114458_create_parcel_fares_parcel_weights_table	1
50	2023_02_22_063650_create_parcels_table	1
51	2023_02_22_085634_create_channel_conversations_table	1
52	2023_02_22_085659_create_channel_lists_table	1
53	2023_02_22_085727_create_channel_users_table	1
54	2023_02_22_085752_create_conversation_files_table	1
55	2023_02_25_035752_create_reviews_table	1
56	2023_02_27_042506_create_user_last_locations_table	1
57	2023_03_02_032942_create_activity_logs_table	1
58	2023_03_06_052511_create_recent_addresses_table	1
59	2023_03_14_121257_create_fare_bidding_logs_table	1
60	2023_03_16_074055_add_payer_information_to_payment_requests_table	1
61	2023_03_18_042902_add_external_redirect_link_to_payment_requests_table	1
62	2023_03_19_113319_change_column_in_payment_settings_table	1
63	2023_03_21_072752_add_receiver_information_to_payment_requests_table	1
64	2023_03_22_040654_create_jobs_table	1
65	2023_03_22_053625_create_driver_details_table	1
66	2023_03_22_072803_create_driver_time_logs_table	1
67	2023_03_23_055542_create_user_level_histories_table	1
68	2023_03_28_041451_add_column_to_payment_requests	1
69	2023_03_28_061810_add_payment_platform_column_to_payment_requests	1
70	2023_03_28_064934_create_rejected_driver_requests_table	1
71	2023_04_03_075904_create_temp_trip_notifications_table	1
72	2023_04_10_064449_rename_payment_settings_to_settings_table	1
73	2023_04_12_071813_aad_additional_data_column_to_settings_table	1
74	2023_04_29_061951_create_trip_request_fees_table	1
75	2023_04_29_062028_create_trip_request_coordinates_table	1
76	2023_04_30_060033_create_trip_request_times_table	1
77	2023_04_30_094812_create_transactions_table	1
78	2023_04_30_110147_create_user_accounts_table	1
79	2023_05_02_112219_create_parcel_user_infomations_table	1
80	2023_05_02_112241_create_parcel_information_table	1
81	2023_05_13_102728_create_admin_notifications_table	1
82	2023_05_13_123323_create_app_notifications_table	1
83	2023_05_17_091349_create_loyalty_points_histories_table	1
84	2023_05_18_045035_create_withdraw_methods_table	1
85	2023_05_18_102011_create_withdraw_requests_table	1
86	2023_05_25_084737_create_otp_verifications_table	1
87	2023_05_29_100521_create_time_tracks_table	1
88	2023_05_29_100531_create_time_logs_table	1
89	2023_06_08_065011_add_failed_attempt_col_to_users_table	1
90	2023_06_08_101119_add_more_cols_to_otp_verifications_table	1
91	2023_07_05_055628_add_is_paused_to_trip_requests_table	1
92	2023_07_09_060537_add_screenshot_column_to_trip_requests_table	1
93	2023_07_12_062801_add_is_ignred_column_to_fare_biddings_table	1
94	2023_07_12_100856_add_is_ignred_column_to_fare_bidding_logs_table	1
95	2023_11_12_105624_add_base_fare_column_to_parcel_fares_parcel_weights_table	2
96	2023_11_13_040038_create_zone_wise_default_trip_fares_table	2
97	2023_11_13_041656_add_zone_wise_default_trip_fare_id_column_to_trip_fares_table	2
98	0000_00_00_000000_create_websockets_statistics_entries_table	3
99	2024_02_12_105135_add_column_channelable_to_channel_lists_table	3
100	2024_02_13_150109_add_column_conversationable_to_channel_conversations_table	3
101	2024_02_23_180314_change_vin_number_and_transmission_column_type_to_vehicles_table	3
102	2024_03_23_131340_add_old_identification_image_column_to_users_table	4
103	2024_03_25_094242_create_cancellation_reasons_table	4
104	2024_03_25_140744_add_trip_cancelletion_reason_column_to_trip_requests_table	4
105	2024_04_02_144248_add_full_name_column_to_users_table	4
106	2024_04_21_142556_add_is_read_column_to_channel_conversations_table	5
107	2024_04_23_180557_create_applied_coupons_table	5
108	2024_04_24_132919_add_current_language_key_column_to_users_table	5
109	2024_04_24_162240_create_discount_setups_table	5
110	2024_04_25_094825_create_zone_discount_setups_table	5
111	2024_04_25_094846_create_customer_level_discount_setups_table	5
112	2024_04_25_094855_create_customer_discount_setups_table	5
113	2024_04_25_111529_create_vehicle_category_discount_setups_table	5
114	2024_04_30_145010_add_discount_id_discount_amount_column_to_trip_requests_table	5
115	2024_05_07_095536_add_transaction_type_to_transactions_table	5
116	2024_05_26_102832_add_soft_deletes_to_withdraw_methods_table	6
117	2024_05_26_104421_create_user_withdraw_method_infos_table	6
118	2024_05_28_100241_add_status_column_to_withdraw_requests_table	6
119	2024_05_28_154644_add_driver_note_approval_note_denied_note_column_to_withdraw_requests_table	6
120	2024_05_30_170257_add_method_name_to_user_withdraw_method_infos_table	6
121	2024_06_25_101513_create_zone_coupon_setups_table	7
122	2024_06_25_101559_create_customer_coupon_setups_table	7
123	2024_06_25_101616_create_customer_level_coupon_setups_table	7
124	2024_06_25_122501_add_multiple_column_to_coupon_setups_table	7
125	2024_06_25_165330_create_vehicle_category_coupon_setups_table	7
126	2024_07_26_150807_add_service_to_driver_details_table	8
127	2024_07_26_162948_add_parcel_weight_capacity_to_vehicles_table	8
128	2024_07_27_162359_create_external_configurations_table	9
129	2024_08_25_095629_create_referral_earning_settings_table	9
130	2024_08_25_151348_add_ref_code_and_ref_by_column_to_users_table	9
131	2024_08_27_161454_create_referral_customers_table	9
132	2024_08_27_161506_create_referral_drivers_table	9
133	2024_08_28_102837_add_referral_earn_column_to_user_accounts_table	9
134	2024_08_28_150709_create_parcel_cancellation_reasons_table	9
135	2024_08_28_180146_add_return_fee_column_to_parcel_fares_table	9
136	2024_08_28_180211_add_return_fee_column_to_parcel_fares_parcel_weights_table	9
137	2024_09_07_121820_add_return_fee_to_trip_request_fees_table	9
138	2024_09_08_161850_add_return_fee_and_return_time_to_trip_requests_table	9
139	2024_09_09_130859_add_due_amount_to_trip_requests_table	9
140	2024_09_09_135219_add_returning_and_returned_to_trip_status_table	9
141	2024_09_18_171058_add_cancellation_fee_column_to_parcel_fares_table	9
142	2024_09_18_171122_add_cancellation_fee_column_to_parcel_fares_parcel_weights_table	9
143	2024_09_19_153330_add_cancellation_fee_column_to_trip_requests_table	9
144	2024_09_25_165143_add_extra_fare_status_fee_reason_column_to_zones_table	10
145	2024_10_06_102727_add_readable_id_to_zones_table	10
146	2024_10_06_114505_set_readable_id_for_existing_zones	10
147	2024_10_10_104044_create_parcel_refund_reasons_table	10
148	2024_10_10_172108_create_parcel_refunds_table	10
149	2024_10_10_172133_create_parcel_refund_proofs_table	10
150	2024_10_22_155426_add_extra_fare_fee_and_extra_fare_amount_to_trip_requests_table	10
151	2024_10_31_140822_add_customer_note_column_to_parcel_refunds_table	10
152	2024_11_10_124148_create_question_answers_table	11
153	2024_11_10_124929_create_support_saved_replies_table	11
154	2024_11_12_094856_change_morphable_columns_nullable_to_channel_conversations_table	11
155	2024_11_14_121108_change_morphable_columns_nullable_channel_lists_table	11
156	2024_11_27_092614_add_readable_id_to_roles_table	12
157	2024_11_27_092915_set_readable_id_for_existing_roles	12
158	2024_11_28_180147_add_ride_count_parcel_count_column_to_driver_details_table	12
159	2024_12_01_154702_add_draft_to_vehicles_table	12
160	2024_12_01_155122_add_is_approved_to_vehicles_table	12
161	2024_12_02_124425_add_deny_note_to_vehicles_table	12
162	2024_12_04_124303_add_reference_to_transactions_table	12
163	2024_12_17_105240_create_safety_precautions_table	13
164	2024_12_17_124938_create_safety_alert_reasons_table	13
165	2024_12_21_100757_create_safety_alerts_table	13
166	2025_02_26_102543_add_type_group_action_column_to_firebase_push_notifications_table	13
167	2025_03_03_092817_remove_unique_constraint_from_name_column_in_firebase_push_notifications_table	13
168	2025_03_03_142412_insert_data_to_firebase_push_notifications_table	13
169	2025_05_15_104430_insert_schedule_trip_data_to_firebase_push_notifications_table	14
170	2025_05_19_173812_add_is_read_and_notification_type_columns_to_app_notifications_table	14
171	2025_05_31_151021_add_ride_request_type_scheduled_at_is_notification_sent_sending_notification_at_to_trip_requests_table	14
172	2025_06_12_110454_add_readable_id_to_transactions_table	14
173	2025_06_12_122124_set_readable_id_for_existing_transactions	14
174	2025_07_14_183005_create_send_notifications_table	14
175	2025_07_17_121110_add_dynamic_values_to_firebase_push_notifications_table	14
176	2025_08_11_105202_create_surge_pricing_table	15
177	2025_08_11_105214_create_surge_pricing_zones_table	15
178	2025_08_11_105303_create_surge_pricing_time_slots_table	15
179	2025_08_11_110454_create_surge_pricing_service_categories_table	15
180	2025_08_23_170522_add_surge_percentage_to_trip_requests_table	15
181	2025_09_24_113827_create_wallet_bonuses_table	16
182	2025_09_29_152222_add_added_bonus_to_transactions_table	16
183	2025_10_07_150135_insert_cash_in_hand_limit_exceeds_data_to_firebase_push_notifications_table	16
184	2025_10_13_173152_insert_digital_payment_successful_data_to_firebase_push_notifications_table	16
185	2025_10_13_190748_change_dynamic_value_of_admin_collected_cash_to_firebase_push_notifications_table	16
186	2025_10_16_102042_create_late_return_penalty_notifications_table	16
187	2025_10_16_135726_insert_parcel_return_penalty_data_to_firebase_push_notifications_table	16
188	2025_10_18_155206_insert_parcel_canceled_data_for_driver_to_firebase_push_notifications_table	16
189	2025_10_19_125225_insert_parcel_canceled_after_trip_started_data_to_firebase_push_notifications_table	16
190	2025_10_21_140346_insert_fund_added_digitally_data_to_firebase_push_notifications_table	16
191	2025_10_21_161049_add_trx_type_to_transactions_table	16
192	2026_01_11_150028_create_landing_page_sections_table	17
193	2026_01_11_172655_move_landing_pages_data_to_landing_pages_table	17
194	2026_01_13_110421_create_blog_settings_table	17
195	2026_01_14_100911_create_blog_categories_table	17
196	2026_01_14_154749_create_blogs_table	17
197	2026_01_15_124701_create_blog_drafts_table	17
198	2026_01_18_163608_create_driver_identity_verifications_table	17
199	2026_01_19_000149_add_is_verified_base_image_verified_image_is_suspended_suspend_reason_trigger_verification_at_to_driver_details_table	17
200	2026_01_21_162254_create_ai_settings_table	17
201	2026_01_26_125509_create_newsletter_subscriptions_table	17
202	2026_01_29_120205_insert_face_verification_completed_successfully_data_to_firebase_push_notifications_table	17
203	2026_02_09_112612_create_spin_wheel_tables	18
204	2026_02_09_140000_create_driver_subscription_tables	19
205	2026_02_09_150000_add_pickup_charge_and_sharing_columns	19
206	2026_02_09_152339_add_pickup_and_sharing_fields_to_zone_wise_default_trip_fares_table	20
207	2026_02_09_160000_add_distance_and_timestamps_to_shared_trip_passengers	21
208	2026_02_14_000001_seed_pilot_balance_business_settings	22
209	2026_02_14_180000_add_parcel_time_pricing_and_helper_fields	23
210	2026_02_15_000001_convert_zones_coordinates_to_postgis_geometry	24
211	2026_02_15_100000_add_discount_and_corporate_fields_to_users_table	25
212	2026_02_15_100001_create_corporate_tables	25
213	2026_02_15_100002_add_special_discount_to_trip_request_fees	26
214	2026_02_15_200000_add_earning_model_settings	27
215	2026_02_15_200000_add_pickup_waiting_fields_to_parcel_fares	28
216	2026_02_17_100000_enhance_spin_wheel_tables	29
217	2026_02_17_120000_add_foreign_keys_for_referential_integrity	30
218	2026_02_17_140000_add_dual_car_sharing_and_festival_offers	31
219	2026_02_17_200000_add_vehicle_category_to_parcel_fares	32
\.


--
-- Data for Name: milestone_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.milestone_setups (id, name, description, customer_id, customer_level_id, driver_id, driver_level_id, thumbnail, banner, reward_type, reward_amount, start_date, end_date, challenge_type, target_count, referral_code, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: module_accesses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.module_accesses (id, user_id, role_id, module_name, view, add, update, delete, log, export, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: newsletter_subscriptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.newsletter_subscriptions (id, email, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notification_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notification_settings (id, name, push, email, created_at, updated_at) FROM stdin;
2	ride_request	t	f	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
3	ride_accepted	t	f	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
4	ride_started	t	f	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
5	ride_completed	t	t	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
6	ride_cancelled	t	t	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
7	parcel_request	t	f	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
8	parcel_accepted	t	f	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
9	parcel_delivered	t	t	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
10	parcel_cancelled	t	t	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
11	payment_received	t	t	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
12	wallet_update	t	f	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
13	driver_assigned	t	f	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
14	chat_message	t	f	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
15	safety_alert	t	t	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
16	subscription_update	t	t	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
17	withdrawal_update	t	t	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
18	review_received	t	f	2026-02-15 13:15:56.130782	2026-02-15 13:15:56.130782
\.


--
-- Data for Name: oauth_access_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.oauth_access_tokens (id, user_id, client_id, name, scopes, revoked, created_at, updated_at, expires_at) FROM stdin;
cfcb8307a4460406b1f17dd2969cf1e08c5d840269813f31080f1fcbca659e423683c937e9f1897a	879a7709-2451-4f6e-969f-5250b3991ccb	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-14 18:28:30	2026-02-14 18:31:19	2027-02-14 18:28:30
05ab8fa91bf530ea19743a6d45f6dad4baedc576c4c97a7fe82a89a882881c9e96cb90e425fab544	8de7e4bf-0483-4a72-895b-bcf79594bfd2	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-16 15:47:53	2026-02-16 15:48:02	2027-02-16 15:47:53
b725077b1ec914ebbbacdc670967de693b0d1c57ae2954f68a7e5a8ff31321862bcc3656e441d38c	879a7709-2451-4f6e-969f-5250b3991ccb	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-14 18:31:19	2026-02-14 18:32:47	2027-02-14 18:31:19
31c8a4df4822e014b5c9d13398cee031223b455e7e965fb3a2a28640e9a9ab3fa12096ec6d964e9d	8de7e4bf-0483-4a72-895b-bcf79594bfd2	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-16 15:24:39	2026-02-16 15:44:56	2027-02-16 15:24:39
8239b3af0728f5e16bd0de87d4c057e70ac2218ab2be09909eff542b158bd626284cf32f5f6c6d2f	879a7709-2451-4f6e-969f-5250b3991ccb	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-14 18:32:47	2026-02-14 18:33:02	2027-02-14 18:32:47
e756372f9f2250c19734367ffc19a3f72aef146c65085d10782daa291d09e569f2e62eba2d19c2b0	879a7709-2451-4f6e-969f-5250b3991ccb	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-14 18:33:02	2026-02-15 02:00:38	2027-02-14 18:33:02
90524c21c6fba91767f44c87148ff7bbc640b89c0e0de0c1365c599a8addb16be8d2196d2856f033	879a7709-2451-4f6e-969f-5250b3991ccb	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-15 02:00:38	2026-02-15 02:19:58	2027-02-15 02:00:38
fbfba5f18aa6275bfcd5031ec7a124479b31a9cec7f910e33547d37f6c22184e8440c200e4ecd09a	1b81af34-c972-49df-b816-ca2e925e9b9b	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToDriver	[]	t	2026-02-16 15:24:52	2026-02-16 15:44:56	2027-02-16 15:24:52
043b2c2477c6824d004959f6c290dd310e1ccd4bbf65ec1992c5f19bd2957676fa6edeb3963aeeae	00757917-1231-423e-aa60-c0e956f0ef0a	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToDriver	[]	t	2026-02-14 18:30:56	2026-02-15 02:21:17	2027-02-14 18:30:56
a0e4a4abb6fef2dd501f9334b64edfddaad06dd2b57d5d5e24cf58d339def4ba1f28d7f71f93f347	879a7709-2451-4f6e-969f-5250b3991ccb	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-15 02:19:59	2026-02-15 02:21:42	2027-02-15 02:19:59
289638ecca5b85631104e3a0f3f0a1caf1b12626242c16098d4bfffe96d69234899c4d7778a59459	879a7709-2451-4f6e-969f-5250b3991ccb	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	f	2026-02-15 02:21:42	2026-02-15 02:21:42	2027-02-15 02:21:42
bac52946b21600c891458a3b5b572f6f716dbdbf28a30468ff4f61f86fcca15a0e9cfaccbdb89aa8	00757917-1231-423e-aa60-c0e956f0ef0a	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToDriver	[]	t	2026-02-15 02:21:17	2026-02-15 02:21:42	2027-02-15 02:21:17
27d1e70ca5ac03c800dc1e99345f3a083f90a015592a75c2192df6023a591387ef3f8e7ecb8f815b	00757917-1231-423e-aa60-c0e956f0ef0a	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToDriver	[]	f	2026-02-15 02:21:42	2026-02-15 02:21:42	2027-02-15 02:21:42
6f2dfd124dd1095a9e5ffacd75cad42a42bc500f87e144e18663ba0348297b139939d0df93aae230	8de7e4bf-0483-4a72-895b-bcf79594bfd2	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-16 15:48:02	2026-02-16 15:49:53	2027-02-16 15:48:02
9418580157a64a5f18a43296963b3fc6394be1b7d9c00d74924a2cc3f36090b79b8672b949ce2f0a	1b81af34-c972-49df-b816-ca2e925e9b9b	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToDriver	[]	f	2026-02-16 15:44:56	2026-02-16 15:44:56	2027-02-16 15:44:56
b3fd5f723ce472b09cfdc66ee6d8addc4cba8a6e0f2b81e1f6dcd7ea22043f6675ade7c4b7c3d9f9	b8dd794f-b7de-4bab-b53d-43d06dd45e52	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToDriver	[]	t	2026-02-16 15:24:52	2026-02-16 15:44:56	2027-02-16 15:24:52
654a732b73edfc98342503bf0a3fadb9f758fb25190ae508f7da11e6fb76bc62f612803bda480b83	b8dd794f-b7de-4bab-b53d-43d06dd45e52	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToDriver	[]	f	2026-02-16 15:44:57	2026-02-16 15:44:57	2027-02-16 15:44:57
f244e06842b2cddd2570533b8474caed955e889562fa46860794cdf430bd4c91e0aff7ab5e1fe2f1	62e81720-2260-4b67-bf44-fa8c558a116f	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToDriver	[]	t	2026-02-16 15:24:52	2026-02-16 15:44:57	2027-02-16 15:24:52
efbcfe576c75039c515c3a58fea94d0df0e25b2276af61eaa953fe7da5b9f7651406b36fad52eb79	62e81720-2260-4b67-bf44-fa8c558a116f	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToDriver	[]	f	2026-02-16 15:44:57	2026-02-16 15:44:57	2027-02-16 15:44:57
4f607ed04fb15637f92f132ceb5cf8623329aa3c85ed377e36fccc1d152d54b940fd2a82941f87df	8de7e4bf-0483-4a72-895b-bcf79594bfd2	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-16 15:44:56	2026-02-16 15:47:44	2027-02-16 15:44:56
c5d041a52b7a313552c89c1bbec5055299bb3d2a35b4990b1121423a4b41bcf9ff632457c7f4da89	8de7e4bf-0483-4a72-895b-bcf79594bfd2	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-16 15:47:44	2026-02-16 15:47:52	2027-02-16 15:47:44
5e410810b85860f2c1599757103bb94e5069283ba22998ccb04fda4dc9abd55de170217e2221471b	8de7e4bf-0483-4a72-895b-bcf79594bfd2	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	t	2026-02-16 15:49:53	2026-02-16 15:50:06	2027-02-16 15:49:53
dfacdd131dce5e12b7e90bfe54e43e25d711997f564dcc4bacbd0b5d7b64a6910737be1dc1d2a393	8de7e4bf-0483-4a72-895b-bcf79594bfd2	a1147d18-cb1c-4ec3-997d-bc627a4453b8	AccessToCustomer	[]	f	2026-02-16 15:50:06	2026-02-16 15:50:06	2027-02-16 15:50:06
\.


--
-- Data for Name: oauth_auth_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.oauth_auth_codes (id, user_id, client_id, scopes, revoked, expires_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.oauth_clients (id, user_id, name, secret, provider, redirect, personal_access_client, password_client, revoked, created_at, updated_at) FROM stdin;
a1147d18-cb1c-4ec3-997d-bc627a4453b8	\N	JAGO Personal Access Client	ib0PI4FQ6veFrLdhT52CU9hba2hY9hi2dWJrVqaR	\N	http://localhost	t	f	f	2026-02-14 18:28:21	2026-02-14 18:28:21
\.


--
-- Data for Name: oauth_personal_access_clients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.oauth_personal_access_clients (id, client_id, created_at, updated_at) FROM stdin;
1	9a878b41-fc9e-4789-a835-0b3ebe060778	2023-11-04 09:44:36	2023-11-04 09:44:36
3	a1147d18-cb1c-4ec3-997d-bc627a4453b8	2026-02-14 18:28:22	2026-02-14 18:28:22
\.


--
-- Data for Name: oauth_refresh_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.oauth_refresh_tokens (id, access_token_id, revoked, expires_at) FROM stdin;
\.


--
-- Data for Name: otp_verifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.otp_verifications (id, phone_or_email, otp, is_temp_blocked, expires_at, created_at, updated_at, failed_attempt, blocked_at) FROM stdin;
2	+919876543212	000000	f	2026-02-14 18:30:17	2026-02-14 18:27:17	2026-02-14 18:27:17	0	\N
3	+919876543215	000000	f	2026-02-14 18:33:48	2026-02-14 18:30:48	2026-02-14 18:30:48	0	\N
\.


--
-- Data for Name: parcel_cancellation_reasons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_cancellation_reasons (id, title, cancellation_type, user_type, is_active, created_at, updated_at) FROM stdin;
4973ede7-166b-445c-8267-fd40e67dab0f	Changed my mind about sending the parcel	accepted_ride	customer	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
5d4c0ddb-de91-4f51-b857-46bdfc3009c2	Wrong pickup or drop-off address	accepted_ride	customer	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
ffd33a71-65e5-47c8-bff4-077b3a750ff3	Pilot is too far away	accepted_ride	customer	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
02d553b5-cf50-4929-9df4-7338e09d27e5	Found a better delivery option	accepted_ride	customer	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
b303cbb9-68a1-42b6-9abb-1a27da70554a	Parcel no longer needs to be sent	accepted_ride	customer	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
1c5b0914-b8c1-4686-bb25-772f3997f787	Pilot is taking too long to arrive	ongoing_ride	customer	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
4dcdbba9-d6c3-4c95-bb40-c54d85f7dac3	Safety concern about parcel handling	ongoing_ride	customer	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
2347692a-03e4-41c9-89e3-e86d87c53d3e	Pilot is going wrong direction	ongoing_ride	customer	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
57ad846d-fd11-4286-b76e-7e34f13221fa	Customer not available at pickup	accepted_ride	driver	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
c1ec26ac-7c82-4c5e-9120-d496fbd3ea46	Parcel is too heavy or oversized	accepted_ride	driver	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
2c26adee-5229-4268-9c00-f0f42e1b1080	Cannot reach pickup location	accepted_ride	driver	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
4ac07239-c726-4577-b9d5-154b170dd3d3	Vehicle issue	accepted_ride	driver	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
4a4eeaeb-cab7-47d1-8ac0-94b852f5d4f6	Receiver not available at drop-off	ongoing_ride	driver	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
4e5ea52c-2dce-433f-977c-d02201cb2b17	Wrong delivery address	ongoing_ride	driver	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
7632ef98-f5d1-442f-9a28-4ec47709853c	Road blocked or inaccessible	ongoing_ride	driver	t	2026-02-15 15:09:09.877433	2026-02-15 15:09:09.877433
\.


--
-- Data for Name: parcel_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_categories (id, name, description, image, is_active, deleted_at, created_at, updated_at) FROM stdin;
19d6c1ad-4e38-4757-a10c-e911af57469b	Documents	Letters, envelopes, paperwork, certificates		t	\N	2026-02-15 05:43:43.088516	2026-02-15 05:43:43.088516
1cadd5a3-eda5-4275-b7cc-a24f95018359	Small Package	Small boxes, electronics, accessories		t	\N	2026-02-15 05:43:43.088516	2026-02-15 05:43:43.088516
7b78ce2c-84df-4df1-9d82-41036ff0c318	Medium Package	Medium boxes, clothing bundles, shoes		t	\N	2026-02-15 05:43:43.088516	2026-02-15 05:43:43.088516
7b589f71-f578-4399-bc88-d642384ad59b	Large Package	Large boxes, furniture parts, appliances		t	\N	2026-02-15 05:43:43.088516	2026-02-15 05:43:43.088516
eed8d0dc-713f-4317-a8f8-01930ac91519	Fragile Items	Glass, ceramics, delicate electronics		t	\N	2026-02-15 05:43:43.088516	2026-02-15 05:43:43.088516
80c5fee0-e64f-4d35-9022-34db679fcd20	Food & Perishables	Food items, cakes, flowers, perishable goods		t	\N	2026-02-15 05:43:43.088516	2026-02-15 05:43:43.088516
\.


--
-- Data for Name: parcel_fares; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_fares (id, zone_id, base_fare, return_fee, cancellation_fee, base_fare_per_km, cancellation_fee_percent, min_cancellation_fee, deleted_at, created_at, updated_at, per_minute_rate, minimum_fare, pickup_charge_per_km, pickup_free_distance, waiting_fee_per_min, vehicle_category_id, vehicle_category_name) FROM stdin;
9a49b4e4-bc31-4221-9b76-4e3be034e830	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	30.00	10	10	12.00	10.00	20.00	\N	2026-02-15 07:54:01.346437	2026-02-15 07:54:01.346437	1.50	50.00	0	0.5	0	\N	\N
ea4ca4d4-c9a1-4b56-b762-3f306d9c57ea	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	25.00	15	10	8.00	0.00	0.00	\N	2026-02-17 16:28:32.300919	2026-02-17 16:28:32.300919	1.50	30.00	0	0	0	b6348701-aa7a-4c25-a9d5-b0407649dc78	Parcel Bike
de83d28d-dbe3-474c-9495-4d143a0db7d7	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	40.00	20	15	12.00	0.00	0.00	\N	2026-02-17 16:28:32.300919	2026-02-17 16:28:32.300919	2.00	50.00	0	0	0	b7c933ad-9a4c-4dd9-a508-5815f7582fa2	Parcel Auto
b6260dfc-9052-44ee-bd43-d76ad014d466	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	100.00	50	30	18.00	0.00	0.00	\N	2026-02-17 16:28:32.300919	2026-02-17 16:28:32.300919	3.00	150.00	0	0	0	fcd1a8f8-3d16-40ad-bb79-9ab56a9716a1	Tata Ace
f7bcd008-b703-4b7f-94f6-1e46c789e589	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	150.00	70	40	22.00	0.00	0.00	\N	2026-02-17 16:28:32.300919	2026-02-17 16:28:32.300919	4.00	200.00	0	0	0	96b93677-3e3b-4b74-abbf-ca28d372ec82	Mini Truck
3bedf934-3086-4bf8-9521-186524e16595	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	180.00	80	50	25.00	0.00	0.00	\N	2026-02-17 16:28:32.300919	2026-02-17 16:28:32.300919	4.50	250.00	0	0	0	9625ce4c-0ffb-498c-a4f6-1e37cdd0099f	Pickup Truck
\.


--
-- Data for Name: parcel_fares_parcel_weights; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_fares_parcel_weights (id, parcel_fare_id, parcel_weight_id, parcel_category_id, base_fare, return_fee, cancellation_fee, fare_per_km, zone_id, created_at, updated_at, per_minute_rate, minimum_fare) FROM stdin;
2	9a49b4e4-bc31-4221-9b76-4e3be034e830	94bdbbb7-7ebb-453c-880d-50b897d00df4	19d6c1ad-4e38-4757-a10c-e911af57469b	20	10	10	8.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	40.00
3	9a49b4e4-bc31-4221-9b76-4e3be034e830	94bdbbb7-7ebb-453c-880d-50b897d00df4	1cadd5a3-eda5-4275-b7cc-a24f95018359	30	10	10	10.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	50.00
4	9a49b4e4-bc31-4221-9b76-4e3be034e830	94bdbbb7-7ebb-453c-880d-50b897d00df4	7b78ce2c-84df-4df1-9d82-41036ff0c318	40	10	10	12.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	60.00
5	9a49b4e4-bc31-4221-9b76-4e3be034e830	94bdbbb7-7ebb-453c-880d-50b897d00df4	7b589f71-f578-4399-bc88-d642384ad59b	60	10	10	16.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	80.00
6	9a49b4e4-bc31-4221-9b76-4e3be034e830	94bdbbb7-7ebb-453c-880d-50b897d00df4	eed8d0dc-713f-4317-a8f8-01930ac91519	50	10	10	14.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.50	70.00
7	9a49b4e4-bc31-4221-9b76-4e3be034e830	94bdbbb7-7ebb-453c-880d-50b897d00df4	80c5fee0-e64f-4d35-9022-34db679fcd20	35	10	10	11.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	2.00	55.00
8	9a49b4e4-bc31-4221-9b76-4e3be034e830	adafae1f-187f-4417-b20a-d4b834bcb612	19d6c1ad-4e38-4757-a10c-e911af57469b	30	10	10	10.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	40.00
9	9a49b4e4-bc31-4221-9b76-4e3be034e830	adafae1f-187f-4417-b20a-d4b834bcb612	1cadd5a3-eda5-4275-b7cc-a24f95018359	40	10	10	12.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	50.00
10	9a49b4e4-bc31-4221-9b76-4e3be034e830	adafae1f-187f-4417-b20a-d4b834bcb612	7b78ce2c-84df-4df1-9d82-41036ff0c318	50	10	10	14.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	60.00
11	9a49b4e4-bc31-4221-9b76-4e3be034e830	adafae1f-187f-4417-b20a-d4b834bcb612	7b589f71-f578-4399-bc88-d642384ad59b	70	10	10	18.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	80.00
12	9a49b4e4-bc31-4221-9b76-4e3be034e830	adafae1f-187f-4417-b20a-d4b834bcb612	eed8d0dc-713f-4317-a8f8-01930ac91519	60	10	10	16.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.50	70.00
13	9a49b4e4-bc31-4221-9b76-4e3be034e830	adafae1f-187f-4417-b20a-d4b834bcb612	80c5fee0-e64f-4d35-9022-34db679fcd20	45	10	10	13.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	2.00	55.00
14	9a49b4e4-bc31-4221-9b76-4e3be034e830	4cf69e8e-a3b5-44f1-8984-ab83404d694c	19d6c1ad-4e38-4757-a10c-e911af57469b	45	10	10	12.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	40.00
15	9a49b4e4-bc31-4221-9b76-4e3be034e830	4cf69e8e-a3b5-44f1-8984-ab83404d694c	1cadd5a3-eda5-4275-b7cc-a24f95018359	55	10	10	14.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	50.00
16	9a49b4e4-bc31-4221-9b76-4e3be034e830	4cf69e8e-a3b5-44f1-8984-ab83404d694c	7b78ce2c-84df-4df1-9d82-41036ff0c318	65	10	10	16.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	60.00
17	9a49b4e4-bc31-4221-9b76-4e3be034e830	4cf69e8e-a3b5-44f1-8984-ab83404d694c	7b589f71-f578-4399-bc88-d642384ad59b	85	10	10	20.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	80.00
18	9a49b4e4-bc31-4221-9b76-4e3be034e830	4cf69e8e-a3b5-44f1-8984-ab83404d694c	eed8d0dc-713f-4317-a8f8-01930ac91519	75	10	10	18.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.50	70.00
19	9a49b4e4-bc31-4221-9b76-4e3be034e830	4cf69e8e-a3b5-44f1-8984-ab83404d694c	80c5fee0-e64f-4d35-9022-34db679fcd20	60	10	10	15.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	2.00	55.00
20	9a49b4e4-bc31-4221-9b76-4e3be034e830	86eb1302-1cc0-4f4c-94ef-2b07eb3e53c5	19d6c1ad-4e38-4757-a10c-e911af57469b	65	10	10	15.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	40.00
21	9a49b4e4-bc31-4221-9b76-4e3be034e830	86eb1302-1cc0-4f4c-94ef-2b07eb3e53c5	1cadd5a3-eda5-4275-b7cc-a24f95018359	75	10	10	17.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	50.00
22	9a49b4e4-bc31-4221-9b76-4e3be034e830	86eb1302-1cc0-4f4c-94ef-2b07eb3e53c5	7b78ce2c-84df-4df1-9d82-41036ff0c318	85	10	10	19.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	60.00
23	9a49b4e4-bc31-4221-9b76-4e3be034e830	86eb1302-1cc0-4f4c-94ef-2b07eb3e53c5	7b589f71-f578-4399-bc88-d642384ad59b	105	10	10	23.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	80.00
24	9a49b4e4-bc31-4221-9b76-4e3be034e830	86eb1302-1cc0-4f4c-94ef-2b07eb3e53c5	eed8d0dc-713f-4317-a8f8-01930ac91519	95	10	10	21.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.50	70.00
25	9a49b4e4-bc31-4221-9b76-4e3be034e830	86eb1302-1cc0-4f4c-94ef-2b07eb3e53c5	80c5fee0-e64f-4d35-9022-34db679fcd20	80	10	10	18.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	2.00	55.00
26	9a49b4e4-bc31-4221-9b76-4e3be034e830	e3709b7a-13e5-4a36-a7d0-b00f32117c0b	19d6c1ad-4e38-4757-a10c-e911af57469b	90	10	10	18.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	40.00
27	9a49b4e4-bc31-4221-9b76-4e3be034e830	e3709b7a-13e5-4a36-a7d0-b00f32117c0b	1cadd5a3-eda5-4275-b7cc-a24f95018359	100	10	10	20.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	50.00
28	9a49b4e4-bc31-4221-9b76-4e3be034e830	e3709b7a-13e5-4a36-a7d0-b00f32117c0b	7b78ce2c-84df-4df1-9d82-41036ff0c318	110	10	10	22.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	60.00
29	9a49b4e4-bc31-4221-9b76-4e3be034e830	e3709b7a-13e5-4a36-a7d0-b00f32117c0b	7b589f71-f578-4399-bc88-d642384ad59b	130	10	10	26.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.00	80.00
30	9a49b4e4-bc31-4221-9b76-4e3be034e830	e3709b7a-13e5-4a36-a7d0-b00f32117c0b	eed8d0dc-713f-4317-a8f8-01930ac91519	120	10	10	24.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	1.50	70.00
31	9a49b4e4-bc31-4221-9b76-4e3be034e830	e3709b7a-13e5-4a36-a7d0-b00f32117c0b	80c5fee0-e64f-4d35-9022-34db679fcd20	105	10	10	21.00	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	2026-02-15 07:54:30.816541	2026-02-15 07:54:30.816541	2.00	55.00
\.


--
-- Data for Name: parcel_information; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_information (id, parcel_category_id, trip_request_id, payer, weight, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: parcel_refund_proofs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_refund_proofs (id, parcel_refund_id, attachment, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: parcel_refund_reasons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_refund_reasons (id, title, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: parcel_refunds; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_refunds (id, readable_id, trip_request_id, coupon_setup_id, parcel_approximate_price, refund_amount_by_admin, reason, approval_note, deny_note, note, customer_note, refund_method, status, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: parcel_user_infomations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_user_infomations (id, trip_request_id, contact_number, name, address, user_type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: parcel_weights; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcel_weights (id, min_weight, max_weight, is_active, deleted_at, created_at, updated_at) FROM stdin;
94bdbbb7-7ebb-453c-880d-50b897d00df4	0.00	1.00	t	\N	2026-02-15 05:44:07.843023	2026-02-15 05:44:07.843023
adafae1f-187f-4417-b20a-d4b834bcb612	1.00	5.00	t	\N	2026-02-15 05:44:07.843023	2026-02-15 05:44:07.843023
4cf69e8e-a3b5-44f1-8984-ab83404d694c	5.00	10.00	t	\N	2026-02-15 05:44:07.843023	2026-02-15 05:44:07.843023
86eb1302-1cc0-4f4c-94ef-2b07eb3e53c5	10.00	20.00	t	\N	2026-02-15 05:44:07.843023	2026-02-15 05:44:07.843023
e3709b7a-13e5-4a36-a7d0-b00f32117c0b	20.00	50.00	t	\N	2026-02-15 05:44:07.843023	2026-02-15 05:44:07.843023
\.


--
-- Data for Name: parcels; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.parcels (id, trip_request_id, sender_person_name, sender_person_phone, sender_address, receiver_person_name, receiver_person_phone, receiver_address, parcel_category_id, parcel_weight_id, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: payment_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payment_requests (id, payer_id, receiver_id, payment_amount, gateway_callback_url, hook, transaction_id, currency_code, payment_method, additional_data, is_paid, created_at, updated_at, payer_information, external_redirect_link, receiver_information, attribute_id, attribute, payment_platform) FROM stdin;
\.


--
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pick_hours; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pick_hours (id, name, duration_type, extra_charge, start_date, end_date, start_time, end_time, week_days, zone_id, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: question_answers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.question_answers (id, question, answer, question_answer_for, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: recent_addresses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.recent_addresses (id, user_id, zone_id, pickup_coordinates, pickup_address, destination_coordinates, destination_address, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: referral_customers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.referral_customers (id, customer_id, ref_by, ref_by_earning_amount, customer_discount_amount, customer_discount_amount_type, customer_discount_validity, customer_discount_validity_type, is_used, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: referral_drivers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.referral_drivers (id, driver_id, ref_by, ref_by_earning_amount, driver_earning_amount, is_used, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: referral_earning_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.referral_earning_settings (id, key_name, value, settings_type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rejected_driver_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rejected_driver_requests (id, trip_request_id, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reviews (id, trip_request_id, given_by, received_by, trip_type, rating, feedback, images, is_saved, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: role_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role_user (id, role_id, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id, readable_id, name, modules, is_active, deleted_at, created_at, updated_at) FROM stdin;
fcdd0de5-bfad-44e2-93d8-50cc9aa61337	1	Admin Manager	["trip_management","user_management","vehicle_management","fare_management","promotion_management","parcel_management","transaction_management"]	1	\N	2026-02-17 16:55:06.157801	2026-02-17 16:55:06.157801
3d60b694-6641-4fc2-b409-9ab91b71898e	2	Operations Manager	["trip_management","user_management","vehicle_management"]	1	\N	2026-02-17 16:55:06.157801	2026-02-17 16:55:06.157801
f1a3800b-62d0-4da4-ba14-dcfc6227d7ed	3	Finance Manager	["transaction_management","fare_management"]	1	\N	2026-02-17 16:55:06.157801	2026-02-17 16:55:06.157801
\.


--
-- Data for Name: safety_alert_reasons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.safety_alert_reasons (id, reason, reason_for_whom, is_active, created_at, updated_at) FROM stdin;
618dcd0d-c663-4900-8fee-4dd1cdc1ec24	I feel unsafe	customer	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
b7cbf85e-c332-4234-8968-f032836172db	Driver is behaving inappropriately	customer	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
f22f1997-bac9-4562-ab2c-52ae7c702d59	Driver is taking wrong route	customer	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
297c03a0-c2ad-4835-acd6-6103106a0130	Vehicle condition is dangerous	customer	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
feb7696f-eca4-4416-9bfc-2c6a56123411	Driver appears intoxicated	customer	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
1323bb60-d46b-4cb9-a9c4-9496538c4e85	I am in an accident	both	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
36a57e9c-94ab-4591-94cf-a2892539b103	Other emergency	both	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
50e1c710-22fd-4000-a7b9-d983b63a1920	Customer is behaving inappropriately	driver	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
7af96467-fbb7-47b2-9b74-14074b87ff35	Customer is threatening or aggressive	driver	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
005b2a35-5eb3-4417-9c64-b567e5b3f5fa	Unsafe area or road conditions	driver	t	2026-02-17 16:50:29.832548	2026-02-17 16:50:29.832548
\.


--
-- Data for Name: safety_alerts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.safety_alerts (id, trip_request_id, sent_by, reason, comment, alert_location, resolved_location, number_of_alert, resolved_by, trip_status_when_make_alert, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: safety_precautions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.safety_precautions (id, for_whom, title, description, is_active, created_at, updated_at) FROM stdin;
12f406fa-8348-4ee1-a36e-af9a85d7bdb7	["customer","driver"]	Share Ride Details	Share your trip details with trusted contacts before starting a ride	t	2026-02-17 16:50:25.236637	2026-02-17 16:50:25.236637
38a5d998-db20-4132-a82b-450bc3c82555	["customer"]	Verify Vehicle Details	Always verify the vehicle number plate, model and color before boarding	t	2026-02-17 16:50:25.236637	2026-02-17 16:50:25.236637
0e13c2c3-21c7-4b9d-b176-4528e86c47d2	["customer"]	Check Pilot Identity	Verify the pilot face matches their profile photo in the app	t	2026-02-17 16:50:25.236637	2026-02-17 16:50:25.236637
62660be0-ae30-4c9f-8c24-460c1355f4e7	["customer","driver"]	Wear Seatbelt	Always wear your seatbelt during the ride for safety	t	2026-02-17 16:50:25.236637	2026-02-17 16:50:25.236637
431f833e-3d86-49e4-b5c1-e6a5490fda46	["customer"]	Sit in Back Seat	Prefer sitting in the back seat when riding alone especially at night	t	2026-02-17 16:50:25.236637	2026-02-17 16:50:25.236637
1af31dbc-19c7-40ac-b1b8-2d53b4498591	["customer","driver"]	Track Your Route	Keep the app open and follow the route during the trip	t	2026-02-17 16:50:25.236637	2026-02-17 16:50:25.236637
\.


--
-- Data for Name: send_notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.send_notifications (id, name, description, targeted_users, image, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) FROM stdin;
DGvSaaiwPyGl8FaDn7TEsWMEAwLTsWKIZ0l4Bijb	\N	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJa0pPYTJKeVJtOTRLMHd5TTNKRk5HUTFjV2REZWxFOVBTSXNJblpoYkhWbElqb2lTalpZV0VWQlZVdFZRMjF3U0VGTVkzVXhNMVJCVVZGTE0yeFdWbkJ5V1ZaMVpERlNjMUZSWVM4d2FraHVUbEpHSzBscVVHRTRLMHRNVVU5eVduUkpaRmM1T1ZSSWVuWktSVk40V25wTFpIVlhkRUpDYjJ0S1kwVnRNWEE1Ums4d2JIQXhUMGxWT0hZM2FGQkxSekE1Y0hrelRVcFJSV1ZwV20xT1lsZGphMlZTVWpkUFFsRldOVEJWUWxwWk9Va3lVblpZYjA5bU9HSjBlVlZXVlVaQmNtSTVaMnRQVGxsek0zWlNZbm94Y201bVZISnhaMjlKZVRZM2JVUm5SR2RCZURVM2JXUXZWMmcxZGs1TFVrb3lNRUV2YkhoUVZ6ZDBaR2xDV1dOMGVYVlpTVVJvU2xSbFptaEhjejBpTENKdFlXTWlPaUpsWXpGa09XTmtNVFpsTjJZME9EUXlaR016TUdRNE5HUTNNamRoT0RCbVkyWmpOREZsWVdKbE5qZ3pNbUV3TXpBMFlXTmtPV1ZpT0RBMFpqQXhPV1pqSWl3aWRHRm5Jam9pSW4wPQ==	1771346415
96YoLcGNiswkOUcDbkOp1ITYtplwintqknfiY4r1	\N	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/140.0.0.0 Safari/537.36	ZXlKcGRpSTZJbFl5VG5SVldsRlBha1ZhWVRNMlNFTmxVRUpMV0djOVBTSXNJblpoYkhWbElqb2lTV0pIU25WemJsY3hXREl3TTFKR1ZVMTZPRVpwTWpoc1kyTnRWamxWY0hwRWEwZFBkMlJFTlRGUFFqWTFPWGMxTmxCRGMxbFRkSGhqVW5ad2JsZGhlbkZPZFZFeVVISnRSRFpGU2tOMmRWYzFNRmN6WmpKWk5TOWhUMVY2Vm1KQ01pdGpNRGt6WVVaNVdHTlBkRXhzYzBvNWJucDBTWHAyTjJoMFRubGtabVJhYzFwU00xbGliV014VVc4NWIwZ3hjRTVHWTJONFV6WlJTaTl0VUROblJUVnplREJvUlZJeGJIZEtiblpRYlhSeVdWQnJURUZWVnpKSVRIcFFaQ3RITXpOaVRtbFhWR3N3TUVRdlRIVkRiVEZqY21oVGJXOUNWbmM0ZUVGR1ZUUmpRVkpXU205QlNIVnNNSE01YUhGUFdtc3pNSHB4UkVKRFNIUnBUU3Q0ZVdFdmNubDJOVmgxY1hwMmMzaDFlR3haYlhGT2NWVnlabkZxY0dGMFJFVndOR2xYYjIxR2JGSldPU3RvWXpSTVZUTnlXRTUwUTNGT1EwRnVkRUZoYjNCRGEwWkhNV3RoYkdKT2VuQkVLM3BqWTNCS1FWWjFiRWRPYmxkT2QwMWxZa3gxYldoM1UwRm1PWFl3UldzNVNsSndjVlZ5VGxaa2Fua3pTVlJRV0V4NGNYaHJSbWhPYm1SUVIxSk5Vblp6THpGc2QxVnJWMjFMY0ZaTFV6SkplalU0YjBkNVRVbzRTbkZhYmpOUVFXcG9TRzlzVFRCSVNsQlBOVWR1YlhGeE1UZG5SR2wzUVVaSEswWnhkbXhCTlRoTWJFbGFVMnA0UXk5VlZrY3lOakJqU0haVmJsaHdkMDF1V2s1U1VFUkhkM0ZRUzFJNWIxQnJOR3RNU1dWYVEwVm9SbnBVWldoc2RHVlVXVXh3TW14Nk1VdEROSEV2TWtwRlVsSjJZbmRSZUZZeFJXNDBaRVppYjNOellTOU5iREpLVG5SdVdIWkVkR2RUY0ZkR1Nrd3hkMFZoT0VSeGR6QlVPVzlVVFRJMWIwUmhUMVl3WlU1RGRETlBOVXdyUldkTFpGQjJZMHRsT0hGQldtOTJWeTlPU0UwMVVsTldlamhQV0d4c1NFOVJTMlpJS3pkSU9ITk1jVGhHTlcxRWVtVnBWbmg2Wm5KU2NtZFBaRE4zWjB0UVVYaFRWR2N3YUZsT1VUUjZXa2RrU1VwMkt6QklMMVZSTkVOUlFWRldaMmhEZUdkSE4xQlJSVVk0YVhoVFVDOWpObFExUVRCeWJHZFNiMHR6WVRKNGFHTTBaV1Z4TVRKYVJrOWxVRzVqY2tKRGJERXlSMmhtTW5VemVEVlZPV2QzUnl0aVIwRTFNbEV3ZW5FdldFVTVRbFkwUmxWT1QxSkdTazFYUkhsR2F6QmxUVUpTUjJ0WlFXazRaWEo1YVc1WWJEQkNTRUZwWlRCYWFGVlBaM2xsYmtNeVVscFRSV28wY1VSV2R5dHFSVlpHTjNsQllWRnhWVlZ1ZFRSRGRVeHZjellyUVVSVmVrSjNaelV6Vmt0b1dXSlhVRW95TDFCaGVrY3JRa3RzUkZaUllrUTBRbkJVU2pkVk4wWmxaVXhJTjJKcVpYVjZURnBMZDFwaGJYSkZLMU0zZFU5SWVrdEJSVkV5T0VSblZtdGxja3RJU2twMlNUTlFXbTl4ZWpoRGQxZEJjRUZrTm5SNVRYTTRVamM0VVZsNFZUbHlVMDgwV1Rab01XOVJSMU5RY0ZGNGNpOVlVWEJSU1QwaUxDSnRZV01pT2lKall6RXdOamt5WlRrMFl6Y3lNamhoWVRFelpEWXhNak0xTTJVNE4yUmtPR000TmpJME1EUTBORGcyTlRFMlpXSmxNekF4TlRnMk1HWmxZemN3WW1aaUlpd2lkR0ZuSWpvaUluMD0=	1771347550
qplGXj48fbWUxGQCbEZ82og5R0s70BXSQatzjXcf	\N	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/140.0.0.0 Safari/537.36	ZXlKcGRpSTZJblZyVVZaQk0yaEpiWGRFTDB3NVZuRlVaa2RMU21jOVBTSXNJblpoYkhWbElqb2liMDVaTUdsU01sa3lSMGhSYm10WU1XbzJabXd2U3poS01YcFNPV2s1YnpkR01GaEljbGRyWW13dmEydzFVa1pWZUc5eFR6VTNXbHBxSzBsTmJFSlpaa2syTTIxR2NUSlRkVmxMVXpZMFdtVm9Sa0Z6U2xCWEwxTlVXVEozZG1KRVdFNVpaM1kzVW5CVEwxRk1XR3d2U1U4cmVuWnpjVWQyYmxKUGJEQmhXbXhTU3l0TmVIbHBhVGRvY2xSa2RDOXNVa0YzUTJOUGJEUnlZbVp0TkRaTFJYQnNiVVkxY0hnclRtWnFLekZxWmtaclJXWlllRzFwVmpGT01FOUhaR05aYzNOTFNIQklTMFpXUzFCeGJVUk9Wakp3WlVWaGNuRmpVa2g0UVVaMlIzSjVlV1JNZUVod1UydHhhbk5ZVTFkU1duSXZWRTVQZFhOUFZGSXJRVUpCZWpVMWFIcDNXVmxyY20xSFQxbzBXRzlQZVVOM05VbEJTVzl0ZUVOd2JrcFNRamxQZDJWeVJVaEpORUZ6V2poRGJuUlVUSE0zSzFCalRXcDFSM0IxTUdaa1YyMDNWbTQyYlM5Q09GZEROR1I0YW05cWNDOVplRXhyWlhsTlpIcGxaM050ZGpoRE9WTlpTa3N2WkdWM1ZWSTVTamxKU21rNFkwczBkMVJzTWpSYWJIUmFNM1V6VTFoT2F6QkJNbm8zU3pKNE1ITlZhbGhDTHpad2JYaDVlV2g2WmxGU1VEWlplbTR2WWxWWmVFWldRWFZLYms1clZuTTBlbTAyUjNKeFlsTkhWMFZ2TjNrd05EbFdTa05KZW1nd1duWmxjRFZCUlhSSmVFRklUbFYxTlZrMlVrbzRhalZJUTJwSldFVnlZMlU1UjNGT04wODVXVkJaZFc1M1UzVkhTbE01VUhaSWFVVllVM0o2U1RWVFkxUmxZVkp5V0VkeVZUWlBUWEpEVnpsU1pVbHhhUzlLY21oblIydFpVa2NyU25acVdIa3pjR1paTjFCc1pVUllObUk0V1M5cmFGaEZVSGhMTm5WVWNrZEdWSGxhYW1OQlNWZ3pNemx6V2t4eVIyOUpiMDFsYmtVclkycFlMMmhIVFRsVWFHcHhUVVkxY1V0aFlYZzNSV0ZwUzNoUFYwNUdUM05uVDNOUWVVVmFXSFpVWkhKV09URnRjbVE0YlVKd2JYVkpaVXRDWm5sbFlWVTJVVU5MWXprMmQzTTJhM1pPTDFkVE4zTk1iMUJtTDNkWk5XMVZLMUF5WlZoWU1uVTJSR2RhUkhkSGRYSnhkV2N2UnpaMGFraDFZaXR0VlhWRFNFNTRNMEU0UkhGdlMxUnhOMVJpTDIxcWVFMDJNVXhIVkVSNVVUY3pjamt4U25oblNHOXRORUpaV1hSellYVklUVWRhUldjMVJHOU9iSEpHYzNwTGNqQnRSRmRYWVhoVVZGUnBXa000ZEdoeFUzbE1ka2RoVjNCbVRXSTJkM2w2U0UxUGRYSXdUbTVXVUVGbFFrNUxSR3RITDBwTmRrOVBUak5YWVRoRGFuRnNWR2t5TUc5SlZ6ZFdXWE0zVWxwUmRtMUVVbGhCTUhNcmNsa3JWVEZMTVVsbFUySm5abUZoVlZCSEsybEhXSEJJYWpnemFYUlljazFwTTJkUlRuUTBOamszUVUxU1YySkpUQzlRUnpWalNUWk5RbEZIY1ZoaVMxUkpLM05TYlUxVWFHTk9OVUpYVm0xRk4wdHZNMmd2WVhOdVp6bEdhV2RNVEVrM1EyUjBNbGsyY3owaUxDSnRZV01pT2lJeE9UVTBPVFJoTnpWaVkyUmpaRE0xT0RrMVlqVXlaVFptWldRM01qQmxNbVl5WkRjeE5tWm1ZVFU0TURkaU1UWXdZVEU1TnpJeE56VmhNelZpWVRsaElpd2lkR0ZuSWpvaUluMD0=	1771344700
TZLzj3K6bpe6J5E9fZNcSMXUvhEiN4bBGQLvuB1r	\N	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJbEExYjJOc1JHcERWVWMzU21KcmNTOW5PV0VyTDJjOVBTSXNJblpoYkhWbElqb2lhbUZhVkhSb1QwTk1jMlp5T0Rsb2JrVTNjRzFoUWtodk1FbGpRMnMwVEc1blZVUjZURXhYWm1OaVVXZEhjMGxNTVRabE9YcDJPRkJTTUZGRlFta3hiMmhSUTNwNVkyUjNSbWxQU2xCd1dsSnNaV2xQYW5oRlVsQjJVMmhCVFZjeGVYUmtRbVkxU1ZKUmNHeE5XbGRtYzJoMVVuWktZMHB2U1U5Q1FuTjFUVlF6U2tkV01VSkljMFJ0UVdsbFYyZG1VR1pNTTJWVWRtNTBiVGgwY205eU0xSkVUMjlwYW1GUmFucFljVmx1YlhZeFluRnNlV3RtUkZnNVRpOXNXRWxQU0VRMlZXSXZhREp1V2xZNGRXdE9aVnBzZVcxaU5VOXZWVmRXTDBNMGVYQmxNMlowYW1SdVUya3JaamhhWmxnemQwMXhVMWh1U0hOSUwycEpOR0ZFVG5GaGFXTlJhMnB5U2psTU9WVjZTV3Q0WVV0WlRVNURTVE5WV1drMGFITkpjQ3MwVldSR05UZDRkVk52V1VrNGJWaHhSRFZWYzJRclQzUXlUR3cxTUVSbGNqSnFOR0psV1Uwek0xYzVkRzlQY25ZNFRWWmtVelpIY2poQlFYWkxRMk5JTkcxdmJFUktOV0pPVm1FM1lWUktjVWxUY1VSeU1WRmpVVU5NVHpGMFprZFdUM053YVhBelMwUlBWMkZ3ZDB4VksxRnZjRXRPWkVGaGVtMUpOV2hwZW0xV1pHZEdWRVEzZWpOT1IyVkJVMG9yYUdGalQydEhZM2w2SzNwcGNYQmxURGh3WWtwR2NWSjFZM3BzVDBOcUx5OTBjbTl0UzFOSmFXcFRMM0JXY2tGeU5FcHFhbVU0ZEhsRVYyUmpNWGx6VUZkT1ZtZG5kelZvUlU1WmRFczJabUYyTmtkVlMydHNRbGcyTkZWelQxQlBUbkZPUkVkdldUTmxjVFV5ZGpWcmRURkpjR3RLWTFKRlJYVmplbGMzT0hobmVGWjNSblpMTUN0alpXZHlkMmhoUVRZemN5c3pOWHBWUWtsVFNHSk9SbTlXTDFkS1FsQkplRVpYTUhKMWVqVjJWVVI2UzJwcllucEJZa2RFZFU5TWNXeDVXVXRZV1c1UmRXWndSRVF4VmpGck5YVTJjVUl5VUZKWlZVWnhhREUwY2tKc1REWnRPSEJSYURoamJtOHdhbkkyYUdNMU1sSm9Nek5ST1ZKek1YbEZZa3g0UkhsaVRsTndVV3BRT0hKSmMyWnlRVUVyVHpsaGQwNVJaMHh6TDFwdVpIRktWRzV3THpkWVdFeEpWMFp0V25WNWJWTnFkSE5CZGtveVJ6SkdMMncyTVRsNEx5OXJaV2RTY2toVVluaHphMHBuYjNGMVVFWlVSakJLTjBKWk4wOTNTR2ROTDA1a00ySmpkbTFXWmpoUGIzWkljR1YwWTJ0a1RWVk9Ta2hWV0VGaFJucDFWVEZYYlhObWJGY3pVa1UwZWpaeWIydEZTVU5qUzNjdmJUZEtlblI1WTJ4UldqQmpaRTFyZEVGNVlubDFSbEJHU3k5WWRrTjZUV3hFVldrM2VXNHhhbkpZTW1nNVRHZDJRMHN2T1ZsT2N5dFdPVmxVYld4aVpWQXhWa1ZFVmtFMFREaFpOSEpVTm5kTFlYaDZibWhyTjFreFVuZ3pORkF6UmtZemJuQm5Xa1o1ZEZsWmJVMTNXa1JoYlZoRlRtY3JWRk0zYkhwdlVIUm5aVUYzYkUweFJWUlJNWEZCTDNSVVkySXlXbkl2UlQwaUxDSnRZV01pT2lKaE1ESXdNRFkxTmpRM1pEYzRPREUwTWpFek1tRTJNMk0wWlRWbVpXVXhOMlUxTjJNek16VXpaV014Tm1ObFpESXpPR0V6WmpneVlqUTVPREJtTW1WbElpd2lkR0ZuSWpvaUluMD0=	1771350324
ZhcSslVDIVZ9I0MKNSJBhSJr4cQ7FgBa7DhJ4VAq	\N	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJblIzUVd0dFFsZFpPRVV4VlVaRVVUbGpPV3R4VEZFOVBTSXNJblpoYkhWbElqb2lSbWxMZFhkSlpqWTRaRFpOVm5aMllWbENSVGRaT1ZoQ1NXUjZkRWx6VG5vNVlVUllkM2cyWkV4TFpYQmhkbWMxYUdZMWVFOU9PRkY2YjBFeVFUQmFUazAwT0V0cmJHY3hiVGwyWlRaQmFqTkxiRlJIYmxsd1RHTjNkRGtyUVVoWlRFeEVRV0ZzTW5Wc1dDOVpPRmhFVjNGbFUwTlFNRzlMV1cwNWNXSkZXR2RtV0VoelVuRlRhRUZTY0dvd1dUVTVSak5DTURSU1ExSnJWVTUwWldkSU56TnJNR1JRYlhSbFpGWTJPV3hIY3l0TE5GRm1SbWRLYUZCRWVsZFJlU3MzZERWWFFUSk5TVTgxU0VscFdGQjRPV1JhYW5kbWRHcHJLMjVoWm5WRVJGSm9hRUZZVFRsWFZrSjBPRDBpTENKdFlXTWlPaUk0TVRVMk1HSTJZelppTTJFMVpUUTNNakUwWXpCaFptRm1ZVGs0WmprNE9XSTVZamxoWkRCa05qYzFZVEJpTldZek0yVXpNR1EwT0dZeVptVTNNVGs0SWl3aWRHRm5Jam9pSW4wPQ==	1771345985
qS6JnMinJq1X0xp83bNRom4qmPwY0PswvoY7y37E	\N	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJbWRZTTFNeVFsUnBVMHBuUmxaUE1WbzRVbTlwYW1jOVBTSXNJblpoYkhWbElqb2lTSGMwYlZOcVpubzJRV1pvUjA1RlVuaGlUMjF0UW01alZqUmtXRkJoWm5WNmNsWkRlVWg2U0Zad2NrRmlWV000V0ROckx6RlJWeTlhWldoaFQzbElPRmQ1WVZSeFFXMTBhV1YzY2k5Rk5YRkZSV1V2Y0hWV1drZE5hRWhaWXpVcmVVUmlkaXRKUVhNMWNUZGtkMXBVWldKRWVYZzRlakE0TmpjNUwwVjRTelpGTDNGamJYaG1UMHh6U0hKelVHUjZhbWR6UkU5WlJXSkVZblptYzFONlMxWnNhVWhrVkdKMmRqQkxTRVpCYVRSVFlteEhTbmd3UVZsWVoyVmlVV0kxY2toRmVVczJlRXRrVkZVd1dVcExZVXR3TkVSeFNHY3JkVU5rZUZab1FWTTRRa2xCUTFNMU9HOXpNRDBpTENKdFlXTWlPaUkwTmpsalptUm1OV05sTWpWaE9HWm1NVFZrT1RFMk1EVmlZV1k0WVRkaU5HWTJaak5oTUdGaU1EY3dNRFJqTVdOaE5tWTJPR1kyWlRJeE1XSXdOelUwSWl3aWRHRm5Jam9pSW4wPQ==	1771350236
XEgjpHwiB8RXEhWaW9VCibbvVEeFn8xkaOOwOQbm	\N	10.84.8.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJalUzTTJabFprOUJObXR2TVVvM1dWSTJObEpNTDFFOVBTSXNJblpoYkhWbElqb2lkSFZxYlRONWRTODJXRm95WVdKa1JDOW5UVmRTTlRZd2REWlhSbkZzY0VRek5razFWa0ZKV2tkVlZIb3ZOVlYyUzI5bWIzazNRWFJUTkhWUlUyMWpXbmhDU1hkWVdsaE1hRmRoU1V4MVpIZ3dVakpzYURoRldsZGFNMEZTT0hBdlIyMW1lbEl5T1hCS1IwVXZUa0pPY0RKb1dDOXhUV2R4YldKWlUySlpOVk4wYW5KRkwyaFBkVmRpYWsxbWNHTndObEpTVWpGMVpIazNkV052YlROdFVtMXJiRWhOYXk5dlMzVk9MMVI2VVZaT2RIRlZUSGx0Vm14eWNuTTFOeTlTT1hacmRWbENSbVpSTmpWclVraG5lVWx6WkVReVdWbEVjMVUwYW5oRlZrWnVTV3d4V0ZaMmR6ZHRhVlpoVVRWR1VWQm9Ra2xpYTJwS2EyOTJZWGRrWjFsMmJsZFJVVVZ6TUVOcFoxZ3dlVWxoVVhkTGEwcGpkbGxQTDJac1VtOWpTaTluWkhreE9DOTBNMjAwVGsxSkt6VnlURXh5ZW5KS1RXaDVSUzlsU1VwRVZHOW9ZamR4ZFdGTWJWQXhkSFZFVG5obmVWSjZhMWhEV25wRlFVbFBRbkZvZFdGNmIzcFVSVFJzUjBndk5sazNjMGszVlZWVWEwZG9hSEpTVTBGWFJrSXpVRWxOTVRGWGVVZHBTRXBZZGpscllURnVibWRXVGtsNE0zZ3hTRXBpU1ZGTFNFeFNTRlZrTWxSdk1pOXpWazkwVW1jMFkxSXJZMkUzV0RKRE0xVkJRbWxUU2xWQmNFWjVkRUZCV2pkWVUwVnRhM0ZETVRRMWMzSk9la3hsYVVaSlNteEhUelI2ZVU1R1FtNTRlbE55TUhSTGRqVnJhRTFVTmpsSlVUSmFSazh5VEZWb2FXZGFNMHc1ZG5ZMmNrZzFUVWwxVUU1MlZqTkpVRmR1TW1OV1ZYUjFMelZhUVdKSmVGWm9lRTVhWVdoVkx6QlJPR2RhZWpCdVVpODNWMUpaTVdGdFZGZFFZVmx4VkVocVlraGFZVkpvYlRaWU5YSXhkM2tyWlNzemFUTnlUWGM0V2tZMloxYzNXbkJDVnpOTlkzcEhZMWRLTVM5VVExSllRMkpUWkc1UmFtVnpZV1ZwYVd0S2QybHZPSFJoY0VwS1FWSmtTRlJGWVZBMmNIRXZjbkJZZG13eVNFZGxPR1ZvWm5KalVUWjZOMFZuTlRVeVVraEVRbTFrTUVsVloycG9RVEZZV25KblFXRldNelJMTVhveGMwSlBOelU0ZEVGcFVuZ3lNRGRsYjBzMkwwRnphbTAyVEVOc2FDdHpNVk5LY2s4NFIwdDRTazVXVGxwMVowaHpLelJNU21oU2VrWldaVUpoZVhkWmRtTjNaVk4wYWs5NVVVUnNWSHBpY1RWMVV6TXpaRUl2Y2tZNVEwODRhVmt2UW1kV1JqRXhNMlJSWWxCQlVHSlNSRVp1ZDFGb2FEZFlOVFJ6U1VZeVIwOXdVMFJCUTJKd2JEVktiMWhJTkZSRmR6ZDViMlI0YVhrNFpURmlPSEl4V2pWak1FTXdaa0ZwY1M5dVkyaEhUMmR1WjNsRVVURkVUbkZZSzNwWU0waG9RVUUyVTFoSk9HNWpiV2xZY0ZSWldIRk1UbUpHVDFFM1FXRkxObFpWVW5rck1VUnpaRkptUlhneFJXaG1aMHhFYzFwbE5tY3dlREpRYVZkeWRHUjBVSGRFVDJkRmIyZGhZMWRPS3pSQmJsWllZWE12YXowaUxDSnRZV01pT2lKaU1HWXdOREkzWTJabU5qRmlaakpoTXpsbFpqazFNVFl4WW1FM09XSTJOV05rWmpneFltWmtNRGhpTWpVNU9ERTRNVFppWkdVM04ySmpZV1V5Wm1Ga0lpd2lkR0ZuSWpvaUluMD0=	1771344872
biddzkOP3vsxleciz2DMEB9G2pVYNw7dLEaDyANZ	\N	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJa0pOZFZCV1IzUlZlVUl2ZVZoVmNVRkdOMnBhVldjOVBTSXNJblpoYkhWbElqb2lSM3BzWlRsVFJYRXdiblZzVHpkRWIydE9aSFJ3U25KTmQwNVhaMUUzYkUwcll6bHpabGxZSzJOcGVsZG1NVTFLVTNoRmJuQk9abkJGT1VGdFVsRkpSVFZzUTBGWWF6bGtVMWxpWlZwSVNFdHBOelF4T0VoVGRGSkRiRGhWZUdGSmNGaENURWxIVDNseGRFNVNSbVJPUlhkT2Jsb3lZMjVtV1VSTVUwOVVkU3RKYlVjNWRrRm9lVVpKTTFad1RFSlpjMFJaVGtscFVFbHdWMjlaY1hBMGFsbFdNVko1ZERsTU4waDZMM2RuVTA5R1VVRnJkRlZpTlhRelEyeHlZME5HTVRkSFVVRXdkWFZqZGtKbWRWSm1VRVpJV2pWT1YwaHdjVGRhYmxOaVJraFdNVEJ2ZERCemFtTlVWbU5RV21GUFNYaERNSElyVDJweVZtUktabWhuZERkR2Vsb3pjMWhoYTBONU1YTnVjMkZNWWxNMldHVTNPRkIzSzFaa1dDdHNhVmg1Ykc5UWFGTlFLMVZGU1ZSQmVFWlVaM0JJVmtwSE5WaGlNVFJaYUZwUVIwNUhTbm8yVW1sU2RXTnBiVVJyWTNjM1QxRkpRV1pRTjJOd1RHVkZRbWRIVERObVJuRjFXbkpxYTA1MGRVeERTVVZ0TWtOc1ZpOU5MMHBwUlRGTVMyVkhRMWxRYjJaTldYUmhWSE5rTTBrd1IzaHViMDU2U3pGYWJISXZUbk51TWtJeFZtZHZURWxKV2tvNWNpdEpPREpDYUdsNGJHaElhVlZQZEVOMWNWaFlOVmg1TmtZNU1taHNjR3ByTTFaeWR6WXlWRE5EZEc0NVpEVkZUVU5qZVVNNWFEUjVUMnR1ZERoTFVrTlJVeXQxYURoc1NITlBhRzFTYm1ReFJVcHFXbmh0VVdscFdVTXdLMmRHT1hGRlpsaEdTekJ2WVdKMk1rZGhhbXBGY1hOTVpYcDZaR1JFYlU1clZFNW5PRkJDZW14a00ybFVTbGRoYms5YVZVWXdRWFF6WVZSNWNqSm5ZbVF2ZHpCMUwwdERPVFkxV1V0eWNqZDBaV2xhTlROck1sbGpPV1p0ZVVWS2N6VkVSa3M0Y1VSMWFXbDNiVE0xZEZkQ1EydzNNVXMyTHpWUVdYWmxVVGw2TTFOVWJtVnBWSHBSUjJscU56VnBZU3R2VmtOVk0yVk9SbkJRVkdkWVZ6ZHdOME50V1dwNGVYaEtVRlF3UkdOaFIyZ3pNVFZvYjJGTVNUZFZlRTFyVEdRM1JIQmFTMlV3ZEZwYWVrUjFVbkZXTm1JemJYVjZValp4Tld4dlEydFlaRzFwVTJ0U2RVa3JjelZTZEhWcFVWRkZjaTl3VlhCelNYQTRaRGR2U1VkdWJGZE5XWEp6WkRSV1FtWlZSMkZFTjBjeWVUVTRiMmRUTlVKbVVGUnRhVWhpT0RscFduQkpObHBFTW5ZeFkybExUVXMxWkRsV01XRndWR1I0ZGxjMU5ETTVielY2UkVaVGNHWjBWa2M1ZEV0RWJVWjFPRzFpVEV0VGFrOHdLelZLVWpNME1FNDVibmxTV1M5RFpFMXdUVmgyWXpoeWJpc3hNbWQ2V25FM1dWVnNhVVV2YUZOU2JHcHdiazFEUkRKcGR5dHpRVE5JTDJ4NWFVVk5jVzE2VlZWcVIxb3dWbGx3ZVdsRlJEaE1LM0ZRZW01NU5ucEpiMFUwTUdoa1VVTmlWbFZLYlVGR2ExVk9kR1IwVWpSa01WVTRiR3RRZVZOa1JWZGtXRTV4VTFGS2VEbEtlV2hGZUdwamNIZG9NVTVIZEd4bFNHNDViak5KY0Vab2FGTlJRVTV2WTFoaFpVTjNXakp1TWl0Q1dFaENWR05hV2k5bFkwZGhWVmRJVHl0UVpHcExRakJSY0RaSEsxUnBUSEkxZFhaTE1YbzFRelY2TjNwSWMyOVZTV3BvWlRoUUt6RnNaVkJIUlhKelZsbFJXWGxCVml0ellubHBUakpxZWpBNFBTSXNJbTFoWXlJNkltVTFZMkUyWkRNME1qVTNaalEzT1RFMk1UY3daVGd5WkRNek56UTRZMk0yTkRJM1pUZGtaVGMzWkRZeFlUY3dOamcyTkdVek1XTXdNR1kxWXpBMU5tVWlMQ0owWVdjaU9pSWlmUT09	1771346826
6HODByd2WwYbzvsTlLtRSeluI0Foe5xF76m3uWvn	\N	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJbmxZYkVwNlNGSnpjVWwzZGs1R1JYZEtVV1JSU0hjOVBTSXNJblpoYkhWbElqb2lNRmRyY0hoUk0ycFJTbmMyWVZCSGMzWllaMnhoWTFOV09FczROa2RNTkdsVEwwNU1iRXRVWTBsamJqSjJUREY2UkhOUlQzVkZVa1p2UW5ocFpYVkNWREpIZGxSTFNsTkxjMFp5TkVOWWRWaHFOMlVyVDJWclFpOUpiak0ySzJoc2FtNU1TbWRFZEZGRVdrODVkbEF3VlRCRVFrZzBaRVpaVVVwR1ZVVmxTamhIYjNwcFozWm5SM1oyV0ZGb05GSTNXa05EU2toeVVHSXljbmhJYVcxUE1raHdlV2hTV1ZWMlNubDZhemcyY0doQlYxb3pObTlSTURGdVdURjZNRGRtUjJFMGJYTk1aV3dyZVdadGNUTmhaRmw0VXpGblFuRnNibFJNWmtKWVJYWTBlV2R1U25OeE1rNVFRaTlMTDJwMVlVRnBkWEI1Y1ZkbWJYSm9kMDFXVTNoc1ZHcE9jR0ZwTkRkU2FXTlhlRFYyVldWTGMwOUhOV2RXUWs1dmIxWlBNMWRxWWxKR1RXMDNTRWRMVlhsVFdXODNhRXBDTW1KaWVVRlBTa0o0V2tJMVYwSkhaMWcwWjFGRWMyTlNWRmhuU20xTFdEZEZSMmhOVFRsRWJXeDVXRE0yTWxCWFdVeG5hVUYyYkhad1NESTRaa2wxUTFSaVJsbEZiM2xUWVRrdmVraHBNRGRFYUhWRVVrbHZaVUpCTkRsNU9FWldNa1VyTDNFMGMzVkxURXh1VUZoclQxVTBka1pHT1dwNGQxaGpRVGRxVWpObGVuVjVNWE5HUkZsVGVXMVlPRzV1UjBwUVlsTXJNRmN3UlZsa1UxazBOalp5VGxCSWMySlJaRGhOVFRsblJITjFaM0ZWYW5GRFZsQktlR3d2U0d4TlMwVkxSM296TlZwQ1FUQlFWVWM0VUVFMVoycHFaRWh3YldOd1kwWklRbTQ1YzB3eGJuZGxNMkYzUkRKS09GbHJhamxGV2lzd1ozVTRUV0ZaTUZjdlMwOHpjRVZWWXpWTVFWazBlRmsxVWxSQ0wxZDFXbkpFYXpKamRGazRjbkJLVEhsbldrVkVZekJyWmpOaVZFcDZNM1V3V0ZOSFJHOHdNMWQ0ZEZaVmVrZ3phMGN6YjJabllXOHhWMWN4TmtkNk1EUkpORkpOWVVSeFpGRjZlVWN6YURoUlVVOHlOM2xNYmtSSVkzbFJiR00zYUZsb2FrOXFOeTlyUzBRekwzQldSbXQ0Tm5wM05sVjZlWGhLUkZCWmNIUnRhbFJXUXpob1UzSmxhVlU0UWxCR00zcElPRkJQU0Zab1EyRmFXbEo0YzBSbWF6VjFZVnBYZEhwWmRUVkJVRTFXZEdKd0sycG9ZMmRKVnpCbWJVVXdSRm81VldObVdIbG5aVWR0UlZOTllYSkRkVU5KWml0WVlsWlBkbFJYTTJWSWVubGxRamRWUm1VMlJGRTRaM1JYUkRrd05uVlRabUpLVURrck1UQXdUVFpIVTJzMVpUUTRORGt2WVhoalprSXhhbkY0WjNwNWRuY3lTMGd3YXpnd1VHNU9aSFp0WWxreE5URTRRVXBUV0RWcUt6Tk5kMmRTWVhGaVVEbFBRVmhYVDFCWE1FNXNSVEp3U201VllVSmlUMjVIUmsxQ1NtWkxORU5OUVZJclJWVXJkVkZxWjJWNlUyTmlOakpYUzBwUE1uVnpWVk5GTVdoc1EweDBZbVJhWkdONmQyWjVOVmxvSzBGUFVXVlBXbGhuYjJ0UFFYSlNVMFJ1V0hWMlNWUlVVbHA1YXowaUxDSnRZV01pT2lJMU5XRXlNVFZtTVdZMFpqazNaVGRsWlRVeFltUXdNRE0yTWpJMk9HTXhORGRrTVRFMU5qVTVOemN5WVRFeE5ETmtOVGxrT1RObFlqSTBZMlU0T0RCbUlpd2lkR0ZuSWpvaUluMD0=	1771347607
ZMJaj7QTk5sBxHFvnnEv8M5QviPrP5XG5bmAc8D6	\N	127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/140.0.0.0 Safari/537.36	ZXlKcGRpSTZJazh2YmtoSmRGQjBNWFZwVTFWc2RFRnZSbmh2VGxFOVBTSXNJblpoYkhWbElqb2lSMDFFWVVkUWEydFdXR1ZuVFVsRGJVRkZNRUV6WjJwQlIwbDJURzk1V0ZCdVRFa3JlV2xZYzFkbk4yUkNOM2s0YVZKMmVsaExlRXd4VFRCd2VrdzVWMGRYVkhKSlNsTkRXa1kzTDFoTVdHOURkRUpKV0ZCVE1XZEVhRFJoUW1KTk9DOTRhVU0wVUhaYVRXTnlWV05ETDIxWmJIbG1ZemRhTUdwVlpVUkxTV1pzY25CT0swZEJiSE4wWlRCcFdFWm5XWEprYVM5RFNEVjJVR3N4VEhGVlpuZExWMkZZTUdrM2NXMUhUbTl1TDBsSmJHVlNPQzgzYlZObE1pOVlkREpTY0VKRVpISkJTMkUxYVRoSFpubExkMFV4TkhwNk0zbHNVekZVYXlzMlNqVjJVR3RZVURadFdERlRRM0J0T0hsbmExTlBkMUkyUkVjMVQyRjBaMll4YUhWR1ZHdEVibHBXU0d4RVNrVnZlVkZMTVd0R2RHbDZObGR6VjNOM1VYRTFjRWxCVDNoVlZqTnplWGxsTkRkRmFrcERlV05pYzBwWWJXWnZXSEEwVGxKSk5VTnRORFl2ZGl0MmVHcFhlVlV4TlRsUU9IZHRVVVp1UVVwRmNVUmlXamhuVm0xdlVuQkVSMkprYTJ3dkszZEZiV2RYUVVreVdUWkVhR2d6UjFORVZIRjJSaXRTVlRST1JFWkpZak00Y3paek1uVTBaMUoyVDJaUGEyWXllbUl2VFd4cU0yVlpRbk55YW1aRWRWcHZTWEZWWTBWbWFIVnJSRWxrWVVoaU5XNHJkbmgzY2tsdWQyRXlTUzlOVFhGNGMzSmxhR1YyZWpOMmEzcDBjMnM1VFdNclZIcFpPR1JKVGxkblRVNU1Tbkl5T0RGVU5tOTVlSFoyTlZKRFZtbzBkMHBXU0ZKSlZWRXdNVzFaWjFVNWMzRlNibGxIVkRGT1IweFFWR2gxU1ZwcFRIWk9ORUk1VDAxRUwxUlpOblpFWWpCa1NHc3ZWM2t5WWt4d1REbDJSMUkzTWtaSFNuZEtTMUZJWlVWa2IweExTbGRXTVd0dE1FdzFXR1J3V0dSbWNFRlBkV1kwUW1Gc2JWRmFXRUZPVEdOV1NubHdZVWhQVFRaWlFuWkpRMjlRUkhoc0wwRkdhVFkxY0VrNVV5dHFSalJDVVVwUE1uQnNhbk16ZVdkQ2JIRndjV0pvTkVacVQyczJjMmgwYm5KRVJERnhlbkptUTFsYWVuaGpibVpqWlZwWmFtMURSRkkwUkhSQksyaEZiSFJuU1cweVdHWlNNVE5hUTFCRmRYaFRRazl1TlVVeGMwVnZUVkZuVjBKc1VXaE9aM3BxVVhoVlEzQnBWMGw2VEdFd2NsSXlRaTgyTDBKaVlscEZSbEppVEU4MVdIRkRjRkZwVjFKaU5WSm5NRUptYTBWcU5raE5PRlJYZDBGU1RVOWpXWFJCUkRCeGJWazJNVFZLU2tZMVEyUlljbFpGVEVvMFFVMWtiRWhwY2tOclpucEdORXB4VkhGWVZXVlJZbFpRTUUxVlRVc3dka1ZEVlhJdk4zaG5WRWMyVTJseGFFTndTbVZwWmpRd1pUUnVSVFpWZEhKVGRqVkZjWFJKUlV0aVJuaEdlR0ZXWlhBNWFFRllka3M0VVhocVIzVlhXRzFZZDBWa2EzaHlSVE5WZVZsVlNGQmlha2hwT0N0V2VtcHRVR3BGUWtZNU9GWm9OVlEwWkdSRk9HRTVZVTFrT1dKQ1RYZHZPVEl4TkZGU05USnpSRUp2T0QwaUxDSnRZV01pT2lJeU9HVmpOVEppWldKa09UWTBPVGd4WldRMU5Ua3pNVE16T1RNellqWmxaV0k1WVRWaE5tUTJaVFEzWmpFME1UUmxObUZoWTJReE5tRTFOalZsT1RVMElpd2lkR0ZuSWpvaUluMD0=	1771349432
Cz40VuFcXHFscrugyaAJcpa4EtZMtNPxEtmck0ex	\N	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJbTExVUdvd1NXcGxTV0l4TUZaVE4wTkpOR2xCVm5jOVBTSXNJblpoYkhWbElqb2lkSEJ4UmpsMVFXZHZaVElyZWpkTmRVMDBRbTQwYjIxcE5tUjBVbVExVjFOTWRWWkhXbGhHVkRSRk0wc3pabk4xZVRKWVQwVXJRVEVyTkdzMVlYUkdaRWR6ZVd0WE0zWjBaVEo1YkRkRVRFWkJVQzlDWW0xdGNHOUROMUF2Y1ZkV2FHdFdZMDA1YmxBMldscDBWazUxWm5aTWJsbzBZa2hXZWxoYU5VVnhibUpTWjJKa1EwOWpXVEZLUTIwd2IxZHFSVnBOY2xWWlFub3dSVTV6VDFZNVNsaHRXR0pwY1haek1tb3lUVkJWZGxOT1J6ZzRORGhrYlV3eWIzcG9lVWRsYmtWcU1YTm9TR1I1T0RobmVIY3hMemhQYXpGcFZEUTFWMHBaY0ZCQ1ZtSTVjbmhaWm1wRE1YVlZkRmRKY2pWR2NXRlpPRTkzSzAxNVIzb3JhbHBSVUdaa1lrNXpVVk5JUjFKWVRubHFhM3AzYkhsbGVFNTVhVTlhV1V0NlNqSk9SRnBEY0UxRldrWklNMGRCVTI1dVJqUXdTRGRpVG1rdllVczBRbEFyU25kMlkzQjJSREY1YlRSMVZ6UklXVVZFVDJOWGMydDViR0YwWkhOR1luWnJNMmwwU2toNVJVNVJia1JYYWtaemJtNHljWEJMZWt0Mk1WazBkWE01WWs0NE1tbGxVbTh5YzA1NGIyOXdibGxoUTNvMWJHUnNabGQwUmxsQmJGZGhNemswV25OVVRrOUVRbU0xUVdKdmQyVTBZVlVyWlRWeFIybDNZMUZuTjNKRU5EaHRRa2R4VmxJM05WcDNSSFJGYW1oM2RHaE5TMGhpUWtaMFowODVZblZpY1VVclpqZG9OVGs0TTJoNVYzSnVVbXRMV0dOWU4ycEphV1p6TlhaT05EbDFWMWR2WnpGVVIzVlJVRWhWWmtaNVpFSm1NbU4yTDJKNk5rOXFlRTVMUVdSRU5XTk9OalkzWTA1S04yNDRVVTk2UjBGT1VIRk5kazkwTkZZek1WSkdOekEwTW5aWlFsRnVjRkJPVkN0MFlWZHdlVWsyTkdWek9EQlphQzgwYjFsUFJtZHhZbVJ5U25ObFdtZHJPVGRpYm05cmRXSkZlRTltVjBoc1MxRXhSV2ROS3pSNmEyaG9RM05VUTNac1IybHZjVU5OWWsxV1dtVkJOWEJQTm0xQlJqbDFjamgxVUdOdVJVMTJUSGxTZUhkWkt6aDBaelYzZGxacGRXdHRZMFV3UzFwbVlrMHhSMnhUTkZsTE56QlhSVU4xTDFwM2VtRm5NR3hZYzNSUldDdGlRVVJ0TkZobGRtNVBWSE5yU21JNFF5dDVXbmh3Vm5kUlJtWndiVzFITTNsVFowUTJZMGNyUTB0WWVYTnlURXhuVGpORE0wTTJUUzlRV0ZKWVIyeDJWVGhOUlcxT1JGSk5kbWhyTlV0Uk9HTnRhSGx2V2tOQlExSnlSMFpXWjNodVYzRXpSWFUzVWpjNGJuRmpjemgyZWpkUmJIWkdPR3R5V21KS2VqaG5kMGRKTTBGTGNVNXdTM0UxZHpSclZpOXNiM0ZQVTBNNE0yRlRkRnBPYTJwc1pVRkJOa2gxVjFKeFZGbGlPSFV3TURKcFdXWkVPQ3N3UTFReVoyWXdXVGw2VTBjeFdUYzVLMWRxUkRsbGNFeEdZMlpDWkV0blVUTnVXR3RTWWlzeWJVVlNjREIzZFdwcFNuWXlkVkpYYlV0dFZrMXdaekJ1Y0d3d1NEbE1jbWh5ZWpaWGNWSTFPRlZUVVQwaUxDSnRZV01pT2lKbU9USXpOamRsTXpBeU9ERXhZalV3TkRaalpqWmtaalV4TVdVeE4yUTJOVE01TVRJek1USTRNV1V3Tm1JeU9EVmxOV1UwWW1RMk1tRm1NR0UxTXpJMklpd2lkR0ZuSWpvaUluMD0=	1771350595
RL05wGS0BPJtbmng0yZe1GME6gs3hi0Nspxo7i9V	3aaa1fef-3e50-45cc-9b53-696835ce85c5	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJbHBqZFdrMGRWaEZTVmN6WkVORmNteGpiaXRrVWxFOVBTSXNJblpoYkhWbElqb2ljR1U1Tml0dmFXbHhXRXhrWlhGRFdXbHlZbGRtT0hJMFJXeFNlbVpDWkV3M1JXbEtjV2gyVDFVeE15OXBRamt3T0ZCalptZFBibGhGTTBGTmFXSXJWVXRyV1hod05EbG9iVXhpYzJSeFlVcE9NWFoxWm5NdlJrVlhlRnB2U210ek1sTnlNM1Z6WlhsRlJYcFFkVVV2YkZOWE9ETkhiVEIwU1RoeVEwZFFSMDVKYm1KRlJsUnBVRFF5U2xSQmNEaEhiWGM0UTFwRVRHbDFZa2M1VWpodmJtcENORXhsTjNGMVVFOXpaekUxZEZRMWRXNXNaVTFEYVUxVmNHaEJiR3BsYjB4Q01HbEVNbGRzTUVKVFYwTlVhMGhwYUVKWVVtTnNObEkzVG1OT1MxVlhaazg0UnpKNk9YWkRNMVJhVjFwelJrMXJUWGM1U2paV2NFNDBkbk5UWWpKSlMxSk9NVkFyYWtoNllrNURXalJZWlhWNWFETkxZbVV3TmxSdFRYQlJWRlpHWmpOVVVuVm5XRkZoVFhSUVlVTjJXVkI1YlUxb2NGSm5VVWRIYUZCQ1ZUSnRXazVzTUZKM2QxUmFkVE5qU1hOdlNqZEdhbTVCY0hOelQwbHNiVXBJWldwVlNFNXZXWEpwUmtoMFZtcE5UU3REYTA5a2RUWnJUeXR0VkRsa05YQnFSa3BhYW1zeWNEa3dla1l6Y1dRMFFsTnJOR2hTVFZBMFVsSm9aMEZQVVhCSk1rbDFXbTFxWmtsalZHNVlWSGhPWnpSYU5rTTRRVTlKUkVGM05rSnRiRWxQY21GRVVUUkdhRTh3VEdZM2VFOVViRU16WmsxSlYxTjZRazFEWW5ScEswbFFlbEZWUVVGaE5XVnlVbGQwYldGeEx6STNPV1I1WkdnemJFVkRjVzR2ZWpreGExWndXalkwVTJOV2NUWjJhMVJoU0RCT05VZG5jVEpaU1dONlIzRk5SMnBuY0daYWNWbHZXRVV5UlhSUVdFd3JTRGRQVGpoek9HRkZkWEJzVjBjMlpHdFRZVGRRT0dWaWEwaHNTbWQ1YTJOcmExQkRkVE5oZVUxUWJFcFVUakpoYkc1MUt6RkdhSGRETlZwcWVVMUplREU1ZFhObWVXMTZMMnhXZUdJMFJrWjBOME16ZVRKbE5HbHpOVTVMTm1sNFUwMTRkSEp0UmxSbFkxSnBkeTlFUVZGVWNHMDBPVWxDTDJOeFdHaFhjR2QzY1dNMFZEaG5NVmRpYUhkU2VraHdRbXRRYkVGcGIzRmtObUl5Y2s5MGQzWmhXVFUwUjB4MVJIQldaMEYyV1RFelF6RmhUVXRhUzNZd2JHRk1VVGxYZVd0NlUxQXJRMjVIV2pKUE1tbFZNRFpaZUZCNlkwSlRWM1V2ZVdWa1RFbHhhVEZNUjBSUFRGRm5hWFk0YTBScWJESnRVU3R4T1RrM1JtbEtRelY0Wmt0cE5rTk5RM295V1hsV1FYTktPVVJJTVVrd1JGaGtMMFZuVkZWRUt6WkdMMk5vUVdWM01YVlVSRTlJU210V1ZHVkhaM2RZY0hwbFJVTjVNWFZaVTJWMlJIQnVXRUZKT1dadllTOVBkRmRaTkdOSmVFbExabUlyU0ZaWmMybDNWMEZ1ZUhaMlMyWXJkMlo2WW01b1JFMHZOR1pDZWs1YVRHWTFiVFJCVm5CNGQyVnpSRlZoTkRBM05VRnJWbk5TWjNwWll6TkRUalF5VFU1UmVYcDRRVU5LVUdGS1ZUSmFUVFp3V2sxU1JUaEVWMmcwWWs5emFGaG9jR2xhYm5CbkwwMUNlV05hWmxBMlZHWlRaM0Z5VDJsMGVrOXFhbWxQUlc5S1RsVnpibWhNTnpkR2RITXdjM0ZsUkN0V05Xc3lTakI1UXpaSGRqTXdTek5MUzIweVJYYzRMekpJZUhreVFqbERaekI1TkZKVlNUaG1ORFZ5UW1aTlFsZzRVRGhDVVZoelYzTndjbWxoTXprdlVHcGpRMGM1UVZoVFNIZHdaVkZXWkRoa04yRlVjV1ZvVUhSVlNXbEdUVFYyYlhaUlFqRXpZbU0wYld4UFFVVkhVVlZYWmpsVWFWaFRjbHAyYUZFNE9FMUNRVkZTZEU5dmFsQXlZbTFYTW01cVNUVnBkRXRZTkdWelYyVjNNak5sVVN0TE9FdHpSMEV5YjFKREwweHNRVVpFVXpaU2JYQnFWa1ZOTVVoTGFHazNNRFYwUVdsWmVreGlWMlpsWnpSeGQzSm1XVmxHZG1nMWVHcHNTVE5SU25adGFGTnZlRTAwYWtSSloybFJWbFp0TkRsU1MwRldVMkowUVZreFJGUkpiM2g0UVhwb0wyYzNPSHBaV1ZKSFNXMHlOMUUyU25SQlpEVmpXV1pRTHk5M2RERmFXR2RCWkRCaWVtdGtOMDlzY1RCSmVWQnlRVGx0U1ZKbVVVbG9URUZKTUZwaWRFbHVhR3BvWm1GME5rdERTRlZhZW1kWmMzbE5WVVJKTWtsMlVIZGFNVlZ4YVVvMFkyWkRSWFpuVDBaelEwSlpOVVJQTWtaNmNHMVJkRk5MVW5wa1p6aFRaVUU5SWl3aWJXRmpJam9pT1dFM1pUVTJabUUwWVdRek1EaGpaalEwTnpGaE56VTBNamN3TnpCa09HRTBZV05tTldZME5qTmtOV0ZrT1RObU16azNORFZoWkRrNE9HTXdOVFUwTUNJc0luUmhaeUk2SWlKOQ==	1771346405
LVxAsxJWc3k4LXRob7bunRStXWJQ3gXJUj8Ye3mf	\N	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJazR5VTNFNWRGTmhiVU5NVTA5NFEwcHRhRmh2VVdjOVBTSXNJblpoYkhWbElqb2lhVlpHVDA1SFowTTFZMHRRTlhoNlFYaFFUSEJVUjNkak5YWjVTVkUyZUhJMUt6azRjbGhDWW5wU01UQTNWakZpTVVsTFNISm9hVzl0TVd0QldHWnhlR1JMSzJZd2JqQkpWbVYwZVVkSGVXRjBiV1ozUTNsUWVuSlNXbFZ2YWtGa1NEbEdSMVZMWnpob05qQklNR3cwZVhKS2MwZzBOMnRaUzJ0YWJXb3lNRTltVTJ0SU1UZ3llVWx2UW5oV1ZVZEVlR2Q2V0RRMGFscEJkbVZCZUROdmVHcFZOMFp3VERSd1IydHVjbXBuZHpVek5WSnRaRWxCVlZSRlFVUjFSRTE2YlhkcE1sTTROalFyUVd3NFVUWkdiamhhTVdwek5tMTBTbmQ2VDFWNGVYUlFOVkpGZW1SWldrdzNkejBpTENKdFlXTWlPaUkwWVRnMlpUWmhaV0kxWXpRNFlUWTFNelEyTnpZNFl6QmhORE13Tnprd1lXWmlNalF6TW1aa1pHUTRNR1EzWVdVd05XRTRPVEJrWTJObFlqazVOR1UySWl3aWRHRm5Jam9pSW4wPQ==	1771350367
tFvZ9lrGhQ13TDMlnHnm1QAp11IGbWIXaIF0TdAN	3aaa1fef-3e50-45cc-9b53-696835ce85c5	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJbEY2ZW1wWlIzUlVSMkoyVTFaV1MwMVhURWs0TUdjOVBTSXNJblpoYkhWbElqb2lVbFpaVkVWQ1UzbzNiVll2VFRaNFVuUjRjRXRVZG5CRFRUWTRWV1pLWW1WYVVXcExablpqZGtGemFqbE1ibFZKTHpCTVNIRlFMMnh0S3k5a2VHdHJjMDV6ZEhoSlRqSnNlblJET0ROcFIxZEZUVXRFTms5dlJrUnNWVWhWUW0xSlRXUXZiMnRXVERGUGVUUnFWRGN4U1ROek5HSjRWV1pTUlhJdlFYZHZTRzR3WVV4S2JVZFhUMFZMVUUxS1RWTmFRV1IwZFVGRGRYZDJiM0pGY0ROd01WWXllbE5hVldkNVVsUk1UWFZNWldnMVVEQXdaM001T1VOYVREVk1hV1pRYlRCcEwycFdUVWxHZDBsME5rSkxVVzRyUWtsYVlVdG1lVVoyTVdGSWVTOUhielk0V1N0YU5FZHZXR2N5TjBwalNYVlFOMHN6Y2pCNGRWRnpjR0UwTWtReGQzSjBObnA1WVdrdlptZHdlRlIxTkVSSFRtNXNVV1ZYYTFkUWVIUXhkWGhIYTI1U1pIWldhMkpQUjFKa2FWSkhTamR4UVVodWRrZ3plbkZ2ZUVOUGJYTlNlbHBhUm1FelFuZHdaRkJ3WVdSeVVHRjNUbUZQT1ZjMlFYVnFjalkzYmxWTFdGaFpWVkJ4TTAwdlZIcHBNa0oxYm05eWNFUnhUbFJEVDBrcmFFOVdXbVZyYUdaV1VtMWlaWFV2WTFoSksyeDFSMlp5ZWtaU2QwaFVTV2xqZWk5dVQxZ3hMMjFZU3l0aWJIcDBWMVpvUnpSeGJ6aFBURGR6Ymsxa1UxazNXbnBHU2xKVlJYTnlOWFZMYTJaSE5tNTVjbW8yTVdwaWRtdFRTRXd5YUZoUU4zTjZjRlpaSzNKSmVGWmhSVzQ0TUU4cldtMWplRVp0WlU1WFFVeEVVa1ZSYzFneGN5OHhhR05oYTJKM1UxQXpkbk5MU1hvMWVIQnpRVFoxVG5aamVHSnRXRXBTVjJzMVVsUjNaVEJVUWtKRGFIbEROMFZJVDNkSGFua3dTemxaZG5sVE9VeFNibkprYjFNNU5WWkJja3hUYTFCcU5URXJWbTAyWkZkQ1ZUTXpkMVp4ZW5oWUszWnFjbFkyWlhwT2FuaGxSbkE0Y0dNclkySkdZMXBJY2xOMFIycEtVblZGT0RWVVJsSnhTelpNTWpBd1ZHTjBNRlp0UzJSUVZrbGFiaTlNYjFVeGQxaGhNa2xMUlRocVdFSmFTVXRIU0RSMlFYTjJVSGx5Y0VOdlEwMUZNM1ZLVmxac05saDVTekE0TWtWUlZubEJSU3RyT1UxRU9VNUtlSHBXYVVOVFdFTnJMM1Z0T1RSdVJrOXdLMWhQYm5BemNXRkdVa1YzU0ZwRmEzRm5jbEpWZUhSeFUyd3pjRlo0ZG01WU5UTmxSME5xVm1oRVoxaHZibnBYWm5GTU9HbFFXRzFFTlhjdmNUTkpSbmd4Vm5KRE9XSktTakpCWW5SSlpETlVNVEl2VUVOWlMweFVTWFY2VXpoS1dYazJWV0pIYmt4QmMwWnNVbTlFSzFOUldsbElWMGRCVjBOMFMxbEZOR001VFZKR1FrTlNWSEpxUWtOUFEwOUdiVVJwYjJFd05qVkVSVE50TTFsT1RtTk1VR05YUW1wbVZVNDBlVzVITjJWYVlYZHBSV00xTkdwUGJuWjJOMHRTZDFWMVVGVlJka3RpZDJwME5VeGtjakJJVms5Vk5qSnNaM0pvTjNkWGFHWlFTa1ZDTlRKYVQzVkNjblJsWVRWMVZFUlVPRGQyVDNFd2NVOW1UbGxhVW1WNmFYSXlaRkpXV2xveU5ubGpiVTVqVURsQ1NsTmlVekJRY2t0V1YweExjaXMzYTJOc2NVMHlXWGxSYkhSUVRsY3ZNVXd2ZFRjdk1uRlZaakZGUVdJMFdYQXdkemxDUTFGVGVubHZjVTl1YTFGSlRVRXZlakp0VldGS1VXdGpkbEl4ZFRkdFVsQjJhMlZqYUZkQlEzVjFiMkZZYldwRU0yOW5aMDVtV0VrMVNucDJVVTB3YVRRdk5HMDVSbHBEU0cxaWVWUjVablpNZVc1NldqWnVka0pKUjFod2IwTnhiV3h3TDB4alIydEtlbk5QWjJkdmQyVTFTVlUwVTFGUEt6ZFVUbmhSYlhBNFpWTTNkQ0lzSW0xaFl5STZJbUU0WlRRelpqTmxOamhqTmpKaE4yWmpaV000T1dJeFptTTVPVFJtWVRoalpHRXpabVJoWXpreU0yUTVaRGxtWldSaE0yRTNNekU1TW1GaVl6QXpPVGdpTENKMFlXY2lPaUlpZlE9PQ==	1771350175
AWgdIItjiLrIJs87UF27fIKlzRwJuED2H05YlxW4	3aaa1fef-3e50-45cc-9b53-696835ce85c5	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJa3BCT1d0VGRHMUtOU3RvUlVwUmNFRlhObkZhZUdjOVBTSXNJblpoYkhWbElqb2lPVmxwVWtaUGMyVmpSWEZuYjFGeVNETnlWMFk0UWxCRldUQktWbFZ3WWtKc1lWaHRTMFptTkhwQlNVRldXblZoVjBGV2JsUmpPRGM0YUc1eFpXNVhPRlZ1TkZwMk9WZ3ZXVmROYWpGaFNYWnBja1U1YVhacFVtMTBjRk5yZUZOSk4wbHNORVZZYjBKMWRHZ3laamhhSzNGemRtRkZia2huYzFZMGJrbFZVWFY2Umt4dldEQmxiMlpLYURCU2JHOVhNRU5GSzNsR1dqQjRkVWxPUVhOaVdTdFpUbEZ3ZEU5b2NqWjBWbGRqTVd4dEx5OURVWG95T1VkVVFteEpiMGx5Wm05RFRrSnFVa3R0YUVOdE5rdE1ObXB2Y2twRWRsVlFXa0ZCVUVaamEwTlNTMFJ4Y0dwVU9YTnhNSFZYVGtSSU0zWlpXR3h5TDNkRVNYQjVWalZRVkZkaVMyRlpTVVpFVlRWdVowSmlkVGx2VVZSRGJuWnBlR0kxYUVSUVlubzFOVGR0ZG14R1dtZEpVbVZLUm05cGJTdDFNbXBuWTBoVlZWRmFNbXh1ZUhGRk1GbGliRTEyUkdVelEyWkJkbmszVGtjMWNWcHNWMkpYZEVvMVNWUkZlVlE0TlV4cGVYcEJOVTFITVhWNmVXeHphbGN5ZVVKRU1FVkVjM1ZPWnpoV1MyUnRjMWhYVVd0clluWnRVVTlTZUhCV0t6aEJlazFrU0dSWFNHODBXVUZuZFhSUVFrODBhR1ZGVjFOTmR6VndLMUpJYVZGVVltVnJiVGQyTkdjeFoyaGFNRlZpVmxaUGNVbzVSMU5HV1ZaaVVUVkVTak5MUm1sbUx5OTZTekJhZW5VNWRWZDJRM0pTTVhWT1YxTnJaRmxDVUdGT09GQmlUVzB2VUhRclQwcFVibFU0WmtNeVpIVnpRVVp3Um1WeVluZHpTa1JDTm01UFFsZFhkbEZwVjFoWFlqSTFOVzAxTDI1RVMxTnNlV3M1ZVhCdVpGUXlOVUZ4VlUxdmJYbElLM05yV21WV2JGZ3pUWGhKU1U5VUsxa3JaMm8zVW5GbE16ZGFPVWhoTm5OM2MxYzFRVGhJTlU0M1pDOXhaa2xNTkhOYU1FSlZWbWxIZUhKNE1GQnRRVVZKUTBOQ1lsWXlVMmxCV25CUlVuRjBOV012WW1JeVRHNUlSMnBrWlUxdmR6SlJSMkpJWkdKclRXcHlUVzlYTkZkRlRFNWFjVnBUU0ZOemRGcHhUemxQUWsxSmEyNDVTV2xKTlU0elpHOHJkR3A1TTBsNFZEY3Jia3AzYmxSeWFWaDFPRk40YVM5bFJ6bDZWMlZCY2pSdlpFdHdNVGRYTW5WTGFFVllNRlpHWTNJeVdqRjBTRk4xZFRkSlQwcExTME5oYldkMmFrOWxhRlZMV25sdFdrRkRabU5FYkdSWU1XeDBUVFpLZVV4V01XeElWM0Y1TDFBM2JGazNiRTV3U0RjMlNHWkhUbXMwVDJwYVMxVTJMelJKU2l0b05reHVjM2hSYkRkQ2FFNTBNazUwVTBoRlZtVjJWamw0ZHpacFRXMXlTMUJqYm1GRlIydHlSMkZtYVhORmVHbDJOazFEV1cxRlIwNVJUMmQyU0V0cmRIbDRWeXRxVkhwaGJ6QklhRVp2VFRKMVNXZG9SbGxvTVhSeGRHbEJLMmxpUlZkaU4wODNPRmxDY0U0eldHNDNkWE5ZUjJwV1RFSjFhRXhGY0ZZMU1sTm9RV0ZXVFU5TFFqZEhkMWhoZGl0MU1sSnJiRUptWlM5b09UaEtRMjV0VG5GWVdHTkVRVFprV2tZclRsQjRWelJ3V0ZBMllYcGpkRmhxU25NMWMwbzNTazB2ZGpSeVJIWTBTV1pxUTBSVVExRm9ValoxVW10MVdYTkNVbWRwVUZGWWQzTndWMm80V1RjelFqZFZieXN5Y1dKTmRTdHVNRGRhZFVaS05qaHBaalpWYjFacVZGbFFhWFZLWmpCaEswZDRTR1U1YUdGWlBTSXNJbTFoWXlJNkltWTJPR0l3WkRCa01EWmpZVGN4WWpkalpHVXpNalF6WWpJME5XRXpPRGhpTmpkaE5HSmpPRGxpTW1Rell6RXpZV05qTlRZMFpHRXlPR1prTW1KbFkyTWlMQ0owWVdjaU9pSWlmUT09	1771345925
ISeyVHO4uoliQCLR1FpPO2NHKOU4YK4CuTyN6MGO	\N	172.31.110.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	ZXlKcGRpSTZJakZxV2s1SVJrb3ZkV0pCUjFOME5HWlJjRFpSZVhjOVBTSXNJblpoYkhWbElqb2llR0ZoU201dk9USmFXVVUxYlhOTVprdDJURzR4YW5KWFpXdHZjSFV3U0VKSUx6Y3pNRWhuVEVwSk1tTnBZa013TDNOU1RERlFZVk5UYXpCME9VeENZblEwYTBvM2JVa3hVRGxuYkVWVlowcGxWSEZDY1VaTmVDODRWRUp4U2pCWlpIZEZhamRXZVRKaGNUUjJWR2hoWWxsdVdIWlBWbkJhWmtsb1JGZG9abGRFYnpSSVRsTXZaMDVrUzJOeVNsUXlTVVZVU1RWQllYZFlTaTlyYVRVMVMzbFhPRVJ5V1dSNFNXbEVlRWQwVjNkdU1uTnBUemsyVlcxNU5qSXJXVFp4UzJSMVRtNUlUbGxLUkZVNU0xTTRXbFpDVWtGWWFXNVNhbTA1TWxJMlpEUTFaMnhWVUdSd1ZFSnhZMGhYTjBKR2NqVjBPR0U1VW5oVlJHTlRkMEZHYmpOek9EZEdhVFV2ZWt0amVWQklTVnBoTm1OcVkxcFhVMVl2YWk5S1ZETXZTMlp5UTFGQk4xWk9XbkVyV0dkVFlUQm1kR1JMZDNsSlJ6UlZabXBFVmpSdk56VkZibXAyV0ZkV1IzWmthRzQyZVdWcFQybFdZVXhqVlhoSVEwMXFhRXBuV1VKTFJHWk9VWFlyYWtOc1dXRlZhMHBGVW1FM1JraHBUVWh1UzA1QmIxRjRURmxRZWpkVWFFbEtURzU1T0RWMWF6RTVkRmh3UnpnclRGUnhSelExTTFZdk5UQjVNMGxxVDBGV1pWSmlXbE5yYmtSelkyNUxaM1pNU1d0eGRWWmlZMmhQTDBreWJFWTFOVEZYWldWUFRsaDRZMnczUkN0V09HTXdaVTlyWm5Jdk9ITlhkR0V5SzA5cFJUbERUMmRHTDBsaGJVRlVTbTVRTm5SUGRsbFZZbWRQT1dkTE9HNHhOa2RVU0VsNWMxZFBNa1pLWnpWMFFsSkZNWGRHUVhWWmVGTnZiRWxaYzBsU1pubDJlbEZqVFdFeE5sWXhZVk4yVGpCVFRsRnNZMUZpTDNsVFdHeFRLMFJWUTB0cGVDdGFSMEpKVWpkdE5sRnBOSEpLVW5SMVUwbzBlVTFrSzBkbE5Vd3lTM0pPYURsc1pUa3pZbTFWY0hrMlZuY3pNV2RSU2xVM1JHaHJLMjV1YjNSQ1VUWldVR2RvVnpSRVYxZEZSbUY2TkRoSk0xaEdRM0J2TW1KTVZHNTJNVGRPVEV0c1JXdHRaamxNV1hOMFIyTTNjRmMxZFZsdFIzcExPRVJxYm5GYVpVMUhabFpKY1VKQlptMTBkSHA1ZFhCa1VUUjZkblZzUVd0eU1VSkRiMEZOVjNsRGEwOUJWR2hQTTJzMVMyY3hibkZOZWtwdU4yWldWRGRPUkhGTU1UQkRkamx6VEdoRFYyZ3dOSGt5WkRKRFprNDBWV3htZEVwVVpVaFBPR1JyVkdJemRucE1SMjFuV0VaSVUxSm9WMWROZFRWUmMzRnpZMVpZYTJKc2RsVnhXR1pMUmxGb2VGbFFaRWh0Y2s1dVpFWXdkeTlDVm1sSlRqYzRNRTAwTDBsR2NETXJkREozYUhKclowTktkR3A0TDI0emRWaHlPR0ZzUTA5MU1GaENjVFJzUkU5WksyWlZURnBrY0VWVUwwTkRWRVprU1Rab1RHSnZjMWhSWkVkNk5rdzBhazB3YzBSWWJWbGFhVmwyYlc1SVZXUXJPR0UyVjFnMmNDOXNXblIwTnpsQ2JUQlFkbVF5ZWxoMmIwSmpTVTVZY0VOdVQwZFFZbmQxU1QwaUxDSnRZV01pT2lKa1ptTTJPREEzWTJaa1kyWTVPV0kwTjJNMllqWTVabVEwTWpWall6ZGlaV1EzWVRrMk0yUmtZelprWkRWalkyVXpaVGd3T1RGaU0yWmtOR0pqTlRNeUlpd2lkR0ZuSWpvaUluMD0=	1771349491
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.settings (id, key_name, live_values, test_values, settings_type, mode, is_active, created_at, updated_at, additional_data) FROM stdin;
d9728939-d3a7-46cc-a022-119506175333	stripe	{"gateway":"stripe","mode":"test","status":"0","api_key":"","published_key":""}	{"gateway":"stripe","mode":"test","status":"0","api_key":"","published_key":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"Stripe","gateway_image":""}
b40f220f-f04b-4ba6-9895-f4df4382991d	paypal	{"gateway":"paypal","mode":"test","status":"0","client_id":"","client_secret":""}	{"gateway":"paypal","mode":"test","status":"0","client_id":"","client_secret":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"PayPal","gateway_image":""}
86cb1f4d-149d-4dc9-8b3f-f0a36afdb4af	ssl_commerz	{"gateway":"ssl_commerz","mode":"test","status":"0","store_id":"","store_password":""}	{"gateway":"ssl_commerz","mode":"test","status":"0","store_id":"","store_password":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"SSLCommerz","gateway_image":""}
9db05567-78b4-429f-9d73-0f20626e335e	flutterwave	{"gateway":"flutterwave","mode":"test","status":"0","secret_key":"","public_key":"","hash":""}	{"gateway":"flutterwave","mode":"test","status":"0","secret_key":"","public_key":"","hash":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"Flutterwave","gateway_image":""}
f7536bec-fc5b-4e07-ac97-0d102a170c11	paystack	{"gateway":"paystack","mode":"test","status":"0","public_key":"","secret_key":"","merchant_email":""}	{"gateway":"paystack","mode":"test","status":"0","public_key":"","secret_key":"","merchant_email":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"Paystack","gateway_image":""}
9e0867cb-537d-48dc-a85c-8dddbf59aa5a	mercadopago	{"gateway":"mercadopago","mode":"test","status":"0","access_token":"","public_key":""}	{"gateway":"mercadopago","mode":"test","status":"0","access_token":"","public_key":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"MercadoPago","gateway_image":""}
92bf6e33-eb27-49d7-b75a-9a98051254f8	paytm	{"gateway":"paytm","mode":"test","status":"0","merchant_key":"","merchant_id":"","merchant_website_link":""}	{"gateway":"paytm","mode":"test","status":"0","merchant_key":"","merchant_id":"","merchant_website_link":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"Paytm","gateway_image":""}
361956a4-8110-4588-91ad-12b6d09854c7	senang_pay	{"gateway":"senang_pay","mode":"test","status":"0","secret_key":"","merchant_id":""}	{"gateway":"senang_pay","mode":"test","status":"0","secret_key":"","merchant_id":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"SenangPay","gateway_image":""}
f029ad1b-894b-4f24-b5da-f00b09ba34dd	paymob_accept	{"gateway":"paymob_accept","mode":"test","status":"0","callback_url":"","api_key":"","iframe_id":"","integration_id":"","hmac":""}	{"gateway":"paymob_accept","mode":"test","status":"0","callback_url":"","api_key":"","iframe_id":"","integration_id":"","hmac":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"Paymob","gateway_image":""}
6ed7e20e-2263-4874-a61e-6e2a41b9da4e	liqpay	{"gateway":"liqpay","mode":"test","status":"0","private_key":"","public_key":""}	{"gateway":"liqpay","mode":"test","status":"0","private_key":"","public_key":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"LiqPay","gateway_image":""}
243e1683-0ce4-4b2c-b1ea-9ca18895c7c2	paytabs	{"gateway":"paytabs","mode":"test","status":"0","profile_id":"","server_key":"","base_url":"","supported_country":"egypt"}	{"gateway":"paytabs","mode":"test","status":"0","profile_id":"","server_key":"","base_url":"","supported_country":"egypt"}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"PayTabs","gateway_image":""}
b90d4b1d-96fe-42a2-9f38-c42bb1dcc1bf	bkash	{"gateway":"bkash","mode":"live","status":"0","app_key":"","app_secret":"","username":"","password":""}	{"gateway":"bkash","mode":"test","status":"0","app_key":"","app_secret":"","username":"","password":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"bKash","gateway_image":""}
cfc1a002-99d9-4cd1-8b40-a7331250595a	pvit	{"gateway":"pvit","mode":"live","status":"0","mc_account":"","merchant_key":"","mc_tel_merchant":"","access_token":"","mc_merchant_code":""}	{"gateway":"pvit","mode":"test","status":"0","mc_account":"","merchant_key":"","mc_tel_merchant":"","access_token":"","mc_merchant_code":""}	payment_config	test	f	2026-02-14 05:51:42.934053	2026-02-14 05:51:42.934053	{"gateway_title":"Pvit","gateway_image":""}
88691a29-553a-4f95-be48-e76fd8d18839	razor_pay	{"gateway":"razor_pay","mode":"live","gateway_title":"Razorpay","status":"1","api_key":"rzp_live_RgM7ylDDU7moQj","api_secret":"NoLQoxlCg8SPnKHSX0ciIDjJ"}	{"gateway":"razor_pay","mode":"live","gateway_title":"Razorpay","status":"1","api_key":"rzp_live_RgM7ylDDU7moQj","api_secret":"NoLQoxlCg8SPnKHSX0ciIDjJ"}	payment_config	live	t	2026-02-14 05:51:42.934053	2026-02-15 12:51:33	{"gateway_title":"Razorpay","gateway_image":""}
7c5eae31-42a2-4888-b20b-dfde191be5c4	twilio	{"gateway":"twilio","mode":"live","status":"0","sid":"","token":"","messaging_service_sid":"","from":"","otp_template":"Your JAGO verification code is #OTP#"}	{"gateway":"twilio","mode":"test","status":"0","sid":"","token":"","messaging_service_sid":"","from":"","otp_template":"Your JAGO verification code is #OTP#"}	sms_config	live	f	2026-02-15 13:15:51.030585	2026-02-15 13:15:51.030585	\N
89a8aace-8c79-4a1b-9529-50ac5f033eb7	nexmo	{"gateway":"nexmo","mode":"live","status":"0","api_key":"","api_secret":"","from":"JAGO","otp_template":"Your JAGO verification code is #OTP#"}	{"gateway":"nexmo","mode":"test","status":"0","api_key":"","api_secret":"","from":"JAGO","otp_template":"Your JAGO verification code is #OTP#"}	sms_config	live	f	2026-02-15 13:15:51.030585	2026-02-15 13:15:51.030585	\N
21d1c216-891a-4bcd-ae79-33f4c68ab18b	2factor	{"gateway":"2factor","mode":"live","status":"0","api_key":"","otp_template":"Your JAGO verification code is #OTP#"}	{"gateway":"2factor","mode":"test","status":"0","api_key":"","otp_template":"Your JAGO verification code is #OTP#"}	sms_config	live	f	2026-02-15 13:15:51.030585	2026-02-15 13:15:51.030585	\N
a2e67df7-08fb-4754-ab6d-f86394633aae	msg91	{"gateway":"msg91","mode":"live","status":"0","auth_key":"","template_id":"","sender_id":"JAGO","otp_template":"Your JAGO verification code is #OTP#"}	{"gateway":"msg91","mode":"test","status":"0","auth_key":"","template_id":"","sender_id":"JAGO","otp_template":"Your JAGO verification code is #OTP#"}	sms_config	live	f	2026-02-15 13:15:51.030585	2026-02-15 13:15:51.030585	\N
b49bd359-ca2b-4213-afaa-a603a5badfe8	releans	{"gateway":"releans","mode":"live","status":"0","api_key":"","from":"JAGO","otp_template":"Your JAGO verification code is #OTP#"}	{"gateway":"releans","mode":"test","status":"0","api_key":"","from":"JAGO","otp_template":"Your JAGO verification code is #OTP#"}	sms_config	live	f	2026-02-15 13:15:51.030585	2026-02-15 13:15:51.030585	\N
\.


--
-- Data for Name: shared_trip_passengers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shared_trip_passengers (id, trip_request_id, shared_group_id, user_id, seats_booked, otp, otp_verified, is_picked_up, is_dropped_off, pickup_lat, pickup_lng, pickup_address, drop_lat, drop_lng, drop_address, fare_amount, status, created_at, updated_at, distance_km, picked_up_at, dropped_off_at, cancelled_at, sharing_type) FROM stdin;
\.


--
-- Data for Name: sharing_fare_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sharing_fare_profiles (id, zone_id, vehicle_category_id, sharing_type, base_fare_per_seat, per_km_fare_per_seat, discount_percent, commission_percent, gst_percent, min_fare_per_seat, max_detour_km, min_distance_km, max_distance_km, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: social_links; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.social_links (id, name, link, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: spin_wheel_configs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.spin_wheel_configs (id, is_active, title, subtitle, min_discount, max_discount, spins_per_day, segments, segment_colors, created_at, updated_at, max_total_per_user, ride_completion_required) FROM stdin;
e4550157-42a9-4b9e-858f-ff60e892d2a6	t	Spin & Win!	Spin the wheel to win wallet rewards!	5	10	2	[5,10,15,20,50,100]	["#2563EB","#16A34A","#DC2626","#D97706","#7C3AED","#0891B2"]	2026-02-13 17:46:09	2026-02-17 09:50:35	500.00	t
\.


--
-- Data for Name: spin_wheel_results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.spin_wheel_results (id, user_id, trip_request_id, discount_value, created_at, updated_at, wallet_amount, transaction_id) FROM stdin;
\.


--
-- Data for Name: spin_wheel_segments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.spin_wheel_segments (id, spin_wheel_config_id, label, amount, color, weight, is_active, sort_order, created_at, updated_at) FROM stdin;
76d04e6e-3df7-40f6-ae8c-575e339de8d0	e4550157-42a9-4b9e-858f-ff60e892d2a6	₹5	5.00	#2563EB	30	t	1	2026-02-17 08:58:12	2026-02-17 08:58:12
3d3f0a36-2453-4b78-aa8e-822d582bb5fd	e4550157-42a9-4b9e-858f-ff60e892d2a6	₹10	10.00	#16A34A	25	t	2	2026-02-17 08:58:12	2026-02-17 08:58:12
847c6e6b-9c72-4aa5-b434-ec2a53b9dd53	e4550157-42a9-4b9e-858f-ff60e892d2a6	₹15	15.00	#DC2626	20	t	3	2026-02-17 08:58:12	2026-02-17 08:58:12
68f56de4-506b-47ce-bd9d-a6e9cccd5578	e4550157-42a9-4b9e-858f-ff60e892d2a6	₹20	20.00	#D97706	15	t	4	2026-02-17 08:58:12	2026-02-17 08:58:12
9936060f-f01a-40a1-bf1d-8baae38d0038	e4550157-42a9-4b9e-858f-ff60e892d2a6	₹50	50.00	#7C3AED	7	t	5	2026-02-17 08:58:12	2026-02-17 08:58:12
1b24398c-a197-4763-aed0-250bfda57898	e4550157-42a9-4b9e-858f-ff60e892d2a6	₹100	100.00	#0891B2	3	t	6	2026-02-17 08:58:12	2026-02-17 08:58:12
\.


--
-- Data for Name: subscription_plans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.subscription_plans (id, name, description, duration_type, duration_days, price, max_rides, is_active, created_at, updated_at) FROM stdin;
80b0d68e-7542-483c-910d-f2babb0693ea	Daily Plan	Best for part-time pilots - 15 rides per day	daily	1	49.00	15	t	2026-02-17 17:43:46	2026-02-17 17:43:46
9403d464-e67d-449e-930b-73efe055bab5	Weekly Plan	Popular plan for regular pilots - 100 rides per week	weekly	7	299.00	100	t	2026-02-17 17:43:46	2026-02-17 17:43:46
992e7512-7c29-48da-91c5-5909a4d058cb	Monthly Plan	Best value for full-time pilots - unlimited rides	monthly	30	999.00	9999	t	2026-02-17 17:43:46	2026-02-17 17:43:46
\.


--
-- Data for Name: support_saved_replies; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.support_saved_replies (id, topic, answer, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: surge_pricing; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.surge_pricing (id, readable_id, name, surge_pricing_for, increase_for_all_vehicles, all_vehicle_surge_percent, increase_for_all_parcels, all_parcel_surge_percent, zone_setup_type, schedule, is_active, customer_note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: surge_pricing_service_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.surge_pricing_service_categories (id, surge_pricing_id, service_category_type, service_category_id, surge_multiplier, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: surge_pricing_time_slots; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.surge_pricing_time_slots (id, surge_pricing_id, start_date, end_date, selected_days, slots, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: surge_pricing_zones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.surge_pricing_zones (surge_pricing_id, zone_id) FROM stdin;
\.


--
-- Data for Name: temp_trip_notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.temp_trip_notifications (id, trip_request_id, user_id) FROM stdin;
\.


--
-- Data for Name: time_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.time_logs (id, time_track_id, online_at, offline_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: time_tracks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.time_tracks (id, user_id, date, total_online, total_offline, total_idle, total_driving, last_ride_started_at, last_ride_completed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transactions (id, readable_id, attribute_id, attribute, debit, credit, balance, added_bonus, user_id, account, transaction_type, reference, trx_ref_id, trx_type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: trip_fares; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.trip_fares (id, zone_wise_default_trip_fare_id, zone_id, vehicle_category_id, base_fare, base_fare_per_km, waiting_fee_per_min, cancellation_fee_percent, min_cancellation_fee, idle_fee_per_min, trip_delay_fee_per_min, penalty_fee_for_cancel, fee_add_to_next, created_at, updated_at, pickup_charge_per_km, pickup_free_distance, shared_discount_percent) FROM stdin;
ccef1962-a15f-4f34-bb55-4f1a759b0c8f	eb058536-5c8d-434a-a4e2-e43200f8cc04	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	ee9b9b13-d870-44ef-9d46-ab3add413de5	25.00	10.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	2026-02-14 17:15:43.557774	2026-02-14 17:15:43.557774	5.00	0.50	0.00
9bceb9ae-9f7a-4c54-992d-91cfe5e74535	eb058536-5c8d-434a-a4e2-e43200f8cc04	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	f1e3ceb1-d0ca-4ec3-9f11-fab251e7cc29	15.00	8.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	2026-02-14 17:15:43.557774	2026-02-14 17:15:43.557774	3.00	0.50	0.00
66a752a1-287a-4bb7-b15d-236aa3d1c58a	eb058536-5c8d-434a-a4e2-e43200f8cc04	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	fdbc096e-aab1-4c7a-bf87-6db00a21e6d5	50.00	15.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	2026-02-14 17:15:43.557774	2026-02-14 17:15:43.557774	8.00	0.50	0.00
49459662-c6f5-4e75-b7a5-5a0f878d63e6	eb058536-5c8d-434a-a4e2-e43200f8cc04	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	0ee1d32c-6044-4d52-bc56-6607e7fa239a	40.00	12.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	2026-02-14 17:15:43.557774	2026-02-14 17:15:43.557774	6.00	0.50	30.00
\.


--
-- Data for Name: trip_request_coordinates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.trip_request_coordinates (id, trip_request_id, pickup_coordinates, pickup_address, destination_coordinates, is_reached_destination, destination_address, intermediate_coordinates, int_coordinate_1, is_reached_1, int_coordinate_2, is_reached_2, intermediate_addresses, start_coordinates, drop_coordinates, driver_accept_coordinates, customer_request_coordinates, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: trip_request_fees; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.trip_request_fees (id, trip_request_id, cancellation_fee, return_fee, cancelled_by, waiting_fee, waited_by, idle_fee, delay_fee, delayed_by, vat_tax, tips, admin_commission, created_at, updated_at, pickup_charge, cancellation_fee_admin_share, cancellation_fee_driver_share, special_discount_amount, special_discount_type) FROM stdin;
\.


--
-- Data for Name: trip_request_times; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.trip_request_times (id, trip_request_id, estimated_time, actual_time, waiting_time, delay_time, idle_timestamp, idle_time, driver_arrival_time, driver_arrival_timestamp, driver_arrives_at, customer_arrives_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: trip_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.trip_requests (id, ref_id, customer_id, driver_id, vehicle_category_id, vehicle_id, zone_id, area_id, estimated_fare, actual_fare, estimated_distance, paid_fare, return_fee, cancellation_fee, extra_fare_fee, extra_fare_amount, surge_percentage, return_time, due_amount, actual_distance, encoded_polyline, accepted_by, payment_method, payment_status, coupon_id, coupon_amount, discount_id, discount_amount, note, entrance, otp, rise_request_count, type, ride_request_type, scheduled_at, current_status, is_notification_sent, sending_notification_at, checked, tips, deleted_at, created_at, updated_at, is_paused, map_screenshot, trip_cancellation_reason, ride_mode, seats_requested, shared_group_id, receiver_otp, helper_required, helper_fee, time_based_fare, estimated_time_minutes, sharing_type) FROM stdin;
\.


--
-- Data for Name: trip_routes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.trip_routes (id, trip_request_id, coordinates, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: trip_status; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.trip_status (id, trip_request_id, customer_id, driver_id, pending, accepted, out_for_pickup, picked_up, ongoing, completed, cancelled, failed, note, created_at, updated_at, "returning", returned) FROM stdin;
\.


--
-- Data for Name: user_accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_accounts (id, user_id, payable_balance, receivable_balance, received_balance, pending_balance, wallet_balance, total_withdrawn, referral_earn, created_at, updated_at) FROM stdin;
bf4183f5-6ee8-4bc0-a713-602afd2d4d63	3aaa1fef-3e50-45cc-9b53-696835ce85c5	0.00	0.00	0.00	0.00	0.00	0.00	0	2026-02-13 11:51:31	2026-02-13 11:51:31
15f0c4ee-5383-4f90-8235-5da8fcb501f9	30ba60f2-6cbc-4d48-8e06-7064fc919075	0.00	0.00	0.00	0.00	0.00	0.00	0	2026-02-14 18:26:15	2026-02-14 18:26:15
0bf7a710-8071-4ca0-a61b-95dc313bc9eb	879a7709-2451-4f6e-969f-5250b3991ccb	0.00	0.00	0.00	0.00	0.00	0.00	0	2026-02-14 18:27:17	2026-02-14 18:27:17
86318fb5-c4a1-4c64-a82a-709658e85ee0	00757917-1231-423e-aa60-c0e956f0ef0a	0.00	0.00	0.00	0.00	0.00	0.00	0	2026-02-14 18:30:48	2026-02-14 18:30:48
9207cc30-083d-4a8e-a595-b0abd2429112	8de7e4bf-0483-4a72-895b-bcf79594bfd2	0.00	0.00	0.00	0.00	500.00	0.00	0	2026-02-16 15:22:09	2026-02-16 15:22:09
d51f80d3-9b86-4547-a797-f6cf7be4b86a	1b81af34-c972-49df-b816-ca2e925e9b9b	0.00	0.00	0.00	0.00	1000.00	0.00	0	2026-02-16 15:22:09	2026-02-16 15:22:09
d4d3ba9f-6985-48d8-9e27-784e0800573f	b8dd794f-b7de-4bab-b53d-43d06dd45e52	0.00	0.00	0.00	0.00	1000.00	0.00	0	2026-02-16 15:23:24	2026-02-16 15:23:24
f1811c28-e85e-4a91-a75b-1826c53cd105	62e81720-2260-4b67-bf44-fa8c558a116f	0.00	0.00	0.00	0.00	1000.00	0.00	0	2026-02-16 15:23:24	2026-02-16 15:23:24
\.


--
-- Data for Name: user_address; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_address (id, user_id, zone_id, latitude, longitude, city, street, house, zip_code, country, contact_person_name, contact_person_phone, address, address_label, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_last_locations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_last_locations (id, user_id, type, latitude, longitude, zone_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_level_histories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_level_histories (id, user_level_id, user_id, user_type, completed_ride, ride_reward_status, total_amount, amount_reward_status, cancellation_rate, cancellation_reward_status, reviews, reviews_reward_status, is_level_reward_granted, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_levels; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_levels (id, sequence, name, reward_type, reward_amount, image, targeted_ride, targeted_ride_point, targeted_amount, targeted_amount_point, targeted_cancel, targeted_cancel_point, targeted_review, targeted_review_point, user_type, is_active, deleted_at, created_at, updated_at) FROM stdin;
ec6e6001-c7e8-42a9-ad2f-d7b5c9c5a001	1	Level 1	no_reward	0.00	\N	0	0	0	0	0	0	0	0	customer	t	\N	2026-02-13 11:50:55.987361	2026-02-13 11:50:55.987361
1178d9c2-fd60-4c83-aeee-90ebaa4e555b	1	Level 1	no_reward	0.00	\N	0	0	0	0	0	0	0	0	driver	t	\N	2026-02-14 18:30:39.60486	2026-02-14 18:30:39.60486
\.


--
-- Data for Name: user_withdraw_method_infos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_withdraw_method_infos (id, method_name, user_id, withdraw_method_id, method_info, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, full_name, user_level_id, first_name, last_name, email, phone, identification_number, identification_type, identification_image, old_identification_image, other_documents, profile_image, fcm_token, phone_verified_at, email_verified_at, loyalty_points, password, ref_code, user_type, role_id, remember_token, is_active, current_language_key, deleted_at, created_at, updated_at, failed_attempt, is_temp_blocked, blocked_at, date_of_birth, is_senior_citizen, is_student, student_id, corporate_account_id, employee_id, user_category) FROM stdin;
30ba60f2-6cbc-4d48-8e06-7064fc919075	Test User	ec6e6001-c7e8-42a9-ad2f-d7b5c9c5a001	Test	User	testuser@jago.com	+919876543210	\N	\N	[]	\N	\N	\N	\N	\N	\N	0	$2y$10$X2HbicAGTc1NwmIh3PBI1OfSduE8KFpP.zYxfRpRRZkdBC2K5EQjK	BDOIDFNLXW	customer	\N	\N	t	en	\N	2026-02-14 18:26:15	2026-02-14 18:26:15	0	f	\N	\N	f	f	\N	\N	\N	regular
1b81af34-c972-49df-b816-ca2e925e9b9b	Suresh Bike Pilot	\N	Suresh	Reddy	suresh.bike@jago.com	+919900002222	\N	\N	\N	\N	\N	\N	\N	2026-02-16 15:22:09	2026-02-16 15:22:09	0	$2y$10$MglPoBf8ybRbHzcJ34ThJ.xinz9fEZIiM76A8QSl7/kHAMwAJs5J6	BIKE4045	driver	\N	\N	t	en	\N	2026-02-16 15:22:09	2026-02-16 15:44:56	0	f	\N	\N	f	f	\N	\N	\N	regular
b8dd794f-b7de-4bab-b53d-43d06dd45e52	Ramesh Auto Pilot	\N	Ramesh	Yadav	ramesh.auto@jago.com	+919900003333	\N	\N	\N	\N	\N	\N	\N	2026-02-16 15:23:24	2026-02-16 15:23:24	0	$2y$10$XBKaQk2PeYlIGhTfkrNRgOaUhfmKMZE6YrYa2geo5dAl4aX.Hffj2	AUTO4885	driver	\N	\N	t	en	\N	2026-02-16 15:23:24	2026-02-16 15:44:57	0	f	\N	\N	f	f	\N	\N	\N	regular
62e81720-2260-4b67-bf44-fa8c558a116f	Venkat Car Pilot	\N	Venkat	Sharma	venkat.car@jago.com	+919900004444	\N	\N	\N	\N	\N	\N	\N	2026-02-16 15:23:24	2026-02-16 15:23:24	0	$2y$10$XBKaQk2PeYlIGhTfkrNRgOaUhfmKMZE6YrYa2geo5dAl4aX.Hffj2	CAR7200	driver	\N	\N	t	en	\N	2026-02-16 15:23:24	2026-02-16 15:44:57	0	f	\N	\N	f	f	\N	\N	\N	regular
8de7e4bf-0483-4a72-895b-bcf79594bfd2	Ravi Kumar	\N	Ravi	Kumar	ravi@jago.com	+919900001111	\N	\N	\N	\N	\N	\N	\N	2026-02-16 15:22:09	2026-02-16 15:22:09	0	$2y$10$MglPoBf8ybRbHzcJ34ThJ.xinz9fEZIiM76A8QSl7/kHAMwAJs5J6	RAVI5814	customer	\N	\N	t	en	\N	2026-02-16 15:22:09	2026-02-16 15:50:06	0	f	\N	\N	f	f	\N	\N	\N	regular
879a7709-2451-4f6e-969f-5250b3991ccb	QA Tester	ec6e6001-c7e8-42a9-ad2f-d7b5c9c5a001	QA	Tester	qatester@jago.com	+919876543212	\N	\N	[]	\N	\N	\N	\N	\N	\N	0	$2y$10$Zkl2R993/OaxaJvQPvPapuU2ex6asosw/53dLWOnFP8keTC9j2M9W	TKJ2OA374S	customer	\N	\N	t	en	\N	2026-02-14 18:27:17	2026-02-15 02:21:42	0	f	\N	\N	f	f	\N	\N	\N	regular
00757917-1231-423e-aa60-c0e956f0ef0a	Test Pilot	1178d9c2-fd60-4c83-aeee-90ebaa4e555b	Test	Pilot	testpilot3@jago.com	+919876543215	\N	\N	[]	\N	\N	\N	\N	\N	\N	0	$2y$10$nGRHwdt/82KJl1Lrv2Em2eSPVxazI1GXA3BCOp6aV1ErB5GQQLvXy	RTIHMTADY7	driver	\N	\N	t	en	\N	2026-02-14 18:30:48	2026-02-15 02:21:42	0	f	\N	\N	f	f	\N	\N	\N	regular
3aaa1fef-3e50-45cc-9b53-696835ce85c5	\N	\N	Super	Admin	admin@admin.com	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	$2y$10$KH2S5NTEyPBiFZk/IiHG0ep5L6S7A/ausamLdYPDIQHlOYzpznKL2	\N	super-admin	\N	cKzPQlbV8MZ05AWAqA85YwIyxdko2UH7E81E7MOMnO8AeJFotq7RTkC6alXJ	t	en	\N	\N	\N	0	f	\N	\N	f	f	\N	\N	\N	regular
\.


--
-- Data for Name: vehicle_brands; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicle_brands (id, name, description, image, is_active, deleted_at, created_at, updated_at) FROM stdin;
293156da-74b4-4b87-8782-f282f0cb98bd	Honda	Honda Motor Company	honda.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
b3169569-e79b-4896-919b-3494e0072b77	TVS	TVS Motor Company	tvs.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
6e2848d6-02b5-4f98-9728-0785f0759e9e	Bajaj	Bajaj Auto Limited	bajaj.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
89124023-6a1c-49b3-b3da-ef5032113e84	Hero	Hero MotoCorp	hero.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
ccc93825-a783-4f8c-9fe3-2aa301eaf04a	Maruti Suzuki	Maruti Suzuki India	maruti.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
b624193a-cd81-466f-aaa2-8d1b6fbc5bb4	Hyundai	Hyundai Motor India	hyundai.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
f77ad384-9aa2-4a67-a426-141136d50df3	Tata	Tata Motors	tata.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
fac49864-792e-40c1-8a5d-f8dadd77957d	Mahindra	Mahindra & Mahindra	mahindra.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
58d2b4c6-15a6-4a83-bf46-32da25de25c1	Royal Enfield	Royal Enfield	royal_enfield.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
1a00fd39-2b1b-4be8-8bc4-7a4d32082b02	Ola Electric	Ola Electric Mobility	ola_electric.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
8a9327fe-3508-446f-b36f-9f0cbeb6a31e	Ather	Ather Energy	ather.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
89b57f6d-32d6-42cd-9eb5-2c8d2619a32f	Toyota	Toyota Motor India	toyota.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
f2d8ad2d-fc1b-4e8b-87d4-a6655c6c308b	Kia	Kia India	kia.png	t	\N	2026-02-15 15:09:23.89704	2026-02-15 15:09:23.89704
\.


--
-- Data for Name: vehicle_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicle_categories (id, name, description, image, type, is_active, deleted_at, created_at, updated_at) FROM stdin;
f1e3ceb1-d0ca-4ec3-9f11-fab251e7cc29	Bike	Motorcycle for quick point-to-point rides		motor_bike	t	\N	2026-02-14 17:14:12.293104	2026-02-14 17:14:12.293104
fdbc096e-aab1-4c7a-bf87-6db00a21e6d5	Car	Sedan car for comfortable rides		car	t	\N	2026-02-14 17:14:12.293104	2026-02-14 17:14:12.293104
0ee1d32c-6044-4d52-bc56-6607e7fa239a	Car Share	Shared car ride at discounted rates		car	t	\N	2026-02-14 17:14:12.293104	2026-02-14 17:14:12.293104
b6348701-aa7a-4c25-a9d5-b0407649dc78	Parcel Bike	Bike for parcel delivery		motor_bike	t	\N	2026-02-14 17:14:12.293104	2026-02-14 17:14:12.293104
ee9b9b13-d870-44ef-9d46-ab3add413de5	Auto	Auto rickshaw for short and medium rides		auto	t	\N	2026-02-14 17:14:12.293104	2026-02-14 17:14:12.293104
b7c933ad-9a4c-4dd9-a508-5815f7582fa2	Parcel Auto	Auto for parcel delivery		auto	t	\N	2026-02-14 17:14:12.293104	2026-02-14 17:14:12.293104
fcd1a8f8-3d16-40ad-bb79-9ab56a9716a1	Tata Ace	Small commercial vehicle for medium parcels up to 750kg		car	t	\N	2026-02-17 15:22:03	2026-02-17 15:22:03
96b93677-3e3b-4b74-abbf-ca28d372ec82	Mini Truck	Mini truck for large and heavy parcels up to 1500kg		car	t	\N	2026-02-17 15:22:03	2026-02-17 15:22:03
9625ce4c-0ffb-498c-a4f6-1e37cdd0099f	Pickup Truck	Pickup truck for bulk and oversized parcels up to 2000kg		car	t	\N	2026-02-17 15:22:03	2026-02-17 15:22:03
\.


--
-- Data for Name: vehicle_category_coupon_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicle_category_coupon_setups (vehicle_category_id, coupon_setup_id) FROM stdin;
\.


--
-- Data for Name: vehicle_category_discount_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicle_category_discount_setups (vehicle_category_id, discount_setup_id) FROM stdin;
\.


--
-- Data for Name: vehicle_category_zone; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicle_category_zone (id, zone_id, vehicle_category_id, base_fare, base_fare_per_km, waiting_fee_per_min, cancellation_fee_percent, min_cancellation_fee, idle_fee_per_min, trip_delay_fee_per_min, penalty_fee_for_cancel, fee_add_to_next, deleted_at, created_at, updated_at) FROM stdin;
24ca87a1-cc79-4206-a0bf-19e147a26336	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	ee9b9b13-d870-44ef-9d46-ab3add413de5	25.00	10.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	\N	2026-02-14 17:16:27.918573	2026-02-14 17:16:27.918573
1f34064b-d77b-4195-90b7-b411af0f581d	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	f1e3ceb1-d0ca-4ec3-9f11-fab251e7cc29	15.00	8.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	\N	2026-02-14 17:16:27.918573	2026-02-14 17:16:27.918573
125559a5-19b8-480b-ad99-57e1cd1df4f8	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	fdbc096e-aab1-4c7a-bf87-6db00a21e6d5	50.00	15.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	\N	2026-02-14 17:16:27.918573	2026-02-14 17:16:27.918573
9669b1ad-d836-4258-83f0-95011a254e4c	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	0ee1d32c-6044-4d52-bc56-6607e7fa239a	40.00	12.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	\N	2026-02-14 17:16:27.918573	2026-02-14 17:16:27.918573
e3bb172c-8e3d-43c3-9e89-94e9534b461f	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	b6348701-aa7a-4c25-a9d5-b0407649dc78	20.00	10.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	\N	2026-02-14 17:16:27.918573	2026-02-14 17:16:27.918573
fe30edf7-be9b-4428-92d8-e3a929dd14fa	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	b7c933ad-9a4c-4dd9-a508-5815f7582fa2	35.00	12.00	2.00	10.00	25.00	1.50	1.00	50.00	0.00	\N	2026-02-14 17:16:27.918573	2026-02-14 17:16:27.918573
\.


--
-- Data for Name: vehicle_models; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicle_models (id, name, brand_id, seat_capacity, maximum_weight, hatch_bag_capacity, engine, description, image, is_active, deleted_at, created_at, updated_at) FROM stdin;
72cf9fcb-b84b-4643-b42f-1c5bf43ba1d6	Activa 6G	293156da-74b4-4b87-8782-f282f0cb98bd	2	150.00	0	110cc	Popular scooter	activa.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
b46a8a8a-6c6d-400d-81fb-c4463bb8a77b	SP 125	293156da-74b4-4b87-8782-f282f0cb98bd	2	150.00	0	125cc	Commuter bike	sp125.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
8988589b-19be-4f34-a616-81aeb6d8eea7	Apache RTR 160	b3169569-e79b-4896-919b-3494e0072b77	2	150.00	0	160cc	Sports commuter	apache160.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
2d31560e-e2dd-4fe9-849e-7f5769c7b434	Jupiter	b3169569-e79b-4896-919b-3494e0072b77	2	130.00	0	110cc	Family scooter	jupiter.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
504e376f-8d3b-45f0-80f1-8dbbb627f899	Pulsar 150	6e2848d6-02b5-4f98-9728-0785f0759e9e	2	155.00	0	150cc	Popular sports bike	pulsar150.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
b42bed82-8731-4a60-88ce-d75bcfc4e391	Compact RE	6e2848d6-02b5-4f98-9728-0785f0759e9e	4	400.00	2	236cc	Auto rickshaw	bajaj_re.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
38a9db44-8694-4054-8832-bdb82ec32de6	Splendor Plus	89124023-6a1c-49b3-b3da-ef5032113e84	2	130.00	0	100cc	India best-seller	splendor.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
e65bae2b-4771-4a1d-9a8f-c346d387699f	HF Deluxe	89124023-6a1c-49b3-b3da-ef5032113e84	2	130.00	0	100cc	Economy commuter	hf_deluxe.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
c1486a1c-3642-4cf0-8b38-5e3b37f9b4aa	Swift	ccc93825-a783-4f8c-9fe3-2aa301eaf04a	5	350.00	2	1.2L Petrol	Compact hatchback	swift.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
8e0a7c01-4793-47a1-920f-3940c0898cde	Dzire	ccc93825-a783-4f8c-9fe3-2aa301eaf04a	5	400.00	3	1.2L Petrol	Compact sedan	dzire.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
3592316f-8443-4815-a80c-5a4755ca3b4a	WagonR	ccc93825-a783-4f8c-9fe3-2aa301eaf04a	5	350.00	2	1.2L Petrol	Tall-boy hatchback	wagonr.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
e4780d21-bbf8-4dc8-95dd-c17463aa9f12	Ertiga	ccc93825-a783-4f8c-9fe3-2aa301eaf04a	7	450.00	3	1.5L Petrol	MPV for families	ertiga.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
40aa74bb-91d3-4f5d-ac14-612d7f73d5ea	i20	b624193a-cd81-466f-aaa2-8d1b6fbc5bb4	5	350.00	2	1.2L Petrol	Premium hatchback	i20.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
b334a550-00bd-4b39-b06a-1be5562ae6f5	Aura	b624193a-cd81-466f-aaa2-8d1b6fbc5bb4	5	400.00	3	1.2L Petrol	Compact sedan	aura.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
fb25da80-5aeb-4c2a-b614-dc6b7b4b5869	Creta	b624193a-cd81-466f-aaa2-8d1b6fbc5bb4	5	450.00	3	1.5L Petrol	Popular SUV	creta.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
feedd863-5982-409d-b103-4dcfae045683	Nexon	f77ad384-9aa2-4a67-a426-141136d50df3	5	400.00	3	1.2L Turbo	Compact SUV	nexon.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
ec85cc41-0ff1-40f6-a2d3-4c2fa0a57133	Tiago	f77ad384-9aa2-4a67-a426-141136d50df3	5	350.00	2	1.2L Petrol	Entry hatchback	tiago.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
6b29c88f-0933-464d-b1f8-9723ba410f9b	XUV700	fac49864-792e-40c1-8a5d-f8dadd77957d	7	500.00	3	2.0L Turbo	Premium SUV	xuv700.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
6116eb49-1a84-4a74-a0e6-dfbd67052fbe	Bolero	fac49864-792e-40c1-8a5d-f8dadd77957d	7	500.00	3	1.5L Diesel	Rugged SUV	bolero.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
b0cf8615-35ab-4105-9d0f-e25c862e0ec4	Innova Crysta	89b57f6d-32d6-42cd-9eb5-2c8d2619a32f	7	500.00	3	2.4L Diesel	Premium MPV	innova.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
0f78cc96-b01a-48cc-936c-ba9547665e90	Seltos	f2d8ad2d-fc1b-4e8b-87d4-a6655c6c308b	5	450.00	3	1.5L Petrol	Premium SUV	seltos.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
6b530146-dde9-4b2e-804d-08687bf961ed	S1 Pro	1a00fd39-2b1b-4be8-8bc4-7a4d32082b02	2	130.00	0	Electric	Electric scooter	s1pro.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
36e93a14-8686-4532-b293-71b5163fae13	450X	8a9327fe-3508-446f-b36f-9f0cbeb6a31e	2	130.00	0	Electric	Smart electric scooter	450x.png	t	\N	2026-02-15 15:09:55.943914	2026-02-15 15:09:55.943914
\.


--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicles (id, ref_id, brand_id, model_id, category_id, licence_plate_number, licence_expire_date, vin_number, transmission, parcel_weight_capacity, fuel_type, ownership, driver_id, documents, is_active, draft, vehicle_request_status, deny_note, deleted_at, created_at, updated_at) FROM stdin;
7d9951b6-73b9-42ba-af79-ed7f9962d81b	VH-BIKE-001	293156da-74b4-4b87-8782-f282f0cb98bd	b46a8a8a-6c6d-400d-81fb-c4463bb8a77b	f1e3ceb1-d0ca-4ec3-9f11-fab251e7cc29	TS09AB1234	2028-12-31	\N	\N	\N	petrol	owned	1b81af34-c972-49df-b816-ca2e925e9b9b	\N	t	\N	approved	\N	\N	2026-02-16 15:23:50	2026-02-16 15:23:50
27ded013-cc24-402f-b71a-6219da0749d9	VH-AUTO-001	6e2848d6-02b5-4f98-9728-0785f0759e9e	b42bed82-8731-4a60-88ce-d75bcfc4e391	ee9b9b13-d870-44ef-9d46-ab3add413de5	TS09CD5678	2028-12-31	\N	\N	\N	cng	owned	b8dd794f-b7de-4bab-b53d-43d06dd45e52	\N	t	\N	approved	\N	\N	2026-02-16 15:23:50	2026-02-16 15:23:50
d367f456-a553-4db5-b98d-60e69706c598	VH-CAR-001	ccc93825-a783-4f8c-9fe3-2aa301eaf04a	c1486a1c-3642-4cf0-8b38-5e3b37f9b4aa	fdbc096e-aab1-4c7a-bf87-6db00a21e6d5	TS09EF9012	2028-12-31	\N	\N	\N	petrol	owned	62e81720-2260-4b67-bf44-fa8c558a116f	\N	t	\N	approved	\N	\N	2026-02-16 15:23:50	2026-02-16 15:23:50
\.


--
-- Data for Name: wallet_bonuses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wallet_bonuses (id, name, description, bonus_amount, amount_type, min_add_amount, max_bonus_amount, start_date, end_date, user_type, is_active, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: websockets_statistics_entries; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.websockets_statistics_entries (id, app_id, peak_connection_count, websocket_message_count, api_message_count, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: withdraw_methods; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.withdraw_methods (id, method_name, method_fields, is_default, is_active, created_at, updated_at, deleted_at) FROM stdin;
2	Bank Transfer	[{"input_type":"text","input_name":"bank_name","placeholder":"Bank Name","is_required":true},{"input_type":"text","input_name":"account_number","placeholder":"Account Number","is_required":true},{"input_type":"text","input_name":"ifsc_code","placeholder":"IFSC Code","is_required":true},{"input_type":"text","input_name":"account_holder_name","placeholder":"Account Holder Name","is_required":true}]	t	t	2026-02-17 16:50:19.513569	2026-02-17 16:50:19.513569	\N
3	UPI	[{"input_type":"text","input_name":"upi_id","placeholder":"UPI ID (e.g. name@upi)","is_required":true},{"input_type":"text","input_name":"account_holder_name","placeholder":"Account Holder Name","is_required":true}]	f	t	2026-02-17 16:50:19.513569	2026-02-17 16:50:19.513569	\N
4	PayTM Wallet	[{"input_type":"text","input_name":"paytm_number","placeholder":"PayTM Registered Number","is_required":true},{"input_type":"text","input_name":"account_holder_name","placeholder":"Account Holder Name","is_required":true}]	f	t	2026-02-17 16:50:19.513569	2026-02-17 16:50:19.513569	\N
\.


--
-- Data for Name: withdraw_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.withdraw_requests (id, user_id, amount, method_id, method_fields, note, driver_note, approval_note, denied_note, rejection_cause, is_approved, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: zone_coupon_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zone_coupon_setups (zone_id, coupon_setup_id) FROM stdin;
\.


--
-- Data for Name: zone_discount_setups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zone_discount_setups (zone_id, discount_setup_id) FROM stdin;
\.


--
-- Data for Name: zone_wise_default_trip_fares; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zone_wise_default_trip_fares (id, zone_id, base_fare, base_fare_per_km, waiting_fee_per_min, cancellation_fee_percent, min_cancellation_fee, idle_fee_per_min, trip_delay_fee_per_min, penalty_fee_for_cancel, fee_add_to_next, category_wise_different_fare, created_at, updated_at, pickup_charge_per_km, pickup_free_distance, shared_discount_percent) FROM stdin;
eb058536-5c8d-434a-a4e2-e43200f8cc04	f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	30	12	2	10	25	1.5	1	50	0	1	2026-02-14 17:15:13.971074	2026-02-14 17:15:13.971074	5.00	0.50	30.00
\.


--
-- Data for Name: zones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.zones (id, name, readable_id, coordinates, is_active, extra_fare_status, extra_fare_fee, extra_fare_reason, deleted_at, created_at, updated_at) FROM stdin;
f6862c59-385b-49aa-84fe-1ec7fe1d5dfb	Default Zone	1	010300000001000000050000000000000000000000000000000000000000000000000000000000000000805640000000000080664000000000008056400000000000806640000000000000000000000000000000000000000000000000	t	f	0		\N	2026-02-14 17:14:39.518014	2026-02-14 17:14:39.518014
\.


--
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 28, true);


--
-- Name: admin_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.admin_notifications_id_seq', 4, true);


--
-- Name: app_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.app_notifications_id_seq', 1, true);


--
-- Name: area_bonus_setup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.area_bonus_setup_id_seq', 1, true);


--
-- Name: area_coupon_setup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.area_coupon_setup_id_seq', 1, true);


--
-- Name: area_discount_setup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.area_discount_setup_id_seq', 1, true);


--
-- Name: area_pick_hour_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.area_pick_hour_id_seq', 1, true);


--
-- Name: blog_drafts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.blog_drafts_id_seq', 1, true);


--
-- Name: blog_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.blog_settings_id_seq', 4, true);


--
-- Name: bonus_setup_vehicle_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.bonus_setup_vehicle_category_id_seq', 1, true);


--
-- Name: channel_conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.channel_conversations_id_seq', 1, true);


--
-- Name: channel_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.channel_users_id_seq', 1, true);


--
-- Name: conversation_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conversation_files_id_seq', 1, true);


--
-- Name: coupon_setup_vehicle_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.coupon_setup_vehicle_category_id_seq', 1, true);


--
-- Name: discount_setup_vehicle_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.discount_setup_vehicle_category_id_seq', 1, true);


--
-- Name: driver_details_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.driver_details_id_seq', 5, true);


--
-- Name: driver_time_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.driver_time_logs_id_seq', 1, true);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, true);


--
-- Name: firebase_push_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.firebase_push_notifications_id_seq', 120, true);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, true);


--
-- Name: landing_page_sections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.landing_page_sections_id_seq', 36, true);


--
-- Name: late_return_penalty_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.late_return_penalty_notifications_id_seq', 1, true);


--
-- Name: level_accesses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.level_accesses_id_seq', 1, true);


--
-- Name: loyalty_points_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.loyalty_points_histories_id_seq', 1, true);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.migrations_id_seq', 219, true);


--
-- Name: module_accesses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.module_accesses_id_seq', 1, true);


--
-- Name: notification_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notification_settings_id_seq', 18, true);


--
-- Name: oauth_personal_access_clients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.oauth_personal_access_clients_id_seq', 3, true);


--
-- Name: otp_verifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.otp_verifications_id_seq', 3, true);


--
-- Name: parcel_fares_parcel_weights_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.parcel_fares_parcel_weights_id_seq', 31, true);


--
-- Name: parcel_information_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.parcel_information_id_seq', 1, true);


--
-- Name: parcel_user_infomations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.parcel_user_infomations_id_seq', 1, true);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, true);


--
-- Name: recent_addresses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recent_addresses_id_seq', 1, true);


--
-- Name: rejected_driver_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rejected_driver_requests_id_seq', 1, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reviews_id_seq', 1, true);


--
-- Name: role_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.role_user_id_seq', 1, true);


--
-- Name: shared_trip_passengers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shared_trip_passengers_id_seq', 1, false);


--
-- Name: surge_pricing_service_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.surge_pricing_service_categories_id_seq', 1, true);


--
-- Name: surge_pricing_time_slots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.surge_pricing_time_slots_id_seq', 1, true);


--
-- Name: temp_trip_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.temp_trip_notifications_id_seq', 1, true);


--
-- Name: time_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.time_logs_id_seq', 1, true);


--
-- Name: time_tracks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.time_tracks_id_seq', 1, true);


--
-- Name: trip_request_coordinates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.trip_request_coordinates_id_seq', 1, true);


--
-- Name: trip_request_fees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.trip_request_fees_id_seq', 1, true);


--
-- Name: trip_request_times_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.trip_request_times_id_seq', 1, true);


--
-- Name: trip_routes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.trip_routes_id_seq', 1, true);


--
-- Name: trip_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.trip_status_id_seq', 1, false);


--
-- Name: user_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_address_id_seq', 1, true);


--
-- Name: user_last_locations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_last_locations_id_seq', 1, true);


--
-- Name: user_level_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_level_histories_id_seq', 1, true);


--
-- Name: websockets_statistics_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.websockets_statistics_entries_id_seq', 1, true);


--
-- Name: withdraw_methods_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.withdraw_methods_id_seq', 4, true);


--
-- Name: withdraw_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.withdraw_requests_id_seq', 1, true);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: admin_notifications admin_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_notifications
    ADD CONSTRAINT admin_notifications_pkey PRIMARY KEY (id);


--
-- Name: ai_settings ai_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_settings
    ADD CONSTRAINT ai_settings_pkey PRIMARY KEY (id);


--
-- Name: app_notifications app_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_notifications
    ADD CONSTRAINT app_notifications_pkey PRIMARY KEY (id);


--
-- Name: area_bonus_setup area_bonus_setup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_bonus_setup
    ADD CONSTRAINT area_bonus_setup_pkey PRIMARY KEY (id);


--
-- Name: area_coupon_setup area_coupon_setup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_coupon_setup
    ADD CONSTRAINT area_coupon_setup_pkey PRIMARY KEY (id);


--
-- Name: area_discount_setup area_discount_setup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_discount_setup
    ADD CONSTRAINT area_discount_setup_pkey PRIMARY KEY (id);


--
-- Name: area_pick_hour area_pick_hour_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.area_pick_hour
    ADD CONSTRAINT area_pick_hour_pkey PRIMARY KEY (id);


--
-- Name: areas areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_pkey PRIMARY KEY (id);


--
-- Name: b2b_parcel_plans b2b_parcel_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.b2b_parcel_plans
    ADD CONSTRAINT b2b_parcel_plans_pkey PRIMARY KEY (id);


--
-- Name: b2b_parcel_plans b2b_parcel_plans_plan_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.b2b_parcel_plans
    ADD CONSTRAINT b2b_parcel_plans_plan_code_unique UNIQUE (plan_code);


--
-- Name: banner_setups banner_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.banner_setups
    ADD CONSTRAINT banner_setups_pkey PRIMARY KEY (id);


--
-- Name: blog_categories blog_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_categories
    ADD CONSTRAINT blog_categories_pkey PRIMARY KEY (id);


--
-- Name: blog_drafts blog_drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_drafts
    ADD CONSTRAINT blog_drafts_pkey PRIMARY KEY (id);


--
-- Name: blog_settings blog_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_settings
    ADD CONSTRAINT blog_settings_pkey PRIMARY KEY (id);


--
-- Name: blogs blogs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blogs
    ADD CONSTRAINT blogs_pkey PRIMARY KEY (id);


--
-- Name: bonus_setup_vehicle_category bonus_setup_vehicle_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bonus_setup_vehicle_category
    ADD CONSTRAINT bonus_setup_vehicle_category_pkey PRIMARY KEY (id);


--
-- Name: bonus_setups bonus_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bonus_setups
    ADD CONSTRAINT bonus_setups_pkey PRIMARY KEY (id);


--
-- Name: business_settings business_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_settings
    ADD CONSTRAINT business_settings_pkey PRIMARY KEY (id);


--
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- Name: call_recordings call_recordings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_recordings
    ADD CONSTRAINT call_recordings_pkey PRIMARY KEY (id);


--
-- Name: call_signals call_signals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_signals
    ADD CONSTRAINT call_signals_pkey PRIMARY KEY (id);


--
-- Name: calls calls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calls
    ADD CONSTRAINT calls_pkey PRIMARY KEY (id);


--
-- Name: cancellation_reasons cancellation_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellation_reasons
    ADD CONSTRAINT cancellation_reasons_pkey PRIMARY KEY (id);


--
-- Name: channel_conversations channel_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_conversations
    ADD CONSTRAINT channel_conversations_pkey PRIMARY KEY (id);


--
-- Name: channel_lists channel_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_lists
    ADD CONSTRAINT channel_lists_pkey PRIMARY KEY (id);


--
-- Name: channel_users channel_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_users
    ADD CONSTRAINT channel_users_pkey PRIMARY KEY (id);


--
-- Name: conversation_files conversation_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_files
    ADD CONSTRAINT conversation_files_pkey PRIMARY KEY (id);


--
-- Name: corporate_accounts corporate_accounts_company_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corporate_accounts
    ADD CONSTRAINT corporate_accounts_company_code_unique UNIQUE (company_code);


--
-- Name: corporate_accounts corporate_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corporate_accounts
    ADD CONSTRAINT corporate_accounts_pkey PRIMARY KEY (id);


--
-- Name: coupon_setup_vehicle_category coupon_setup_vehicle_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_setup_vehicle_category
    ADD CONSTRAINT coupon_setup_vehicle_category_pkey PRIMARY KEY (id);


--
-- Name: coupon_setups coupon_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_setups
    ADD CONSTRAINT coupon_setups_pkey PRIMARY KEY (id);


--
-- Name: customer_coupon_setups customer_coupon_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_coupon_setups
    ADD CONSTRAINT customer_coupon_setups_pkey PRIMARY KEY (user_id, coupon_setup_id);


--
-- Name: customer_discount_setups customer_discount_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_discount_setups
    ADD CONSTRAINT customer_discount_setups_pkey PRIMARY KEY (user_id, discount_setup_id);


--
-- Name: customer_level_coupon_setups customer_level_coupon_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_level_coupon_setups
    ADD CONSTRAINT customer_level_coupon_setups_pkey PRIMARY KEY (user_level_id, coupon_setup_id);


--
-- Name: customer_level_discount_setups customer_level_discount_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_level_discount_setups
    ADD CONSTRAINT customer_level_discount_setups_pkey PRIMARY KEY (user_level_id, discount_setup_id);


--
-- Name: discount_setup_vehicle_category discount_setup_vehicle_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount_setup_vehicle_category
    ADD CONSTRAINT discount_setup_vehicle_category_pkey PRIMARY KEY (id);


--
-- Name: discount_setups discount_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount_setups
    ADD CONSTRAINT discount_setups_pkey PRIMARY KEY (id);


--
-- Name: driver_details driver_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_details
    ADD CONSTRAINT driver_details_pkey PRIMARY KEY (id);


--
-- Name: driver_identity_verifications driver_identity_verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_identity_verifications
    ADD CONSTRAINT driver_identity_verifications_pkey PRIMARY KEY (id);


--
-- Name: driver_overcharge_reports driver_overcharge_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_overcharge_reports
    ADD CONSTRAINT driver_overcharge_reports_pkey PRIMARY KEY (id);


--
-- Name: driver_subscriptions driver_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_subscriptions
    ADD CONSTRAINT driver_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: driver_time_logs driver_time_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_time_logs
    ADD CONSTRAINT driver_time_logs_pkey PRIMARY KEY (id);


--
-- Name: external_configurations external_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_configurations
    ADD CONSTRAINT external_configurations_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: fare_bidding_logs fare_bidding_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_bidding_logs
    ADD CONSTRAINT fare_bidding_logs_pkey PRIMARY KEY (id);


--
-- Name: fare_biddings fare_biddings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_biddings
    ADD CONSTRAINT fare_biddings_pkey PRIMARY KEY (id);


--
-- Name: festival_offers festival_offers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.festival_offers
    ADD CONSTRAINT festival_offers_pkey PRIMARY KEY (id);


--
-- Name: firebase_push_notifications firebase_push_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.firebase_push_notifications
    ADD CONSTRAINT firebase_push_notifications_pkey PRIMARY KEY (id);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: landing_page_sections landing_page_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page_sections
    ADD CONSTRAINT landing_page_sections_pkey PRIMARY KEY (id);


--
-- Name: late_return_penalty_notifications late_return_penalty_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.late_return_penalty_notifications
    ADD CONSTRAINT late_return_penalty_notifications_pkey PRIMARY KEY (id);


--
-- Name: level_accesses level_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.level_accesses
    ADD CONSTRAINT level_accesses_pkey PRIMARY KEY (id);


--
-- Name: loyalty_points_histories loyalty_points_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loyalty_points_histories
    ADD CONSTRAINT loyalty_points_histories_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: module_accesses module_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.module_accesses
    ADD CONSTRAINT module_accesses_pkey PRIMARY KEY (id);


--
-- Name: newsletter_subscriptions newsletter_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.newsletter_subscriptions
    ADD CONSTRAINT newsletter_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: notification_settings notification_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT notification_settings_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_auth_codes oauth_auth_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_auth_codes
    ADD CONSTRAINT oauth_auth_codes_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_personal_access_clients oauth_personal_access_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_personal_access_clients
    ADD CONSTRAINT oauth_personal_access_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_refresh_tokens oauth_refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_refresh_tokens
    ADD CONSTRAINT oauth_refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: otp_verifications otp_verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_verifications
    ADD CONSTRAINT otp_verifications_pkey PRIMARY KEY (id);


--
-- Name: parcel_cancellation_reasons parcel_cancellation_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_cancellation_reasons
    ADD CONSTRAINT parcel_cancellation_reasons_pkey PRIMARY KEY (id);


--
-- Name: parcel_categories parcel_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_categories
    ADD CONSTRAINT parcel_categories_pkey PRIMARY KEY (id);


--
-- Name: parcel_fares_parcel_weights parcel_fares_parcel_weights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_fares_parcel_weights
    ADD CONSTRAINT parcel_fares_parcel_weights_pkey PRIMARY KEY (id);


--
-- Name: parcel_fares parcel_fares_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_fares
    ADD CONSTRAINT parcel_fares_pkey PRIMARY KEY (id);


--
-- Name: parcel_information parcel_information_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_information
    ADD CONSTRAINT parcel_information_pkey PRIMARY KEY (id);


--
-- Name: parcel_refund_proofs parcel_refund_proofs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_refund_proofs
    ADD CONSTRAINT parcel_refund_proofs_pkey PRIMARY KEY (id);


--
-- Name: parcel_refund_reasons parcel_refund_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_refund_reasons
    ADD CONSTRAINT parcel_refund_reasons_pkey PRIMARY KEY (id);


--
-- Name: parcel_refunds parcel_refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_refunds
    ADD CONSTRAINT parcel_refunds_pkey PRIMARY KEY (id);


--
-- Name: parcel_user_infomations parcel_user_infomations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_user_infomations
    ADD CONSTRAINT parcel_user_infomations_pkey PRIMARY KEY (id);


--
-- Name: parcel_weights parcel_weights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_weights
    ADD CONSTRAINT parcel_weights_pkey PRIMARY KEY (id);


--
-- Name: parcels parcels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT parcels_pkey PRIMARY KEY (id);


--
-- Name: payment_requests payment_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_requests
    ADD CONSTRAINT payment_requests_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: pick_hours pick_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pick_hours
    ADD CONSTRAINT pick_hours_pkey PRIMARY KEY (id);


--
-- Name: question_answers question_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_answers
    ADD CONSTRAINT question_answers_pkey PRIMARY KEY (id);


--
-- Name: recent_addresses recent_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recent_addresses
    ADD CONSTRAINT recent_addresses_pkey PRIMARY KEY (id);


--
-- Name: referral_customers referral_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_customers
    ADD CONSTRAINT referral_customers_pkey PRIMARY KEY (id);


--
-- Name: referral_drivers referral_drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_drivers
    ADD CONSTRAINT referral_drivers_pkey PRIMARY KEY (id);


--
-- Name: referral_earning_settings referral_earning_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_earning_settings
    ADD CONSTRAINT referral_earning_settings_pkey PRIMARY KEY (id);


--
-- Name: rejected_driver_requests rejected_driver_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejected_driver_requests
    ADD CONSTRAINT rejected_driver_requests_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: role_user role_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_user
    ADD CONSTRAINT role_user_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: safety_alert_reasons safety_alert_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.safety_alert_reasons
    ADD CONSTRAINT safety_alert_reasons_pkey PRIMARY KEY (id);


--
-- Name: safety_alerts safety_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.safety_alerts
    ADD CONSTRAINT safety_alerts_pkey PRIMARY KEY (id);


--
-- Name: safety_precautions safety_precautions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.safety_precautions
    ADD CONSTRAINT safety_precautions_pkey PRIMARY KEY (id);


--
-- Name: send_notifications send_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.send_notifications
    ADD CONSTRAINT send_notifications_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: shared_trip_passengers shared_trip_passengers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_trip_passengers
    ADD CONSTRAINT shared_trip_passengers_pkey PRIMARY KEY (id);


--
-- Name: sharing_fare_profiles sharing_fare_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sharing_fare_profiles
    ADD CONSTRAINT sharing_fare_profiles_pkey PRIMARY KEY (id);


--
-- Name: sharing_fare_profiles sharing_fare_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sharing_fare_profiles
    ADD CONSTRAINT sharing_fare_unique UNIQUE (zone_id, vehicle_category_id, sharing_type);


--
-- Name: social_links social_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_links
    ADD CONSTRAINT social_links_pkey PRIMARY KEY (id);


--
-- Name: spin_wheel_configs spin_wheel_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spin_wheel_configs
    ADD CONSTRAINT spin_wheel_configs_pkey PRIMARY KEY (id);


--
-- Name: spin_wheel_results spin_wheel_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spin_wheel_results
    ADD CONSTRAINT spin_wheel_results_pkey PRIMARY KEY (id);


--
-- Name: spin_wheel_segments spin_wheel_segments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spin_wheel_segments
    ADD CONSTRAINT spin_wheel_segments_pkey PRIMARY KEY (id);


--
-- Name: subscription_plans subscription_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);


--
-- Name: support_saved_replies support_saved_replies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_saved_replies
    ADD CONSTRAINT support_saved_replies_pkey PRIMARY KEY (id);


--
-- Name: surge_pricing surge_pricing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surge_pricing
    ADD CONSTRAINT surge_pricing_pkey PRIMARY KEY (id);


--
-- Name: surge_pricing_service_categories surge_pricing_service_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surge_pricing_service_categories
    ADD CONSTRAINT surge_pricing_service_categories_pkey PRIMARY KEY (id);


--
-- Name: surge_pricing_time_slots surge_pricing_time_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surge_pricing_time_slots
    ADD CONSTRAINT surge_pricing_time_slots_pkey PRIMARY KEY (id);


--
-- Name: temp_trip_notifications temp_trip_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temp_trip_notifications
    ADD CONSTRAINT temp_trip_notifications_pkey PRIMARY KEY (id);


--
-- Name: time_logs time_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.time_logs
    ADD CONSTRAINT time_logs_pkey PRIMARY KEY (id);


--
-- Name: time_tracks time_tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.time_tracks
    ADD CONSTRAINT time_tracks_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: trip_fares trip_fares_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_fares
    ADD CONSTRAINT trip_fares_pkey PRIMARY KEY (id);


--
-- Name: trip_request_coordinates trip_request_coordinates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_request_coordinates
    ADD CONSTRAINT trip_request_coordinates_pkey PRIMARY KEY (id);


--
-- Name: trip_request_fees trip_request_fees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_request_fees
    ADD CONSTRAINT trip_request_fees_pkey PRIMARY KEY (id);


--
-- Name: trip_request_times trip_request_times_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_request_times
    ADD CONSTRAINT trip_request_times_pkey PRIMARY KEY (id);


--
-- Name: trip_requests trip_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_requests
    ADD CONSTRAINT trip_requests_pkey PRIMARY KEY (id);


--
-- Name: trip_routes trip_routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_routes
    ADD CONSTRAINT trip_routes_pkey PRIMARY KEY (id);


--
-- Name: trip_status trip_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_status
    ADD CONSTRAINT trip_status_pkey PRIMARY KEY (id);


--
-- Name: user_accounts user_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_accounts
    ADD CONSTRAINT user_accounts_pkey PRIMARY KEY (id);


--
-- Name: user_address user_address_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT user_address_pkey PRIMARY KEY (id);


--
-- Name: user_last_locations user_last_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_last_locations
    ADD CONSTRAINT user_last_locations_pkey PRIMARY KEY (id);


--
-- Name: user_level_histories user_level_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_level_histories
    ADD CONSTRAINT user_level_histories_pkey PRIMARY KEY (id);


--
-- Name: user_levels user_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_levels
    ADD CONSTRAINT user_levels_pkey PRIMARY KEY (id);


--
-- Name: user_withdraw_method_infos user_withdraw_method_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_withdraw_method_infos
    ADD CONSTRAINT user_withdraw_method_infos_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicle_brands vehicle_brands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_brands
    ADD CONSTRAINT vehicle_brands_pkey PRIMARY KEY (id);


--
-- Name: vehicle_categories vehicle_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_categories
    ADD CONSTRAINT vehicle_categories_pkey PRIMARY KEY (id);


--
-- Name: vehicle_category_coupon_setups vehicle_category_coupon_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_category_coupon_setups
    ADD CONSTRAINT vehicle_category_coupon_setups_pkey PRIMARY KEY (vehicle_category_id, coupon_setup_id);


--
-- Name: vehicle_category_discount_setups vehicle_category_discount_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_category_discount_setups
    ADD CONSTRAINT vehicle_category_discount_setups_pkey PRIMARY KEY (vehicle_category_id, discount_setup_id);


--
-- Name: vehicle_category_zone vehicle_category_zone_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_category_zone
    ADD CONSTRAINT vehicle_category_zone_pkey PRIMARY KEY (id);


--
-- Name: vehicle_models vehicle_models_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_models
    ADD CONSTRAINT vehicle_models_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: wallet_bonuses wallet_bonuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_bonuses
    ADD CONSTRAINT wallet_bonuses_pkey PRIMARY KEY (id);


--
-- Name: websockets_statistics_entries websockets_statistics_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.websockets_statistics_entries
    ADD CONSTRAINT websockets_statistics_entries_pkey PRIMARY KEY (id);


--
-- Name: withdraw_methods withdraw_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraw_methods
    ADD CONSTRAINT withdraw_methods_pkey PRIMARY KEY (id);


--
-- Name: withdraw_requests withdraw_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraw_requests
    ADD CONSTRAINT withdraw_requests_pkey PRIMARY KEY (id);


--
-- Name: zone_coupon_setups zone_coupon_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_coupon_setups
    ADD CONSTRAINT zone_coupon_setups_pkey PRIMARY KEY (zone_id, coupon_setup_id);


--
-- Name: zone_discount_setups zone_discount_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_discount_setups
    ADD CONSTRAINT zone_discount_setups_pkey PRIMARY KEY (zone_id, discount_setup_id);


--
-- Name: zone_wise_default_trip_fares zone_wise_default_trip_fares_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_wise_default_trip_fares
    ADD CONSTRAINT zone_wise_default_trip_fares_pkey PRIMARY KEY (id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: areas_name_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX areas_name_unique ON public.areas USING btree (name);


--
-- Name: blog_categories_slug_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX blog_categories_slug_unique ON public.blog_categories USING btree (slug);


--
-- Name: blogs_readable_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX blogs_readable_id_unique ON public.blogs USING btree (readable_id);


--
-- Name: blogs_slug_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX blogs_slug_unique ON public.blogs USING btree (slug);


--
-- Name: channel_conversations_convable_type_convable_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX channel_conversations_convable_type_convable_id_index ON public.channel_conversations USING btree (convable_type, convable_id);


--
-- Name: channel_lists_channelable_type_channelable_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX channel_lists_channelable_type_channelable_id_index ON public.channel_lists USING btree (channelable_type, channelable_id);


--
-- Name: failed_jobs_uuid_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX failed_jobs_uuid_unique ON public.failed_jobs USING btree (uuid);


--
-- Name: festival_offers_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX festival_offers_is_active_index ON public.festival_offers USING btree (is_active);


--
-- Name: festival_offers_sharing_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX festival_offers_sharing_type_index ON public.festival_offers USING btree (sharing_type);


--
-- Name: festival_offers_starts_at_ends_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX festival_offers_starts_at_ends_at_index ON public.festival_offers USING btree (starts_at, ends_at);


--
-- Name: idx_call_recordings_call; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_call_recordings_call ON public.call_recordings USING btree (call_id);


--
-- Name: idx_call_signals_call; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_call_signals_call ON public.call_signals USING btree (call_id, created_at);


--
-- Name: idx_call_signals_unconsumed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_call_signals_unconsumed ON public.call_signals USING btree (call_id) WHERE (consumed_at IS NULL);


--
-- Name: idx_calls_callee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calls_callee ON public.calls USING btree (callee_type, callee_id);


--
-- Name: idx_calls_caller; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calls_caller ON public.calls USING btree (caller_type, caller_id);


--
-- Name: idx_calls_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calls_created ON public.calls USING btree (created_at DESC);


--
-- Name: idx_calls_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calls_status ON public.calls USING btree (status);


--
-- Name: idx_calls_trip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calls_trip ON public.calls USING btree (trip_request_id);


--
-- Name: idx_channel_conversations_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_channel_conversations_updated_at ON public.channel_conversations USING btree (updated_at);


--
-- Name: idx_driver_details_is_online; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_driver_details_is_online ON public.driver_details USING btree (is_online);


--
-- Name: idx_driver_details_online_availability; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_driver_details_online_availability ON public.driver_details USING btree (is_online, availability_status);


--
-- Name: idx_driver_details_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_driver_details_user_id ON public.driver_details USING btree (user_id);


--
-- Name: idx_driver_subscriptions_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_driver_subscriptions_driver_id ON public.driver_subscriptions USING btree (driver_id);


--
-- Name: idx_driver_subscriptions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_driver_subscriptions_status ON public.driver_subscriptions USING btree (status);


--
-- Name: idx_fare_biddings_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fare_biddings_driver_id ON public.fare_biddings USING btree (driver_id);


--
-- Name: idx_fare_biddings_trip_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fare_biddings_trip_request_id ON public.fare_biddings USING btree (trip_request_id);


--
-- Name: idx_jobs_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_jobs_queue ON public.jobs USING btree (queue);


--
-- Name: idx_overcharge_driver; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_overcharge_driver ON public.driver_overcharge_reports USING btree (driver_id);


--
-- Name: idx_overcharge_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_overcharge_status ON public.driver_overcharge_reports USING btree (status);


--
-- Name: idx_parcel_information_trip_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_parcel_information_trip_request_id ON public.parcel_information USING btree (trip_request_id);


--
-- Name: idx_reviews_trip_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reviews_trip_request_id ON public.reviews USING btree (trip_request_id);


--
-- Name: idx_sessions_last_activity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_last_activity ON public.sessions USING btree (last_activity);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (user_id);


--
-- Name: idx_shared_trip_passengers_trip_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shared_trip_passengers_trip_request_id ON public.shared_trip_passengers USING btree (trip_request_id);


--
-- Name: idx_shared_trip_unique_active_passenger; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_shared_trip_unique_active_passenger ON public.shared_trip_passengers USING btree (shared_group_id, user_id) WHERE ((status)::text = ANY ((ARRAY['pending'::character varying, 'picked_up'::character varying])::text[]));


--
-- Name: idx_spin_wheel_results_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_spin_wheel_results_created_at ON public.spin_wheel_results USING btree (created_at);


--
-- Name: idx_spin_wheel_results_trip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_spin_wheel_results_trip ON public.spin_wheel_results USING btree (trip_request_id);


--
-- Name: idx_spin_wheel_results_user_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_spin_wheel_results_user_date ON public.spin_wheel_results USING btree (user_id, created_at);


--
-- Name: idx_spin_wheel_results_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_spin_wheel_results_user_id ON public.spin_wheel_results USING btree (user_id);


--
-- Name: idx_transactions_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_account ON public.transactions USING btree (account);


--
-- Name: idx_transactions_attribute_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_attribute_id ON public.transactions USING btree (attribute_id);


--
-- Name: idx_transactions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_created_at ON public.transactions USING btree (created_at);


--
-- Name: idx_transactions_trx_ref_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_trx_ref_id ON public.transactions USING btree (trx_ref_id);


--
-- Name: idx_transactions_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_user_created ON public.transactions USING btree (user_id, created_at);


--
-- Name: idx_transactions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_user_id ON public.transactions USING btree (user_id);


--
-- Name: idx_trip_request_coordinates_trip_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_request_coordinates_trip_request_id ON public.trip_request_coordinates USING btree (trip_request_id);


--
-- Name: idx_trip_request_fees_trip_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_request_fees_trip_request_id ON public.trip_request_fees USING btree (trip_request_id);


--
-- Name: idx_trip_request_times_trip_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_request_times_trip_request_id ON public.trip_request_times USING btree (trip_request_id);


--
-- Name: idx_trip_requests_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_created_at ON public.trip_requests USING btree (created_at);


--
-- Name: idx_trip_requests_current_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_current_status ON public.trip_requests USING btree (current_status);


--
-- Name: idx_trip_requests_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_customer_id ON public.trip_requests USING btree (customer_id);


--
-- Name: idx_trip_requests_customer_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_customer_status ON public.trip_requests USING btree (customer_id, current_status);


--
-- Name: idx_trip_requests_customer_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_customer_status_created ON public.trip_requests USING btree (customer_id, current_status, created_at);


--
-- Name: idx_trip_requests_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_driver_id ON public.trip_requests USING btree (driver_id);


--
-- Name: idx_trip_requests_driver_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_driver_status ON public.trip_requests USING btree (driver_id, current_status);


--
-- Name: idx_trip_requests_payment_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_payment_status ON public.trip_requests USING btree (payment_status);


--
-- Name: idx_trip_requests_status_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_status_zone ON public.trip_requests USING btree (current_status, zone_id);


--
-- Name: idx_trip_requests_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_type ON public.trip_requests USING btree (type);


--
-- Name: idx_trip_requests_type_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_type_status ON public.trip_requests USING btree (type, current_status);


--
-- Name: idx_trip_requests_vehicle_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_vehicle_category_id ON public.trip_requests USING btree (vehicle_category_id);


--
-- Name: idx_trip_requests_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_requests_zone_id ON public.trip_requests USING btree (zone_id);


--
-- Name: idx_trip_routes_trip_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_routes_trip_request_id ON public.trip_routes USING btree (trip_request_id);


--
-- Name: idx_trip_status_trip_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_status_trip_request_id ON public.trip_status USING btree (trip_request_id);


--
-- Name: idx_user_accounts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_accounts_user_id ON public.user_accounts USING btree (user_id);


--
-- Name: idx_user_last_locations_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_last_locations_type ON public.user_last_locations USING btree (type);


--
-- Name: idx_user_last_locations_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_last_locations_user_id ON public.user_last_locations USING btree (user_id);


--
-- Name: idx_user_last_locations_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_last_locations_zone_id ON public.user_last_locations USING btree (zone_id);


--
-- Name: idx_users_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);


--
-- Name: idx_users_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_is_active ON public.users USING btree (is_active);


--
-- Name: idx_users_type_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_type_active ON public.users USING btree (user_type, is_active);


--
-- Name: idx_users_user_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_user_type ON public.users USING btree (user_type);


--
-- Name: idx_vehicle_categories_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vehicle_categories_type ON public.vehicle_categories USING btree (type);


--
-- Name: idx_vehicle_categories_type_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vehicle_categories_type_active ON public.vehicle_categories USING btree (type, is_active);


--
-- Name: idx_vehicles_driver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vehicles_driver_id ON public.vehicles USING btree (driver_id);


--
-- Name: idx_vehicles_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vehicles_is_active ON public.vehicles USING btree (is_active);


--
-- Name: idx_zone_wise_default_trip_fares_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_zone_wise_default_trip_fares_zone ON public.zone_wise_default_trip_fares USING btree (zone_id);


--
-- Name: jobs_queue_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX jobs_queue_index ON public.jobs USING btree (queue);


--
-- Name: milestone_setups_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX milestone_setups_id_unique ON public.milestone_setups USING btree (id);


--
-- Name: newsletter_subscriptions_email_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX newsletter_subscriptions_email_unique ON public.newsletter_subscriptions USING btree (email);


--
-- Name: oauth_access_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oauth_access_tokens_user_id_index ON public.oauth_access_tokens USING btree (user_id);


--
-- Name: oauth_auth_codes_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oauth_auth_codes_user_id_index ON public.oauth_auth_codes USING btree (user_id);


--
-- Name: oauth_clients_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oauth_clients_user_id_index ON public.oauth_clients USING btree (user_id);


--
-- Name: oauth_refresh_tokens_access_token_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oauth_refresh_tokens_access_token_id_index ON public.oauth_refresh_tokens USING btree (access_token_id);


--
-- Name: parcel_categories_name_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX parcel_categories_name_unique ON public.parcel_categories USING btree (name);


--
-- Name: payment_settings_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payment_settings_id_index ON public.settings USING btree (id);


--
-- Name: personal_access_tokens_token_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX personal_access_tokens_token_unique ON public.personal_access_tokens USING btree (token);


--
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: shared_trip_passengers_shared_group_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shared_trip_passengers_shared_group_id_index ON public.shared_trip_passengers USING btree (shared_group_id);


--
-- Name: shared_trip_passengers_trip_request_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shared_trip_passengers_trip_request_id_index ON public.shared_trip_passengers USING btree (trip_request_id);


--
-- Name: shared_trip_passengers_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shared_trip_passengers_user_id_index ON public.shared_trip_passengers USING btree (user_id);


--
-- Name: sharing_fare_profiles_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sharing_fare_profiles_is_active_index ON public.sharing_fare_profiles USING btree (is_active);


--
-- Name: sharing_fare_profiles_sharing_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sharing_fare_profiles_sharing_type_index ON public.sharing_fare_profiles USING btree (sharing_type);


--
-- Name: sp_scat_scid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sp_scat_scid_idx ON public.surge_pricing_service_categories USING btree (service_category_type, service_category_id);


--
-- Name: surge_pricing_readable_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX surge_pricing_readable_id_unique ON public.surge_pricing USING btree (readable_id);


--
-- Name: users_email_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_unique ON public.users USING btree (email);


--
-- Name: users_phone_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_phone_unique ON public.users USING btree (phone);


--
-- Name: users_ref_code_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_ref_code_unique ON public.users USING btree (ref_code);


--
-- Name: vehicle_brands_name_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vehicle_brands_name_unique ON public.vehicle_brands USING btree (name);


--
-- Name: vehicle_categories_name_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vehicle_categories_name_unique ON public.vehicle_categories USING btree (name);


--
-- Name: zones_name_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX zones_name_unique ON public.zones USING btree (name);


--
-- Name: call_recordings call_recordings_call_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_recordings
    ADD CONSTRAINT call_recordings_call_id_fkey FOREIGN KEY (call_id) REFERENCES public.calls(id) ON DELETE CASCADE;


--
-- Name: call_signals call_signals_call_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_signals
    ADD CONSTRAINT call_signals_call_id_fkey FOREIGN KEY (call_id) REFERENCES public.calls(id) ON DELETE CASCADE;


--
-- Name: app_notifications fk_app_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_notifications
    ADD CONSTRAINT fk_app_notifications_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: applied_coupons fk_applied_coupons_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applied_coupons
    ADD CONSTRAINT fk_applied_coupons_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: areas fk_areas_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT fk_areas_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: bonus_setup_vehicle_category fk_bonus_setup_vehicle_category_vehicle_category_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bonus_setup_vehicle_category
    ADD CONSTRAINT fk_bonus_setup_vehicle_category_vehicle_category_id FOREIGN KEY (vehicle_category_id) REFERENCES public.vehicle_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: bonus_setups fk_bonus_setups_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bonus_setups
    ADD CONSTRAINT fk_bonus_setups_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: channel_conversations fk_channel_conversations_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_conversations
    ADD CONSTRAINT fk_channel_conversations_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: channel_users fk_channel_users_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_users
    ADD CONSTRAINT fk_channel_users_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: coupon_setup_vehicle_category fk_coupon_setup_vehicle_category_vehicle_category_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_setup_vehicle_category
    ADD CONSTRAINT fk_coupon_setup_vehicle_category_vehicle_category_id FOREIGN KEY (vehicle_category_id) REFERENCES public.vehicle_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: customer_coupon_setups fk_customer_coupon_setups_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_coupon_setups
    ADD CONSTRAINT fk_customer_coupon_setups_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: customer_discount_setups fk_customer_discount_setups_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_discount_setups
    ADD CONSTRAINT fk_customer_discount_setups_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: discount_setup_vehicle_category fk_discount_setup_vehicle_category_vehicle_category_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discount_setup_vehicle_category
    ADD CONSTRAINT fk_discount_setup_vehicle_category_vehicle_category_id FOREIGN KEY (vehicle_category_id) REFERENCES public.vehicle_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: driver_details fk_driver_details_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_details
    ADD CONSTRAINT fk_driver_details_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: driver_identity_verifications fk_driver_identity_verifications_driver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_identity_verifications
    ADD CONSTRAINT fk_driver_identity_verifications_driver_id FOREIGN KEY (driver_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: driver_time_logs fk_driver_time_logs_driver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver_time_logs
    ADD CONSTRAINT fk_driver_time_logs_driver_id FOREIGN KEY (driver_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fare_bidding_logs fk_fare_bidding_logs_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_bidding_logs
    ADD CONSTRAINT fk_fare_bidding_logs_customer_id FOREIGN KEY (customer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fare_bidding_logs fk_fare_bidding_logs_driver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_bidding_logs
    ADD CONSTRAINT fk_fare_bidding_logs_driver_id FOREIGN KEY (driver_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fare_bidding_logs fk_fare_bidding_logs_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_bidding_logs
    ADD CONSTRAINT fk_fare_bidding_logs_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fare_biddings fk_fare_biddings_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_biddings
    ADD CONSTRAINT fk_fare_biddings_customer_id FOREIGN KEY (customer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fare_biddings fk_fare_biddings_driver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_biddings
    ADD CONSTRAINT fk_fare_biddings_driver_id FOREIGN KEY (driver_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fare_biddings fk_fare_biddings_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fare_biddings
    ADD CONSTRAINT fk_fare_biddings_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: late_return_penalty_notifications fk_late_return_penalty_notifications_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.late_return_penalty_notifications
    ADD CONSTRAINT fk_late_return_penalty_notifications_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: loyalty_points_histories fk_loyalty_points_histories_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loyalty_points_histories
    ADD CONSTRAINT fk_loyalty_points_histories_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: milestone_setups fk_milestone_setups_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestone_setups
    ADD CONSTRAINT fk_milestone_setups_customer_id FOREIGN KEY (customer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: milestone_setups fk_milestone_setups_driver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.milestone_setups
    ADD CONSTRAINT fk_milestone_setups_driver_id FOREIGN KEY (driver_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: module_accesses fk_module_accesses_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.module_accesses
    ADD CONSTRAINT fk_module_accesses_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: parcel_fares_parcel_weights fk_parcel_fares_parcel_weights_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_fares_parcel_weights
    ADD CONSTRAINT fk_parcel_fares_parcel_weights_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: parcel_fares fk_parcel_fares_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_fares
    ADD CONSTRAINT fk_parcel_fares_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: parcel_information fk_parcel_information_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_information
    ADD CONSTRAINT fk_parcel_information_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: parcel_refunds fk_parcel_refunds_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_refunds
    ADD CONSTRAINT fk_parcel_refunds_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: parcel_user_infomations fk_parcel_user_infomations_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_user_infomations
    ADD CONSTRAINT fk_parcel_user_infomations_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: parcels fk_parcels_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcels
    ADD CONSTRAINT fk_parcels_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: pick_hours fk_pick_hours_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pick_hours
    ADD CONSTRAINT fk_pick_hours_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: recent_addresses fk_recent_addresses_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recent_addresses
    ADD CONSTRAINT fk_recent_addresses_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: recent_addresses fk_recent_addresses_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recent_addresses
    ADD CONSTRAINT fk_recent_addresses_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: referral_customers fk_referral_customers_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_customers
    ADD CONSTRAINT fk_referral_customers_customer_id FOREIGN KEY (customer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: referral_drivers fk_referral_drivers_driver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_drivers
    ADD CONSTRAINT fk_referral_drivers_driver_id FOREIGN KEY (driver_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: rejected_driver_requests fk_rejected_driver_requests_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejected_driver_requests
    ADD CONSTRAINT fk_rejected_driver_requests_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: rejected_driver_requests fk_rejected_driver_requests_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejected_driver_requests
    ADD CONSTRAINT fk_rejected_driver_requests_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: reviews fk_reviews_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT fk_reviews_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: role_user fk_role_user_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_user
    ADD CONSTRAINT fk_role_user_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: safety_alerts fk_safety_alerts_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.safety_alerts
    ADD CONSTRAINT fk_safety_alerts_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: temp_trip_notifications fk_temp_trip_notifications_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temp_trip_notifications
    ADD CONSTRAINT fk_temp_trip_notifications_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: temp_trip_notifications fk_temp_trip_notifications_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temp_trip_notifications
    ADD CONSTRAINT fk_temp_trip_notifications_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: time_tracks fk_time_tracks_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.time_tracks
    ADD CONSTRAINT fk_time_tracks_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: transactions fk_transactions_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_transactions_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_fares fk_trip_fares_vehicle_category_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_fares
    ADD CONSTRAINT fk_trip_fares_vehicle_category_id FOREIGN KEY (vehicle_category_id) REFERENCES public.vehicle_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_fares fk_trip_fares_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_fares
    ADD CONSTRAINT fk_trip_fares_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_request_coordinates fk_trip_request_coordinates_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_request_coordinates
    ADD CONSTRAINT fk_trip_request_coordinates_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_request_fees fk_trip_request_fees_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_request_fees
    ADD CONSTRAINT fk_trip_request_fees_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_request_times fk_trip_request_times_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_request_times
    ADD CONSTRAINT fk_trip_request_times_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_requests fk_trip_requests_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_requests
    ADD CONSTRAINT fk_trip_requests_customer_id FOREIGN KEY (customer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_requests fk_trip_requests_driver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_requests
    ADD CONSTRAINT fk_trip_requests_driver_id FOREIGN KEY (driver_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_requests fk_trip_requests_vehicle_category_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_requests
    ADD CONSTRAINT fk_trip_requests_vehicle_category_id FOREIGN KEY (vehicle_category_id) REFERENCES public.vehicle_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_requests fk_trip_requests_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_requests
    ADD CONSTRAINT fk_trip_requests_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_routes fk_trip_routes_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_routes
    ADD CONSTRAINT fk_trip_routes_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_status fk_trip_status_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_status
    ADD CONSTRAINT fk_trip_status_customer_id FOREIGN KEY (customer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_status fk_trip_status_driver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_status
    ADD CONSTRAINT fk_trip_status_driver_id FOREIGN KEY (driver_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: trip_status fk_trip_status_trip_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trip_status
    ADD CONSTRAINT fk_trip_status_trip_request_id FOREIGN KEY (trip_request_id) REFERENCES public.trip_requests(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_accounts fk_user_accounts_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_accounts
    ADD CONSTRAINT fk_user_accounts_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_address fk_user_address_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT fk_user_address_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_address fk_user_address_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_address
    ADD CONSTRAINT fk_user_address_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_last_locations fk_user_last_locations_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_last_locations
    ADD CONSTRAINT fk_user_last_locations_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_last_locations fk_user_last_locations_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_last_locations
    ADD CONSTRAINT fk_user_last_locations_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_level_histories fk_user_level_histories_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_level_histories
    ADD CONSTRAINT fk_user_level_histories_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_withdraw_method_infos fk_user_withdraw_method_infos_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_withdraw_method_infos
    ADD CONSTRAINT fk_user_withdraw_method_infos_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: vehicle_category_zone fk_vehicle_category_zone_vehicle_category_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_category_zone
    ADD CONSTRAINT fk_vehicle_category_zone_vehicle_category_id FOREIGN KEY (vehicle_category_id) REFERENCES public.vehicle_categories(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: vehicle_category_zone fk_vehicle_category_zone_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_category_zone
    ADD CONSTRAINT fk_vehicle_category_zone_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: vehicles fk_vehicles_driver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_vehicles_driver_id FOREIGN KEY (driver_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: withdraw_requests fk_withdraw_requests_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraw_requests
    ADD CONSTRAINT fk_withdraw_requests_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: zone_wise_default_trip_fares fk_zone_wise_default_trip_fares_zone_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zone_wise_default_trip_fares
    ADD CONSTRAINT fk_zone_wise_default_trip_fares_zone_id FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: parcel_fares parcel_fares_vehicle_category_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parcel_fares
    ADD CONSTRAINT parcel_fares_vehicle_category_id_foreign FOREIGN KEY (vehicle_category_id) REFERENCES public.vehicle_categories(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict iZa94sYt38ibBlViILr4R7r9TMwclskK2ZRnTrfAwtCa0Egza3gaAlGzXZI9maf

