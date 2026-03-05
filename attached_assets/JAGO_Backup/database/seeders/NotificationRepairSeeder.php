<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class NotificationRepairSeeder extends Seeder
{
    public function run(): void
    {
        $expectedTypes = ['regular_trip', 'schedule_trip', 'parcel', 'driver_registration', 'others'];
        $existingTypes = DB::table('firebase_push_notifications')
            ->select('type')
            ->distinct()
            ->pluck('type')
            ->toArray();

        $missingTypes = array_diff($expectedTypes, $existingTypes);

        if (empty($missingTypes)) {
            $this->command->info('All notification types are present.');
            return;
        }

        $this->command->warn('Missing notification types: ' . implode(', ', $missingTypes));

        $notifications = $this->getNotificationData();

        foreach ($notifications as $notification) {
            if (in_array($notification['type'], $missingTypes)) {
                $exists = DB::table('firebase_push_notifications')
                    ->where('name', $notification['name'])
                    ->where('type', $notification['type'])
                    ->where('group', $notification['group'])
                    ->exists();

                if (!$exists) {
                    $notification['created_at'] = now();
                    $notification['updated_at'] = now();
                    DB::table('firebase_push_notifications')->insert($notification);
                }
            }
        }

        $this->command->info('Notification data repaired successfully.');
    }

    private function getNotificationData(): array
    {
        return [
            ['name' => 'trip_started', 'value' => 'Your trip is started.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'trip_started', 'dynamic_values' => json_encode(['{tripId}', '{vehicleCategory}', '{pickUpLocation}', '{dropOffLocation}', '{sentTime}'])],
            ['name' => 'trip_completed', 'value' => 'Your trip is completed.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'trip_completed', 'dynamic_values' => json_encode(['{tripId}', '{paidAmount}', '{methodName}', '{sentTime}'])],
            ['name' => 'trip_canceled', 'value' => 'Your trip is cancelled.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'trip_canceled', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'trip_paused', 'value' => 'Trip request is paused.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'trip_paused', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'trip_resumed', 'value' => 'Trip request is resumed.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'trip_resumed', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'another_driver_assigned', 'value' => 'Another driver already accepted the trip request.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'another_driver_assigned', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'driver_on_the_way', 'value' => 'Driver accepted your trip request.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'driver_on_the_way', 'dynamic_values' => json_encode(['{tripId}', '{vehicleCategory}', '{sentTime}'])],
            ['name' => 'bid_request_from_driver', 'value' => 'Driver sent a bid request', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'bid_request_from_driver', 'dynamic_values' => json_encode(['{tripId}', '{approximateAmount}', '{sentTime}'])],
            ['name' => 'driver_canceled_ride_request', 'value' => 'Driver has canceled your ride.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'driver_canceled_ride_request', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'payment_successful', 'value' => '{paidAmount} payment successful on this trip by {methodName}.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'customer', 'action' => 'payment_successful', 'dynamic_values' => json_encode(['{paidAmount}', '{methodName}', '{sentTime}'])],
            ['name' => 'new_ride_request', 'value' => 'You have a new ride request.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'driver', 'action' => 'new_ride_request', 'dynamic_values' => json_encode(['{tripId}', '{vehicleCategory}', '{pickUpLocation}', '{dropOffLocation}', '{sentTime}'])],
            ['name' => 'bid_accepted', 'value' => 'Customer confirmed your bid.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'driver', 'action' => 'bid_accepted', 'dynamic_values' => json_encode(['{tripId}', '{approximateAmount}', '{sentTime}'])],
            ['name' => 'trip_request_canceled', 'value' => 'A trip request is cancelled.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'driver', 'action' => 'trip_request_canceled', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'customer_canceled_trip', 'value' => 'Customer just declined a request.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'driver', 'action' => 'customer_canceled_trip', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'bid_request_canceled_by_customer', 'value' => 'Customer has canceled your bid request.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'driver', 'action' => 'bid_request_canceled_by_customer', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'tips_from_customer', 'value' => 'Customer has given tips {tipsAmount} with payment.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'driver', 'action' => 'tips_from_customer', 'dynamic_values' => json_encode(['{tipsAmount}', '{tripId}', '{sentTime}'])],
            ['name' => 'received_new_bid', 'value' => 'Received a new bid request.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'driver', 'action' => 'received_new_bid', 'dynamic_values' => json_encode(['{tripId}', '{approximateAmount}', '{sentTime}'])],
            ['name' => 'customer_rejected_bid', 'value' => 'Your bid request for trip ID {tripId} has been rejected.', 'status' => 1, 'type' => 'regular_trip', 'group' => 'driver', 'action' => 'customer_rejected_bid', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],

            ['name' => 'schedule_trip_booked', 'value' => 'Schedule trip booked.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'trip_booked', 'dynamic_values' => json_encode(['{tripId}', '{vehicleCategory}', '{pickUpLocation}', '{dropOffLocation}', '{sentTime}'])],
            ['name' => 'schedule_trip_edited', 'value' => 'Schedule trip edited.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'trip_edited', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'schedule_trip_accepted_by_driver', 'value' => 'Schedule trip accepted by driver.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'trip_accepted', 'dynamic_values' => json_encode(['{tripId}', '{vehicleCategory}', '{sentTime}'])],
            ['name' => 'driver_on_the_way_to_pickup_location', 'value' => 'Driver on the way to pickup location.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'driver_on_the_way', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'schedule_ride_started', 'value' => 'Schedule ride started.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'trip_started', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'schedule_ride_completed', 'value' => 'Schedule ride completed.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'trip_completed', 'dynamic_values' => json_encode(['{tripId}', '{paidAmount}', '{sentTime}'])],
            ['name' => 'schedule_ride_canceled', 'value' => 'Schedule ride canceled.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'trip_canceled', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'schedule_ride_paused', 'value' => 'Schedule ride paused.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'trip_paused', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'schedule_ride_resumed', 'value' => 'Schedule ride resumed.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'trip_resumed', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'driver_canceled_schedule_trip_request', 'value' => 'Driver canceled the schedule trip request.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'driver_canceled_ride_request', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'payment_successful', 'value' => '{paidAmount} payment successful by {methodName}.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'customer', 'action' => 'payment_successful', 'dynamic_values' => json_encode(['{paidAmount}', '{methodName}', '{sentTime}'])],
            ['name' => 'new_schedule_trip_request', 'value' => 'New schedule trip request.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'driver', 'action' => 'new_ride_request', 'dynamic_values' => json_encode(['{tripId}', '{vehicleCategory}', '{pickUpLocation}', '{sentTime}'])],
            ['name' => 'pickup_time_started', 'value' => 'Pickup time started.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'driver', 'action' => 'pickup_time_started', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],
            ['name' => 'tips_from_customer', 'value' => 'Customer gave tips {tipsAmount}.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'driver', 'action' => 'tips_from_customer', 'dynamic_values' => json_encode(['{tipsAmount}', '{tripId}', '{sentTime}'])],
            ['name' => 'customer_canceled_the_trip', 'value' => 'Customer canceled the trip.', 'status' => 1, 'type' => 'schedule_trip', 'group' => 'driver', 'action' => 'customer_canceled_trip', 'dynamic_values' => json_encode(['{tripId}', '{sentTime}'])],

            ['name' => 'new_parcel', 'value' => 'You have a new parcel request.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'new_parcel', 'dynamic_values' => json_encode(['{parcelId}', '{sentTime}'])],
            ['name' => 'parcel_picked_up', 'value' => 'Parcel Picked-up.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'parcel_picked_up', 'dynamic_values' => json_encode(['{parcelId}', '{sentTime}'])],
            ['name' => 'parcel_on_the_way', 'value' => 'Parcel on the way.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'parcel_on_the_way', 'dynamic_values' => json_encode(['{parcelId}', '{sentTime}'])],
            ['name' => 'parcel_delivery_completed', 'value' => 'Parcel delivered successfully.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'parcel_delivery_completed', 'dynamic_values' => json_encode(['{parcelId}', '{sentTime}'])],
            ['name' => 'parcel_canceled', 'value' => 'Parcel Cancel.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'parcel_canceled', 'dynamic_values' => json_encode(['{parcelId}', '{sentTime}'])],
            ['name' => 'parcel_returned', 'value' => 'Parcel returned successfully.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'parcel_returned', 'dynamic_values' => json_encode(['{parcelId}', '{sentTime}'])],
            ['name' => 'parcel_returning_otp', 'value' => 'Your parcel returning OTP is {otp}.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'parcel_returning_otp', 'dynamic_values' => json_encode(['{otp}', '{parcelId}', '{sentTime}'])],
            ['name' => 'refund_accepted', 'value' => 'Your refund for parcel #{parcelId} approved.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'refund_accepted', 'dynamic_values' => json_encode(['{parcelId}', '{approximateAmount}', '{sentTime}'])],
            ['name' => 'refund_denied', 'value' => 'Your refund for parcel #{parcelId} denied.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'refund_denied', 'dynamic_values' => json_encode(['{parcelId}', '{sentTime}'])],
            ['name' => 'refunded_to_wallet', 'value' => '{approximateAmount} refunded to wallet for parcel #{parcelId}.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'refunded_to_wallet', 'dynamic_values' => json_encode(['{parcelId}', '{approximateAmount}', '{sentTime}'])],
            ['name' => 'refunded_as_coupon', 'value' => '{approximateAmount} issued as coupon for parcel #{parcelId}.', 'status' => 1, 'type' => 'parcel', 'group' => 'customer', 'action' => 'refunded_as_coupon', 'dynamic_values' => json_encode(['{parcelId}', '{approximateAmount}', '{sentTime}'])],
            ['name' => 'new_parcel_request', 'value' => 'New Parcel Request.', 'status' => 1, 'type' => 'parcel', 'group' => 'driver', 'action' => 'new_parcel_request', 'dynamic_values' => json_encode(['{parcelId}', '{pickUpLocation}', '{dropOffLocation}', '{sentTime}'])],
            ['name' => 'parcel_amount_deducted', 'value' => '{approximateAmount} deducted for damaged parcel #{parcelId}.', 'status' => 1, 'type' => 'parcel', 'group' => 'driver', 'action' => 'parcel_amount_deducted', 'dynamic_values' => json_encode(['{parcelId}', '{approximateAmount}', '{sentTime}'])],
            ['name' => 'parcel_canceled', 'value' => 'Parcel request cancelled.', 'status' => 1, 'type' => 'parcel', 'group' => 'driver', 'action' => 'parcel_canceled', 'dynamic_values' => json_encode(['{parcelId}', '{sentTime}'])],

            ['name' => 'registration_approved', 'value' => 'Admin approved your registration.', 'status' => 1, 'type' => 'driver_registration', 'group' => 'driver', 'action' => 'registration_approved', 'dynamic_values' => json_encode(['{userName}', '{sentTime}'])],
            ['name' => 'vehicle_request_approved', 'value' => 'Your vehicle is approved.', 'status' => 1, 'type' => 'driver_registration', 'group' => 'driver', 'action' => 'vehicle_request_approved', 'dynamic_values' => json_encode(['{userName}', '{vehicleCategory}', '{sentTime}'])],
            ['name' => 'vehicle_request_denied', 'value' => 'Your vehicle request is denied.', 'status' => 1, 'type' => 'driver_registration', 'group' => 'driver', 'action' => 'vehicle_request_denied', 'dynamic_values' => json_encode(['{userName}', '{vehicleCategory}', '{sentTime}'])],
            ['name' => 'identity_image_rejected', 'value' => 'Your identity image rejected.', 'status' => 1, 'type' => 'driver_registration', 'group' => 'driver', 'action' => 'identity_image_rejected', 'dynamic_values' => json_encode(['{userName}', '{sentTime}'])],
            ['name' => 'identity_image_approved', 'value' => 'Your identity image approved.', 'status' => 1, 'type' => 'driver_registration', 'group' => 'driver', 'action' => 'identity_image_approved', 'dynamic_values' => json_encode(['{userName}', '{sentTime}'])],
            ['name' => 'vehicle_active', 'value' => 'Your vehicle activated by admin.', 'status' => 1, 'type' => 'driver_registration', 'group' => 'driver', 'action' => 'vehicle_active', 'dynamic_values' => json_encode(['{userName}', '{vehicleCategory}', '{sentTime}'])],

            ['name' => 'coupon_applied', 'value' => 'Customer got discount.', 'status' => 1, 'type' => 'others', 'group' => 'coupon', 'action' => 'coupon_applied', 'dynamic_values' => json_encode(['{customerName}', '{sentTime}'])],
            ['name' => 'coupon_removed', 'value' => 'Customer removed coupon.', 'status' => 1, 'type' => 'others', 'group' => 'coupon', 'action' => 'coupon_removed', 'dynamic_values' => json_encode(['{customerName}', '{sentTime}'])],
            ['name' => 'review_from_customer', 'value' => 'New review from a customer!', 'status' => 1, 'type' => 'others', 'group' => 'review', 'action' => 'review_from_customer', 'dynamic_values' => json_encode(['{customerName}', '{sentTime}'])],
            ['name' => 'review_from_driver', 'value' => 'New review from a driver!', 'status' => 1, 'type' => 'others', 'group' => 'review', 'action' => 'review_from_driver', 'dynamic_values' => json_encode(['{customerName}', '{sentTime}'])],
            ['name' => 'someone_used_your_code', 'value' => 'Your code was used by a friend.', 'status' => 1, 'type' => 'others', 'group' => 'referral', 'action' => 'someone_used_your_code', 'dynamic_values' => json_encode(['{userName}', '{sentTime}'])],
            ['name' => 'referral_reward_received', 'value' => 'You received {referralRewardAmount} reward.', 'status' => 1, 'type' => 'others', 'group' => 'referral', 'action' => 'referral_reward_received', 'dynamic_values' => json_encode(['{referralRewardAmount}', '{sentTime}'])],
            ['name' => 'safety_alert_sent', 'value' => 'Safety Alert Sent.', 'status' => 1, 'type' => 'others', 'group' => 'safety_alert', 'action' => 'safety_alert_sent', 'dynamic_values' => json_encode(['{sentTime}'])],
            ['name' => 'safety_problem_resolved', 'value' => 'Safety Problem Resolved.', 'status' => 1, 'type' => 'others', 'group' => 'safety_alert', 'action' => 'safety_problem_resolved', 'dynamic_values' => json_encode(['{sentTime}'])],
            ['name' => 'terms_and_conditions_updated', 'value' => 'Terms and conditions updated.', 'status' => 1, 'type' => 'others', 'group' => 'business_page', 'action' => 'terms_and_conditions_updated', 'dynamic_values' => json_encode(['{businessName}', '{sentTime}'])],
            ['name' => 'privacy_policy_updated', 'value' => 'Privacy policy updated.', 'status' => 1, 'type' => 'others', 'group' => 'business_page', 'action' => 'privacy_policy_updated', 'dynamic_values' => json_encode(['{businessName}', '{sentTime}'])],
            ['name' => 'legal_updated', 'value' => 'Legal updated.', 'status' => 1, 'type' => 'others', 'group' => 'business_page', 'action' => 'legal_updated', 'dynamic_values' => json_encode(['{businessName}', '{sentTime}'])],
            ['name' => 'new_message', 'value' => 'New message from {userName}.', 'status' => 1, 'type' => 'others', 'group' => 'chatting', 'action' => 'new_message', 'dynamic_values' => json_encode(['{userName}', '{sentTime}'])],
            ['name' => 'admin_message', 'value' => 'New message from admin.', 'status' => 1, 'type' => 'others', 'group' => 'chatting', 'action' => 'admin_message', 'dynamic_values' => json_encode(['{sentTime}'])],
            ['name' => 'level_up', 'value' => 'You reached level {levelName}.', 'status' => 1, 'type' => 'others', 'group' => 'level', 'action' => 'level_up', 'dynamic_values' => json_encode(['{levelName}', '{sentTime}'])],
            ['name' => 'fund_added_by_admin', 'value' => 'Admin added {walletAmount} to wallet.', 'status' => 1, 'type' => 'others', 'group' => 'fund', 'action' => 'fund_added_by_admin', 'dynamic_values' => json_encode(['{walletAmount}', '{sentTime}'])],
            ['name' => 'admin_collected_cash', 'value' => 'Admin collected cash.', 'status' => 1, 'type' => 'others', 'group' => 'fund', 'action' => 'admin_collected_cash', 'dynamic_values' => json_encode(['{sentTime}'])],
            ['name' => 'withdraw_request_rejected', 'value' => 'Withdrawal request rejected. {withdrawNote}.', 'status' => 1, 'type' => 'others', 'group' => 'withdraw_request', 'action' => 'withdraw_request_rejected', 'dynamic_values' => json_encode(['{withdrawNote}', '{sentTime}'])],
            ['name' => 'withdraw_request_approved', 'value' => 'Withdrawal request approved.', 'status' => 1, 'type' => 'others', 'group' => 'withdraw_request', 'action' => 'withdraw_request_approved', 'dynamic_values' => json_encode(['{sentTime}'])],
            ['name' => 'withdraw_request_settled', 'value' => 'Withdrawal request settled.', 'status' => 1, 'type' => 'others', 'group' => 'withdraw_request', 'action' => 'withdraw_request_settled', 'dynamic_values' => json_encode(['{sentTime}'])],
            ['name' => 'withdraw_request_reversed', 'value' => 'Withdrawal request reversed.', 'status' => 1, 'type' => 'others', 'group' => 'withdraw_request', 'action' => 'withdraw_request_reversed', 'dynamic_values' => json_encode(['{sentTime}'])],
        ];
    }
}
