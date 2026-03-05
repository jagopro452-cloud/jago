<?php

namespace App\Console\Commands;

use App\Events\CustomerTripRequestEvent;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Modules\TripManagement\Entities\TempTripNotification;
use Modules\TripManagement\Entities\TripRequest;
use Modules\TripManagement\Entities\RejectedDriverRequest;
use Modules\UserManagement\Repository\UserLastLocationRepositoryInterface;

class RideDispatchCascade extends Command
{
    protected $signature = 'ride:dispatch-cascade';
    protected $description = 'Re-dispatch pending rides to new available drivers every 30 seconds';

    public function handle()
    {
        $dispatchIntervalSeconds = (int)(get_cache('ride_dispatch_interval') ?? 30);
        $searchRadius = (float)(get_cache('search_radius') ?? 5);
        $maxRedispatchAttempts = (int)(get_cache('max_redispatch_attempts') ?? 10);
        $reverbConnected = checkReverbConnection();

        $cutoffTime = now()->subSeconds($dispatchIntervalSeconds);

        $pendingTrips = TripRequest::with(['coordinate', 'customer', 'tempNotifications.user', 'vehicleCategory'])
            ->where('current_status', PENDING)
            ->whereNull('driver_id')
            ->whereNull('scheduled_at')
            ->where('ride_request_type', 'regular')
            ->where('created_at', '<', $cutoffTime)
            ->where('rise_request_count', '<', $maxRedispatchAttempts)
            ->get();

        if ($pendingTrips->isEmpty()) {
            return;
        }

        $userLastLocationRepo = app()->make(UserLastLocationRepositoryInterface::class);

        foreach ($pendingTrips as $trip) {
            try {
                $freshTrip = TripRequest::where('id', $trip->id)
                    ->where('current_status', PENDING)
                    ->whereNull('driver_id')
                    ->first();

                if (!$freshTrip) {
                    continue;
                }

                $alreadyNotifiedUserIds = TempTripNotification::where('trip_request_id', $trip->id)
                    ->pluck('user_id')
                    ->toArray();

                $rejectedUserIds = RejectedDriverRequest::where('trip_request_id', $trip->id)
                    ->pluck('user_id')
                    ->toArray();

                $excludeUserIds = array_unique(array_merge($alreadyNotifiedUserIds, $rejectedUserIds));

                $expandedRadius = min($searchRadius * (1 + ($trip->rise_request_count * 0.2)), $searchRadius * 3);

                $attributes = [
                    'latitude' => $trip->coordinate->pickup_coordinates->latitude,
                    'longitude' => $trip->coordinate->pickup_coordinates->longitude,
                    'radius' => $expandedRadius,
                    'zone_id' => $trip->zone_id,
                ];

                if ($trip->vehicle_category_id) {
                    $attributes['vehicle_category_id'] = $trip->vehicle_category_id;
                }
                if ($trip->type) {
                    $attributes['service'] = $trip->type;
                }

                $nearbyDrivers = $userLastLocationRepo->getNearestDrivers($attributes);

                $nearbyDrivers->load('user');

                $newDrivers = $nearbyDrivers->filter(function ($driver) use ($excludeUserIds) {
                    return !in_array($driver->user_id, $excludeUserIds)
                        && $driver->user
                        && $driver->user->is_active
                        && $driver->user->fcm_token;
                })->take(20);

                if ($newDrivers->isNotEmpty()) {
                    $requestType = $trip->type == PARCEL ? 'parcel_request' : 'ride_request';
                    $push = getNotification('new_' . $requestType);
                    $notification = [
                        'title' => $push['title'],
                        'description' => $push['description'],
                        'status' => $push['status'],
                        'ride_request_id' => $trip->id,
                        'type' => $trip->type,
                        'notification_type' => $trip->type == RIDE_REQUEST ? 'trip' : 'parcel',
                        'action' => $push['action'],
                        'replace' => [
                            'tripId' => $trip->ref_id,
                            'parcelId' => $trip->parcel_id,
                            'approximateAmount' => getCurrencyFormat($trip->estimated_fare),
                            'dropOffLocation' => $trip->coordinate->destination_address,
                            'pickUpLocation' => $trip->coordinate->pickup_address
                        ],
                    ];

                    foreach ($newDrivers as $driver) {
                        TempTripNotification::firstOrCreate([
                            'user_id' => $driver->user->id,
                            'trip_request_id' => $trip->id,
                        ]);

                        sendDeviceNotification(
                            fcm_token: $driver->user->fcm_token,
                            title: translate(key: $notification['title'], locale: $driver->user?->current_language_key),
                            description: translate(key: $notification['description'], replace: $notification['replace'], locale: $driver->user?->current_language_key),
                            status: $notification['status'],
                            ride_request_id: $notification['ride_request_id'],
                            type: $notification['type'],
                            notification_type: $notification['notification_type'],
                            action: $notification['action'],
                            user_id: $driver->user->id,
                        );

                        if ($reverbConnected) {
                            try {
                                CustomerTripRequestEvent::broadcast($driver->user, $trip);
                            } catch (\Exception $e) {
                            }
                        }
                    }
                }

                DB::table('trip_requests')
                    ->where('id', $trip->id)
                    ->where('current_status', PENDING)
                    ->whereNull('driver_id')
                    ->update(['rise_request_count' => DB::raw('rise_request_count + 1')]);

            } catch (\Exception $e) {
                Log::warning("RideDispatchCascade failed for trip {$trip->id}: " . $e->getMessage());
            }
        }
    }
}
