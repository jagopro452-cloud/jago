<?php

namespace Modules\UserManagement\Service;

use Modules\UserManagement\Entities\DriverSubscription;

class SubscriptionService
{
    public static function checkDriverSubscriptionLock($driver, $tripType = 'ride_request', $rideMode = null): array|bool
    {
        if ($tripType == 'parcel' || $rideMode === 'shared') {
            return true;
        }

        $earningModel = get_cache('earning_model') ?? 'commission';
        if ($earningModel === 'commission') {
            return true;
        }

        $activeSubscription = DriverSubscription::where('driver_id', $driver->id)
            ->where('status', 'active')
            ->where('expires_at', '>', now())
            ->where('is_locked', false)
            ->first();

        if (!$activeSubscription) {
            return [
                'response_code' => 'subscription_required_403',
                'message' => 'You need an active subscription to accept rides. Please subscribe to continue.'
            ];
        }

        if ($activeSubscription->rides_used >= $activeSubscription->max_rides) {
            return [
                'response_code' => 'subscription_ride_limit_exceeded_403',
                'message' => 'You have exceeded the ride limit of your subscription plan'
            ];
        }

        return true;
    }
}
