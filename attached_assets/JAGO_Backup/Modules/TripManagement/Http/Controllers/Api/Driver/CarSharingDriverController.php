<?php

namespace Modules\TripManagement\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use Modules\TripManagement\Service\CarSharingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Modules\TripManagement\Entities\SharedTripPassenger;
use Modules\TripManagement\Entities\TripRequest;

class CarSharingDriverController extends Controller
{
    private function verifyDriverOwnsTrip(string $sharedGroupId): ?TripRequest
    {
        $driverId = auth('api')->id();
        return TripRequest::where('shared_group_id', $sharedGroupId)
            ->where('driver_id', $driverId)
            ->where('ride_mode', 'shared')
            ->first();
    }

    private function verifyDriverOwnsPassenger(int $passengerId): ?SharedTripPassenger
    {
        $driverId = auth('api')->id();
        $passenger = SharedTripPassenger::with('tripRequest')->find($passengerId);
        if (!$passenger || !$passenger->tripRequest || $passenger->tripRequest->driver_id != $driverId) {
            return null;
        }
        return $passenger;
    }

    public function verifyPassengerOtp(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'passenger_id' => 'required|integer',
            'otp' => 'required|string|size:4',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 403);
        }

        $passenger = $this->verifyDriverOwnsPassenger($request->passenger_id);
        if (!$passenger) {
            return response()->json(responseFormatter(constant: [
                'response_code' => 'unauthorized_403',
                'message' => translate('You are not authorized for this passenger')
            ]), 403);
        }

        $verified = CarSharingService::verifyPassengerOtp(
            passengerId: $request->passenger_id,
            otp: $request->otp
        );

        if (!$verified) {
            return response()->json(responseFormatter(constant: [
                'response_code' => 'invalid_otp_403',
                'message' => translate('Invalid OTP')
            ]), 403);
        }

        $passenger->refresh();
        $summary = CarSharingService::getSharedTripSummary($passenger->shared_group_id);

        return response()->json(responseFormatter(constant: DEFAULT_200, content: [
            'message' => translate('Passenger verified and picked up'),
            'passenger_id' => $request->passenger_id,
            'picked_up_at' => $passenger->picked_up_at,
            'summary' => $summary,
        ]));
    }

    public function dropPassenger(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'passenger_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 403);
        }

        $passenger = $this->verifyDriverOwnsPassenger($request->passenger_id);
        if (!$passenger) {
            return response()->json(responseFormatter(constant: [
                'response_code' => 'unauthorized_403',
                'message' => translate('You are not authorized for this passenger')
            ]), 403);
        }

        $result = CarSharingService::markPassengerDropped(
            passengerId: $request->passenger_id
        );

        if (!$result['success']) {
            return response()->json(responseFormatter(constant: [
                'response_code' => 'drop_failed_403',
                'message' => translate($result['message'] ?? 'Drop failed')
            ]), 403);
        }

        $passenger->refresh();
        $summary = CarSharingService::getSharedTripSummary($passenger->shared_group_id);

        return response()->json(responseFormatter(constant: DEFAULT_200, content: [
            'message' => translate('Passenger dropped off successfully'),
            'seats_freed' => $result['seats_freed'],
            'available_seats' => $result['available_seats'],
            'active_passengers' => $result['active_passengers'],
            'trip_continues' => $result['trip_continues'],
            'dropped_off_at' => $passenger->dropped_off_at,
            'summary' => $summary,
        ]));
    }

    public function getPassengerList(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'shared_group_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 403);
        }

        $trip = $this->verifyDriverOwnsTrip($request->shared_group_id);
        if (!$trip) {
            return response()->json(responseFormatter(constant: [
                'response_code' => 'unauthorized_403',
                'message' => translate('You are not the driver for this shared trip')
            ]), 403);
        }

        $passengers = SharedTripPassenger::where('shared_group_id', $request->shared_group_id)
            ->with('user:id,first_name,last_name,phone')
            ->orderByRaw("CASE WHEN status = 'picked_up' THEN 1 WHEN status = 'pending' THEN 2 WHEN status = 'dropped_off' THEN 3 ELSE 4 END")
            ->orderBy('created_at')
            ->get()
            ->map(function ($p) {
                return [
                    'id' => $p->id,
                    'user_name' => ($p->user->first_name ?? '') . ' ' . ($p->user->last_name ?? ''),
                    'phone' => $p->user->phone ?? '',
                    'seats_booked' => $p->seats_booked,
                    'pickup_lat' => $p->pickup_lat,
                    'pickup_lng' => $p->pickup_lng,
                    'pickup_address' => $p->pickup_address,
                    'drop_lat' => $p->drop_lat,
                    'drop_lng' => $p->drop_lng,
                    'drop_address' => $p->drop_address,
                    'fare_amount' => $p->fare_amount,
                    'distance_km' => $p->distance_km,
                    'sharing_type' => $p->sharing_type ?? 'city',
                    'otp' => $p->otp_verified ? null : $p->otp,
                    'otp_verified' => $p->otp_verified,
                    'is_picked_up' => $p->is_picked_up,
                    'is_dropped_off' => $p->is_dropped_off,
                    'status' => $p->status,
                    'picked_up_at' => $p->picked_up_at,
                    'dropped_off_at' => $p->dropped_off_at,
                ];
            });

        $summary = CarSharingService::getSharedTripSummary($request->shared_group_id);

        return response()->json(responseFormatter(constant: DEFAULT_200, content: [
            'passengers' => $passengers,
            'summary' => $summary,
        ]));
    }
}
