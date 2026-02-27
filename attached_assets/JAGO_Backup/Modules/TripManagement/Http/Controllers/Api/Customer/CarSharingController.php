<?php

namespace Modules\TripManagement\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use Modules\TripManagement\Service\CarSharingService;
use Modules\TripManagement\Entities\FestivalOffer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Modules\TripManagement\Entities\SharedTripPassenger;
use Modules\TripManagement\Entities\TripRequest;

class CarSharingController extends Controller
{
    public function getSharingConfig(Request $request): JsonResponse
    {
        $config = CarSharingService::getSharingTypeConfig();

        $offers = [
            'city' => CarSharingService::getActiveOffers('city')->map(fn($o) => [
                'id' => $o->id,
                'name' => $o->name,
                'description' => $o->description,
                'offer_type' => $o->offer_type,
                'offer_value' => $o->offer_value,
                'max_discount_amount' => $o->max_discount_amount,
                'ends_at' => $o->ends_at->toIso8601String(),
                'banner_image' => $o->banner_image,
            ]),
            'outstation' => CarSharingService::getActiveOffers('outstation')->map(fn($o) => [
                'id' => $o->id,
                'name' => $o->name,
                'description' => $o->description,
                'offer_type' => $o->offer_type,
                'offer_value' => $o->offer_value,
                'max_discount_amount' => $o->max_discount_amount,
                'ends_at' => $o->ends_at->toIso8601String(),
                'banner_image' => $o->banner_image,
            ]),
        ];

        return response()->json(responseFormatter(constant: DEFAULT_200, content: [
            'config' => $config,
            'active_offers' => $offers,
        ]));
    }

    public function findSharedRides(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'drop_lat' => 'required|numeric',
            'drop_lng' => 'required|numeric',
            'vehicle_category_id' => 'required|string',
            'zone_id' => 'required|string',
            'seats_needed' => 'nullable|integer|min:1|max:6',
            'sharing_type' => 'nullable|string|in:city,outstation',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 403);
        }

        $sharingType = $request->sharing_type ?? CarSharingService::detectSharingType(
            (float)$request->pickup_lat, (float)$request->pickup_lng,
            (float)$request->drop_lat, (float)$request->drop_lng
        );

        if (!CarSharingService::isSharingTypeEnabled($sharingType)) {
            return response()->json(responseFormatter(constant: DEFAULT_403, content: [
                'message' => translate($sharingType === 'outstation' ? 'Outstation sharing is currently disabled' : 'City sharing is currently disabled'),
                'sharing_type' => $sharingType,
            ]), 403);
        }

        $matches = CarSharingService::findMatchingSharedTrips(
            pickupLat: (float)$request->pickup_lat,
            pickupLng: (float)$request->pickup_lng,
            dropLat: (float)$request->drop_lat,
            dropLng: (float)$request->drop_lng,
            vehicleCategoryId: $request->vehicle_category_id,
            zoneId: $request->zone_id,
            seatsNeeded: $request->seats_needed ?? 1,
            sharingType: $sharingType,
        );

        return response()->json(responseFormatter(constant: DEFAULT_200, content: [
            'sharing_type' => $sharingType,
            'matches' => $matches,
        ]));
    }

    public function joinSharedRide(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'trip_request_id' => 'required|string',
            'shared_group_id' => 'required|string',
            'seats_booked' => 'required|integer|min:1|max:6',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'pickup_address' => 'required|string',
            'drop_lat' => 'required|numeric',
            'drop_lng' => 'required|numeric',
            'drop_address' => 'required|string',
            'sharing_type' => 'nullable|string|in:city,outstation',
            'offer_id' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 403);
        }

        $customerId = auth('api')->id();

        try {
            $result = DB::transaction(function () use ($request, $customerId) {
                $trip = TripRequest::where('id', $request->trip_request_id)
                    ->lockForUpdate()
                    ->with(['driver.vehicle.model'])
                    ->first();

                if (!$trip || $trip->ride_mode !== 'shared') {
                    return ['error' => true, 'code' => 404, 'response_code' => 'not_found_404', 'message' => translate('Trip not found')];
                }

                if ($trip->shared_group_id !== $request->shared_group_id) {
                    return ['error' => true, 'code' => 403, 'response_code' => 'invalid_group_403', 'message' => translate('Group ID does not match this trip')];
                }

                if (!in_array($trip->current_status, ['pending', 'accepted', 'ongoing'])) {
                    return ['error' => true, 'code' => 403, 'response_code' => 'trip_not_available_403', 'message' => translate('This trip is no longer accepting passengers')];
                }

                $sharingType = $request->sharing_type ?? $trip->sharing_type ?? 'city';

                if (!CarSharingService::isSharingTypeEnabled($sharingType)) {
                    return ['error' => true, 'code' => 403, 'response_code' => 'type_disabled_403', 'message' => translate('This sharing type is currently disabled')];
                }

                $alreadyJoined = SharedTripPassenger::where('shared_group_id', $request->shared_group_id)
                    ->where('user_id', $customerId)
                    ->whereIn('status', ['pending', 'picked_up'])
                    ->lockForUpdate()
                    ->exists();

                if ($alreadyJoined) {
                    return ['error' => true, 'code' => 403, 'response_code' => 'already_joined_403', 'message' => translate('You have already joined this shared ride')];
                }

                $seatCapacity = $trip->driver?->vehicle?->model?->seat_capacity ?? 4;

                $usedSeats = SharedTripPassenger::where('shared_group_id', $request->shared_group_id)
                    ->whereIn('status', ['pending', 'picked_up'])
                    ->lockForUpdate()
                    ->sum('seats_booked');
                $availableSeats = max(0, $seatCapacity - 1 - $usedSeats);

                if ($availableSeats < $request->seats_booked) {
                    return ['error' => true, 'code' => 403, 'response_code' => 'no_seats_403', 'message' => translate('Not enough seats available. Only :seats seats left', ['seats' => $availableSeats])];
                }

                $fareData = CarSharingService::calculatePassengerFare(
                    pickupLat: (float)$request->pickup_lat,
                    pickupLng: (float)$request->pickup_lng,
                    dropLat: (float)$request->drop_lat,
                    dropLng: (float)$request->drop_lng,
                    zoneId: $trip->zone_id,
                    vehicleCategoryId: $trip->vehicle_category_id,
                    seatsBooked: $request->seats_booked,
                    sharingType: $sharingType,
                );

                $totalFare = $fareData['total_fare'];
                $offerApplied = null;

                if ($request->offer_id) {
                    $offer = FestivalOffer::lockForUpdate()->find($request->offer_id);
                    if ($offer && $offer->isUsable()) {
                        $offerResult = CarSharingService::applyOffer($fareData, $offer);
                        if ($offerResult['offer_applied'] ?? false) {
                            $totalFare = $offerResult['total_fare'];
                            $offer->increment('current_uses');
                            $offerApplied = [
                                'offer_id' => $offer->id,
                                'offer_name' => $offer->name,
                                'discount' => $offerResult['offer_discount'],
                                'savings' => $offerResult['savings'],
                            ];
                        }
                    }
                }

                $passenger = CarSharingService::addPassengerToSharedTrip(
                    tripRequestId: $trip->id,
                    sharedGroupId: $trip->shared_group_id,
                    userId: $customerId,
                    seatsBooked: $request->seats_booked,
                    pickupLat: (float)$request->pickup_lat,
                    pickupLng: (float)$request->pickup_lng,
                    pickupAddress: $request->pickup_address,
                    dropLat: (float)$request->drop_lat,
                    dropLng: (float)$request->drop_lng,
                    dropAddress: $request->drop_address,
                    fareAmount: $totalFare,
                    distanceKm: $fareData['distance_km'],
                    sharingType: $sharingType,
                );

                return [
                    'error' => false,
                    'passenger_id' => $passenger->id,
                    'otp' => $passenger->otp,
                    'sharing_type' => $sharingType,
                    'fare_breakdown' => $fareData,
                    'total_fare_charged' => $totalFare,
                    'offer_applied' => $offerApplied,
                    'seats_booked' => $request->seats_booked,
                    'available_seats_remaining' => $availableSeats - $request->seats_booked,
                ];
            });

            if ($result['error'] ?? false) {
                return response()->json(responseFormatter(constant: [
                    'response_code' => $result['response_code'],
                    'message' => $result['message']
                ]), $result['code']);
            }

            unset($result['error']);
            return response()->json(responseFormatter(constant: DEFAULT_200, content: $result));

        } catch (\Exception $e) {
            return response()->json(responseFormatter(constant: [
                'response_code' => 'server_error_500',
                'message' => translate('Could not join shared ride. Please try again.')
            ]), 500);
        }
    }

    public function getSharedRidePassengers(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'shared_group_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 403);
        }

        $customerId = auth('api')->id();

        $passengers = SharedTripPassenger::where('shared_group_id', $request->shared_group_id)
            ->with('user:id,first_name,last_name')
            ->get()
            ->map(function ($p) use ($customerId) {
                $isMe = $p->user_id == $customerId;
                return [
                    'id' => $p->id,
                    'user_name' => $isMe ? 'You' : (($p->user->first_name ?? '') . ' ' . ($p->user->last_name ?? '')),
                    'is_me' => $isMe,
                    'seats_booked' => $p->seats_booked,
                    'pickup_address' => $p->pickup_address,
                    'drop_address' => $p->drop_address,
                    'fare_amount' => $isMe ? $p->fare_amount : null,
                    'distance_km' => $p->distance_km,
                    'otp' => $isMe ? ($p->otp_verified ? null : $p->otp) : null,
                    'otp_verified' => $p->otp_verified,
                    'status' => $p->status,
                    'sharing_type' => $p->sharing_type,
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

    public function cancelSharedRide(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'passenger_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 403);
        }

        $customerId = auth('api')->id();

        $result = CarSharingService::cancelPassenger(
            passengerId: $request->passenger_id,
            userId: $customerId
        );

        if (!$result['success']) {
            return response()->json(responseFormatter(constant: [
                'response_code' => 'cancel_failed_403',
                'message' => translate($result['message'] ?? 'Cancellation failed')
            ]), 403);
        }

        return response()->json(responseFormatter(constant: DEFAULT_200, content: $result));
    }

    public function checkAvailableSeats(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'shared_group_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 403);
        }

        $trip = TripRequest::where('shared_group_id', $request->shared_group_id)
            ->where('ride_mode', 'shared')
            ->whereIn('current_status', ['pending', 'accepted', 'ongoing'])
            ->with('driver.vehicle.model')
            ->first();

        if (!$trip) {
            return response()->json(responseFormatter(constant: DEFAULT_404), 404);
        }

        $seatCapacity = $trip->driver?->vehicle?->model?->seat_capacity ?? 4;
        $availableSeats = CarSharingService::getAvailableSeats($request->shared_group_id, $seatCapacity);
        $summary = CarSharingService::getSharedTripSummary($request->shared_group_id);

        return response()->json(responseFormatter(constant: DEFAULT_200, content: [
            'shared_group_id' => $request->shared_group_id,
            'sharing_type' => $trip->sharing_type ?? 'city',
            'seat_capacity' => $seatCapacity,
            'available_seats' => $availableSeats,
            'trip_status' => $trip->current_status,
            'summary' => $summary,
        ]));
    }

    public function getFareEstimate(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'drop_lat' => 'required|numeric',
            'drop_lng' => 'required|numeric',
            'zone_id' => 'required|string',
            'vehicle_category_id' => 'required|string',
            'seats_needed' => 'nullable|integer|min:1|max:6',
            'sharing_type' => 'nullable|string|in:city,outstation',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 403);
        }

        $sharingType = $request->sharing_type ?? CarSharingService::detectSharingType(
            (float)$request->pickup_lat, (float)$request->pickup_lng,
            (float)$request->drop_lat, (float)$request->drop_lng
        );

        $fareData = CarSharingService::calculatePassengerFare(
            pickupLat: (float)$request->pickup_lat,
            pickupLng: (float)$request->pickup_lng,
            dropLat: (float)$request->drop_lat,
            dropLng: (float)$request->drop_lng,
            zoneId: $request->zone_id,
            vehicleCategoryId: $request->vehicle_category_id,
            seatsBooked: $request->seats_needed ?? 1,
            sharingType: $sharingType,
        );

        $activeOffer = CarSharingService::getActiveOffer($sharingType, $request->zone_id, $request->vehicle_category_id);
        $fareAfterOffer = $activeOffer ? CarSharingService::applyOffer($fareData, $activeOffer) : null;

        return response()->json(responseFormatter(constant: DEFAULT_200, content: [
            'fare' => $fareData,
            'active_offer' => $activeOffer ? [
                'id' => $activeOffer->id,
                'name' => $activeOffer->name,
                'description' => $activeOffer->description,
                'offer_type' => $activeOffer->offer_type,
                'offer_value' => $activeOffer->offer_value,
                'ends_at' => $activeOffer->ends_at->toIso8601String(),
            ] : null,
            'fare_after_offer' => $fareAfterOffer,
        ]));
    }

    public function getActiveOffers(Request $request): JsonResponse
    {
        $sharingType = $request->get('sharing_type');
        $offers = CarSharingService::getActiveOffers($sharingType);

        return response()->json(responseFormatter(constant: DEFAULT_200, content: $offers->map(fn($o) => [
            'id' => $o->id,
            'name' => $o->name,
            'description' => $o->description,
            'sharing_type' => $o->sharing_type,
            'offer_type' => $o->offer_type,
            'offer_value' => $o->offer_value,
            'max_discount_amount' => $o->max_discount_amount,
            'min_fare_amount' => $o->min_fare_amount,
            'starts_at' => $o->starts_at->toIso8601String(),
            'ends_at' => $o->ends_at->toIso8601String(),
            'banner_image' => $o->banner_image,
        ])));
    }
}
