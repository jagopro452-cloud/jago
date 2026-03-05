<?php

namespace Modules\TripManagement\Service;

use Modules\TripManagement\Entities\TripRequest;

class TripNotificationService
{
    public function notifyStatusChange(TripRequest $trip, string $status): void
    {
        if (!$trip->customer?->fcm_token) {
            return;
        }

        if ($status === 'cancelled' && $trip->type === PARCEL) {
            $this->sendParcelCancelledNotification($trip);
            return;
        }

        $rideRequestType = $trip->ride_request_type === SCHEDULED ? 'schedule_ride_' : 'trip_';
        $action = $status === 'cancelled' ? $rideRequestType . 'canceled' : $rideRequestType . $status;
        $push = getNotification($action);

        sendDeviceNotification(
            fcm_token: $trip->customer->fcm_token,
            title: translate(key: $push['title'], locale: $trip->customer->current_language_key),
            description: textVariableDataFormat(
                value: $push['description'],
                tripId: $trip->ref_id,
                sentTime: pushSentTime($trip->updated_at),
                locale: $trip->customer->current_language_key
            ),
            status: $push['status'],
            ride_request_id: $trip->id,
            type: $trip->type,
            notification_type: $trip->type === RIDE_REQUEST ? 'trip' : 'parcel',
            action: $push['action'],
            user_id: $trip->customer->id
        );
    }

    public function notifyTripAccepted(TripRequest $trip): void
    {
        if (!$trip->customer?->fcm_token) {
            return;
        }

        $push = $trip->ride_request_type === SCHEDULED
            ? getNotification('schedule_trip_accepted_by_driver')
            : getNotification('driver_on_the_way');

        sendDeviceNotification(
            fcm_token: $trip->customer->fcm_token,
            title: translate(key: $push['title'], locale: $trip->customer->current_language_key),
            description: textVariableDataFormat(
                value: $push['description'],
                tripId: $trip->ref_id,
                vehicleCategory: $trip->driver?->vehicle?->category?->name,
                pickUpLocation: $trip->coordinate?->pickup_address,
                locale: $trip->customer->current_language_key
            ),
            status: $push['status'],
            ride_request_id: $trip->id,
            type: $trip->type,
            notification_type: $trip->type === RIDE_REQUEST ? 'trip' : 'parcel',
            action: $push['action'],
            user_id: $trip->customer->id
        );
    }

    public function notifyWaitingStatus(TripRequest $trip, string $waitingStatus): void
    {
        if (!$trip->customer?->fcm_token) {
            return;
        }

        $rideRequestType = $trip->ride_request_type === SCHEDULED ? 'schedule_ride_' : 'trip_';
        $push = getNotification($rideRequestType . $waitingStatus);

        sendDeviceNotification(
            fcm_token: $trip->customer->fcm_token,
            title: translate(key: $push['title'], locale: $trip->customer->current_language_key),
            description: textVariableDataFormat(
                value: $push['description'],
                tripId: $trip->ref_id,
                locale: $trip->customer->current_language_key
            ),
            status: $push['status'],
            ride_request_id: $trip->id,
            type: $trip->type,
            notification_type: $trip->type === RIDE_REQUEST ? 'trip' : 'parcel',
            action: $push['action'],
            user_id: $trip->customer->id
        );
    }

    private function sendParcelCancelledNotification(TripRequest $trip): void
    {
        $push = getNotification(key: 'parcel_canceled_after_trip_started', group: 'customer');
        sendDeviceNotification(
            fcm_token: $trip->customer->fcm_token,
            title: translate(key: $push['title'], locale: $trip->customer->current_language_key),
            description: textVariableDataFormat(
                value: $push['description'],
                parcelId: $trip->ref_id,
                approximateAmount: $trip->paid_fare,
                locale: $trip->customer->current_language_key
            ),
            status: $push['status'],
            ride_request_id: $trip->id,
            type: $trip->type,
            notification_type: 'parcel',
            action: $push['action'],
            user_id: $trip->customer->id
        );
    }
}
