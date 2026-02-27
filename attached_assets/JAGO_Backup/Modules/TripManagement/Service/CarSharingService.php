<?php

namespace Modules\TripManagement\Service;

use Modules\TripManagement\Entities\TripRequest;
use Modules\TripManagement\Entities\SharedTripPassenger;
use Modules\TripManagement\Entities\SharingFareProfile;
use Modules\TripManagement\Entities\FestivalOffer;
use Modules\FareManagement\Entities\TripFare;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class CarSharingService
{
    const TYPE_CITY = 'city';
    const TYPE_OUTSTATION = 'outstation';

    public static function isSharingTypeEnabled(string $sharingType): bool
    {
        $key = $sharingType === self::TYPE_OUTSTATION
            ? 'outstation_sharing_enabled'
            : 'city_sharing_enabled';
        return (bool)(businessConfig($key, 'business_settings')?->value ?? 0);
    }

    public static function detectSharingType(
        float $pickupLat, float $pickupLng,
        float $dropLat, float $dropLng
    ): string {
        $distance = distanceCalculator([
            'from_latitude' => $pickupLat,
            'from_longitude' => $pickupLng,
            'to_latitude' => $dropLat,
            'to_longitude' => $dropLng,
        ]);

        $outstationMinKm = (float)(businessConfig('outstation_min_distance_km', 'business_settings')?->value ?? 30);

        return $distance >= $outstationMinKm ? self::TYPE_OUTSTATION : self::TYPE_CITY;
    }

    public static function findMatchingSharedTrips(
        float $pickupLat,
        float $pickupLng,
        float $dropLat,
        float $dropLng,
        string $vehicleCategoryId,
        string $zoneId,
        int $seatsNeeded = 1,
        ?string $sharingType = null,
        ?float $maxDetourKm = null
    ): array {
        if ($sharingType === null) {
            $sharingType = self::detectSharingType($pickupLat, $pickupLng, $dropLat, $dropLng);
        }

        if (!self::isSharingTypeEnabled($sharingType)) {
            return [];
        }

        if ($maxDetourKm === null) {
            $detourKey = $sharingType === self::TYPE_OUTSTATION
                ? 'outstation_sharing_max_detour_km'
                : 'city_sharing_max_detour_km';
            $maxDetourKm = (float)(businessConfig($detourKey, 'business_settings')?->value ?? 3);
        }

        $ongoingSharedTrips = TripRequest::where('ride_mode', 'shared')
            ->where('sharing_type', $sharingType)
            ->where('vehicle_category_id', $vehicleCategoryId)
            ->where('zone_id', $zoneId)
            ->whereIn('current_status', ['pending', 'accepted', 'ongoing'])
            ->whereNotNull('shared_group_id')
            ->with(['coordinate', 'vehicleCategory', 'driver.vehicle.model', 'driver.lastLocation'])
            ->get();

        $matches = [];

        $passengerDistance = distanceCalculator([
            'from_latitude' => $pickupLat,
            'from_longitude' => $pickupLng,
            'to_latitude' => $dropLat,
            'to_longitude' => $dropLng,
        ]);

        $passengerBearing = self::calculateBearing($pickupLat, $pickupLng, $dropLat, $dropLng);

        $bearingThreshold = $sharingType === self::TYPE_OUTSTATION ? 30 : 45;

        foreach ($ongoingSharedTrips as $trip) {
            if (!$trip->coordinate) continue;

            $tripPickupLat = (float)$trip->coordinate->pickup_coordinates->latitude;
            $tripPickupLng = (float)$trip->coordinate->pickup_coordinates->longitude;
            $tripDestLat = (float)$trip->coordinate->destination_coordinates->latitude;
            $tripDestLng = (float)$trip->coordinate->destination_coordinates->longitude;

            $tripBearing = self::calculateBearing($tripPickupLat, $tripPickupLng, $tripDestLat, $tripDestLng);
            $bearingDiff = abs($tripBearing - $passengerBearing);
            if ($bearingDiff > 180) {
                $bearingDiff = 360 - $bearingDiff;
            }
            if ($bearingDiff > $bearingThreshold) {
                continue;
            }

            if (in_array($trip->current_status, ['ongoing'])) {
                $driverLat = $trip->driver?->lastLocation?->latitude ?? $tripPickupLat;
                $driverLng = $trip->driver?->lastLocation?->longitude ?? $tripPickupLng;

                $driverToDest = distanceCalculator([
                    'from_latitude' => $driverLat, 'from_longitude' => $driverLng,
                    'to_latitude' => $tripDestLat, 'to_longitude' => $tripDestLng,
                ]);
                $pickupToDest = distanceCalculator([
                    'from_latitude' => $pickupLat, 'from_longitude' => $pickupLng,
                    'to_latitude' => $tripDestLat, 'to_longitude' => $tripDestLng,
                ]);
                $dropToDest = distanceCalculator([
                    'from_latitude' => $dropLat, 'from_longitude' => $dropLng,
                    'to_latitude' => $tripDestLat, 'to_longitude' => $tripDestLng,
                ]);

                if ($pickupToDest > $driverToDest) continue;
                if ($dropToDest > $pickupToDest) continue;

                $pickupFromDriver = distanceCalculator([
                    'from_latitude' => $driverLat, 'from_longitude' => $driverLng,
                    'to_latitude' => $pickupLat, 'to_longitude' => $pickupLng,
                ]);

                $dropToTripRoute = self::pointToLineDistance(
                    $dropLat, $dropLng,
                    $driverLat, $driverLng,
                    $tripDestLat, $tripDestLng
                );

                if ($pickupFromDriver > $maxDetourKm || $dropToTripRoute > $maxDetourKm) continue;

                $detourScore = round($pickupFromDriver + $dropToTripRoute, 2);
            } else {
                $pickupDistance = distanceCalculator([
                    'from_latitude' => $pickupLat, 'from_longitude' => $pickupLng,
                    'to_latitude' => $tripPickupLat, 'to_longitude' => $tripPickupLng,
                ]);

                $dropDistance = distanceCalculator([
                    'from_latitude' => $dropLat, 'from_longitude' => $dropLng,
                    'to_latitude' => $tripDestLat, 'to_longitude' => $tripDestLng,
                ]);

                if ($pickupDistance > $maxDetourKm || $dropDistance > $maxDetourKm) continue;

                $tripFullDistance = distanceCalculator([
                    'from_latitude' => $tripPickupLat, 'from_longitude' => $tripPickupLng,
                    'to_latitude' => $tripDestLat, 'to_longitude' => $tripDestLng,
                ]);
                $pickupAlongRoute = distanceCalculator([
                    'from_latitude' => $tripPickupLat, 'from_longitude' => $tripPickupLng,
                    'to_latitude' => $pickupLat, 'to_longitude' => $pickupLng,
                ]);
                $dropAlongRoute = distanceCalculator([
                    'from_latitude' => $tripPickupLat, 'from_longitude' => $tripPickupLng,
                    'to_latitude' => $dropLat, 'to_longitude' => $dropLng,
                ]);

                if ($pickupAlongRoute > $tripFullDistance || $dropAlongRoute > $tripFullDistance) continue;
                if ($dropAlongRoute < $pickupAlongRoute) continue;

                $detourScore = round($pickupDistance + $dropDistance, 2);
            }

            $seatCapacity = $trip->driver?->vehicle?->model?->seat_capacity ?? 4;
            $availableSeats = self::getAvailableSeats($trip->shared_group_id, $seatCapacity);

            if ($availableSeats < $seatsNeeded) continue;

            $fareEstimate = self::calculatePassengerFare(
                $pickupLat, $pickupLng,
                $dropLat, $dropLng,
                $trip->zone_id,
                $trip->vehicle_category_id,
                $seatsNeeded,
                $sharingType
            );

            $activeOffer = self::getActiveOffer($sharingType, $trip->zone_id, $trip->vehicle_category_id);

            $matches[] = [
                'trip_id' => $trip->id,
                'shared_group_id' => $trip->shared_group_id,
                'sharing_type' => $sharingType,
                'trip_status' => $trip->current_status,
                'detour_score_km' => $detourScore,
                'direction_match_deg' => round($bearingDiff, 1),
                'available_seats' => $availableSeats,
                'seat_capacity' => $seatCapacity,
                'passenger_distance_km' => round($passengerDistance, 2),
                'estimated_fare' => $fareEstimate['total_fare'],
                'per_seat_fare' => $fareEstimate['per_seat_fare'],
                'base_fare' => $fareEstimate['base_fare'],
                'distance_fare' => $fareEstimate['distance_fare'],
                'shared_discount_percent' => $fareEstimate['shared_discount_percent'],
                'gst_percent' => $fareEstimate['gst_percent'],
                'gst_amount' => $fareEstimate['gst_amount'],
                'commission_percent' => $fareEstimate['commission_percent'],
                'offer' => $activeOffer ? [
                    'id' => $activeOffer->id,
                    'name' => $activeOffer->name,
                    'description' => $activeOffer->description,
                    'offer_type' => $activeOffer->offer_type,
                    'offer_value' => $activeOffer->offer_value,
                    'max_discount_amount' => $activeOffer->max_discount_amount,
                    'ends_at' => $activeOffer->ends_at->toIso8601String(),
                ] : null,
                'fare_after_offer' => $activeOffer ? self::applyOffer($fareEstimate, $activeOffer) : null,
                'vehicle_category' => $trip->vehicleCategory?->name,
                'driver_name' => ($trip->driver?->first_name ?? '') . ' ' . ($trip->driver?->last_name ?? ''),
            ];
        }

        usort($matches, fn($a, $b) => $a['detour_score_km'] <=> $b['detour_score_km']);

        return $matches;
    }

    public static function calculatePassengerFare(
        float $pickupLat,
        float $pickupLng,
        float $dropLat,
        float $dropLng,
        string $zoneId,
        string $vehicleCategoryId,
        int $seatsBooked = 1,
        ?string $sharingType = null
    ): array {
        if ($sharingType === null) {
            $sharingType = self::detectSharingType($pickupLat, $pickupLng, $dropLat, $dropLng);
        }

        $distance = distanceCalculator([
            'from_latitude' => $pickupLat,
            'from_longitude' => $pickupLng,
            'to_latitude' => $dropLat,
            'to_longitude' => $dropLng,
        ]);

        $fareProfile = SharingFareProfile::where('zone_id', $zoneId)
            ->where('vehicle_category_id', $vehicleCategoryId)
            ->where('sharing_type', $sharingType)
            ->where('is_active', true)
            ->first();

        if ($fareProfile) {
            $baseFare = $fareProfile->base_fare_per_seat;
            $perKmFare = $fareProfile->per_km_fare_per_seat;
            $sharedDiscount = $fareProfile->discount_percent;
            $gstPercent = $fareProfile->gst_percent;
            $commissionPercent = $fareProfile->commission_percent;
        } else {
            $tripFare = TripFare::where('zone_id', $zoneId)
                ->where('vehicle_category_id', $vehicleCategoryId)
                ->first();

            $baseFare = (float)($tripFare->base_fare ?? 0);
            $perKmFare = (float)($tripFare->base_fare_per_km ?? 0);
            $sharedDiscount = (float)($tripFare->shared_discount_percent ?? 30);

            $gstKey = $sharingType === self::TYPE_OUTSTATION
                ? 'outstation_sharing_gst_percent'
                : 'city_sharing_gst_percent';
            $gstPercent = (float)(businessConfig($gstKey, 'business_settings')?->value ?? 5);

            $commissionKey = $sharingType === self::TYPE_OUTSTATION
                ? 'outstation_sharing_commission_percent'
                : 'city_sharing_commission_percent';
            $commissionPercent = (float)(businessConfig($commissionKey, 'business_settings')?->value ?? 20);
        }

        $distanceFare = $perKmFare * $distance;
        $fullFare = $baseFare + $distanceFare;

        $minFare = $fareProfile ? $fareProfile->min_fare_per_seat : $baseFare;
        if ($fullFare < $minFare) {
            $fullFare = $minFare;
        }

        $perSeatFare = round($fullFare * (1 - ($sharedDiscount / 100)), 2);
        $fareBeforeTax = round($perSeatFare * $seatsBooked, 2);

        $gstAmount = round($fareBeforeTax * ($gstPercent / 100), 2);
        $totalFare = round($fareBeforeTax + $gstAmount, 2);

        $commissionAmount = round($fareBeforeTax * ($commissionPercent / 100), 2);
        $pilotEarning = round($fareBeforeTax - $commissionAmount, 2);

        return [
            'sharing_type' => $sharingType,
            'base_fare' => round($baseFare, 2),
            'distance_fare' => round($distanceFare, 2),
            'full_fare_before_discount' => round($fullFare, 2),
            'shared_discount_percent' => $sharedDiscount,
            'per_seat_fare' => $perSeatFare,
            'fare_before_tax' => $fareBeforeTax,
            'gst_percent' => $gstPercent,
            'gst_amount' => $gstAmount,
            'total_fare' => $totalFare,
            'commission_percent' => $commissionPercent,
            'commission_amount' => $commissionAmount,
            'pilot_earning' => $pilotEarning,
            'distance_km' => round($distance, 2),
            'seats_booked' => $seatsBooked,
            'fare_source' => $fareProfile ? 'sharing_profile' : 'trip_fare_fallback',
        ];
    }

    public static function getActiveOffer(
        string $sharingType,
        ?string $zoneId = null,
        ?string $vehicleCategoryId = null
    ): ?FestivalOffer {
        return FestivalOffer::active()
            ->forSharingType($sharingType)
            ->where(function ($q) use ($zoneId) {
                $q->whereNull('zone_id')->orWhere('zone_id', $zoneId);
            })
            ->where(function ($q) use ($vehicleCategoryId) {
                $q->whereNull('vehicle_category_id')->orWhere('vehicle_category_id', $vehicleCategoryId);
            })
            ->where(function ($q) {
                $q->where('max_uses_total', 0)
                    ->orWhereColumn('current_uses', '<', 'max_uses_total');
            })
            ->orderBy('offer_value', 'desc')
            ->first();
    }

    public static function getActiveOffers(?string $sharingType = null): \Illuminate\Database\Eloquent\Collection
    {
        $query = FestivalOffer::active();
        if ($sharingType) {
            $query->forSharingType($sharingType);
        }
        return $query->orderBy('ends_at', 'asc')->get();
    }

    public static function applyOffer(array $fareData, FestivalOffer $offer): array
    {
        $fareBeforeTax = $fareData['fare_before_tax'];
        $discount = 0;

        if ($fareBeforeTax < $offer->min_fare_amount && $offer->min_fare_amount > 0) {
            return array_merge($fareData, [
                'offer_applied' => false,
                'offer_id' => $offer->id,
                'offer_discount' => 0,
                'reason' => 'Minimum fare not met',
            ]);
        }

        if ($offer->offer_type === 'discount_percent') {
            $discount = round($fareBeforeTax * ($offer->offer_value / 100), 2);
        } elseif ($offer->offer_type === 'flat_discount') {
            $discount = round($offer->offer_value, 2);
        } elseif ($offer->offer_type === 'per_seat_discount') {
            $discount = round($offer->offer_value * $fareData['seats_booked'], 2);
        }

        if ($offer->max_discount_amount > 0 && $discount > $offer->max_discount_amount) {
            $discount = $offer->max_discount_amount;
        }

        $newFareBeforeTax = max(0, round($fareBeforeTax - $discount, 2));
        $newGst = round($newFareBeforeTax * ($fareData['gst_percent'] / 100), 2);
        $newTotal = round($newFareBeforeTax + $newGst, 2);

        return [
            'offer_applied' => true,
            'offer_id' => $offer->id,
            'offer_name' => $offer->name,
            'offer_discount' => $discount,
            'fare_before_tax' => $newFareBeforeTax,
            'gst_amount' => $newGst,
            'total_fare' => $newTotal,
            'savings' => round($fareData['total_fare'] - $newTotal, 2),
        ];
    }

    public static function calculateBearing(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $lat1 = deg2rad($lat1);
        $lat2 = deg2rad($lat2);
        $dLng = deg2rad($lng2 - $lng1);

        $x = sin($dLng) * cos($lat2);
        $y = cos($lat1) * sin($lat2) - sin($lat1) * cos($lat2) * cos($dLng);

        $bearing = rad2deg(atan2($x, $y));
        return fmod($bearing + 360, 360);
    }

    public static function pointToLineDistance(
        float $pointLat, float $pointLng,
        float $lineStartLat, float $lineStartLng,
        float $lineEndLat, float $lineEndLng
    ): float {
        $dAP = distanceCalculator([
            'from_latitude' => $lineStartLat, 'from_longitude' => $lineStartLng,
            'to_latitude' => $pointLat, 'to_longitude' => $pointLng,
        ]);
        $dAB = distanceCalculator([
            'from_latitude' => $lineStartLat, 'from_longitude' => $lineStartLng,
            'to_latitude' => $lineEndLat, 'to_longitude' => $lineEndLng,
        ]);
        $dBP = distanceCalculator([
            'from_latitude' => $lineEndLat, 'from_longitude' => $lineEndLng,
            'to_latitude' => $pointLat, 'to_longitude' => $pointLng,
        ]);

        if ($dAB == 0) return $dAP;

        $t = max(0, min(1, (($dAP * $dAP) - ($dBP * $dBP) + ($dAB * $dAB)) / (2 * $dAB * $dAB)));

        if ($t <= 0) return $dAP;
        if ($t >= 1) return $dBP;

        $projLat = $lineStartLat + $t * ($lineEndLat - $lineStartLat);
        $projLng = $lineStartLng + $t * ($lineEndLng - $lineStartLng);

        return distanceCalculator([
            'from_latitude' => $projLat, 'from_longitude' => $projLng,
            'to_latitude' => $pointLat, 'to_longitude' => $pointLng,
        ]);
    }

    public static function generateGroupId(): string
    {
        return 'SG-' . strtoupper(Str::random(8));
    }

    public static function addPassengerToSharedTrip(
        string $tripRequestId,
        string $sharedGroupId,
        string $userId,
        int $seatsBooked,
        float $pickupLat,
        float $pickupLng,
        string $pickupAddress,
        float $dropLat,
        float $dropLng,
        string $dropAddress,
        float $fareAmount,
        float $distanceKm = 0,
        ?string $sharingType = null
    ): SharedTripPassenger {
        $otp = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);

        return SharedTripPassenger::create([
            'trip_request_id' => $tripRequestId,
            'shared_group_id' => $sharedGroupId,
            'sharing_type' => $sharingType,
            'user_id' => $userId,
            'seats_booked' => $seatsBooked,
            'otp' => $otp,
            'pickup_lat' => $pickupLat,
            'pickup_lng' => $pickupLng,
            'pickup_address' => $pickupAddress,
            'drop_lat' => $dropLat,
            'drop_lng' => $dropLng,
            'drop_address' => $dropAddress,
            'fare_amount' => $fareAmount,
            'distance_km' => $distanceKm,
            'status' => 'pending',
        ]);
    }

    public static function verifyPassengerOtp(int $passengerId, string $otp): bool
    {
        $passenger = SharedTripPassenger::find($passengerId);
        if (!$passenger || $passenger->otp !== $otp) {
            return false;
        }
        $passenger->update([
            'otp_verified' => true,
            'is_picked_up' => true,
            'status' => 'picked_up',
            'picked_up_at' => now(),
        ]);
        return true;
    }

    public static function markPassengerDropped(int $passengerId): array
    {
        $passenger = SharedTripPassenger::with('tripRequest.driver.vehicle.model')->find($passengerId);
        if (!$passenger) return ['success' => false, 'message' => 'Passenger not found'];

        if ($passenger->status === 'dropped_off') {
            return ['success' => false, 'message' => 'Passenger already dropped off'];
        }

        $passenger->update([
            'is_dropped_off' => true,
            'status' => 'dropped_off',
            'dropped_off_at' => now(),
        ]);

        $trip = $passenger->tripRequest;
        if (!$trip) return ['success' => true, 'seats_freed' => $passenger->seats_booked, 'trip_continues' => false];

        $seatCapacity = $trip->driver?->vehicle?->model?->seat_capacity ?? 4;
        $availableSeats = self::getAvailableSeats($trip->shared_group_id, $seatCapacity);

        $activePassengers = SharedTripPassenger::where('shared_group_id', $trip->shared_group_id)
            ->whereIn('status', ['pending', 'picked_up'])
            ->count();

        return [
            'success' => true,
            'seats_freed' => $passenger->seats_booked,
            'available_seats' => $availableSeats,
            'active_passengers' => $activePassengers,
            'trip_continues' => $activePassengers > 0,
        ];
    }

    public static function cancelPassenger(int $passengerId, string $userId): array
    {
        return DB::transaction(function () use ($passengerId, $userId) {
            $passenger = SharedTripPassenger::where('id', $passengerId)
                ->where('user_id', $userId)
                ->lockForUpdate()
                ->first();

            if (!$passenger) {
                return ['success' => false, 'message' => 'Passenger record not found or not yours'];
            }

            if (in_array($passenger->status, ['cancelled', 'dropped_off'])) {
                return ['success' => false, 'message' => 'Cannot cancel - ride already ' . $passenger->status];
            }

            $trip = TripRequest::where('shared_group_id', $passenger->shared_group_id)
                ->lockForUpdate()
                ->first();

            if ($trip && in_array($trip->current_status, ['completed', 'cancelled'])) {
                return ['success' => false, 'message' => 'Cannot cancel - trip already ' . $trip->current_status];
            }

            $refundAmount = 0;
            $refundPercent = 0;

            if (!$passenger->is_picked_up) {
                $refundPercent = 100;
                $refundAmount = $passenger->fare_amount;
            }

            $passenger->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
            ]);

            if ($refundAmount > 0) {
                $userAccount = \Modules\UserManagement\Entities\UserAccount::where('user_id', $userId)
                    ->lockForUpdate()
                    ->first();

                if ($userAccount) {
                    $userAccount->increment('wallet_balance', $refundAmount);

                    \Modules\TransactionManagement\Entities\Transaction::create([
                        'id' => Str::uuid(),
                        'user_id' => $userId,
                        'trx_ref_id' => $passenger->trip_request_id,
                        'trx_ref_type' => 'car_sharing_refund',
                        'credit' => $refundAmount,
                        'debit' => 0,
                        'balance' => $userAccount->wallet_balance,
                        'attribute' => 'wallet_balance',
                        'account' => 'wallet_balance',
                    ]);
                }
            }

            $trip = TripRequest::where('shared_group_id', $passenger->shared_group_id)
                ->with('driver.vehicle.model')
                ->first();

            $seatCapacity = $trip?->driver?->vehicle?->model?->seat_capacity ?? 4;
            $availableSeats = self::getAvailableSeats($passenger->shared_group_id, $seatCapacity);

            $activePassengers = SharedTripPassenger::where('shared_group_id', $passenger->shared_group_id)
                ->whereIn('status', ['pending', 'picked_up'])
                ->count();

            return [
                'success' => true,
                'refund_amount' => round($refundAmount, 2),
                'refund_percent' => $refundPercent,
                'seats_freed' => $passenger->seats_booked,
                'available_seats' => $availableSeats,
                'active_passengers' => $activePassengers,
                'trip_continues' => $activePassengers > 0,
            ];
        });
    }

    public static function getAvailableSeats(string $sharedGroupId, int $totalCapacity): int
    {
        $usedSeats = SharedTripPassenger::where('shared_group_id', $sharedGroupId)
            ->whereIn('status', ['pending', 'picked_up'])
            ->sum('seats_booked');
        return max(0, $totalCapacity - 1 - $usedSeats);
    }

    public static function getSharedTripSummary(string $sharedGroupId): array
    {
        $passengers = SharedTripPassenger::where('shared_group_id', $sharedGroupId)->get();

        return [
            'total_passengers' => $passengers->count(),
            'active' => $passengers->whereIn('status', ['pending', 'picked_up'])->count(),
            'picked_up' => $passengers->where('status', 'picked_up')->count(),
            'dropped_off' => $passengers->where('status', 'dropped_off')->count(),
            'pending' => $passengers->where('status', 'pending')->count(),
            'total_fare' => round($passengers->sum('fare_amount'), 2),
            'total_seats_booked' => $passengers->sum('seats_booked'),
            'active_seats' => $passengers->whereIn('status', ['pending', 'picked_up'])->sum('seats_booked'),
        ];
    }

    public static function getSharingTypeConfig(): array
    {
        return [
            'city' => [
                'enabled' => self::isSharingTypeEnabled('city'),
                'commission_percent' => (float)(businessConfig('city_sharing_commission_percent', 'business_settings')?->value ?? 20),
                'gst_percent' => (float)(businessConfig('city_sharing_gst_percent', 'business_settings')?->value ?? 5),
                'max_detour_km' => (float)(businessConfig('city_sharing_max_detour_km', 'business_settings')?->value ?? 3),
            ],
            'outstation' => [
                'enabled' => self::isSharingTypeEnabled('outstation'),
                'commission_percent' => (float)(businessConfig('outstation_sharing_commission_percent', 'business_settings')?->value ?? 15),
                'gst_percent' => (float)(businessConfig('outstation_sharing_gst_percent', 'business_settings')?->value ?? 5),
                'max_detour_km' => (float)(businessConfig('outstation_sharing_max_detour_km', 'business_settings')?->value ?? 10),
                'min_distance_km' => (float)(businessConfig('outstation_min_distance_km', 'business_settings')?->value ?? 30),
            ],
        ];
    }
}
