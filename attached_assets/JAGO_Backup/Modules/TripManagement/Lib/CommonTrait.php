<?php

namespace Modules\TripManagement\Lib;

use Carbon\Carbon;
use Modules\FareManagement\Service\SurgePricingService;
use Modules\TripManagement\Entities\FareBidding;
use Modules\TripManagement\Entities\TripRequestFee;
use Modules\TripManagement\Entities\TripRequestTime;
use Modules\TripManagement\Service\TripRequestService;

trait CommonTrait
{
    use DiscountCalculationTrait, CouponCalculationTrait;

    public function calculateFinalFare($trip, $fare): array
    {
        $isParcel = ($trip->type == 'parcel');

        $subscriptionModelEnabled = !$isParcel && (bool) get_cache('subscription_model_enabled');
        $driverHasActiveSubscription = false;
        if ($subscriptionModelEnabled && $trip->driver_id) {
            $driverHasActiveSubscription = \Modules\UserManagement\Entities\DriverSubscription::where('driver_id', $trip->driver_id)
                ->where('status', 'active')
                ->where('is_locked', false)
                ->where('expires_at', '>', now())
                ->exists();
        }

        if ($isParcel) {
            $parcelCommissionEnabled = (bool) get_cache('parcel_commission_enabled');
            $admin_trip_commission = $parcelCommissionEnabled
                ? (double)(get_cache('parcel_commission_percent') ?? get_cache('trip_commission') ?? 0)
                : (double)(get_cache('trip_commission') ?? 0);
        } else {
            $earningModel = get_cache('earning_model') ?? 'commission';
            if ($earningModel === 'subscription') {
                $admin_trip_commission = 0;
            } else {
                $admin_trip_commission = (double)(get_cache('trip_commission') ?? 0);
            }
        }

        if ($isParcel) {

            $vat_percent = (double)(get_cache('vat_percent') ?? 1);
            $actual_fare = $trip->actual_fare / (1 + ($vat_percent / 100));

            $specialDiscount = 0;
            $specialDiscountType = null;
            $specialDiscountAmount = 0;

            if ($trip->customer) {
                $customer = $trip->customer;
                $seniorEnabled = (bool) get_cache('senior_citizen_discount_enabled');
                $studentEnabled = (bool) get_cache('student_discount_enabled');

                if ($seniorEnabled && $customer->is_senior_citizen) {
                    $specialDiscount = (float)(get_cache('senior_citizen_discount_percent') ?? 10);
                    $specialDiscountType = 'senior_citizen';
                } elseif ($studentEnabled && $customer->is_student) {
                    $specialDiscount = (float)(get_cache('student_discount_percent') ?? 15);
                    $specialDiscountType = 'student';
                }

                if (!$specialDiscountType && $customer->corporate_account_id) {
                    $corpAccount = \Modules\BusinessManagement\Entities\CorporateAccount::find($customer->corporate_account_id);
                    if ($corpAccount && $corpAccount->is_active && $corpAccount->discount_percent > 0
                        && $corpAccount->parcel_allowed
                        && (!$corpAccount->contract_end || !$corpAccount->contract_end->isPast())) {
                        $specialDiscount = $corpAccount->discount_percent;
                        $specialDiscountType = 'corporate';
                    }
                }
            }

            if ($specialDiscount > 0) {
                $specialDiscountAmount = round(($actual_fare * $specialDiscount) / 100, 2);
                $actual_fare = $actual_fare - $specialDiscountAmount;
            }

            $outstationEnabled = (bool) get_cache('outstation_service_enabled');
            $outstationMinKm = (float)(get_cache('outstation_min_distance_km') ?? 50);
            $estimatedDist = (float)($trip->estimated_distance ?? 0);
            if ($outstationEnabled && $estimatedDist >= $outstationMinKm) {
                $outstationMultiplier = (float)(get_cache('outstation_fare_multiplier') ?? 1.5);
                $actual_fare = $actual_fare * $outstationMultiplier;
            }

            $parcelWaitingFee = 0;
            $parcelPickupCharge = 0;
            $parcelTime = TripRequestTime::query()->firstWhere('trip_request_id', $trip->id);
            $parcelFee = TripRequestFee::where('trip_request_id', $trip->id)->first();

            $parcelWaitingFeePerMin = (float)($fare->waiting_fee_per_min ?? 0);
            $parcelWaitingFreeMinutes = (float)(get_cache('waiting_fee_free_minutes') ?? 3);
            if ($parcelWaitingFeePerMin > 0 && $parcelTime && $parcelTime->driver_arrival_timestamp) {
                $arrivalTime = Carbon::parse($parcelTime->driver_arrival_timestamp);
                $rideStartTime = ($trip->tripStatus && $trip->tripStatus->ongoing)
                    ? Carbon::parse($trip->tripStatus->ongoing)
                    : (in_array($trip->current_status, ['completed', 'cancelled']) ? $arrivalTime : now());
                $waitedMinutes = max(0, $arrivalTime->diffInMinutes($rideStartTime) - $parcelWaitingFreeMinutes);
                $parcelWaitingFee = round($waitedMinutes * $parcelWaitingFeePerMin, 2);
            }

            $pickupChargePerKm = (float)($fare->pickup_charge_per_km ?? 0);
            $pickupFreeDistance = (float)($fare->pickup_free_distance ?? 0.5);
            if ($pickupChargePerKm > 0 && $parcelFee) {
                $pickupDistKm = (float)($parcelFee->pickup_distance ?? 0);
                $chargeableDist = max(0, $pickupDistKm - $pickupFreeDistance);
                $parcelPickupCharge = round($chargeableDist * $pickupChargePerKm, 2);
            }

            $parcel_payment = $actual_fare + $parcelWaitingFee + $parcelPickupCharge;
            $vat = round(($vat_percent * $parcel_payment) / 100, 2);
            if ($parcelFee) {
                $parcelFee->vat_tax = $vat;
                $parcelFee->admin_commission = (($parcel_payment * $admin_trip_commission) / 100) + $vat;
                $parcelFee->special_discount_amount = $specialDiscountAmount;
                $parcelFee->special_discount_type = $specialDiscountType;
                $parcelFee->waiting_fee = $parcelWaitingFee;
                $parcelFee->pickup_charge = $parcelPickupCharge;
                $parcelFee->save();
            }

            return [
                'extra_fare_amount' => round($trip->extra_fare_amount, 2),
                'actual_fare' => round($actual_fare, 2),
                'final_fare' => round($parcel_payment + $vat, 2),
                'waiting_fee' => $parcelWaitingFee,
                'pickup_charge' => $parcelPickupCharge,
                'idle_fare' => 0,
                'cancellation_fee' => 0,
                'delay_fee' => 0,
                'vat' => $vat,
                'actual_distance' => $estimatedDist,
                'special_discount_amount' => $specialDiscountAmount,
                'special_discount_type' => $specialDiscountType,
            ];
        }

        $fee = TripRequestFee::query()->firstWhere('trip_request_id', $trip->id);
        $time = TripRequestTime::query()->firstWhere('trip_request_id', $trip->id);

        if (!$fee) {
            $fee = new TripRequestFee();
            $fee->trip_request_id = $trip->id;
            $fee->save();
            \Log::warning("TripRequestFee missing for trip {$trip->id}, created new record");
        }
        if (!$time) {
            $time = new TripRequestTime();
            $time->trip_request_id = $trip->id;
            $time->estimated_time = 0;
            $time->idle_time = 0;
            $time->save();
            \Log::warning("TripRequestTime missing for trip {$trip->id}, created new record");
        }

        $bid_on_fare = FareBidding::where('trip_request_id', $trip->id)->where('is_ignored', 0)->first();
        $current_status = $trip->current_status;
        $cancellation_fee = 0;
        $waiting_fee = 0;
        $distance_in_km = 0;
        $pickup_charge = 0;

        $waitingFeePerMin = (float)($fare->waiting_fee_per_min ?? 0);
        $waitingFreeMinutes = (float)(get_cache('waiting_fee_free_minutes') ?? 3);
        if ($waitingFeePerMin > 0 && $time && $time->driver_arrival_timestamp) {
            $arrivalTime = Carbon::parse($time->driver_arrival_timestamp);
            $rideStartTime = ($trip->tripStatus && $trip->tripStatus->ongoing)
                ? Carbon::parse($trip->tripStatus->ongoing)
                : (in_array($current_status, ['completed', 'cancelled']) ? $arrivalTime : now());
            $waitedMinutes = max(0, $arrivalTime->diffInMinutes($rideStartTime) - $waitingFreeMinutes);
            $waiting_fee = round($waitedMinutes * $waitingFeePerMin, 2);
            if ($time) {
                $time->waiting_time = $waitedMinutes;
            }
        }

        if (!$trip->coordinate) {
            \Log::error("Trip coordinate data missing for trip {$trip->id}, cannot calculate fare");
            return [
                'extra_fare_amount' => 0, 'actual_fare' => 0, 'final_fare' => 0,
                'waiting_fee' => 0, 'idle_fare' => 0, 'cancellation_fee' => 0,
                'pickup_charge' => 0, 'delay_fee' => 0, 'vat' => 0, 'actual_distance' => 0,
            ];
        }

        $drivingMode = $trip?->vehicleCategory?->type === 'motor_bike' ? 'TWO_WHEELER' : 'DRIVE';
        $drop_coordinate = [
            $trip->coordinate->drop_coordinates->latitude ?? 0,
            $trip->coordinate->drop_coordinates->longitude ?? 0
        ];
        $destination_coordinate = [
            $trip->coordinate->destination_coordinates->latitude ?? 0,
            $trip->coordinate->destination_coordinates->longitude ?? 0
        ];
        $pickup_coordinate = [
            $trip->coordinate->pickup_coordinates->latitude ?? 0,
            $trip->coordinate->pickup_coordinates->longitude ?? 0
        ];
        $intermediate_coordinate = [];
        if ($trip->coordinate->is_reached_1) {
            if ($trip->coordinate->is_reached_2) {
                $intermediate_coordinate[1] = [
                    $trip->coordinate->int_coordinate_2->latitude,
                    $trip->coordinate->int_coordinate_2->longitude
                ];
            }
            $intermediate_coordinate[0] = [
                $trip->coordinate->int_coordinate_1->latitude,
                $trip->coordinate->int_coordinate_1->longitude
            ];
        }

        $pickupFreeDistance = (float)($fare->pickup_free_distance ?? 0.5);
        $pickupChargePerKm = (float)($fare->pickup_charge_per_km ?? 0);
        if ($trip->coordinate->start_coordinates && $pickupChargePerKm > 0) {
            $driverStartCoord = [
                'from_latitude' => (float)$trip->coordinate->start_coordinates->latitude,
                'from_longitude' => (float)$trip->coordinate->start_coordinates->longitude,
                'to_latitude' => (float)$pickup_coordinate[0],
                'to_longitude' => (float)$pickup_coordinate[1],
            ];
            $driverToPickupKm = distanceCalculator($driverStartCoord);
            if ($driverToPickupKm > $pickupFreeDistance) {
                $pickup_charge = round(($driverToPickupKm - $pickupFreeDistance) * $pickupChargePerKm, 2);
            }
        }

        if ($current_status === 'cancelled') {
            $route = getRoutes($pickup_coordinate, $drop_coordinate, $intermediate_coordinate, [$drivingMode]);
            $distance_in_km = $route[0]['distance'];

            $distance_wise_fare_cancelled = $fare->base_fare_per_km * $distance_in_km;
            $actual_fare = $fare->base_fare + $distance_wise_fare_cancelled;
            if ($trip->extra_fare_fee > 0) {
                $extraFare = ($actual_fare * $trip->extra_fare_fee) / 100;
                $actual_fare += $extraFare;
            }

            if ($trip->surge_percentage > 0) {
                $surgeAmount = ($actual_fare * $trip->surge_percentage) / 100;
                $actual_fare += $surgeAmount;
            }

            if ($trip->fee && $trip->fee->cancelled_by === 'customer') {
                $cancellationFreeDistance = (float)(get_cache('cancellation_free_distance') ?? 0.5);
                $driverTraveledKm = 0;

                if ($trip->coordinate->start_coordinates) {
                    $driverCurrentCoord = [
                        'from_latitude' => (float)($trip->driver ? $trip->driver->lastLocations->latitude : $trip->coordinate->start_coordinates->latitude),
                        'from_longitude' => (float)($trip->driver ? $trip->driver->lastLocations->longitude : $trip->coordinate->start_coordinates->longitude),
                        'to_latitude' => (float)$trip->coordinate->start_coordinates->latitude,
                        'to_longitude' => (float)$trip->coordinate->start_coordinates->longitude,
                    ];
                    $driverToPickupCoord = [
                        'from_latitude' => (float)$trip->coordinate->start_coordinates->latitude,
                        'from_longitude' => (float)$trip->coordinate->start_coordinates->longitude,
                        'to_latitude' => (float)$pickup_coordinate[0],
                        'to_longitude' => (float)$pickup_coordinate[1],
                    ];
                    $totalPickupDistance = distanceCalculator($driverToPickupCoord);
                    $remainingDistance = distanceCalculator([
                        'from_latitude' => (float)($trip->driver ? $trip->driver->lastLocations->latitude : $trip->coordinate->start_coordinates->latitude),
                        'from_longitude' => (float)($trip->driver ? $trip->driver->lastLocations->longitude : $trip->coordinate->start_coordinates->longitude),
                        'to_latitude' => (float)$pickup_coordinate[0],
                        'to_longitude' => (float)$pickup_coordinate[1],
                    ]);
                    $driverTraveledKm = max(0, $totalPickupDistance - $remainingDistance);
                }

                if ($driverTraveledKm >= $cancellationFreeDistance) {
                    $cancellation_percent = $fare->cancellation_fee_percent;
                    $cancellation_fee = max((($cancellation_percent * $distance_wise_fare_cancelled) / 100), $fare->min_cancellation_fee);
                    if ($pickup_charge > 0) {
                        $cancellation_fee += $pickup_charge;
                    }
                }
            }
        } elseif ($current_status == 'completed') {
            $route = getRoutes($pickup_coordinate, $drop_coordinate, $intermediate_coordinate, [$drivingMode]);
            $distance_in_km = $route[0]['distance'];

            $distance_wise_fare_completed = $fare->base_fare_per_km * $distance_in_km;
            $actual_fare = $fare->base_fare + $distance_wise_fare_completed;
            if ($trip->extra_fare_fee > 0) {
                $extraFare = ($actual_fare * $trip->extra_fare_fee) / 100;
                $actual_fare += $extraFare;
            }

            if ($trip->surge_percentage > 0) {
                $surgeAmount = ($actual_fare * $trip->surge_percentage) / 100;
                $actual_fare += $surgeAmount;
            }

            // Car sharing uses its own fare logic and doesn't have platform fee/commission
            if ($trip->ride_mode === 'shared') {
                $sharedDiscount = (float)($fare->shared_discount_percent ?? 30);
                $actual_fare = $actual_fare * (1 - ($sharedDiscount / 100));
                $actual_fare = $actual_fare * ($trip->seats_requested ?? 1);
            }

            $vat_percent = (double)(get_cache('vat_percent') ?? 1);
            $distanceFare = $trip->rise_request_count > 0 ? $trip->actual_fare / (1 + ($vat_percent / 100)) : $actual_fare;
            $actual_fare = $bid_on_fare ? $bid_on_fare->bid_fare / (1 + ($vat_percent / 100)) : $distanceFare;
        } else {
            $actual_fare = 0;
        }


        $trip_started = $trip->tripStatus && $trip->tripStatus->ongoing ? Carbon::parse($trip->tripStatus->ongoing) : now();
        $trip_ended = $trip->tripStatus && $trip->tripStatus->$current_status ? Carbon::parse($trip->tripStatus->$current_status) : now();
        $actual_time = $trip_started->diffInMinutes($trip_ended);

        //        Idle time & fee calculation
        $idle_fee_buffer = (double)(get_cache('idle_fee') ?? 0);
        $idle_diff = ($trip->time ? $trip->time->idle_time : 0) - $idle_fee_buffer;
        $idle_time = max($idle_diff, 0);
        $idle_fee = $idle_time * $fare->idle_fee_per_min;

        //        Delay time & fee calculation
        $delay_fee_buffer = (double)(get_cache('delay_fee') ?? 0);
        $delay_diff = $actual_time - (($trip->time ? $trip->time->estimated_time : 0) + $delay_fee_buffer + ($trip->time ? $trip->time->idle_time : 0));
        $delay_time = max($delay_diff, 0);
        $delay_fee = $delay_time * $fare->trip_delay_fee_per_min;


        $vat_percent = (double)(get_cache('vat_percent') ?? 1);
        $final_fare_without_tax = ($actual_fare + $waiting_fee + $idle_fee + $cancellation_fee + $delay_fee + $pickup_charge);
        $vat = ($final_fare_without_tax * $vat_percent) / 100;

        $fee->vat_tax = round($vat, 2);
        $isShared = ($trip->ride_mode ?? '') === 'shared';
        if (!$isParcel && !$isShared && ($earningModel ?? 'commission') === 'subscription') {
            $fixedPlatformFee = (double)(get_cache('platform_fee_amount') ?? 0);
            $platformFeeGst = ($fixedPlatformFee * $vat_percent) / 100;
            $fee->admin_commission = $fixedPlatformFee + $platformFeeGst;
        } elseif ($isShared || $isParcel) {
            $fee->admin_commission = (($final_fare_without_tax * (double)(get_cache('trip_commission') ?? 0)) / 100) + $vat;
        } else {
            $fee->admin_commission = (($final_fare_without_tax * $admin_trip_commission) / 100) + $vat;
        }
        $fee->cancellation_fee = round($cancellation_fee, 2);
        $fee->pickup_charge = round($pickup_charge, 2);

        if ($cancellation_fee > 0 && $fee->cancelled_by === 'customer' && $time && $time->driver_arrival_time) {
            $fee->cancellation_fee_admin_share = round($cancellation_fee * 0.60, 2);
            $fee->cancellation_fee_driver_share = round($cancellation_fee * 0.40, 2);
        }

        if ($time) {
            $time->actual_time = $actual_time;
            $time->idle_time = $idle_time;
            $time->delay_time = $delay_time;
            $time->save();
        }
        $fee->idle_fee = round($idle_fee, 2);
        $fee->delay_fee = round($delay_fee, 2);
        $fee->save();

        return [
            'extra_fare_amount' => round($extraFare ?? 0, 2),
            'actual_fare' => round($actual_fare, 2),
            'final_fare' => round($final_fare_without_tax + $vat, 2),
            'waiting_fee' => $waiting_fee,
            'idle_fare' => $idle_fee,
            'cancellation_fee' => $cancellation_fee,
            'pickup_charge' => $pickup_charge,
            'delay_fee' => $delay_fee,
            'vat' => $vat,
            'actual_distance' => $distance_in_km,
        ];
    }


    public function estimatedFare($tripRequest, $routes, $zone_id, $zone, $tripFare = null, $area_id = null, $beforeCreate = false): mixed
    {

        $surgePriceService = app()->make(SurgePricingService::class);
        if ($tripRequest['type'] == 'parcel') {
            abort_if(boolean: empty($tripFare), code: 403, message: translate('invalid_or_missing_information'));
            abort_if(boolean: empty($tripFare->fares), code: 403, message: translate('no_fares_found'));
            $user = auth('api')->user();
            $vat_percent = (double)(get_cache('vat_percent') ?? 1);
            $points = (int)getSession('currency_decimal_point') ?? 0;
            $extraFare = $this->checkZoneExtraFare($zone);
            $surgePrice = $surgePriceService->checkSurgePricing(zoneId: $zone->id, tripType: $tripRequest['type']);
            $extraDiscount = null;
            $distance_wise_fare = $tripFare->fares[0]->fare_per_km * $routes[0]['distance'];
            $perMinuteRate = (float)($tripFare->fares[0]->per_minute_rate ?? 0);
            $minimumFare = (float)($tripFare->fares[0]->minimum_fare ?? 0);
            $estimatedDurationMinutes = ceil(($routes[0]['duration'] ?? 0) / 60);
            $timeFare = $perMinuteRate * $estimatedDurationMinutes;
            $est_fare = $tripFare->fares[0]->base_fare + $distance_wise_fare + $timeFare;
            if ($minimumFare > 0 && $est_fare < $minimumFare) {
                $est_fare = $minimumFare;
            }
            $extraEstFareAmount = $surgePriceAmount = 0;
            if (!empty($extraFare)) {
                $extraEstFareAmount = ($est_fare * $extraFare['extraFareFee']) / 100;
            }
            if (!empty($surgePrice))
            {
                $surgePriceAmount = ($est_fare * $surgePrice['surge_multiplier']) / 100;
            }
            $extraEstFare = $est_fare + $extraEstFareAmount + $surgePriceAmount;
            $returnFee = ($est_fare * $tripFare->fares[0]->return_fee) / 100;
            $cancellationFee = ($est_fare * $tripFare->fares[0]->cancellation_fee) / 100;

            $discount = $this->getEstimatedDiscount(user: $user, zoneId: $zone_id, tripType: $tripRequest['type'], vehicleCategoryId: null, estimatedAmount: $est_fare, beforeCreate: $beforeCreate);
            $discountEstFare = $est_fare - ($discount ? $discount['discount_amount'] : 0);
            $coupon = $this->getEstimatedCouponDiscount(user: $user, zoneId: $zone_id, tripType: $tripRequest['type'], vehicleCategoryId: null, estimatedAmount: $discountEstFare);

            if (!empty($extraFare) || !empty($surgePrice)) {
                $extraDiscount = $this->getEstimatedDiscount(user: $user, zoneId: $zone_id, tripType: $tripRequest['type'], vehicleCategoryId: null, estimatedAmount: $extraEstFare, beforeCreate: $beforeCreate);
                $extraDiscountEstFare = $extraEstFare - ($extraDiscount ? $extraDiscount['discount_amount'] : 0);
                $coupon = $this->getEstimatedCouponDiscount(user: $user, zoneId: $zone_id, tripType: $tripRequest['type'], vehicleCategoryId: null, estimatedAmount: $extraDiscountEstFare);
                $extraDiscountFareVat = ($extraDiscountEstFare * $vat_percent) / 100;
                $extraDiscountEstFare += $extraDiscountFareVat;
                $extraVat = ($extraEstFare * $vat_percent) / 100;
                $extraEstFare += $extraVat;
                $extraReturnFee = ($extraEstFare * $tripFare->fares[0]->return_fee) / 100;
                $extraCancellationFee = ($extraEstFare * $tripFare->fares[0]->cancellation_fee) / 100;
            }
            $discountFareVat = ($discountEstFare * $vat_percent) / 100;
            $discountEstFare += $discountFareVat;
            $vat = ($est_fare * $vat_percent) / 100;
            $est_fare += $vat;
            $reason = '';

            if (!empty($surgePrice) && !empty($surgePrice['surge_pricing_customer_note'])) {
                $surgeReason = strtolower(str_replace('.', '', '_' . $surgePrice['surge_pricing_customer_note']));
                $reason .= $surgeReason;
            }

            if (!empty($extraFare) && !empty($extraFare['extraFareReason'])) {
                $extraReason = strtolower($extraFare['extraFareReason']);
                $reason .= ($reason ? ' and ' : '') . '_' . $extraReason;
            }

            $estimated_fare = [
                'id' => $tripFare->id,
                'zone_id' => $zone->id,
                'area_id' => $area_id,
                'base_fare' => $tripFare->base_fare,
                'base_fare_per_km' => $tripFare->base_fare_per_km,
                'per_minute_rate' => $perMinuteRate,
                'minimum_fare' => $minimumFare,
                'fare' => $tripFare->fares,
                'estimated_distance' => (double)$routes[0]['distance'],
                'estimated_duration' => $routes[0]['duration'],
                'estimated_duration_minutes' => $estimatedDurationMinutes,
                'time_based_fare' => round($timeFare, $points),
                'estimated_fare' => round($est_fare, $points),
                'discount_fare' => round($discountEstFare, $points),
                'discount_amount' => round(($discount ? $discount['discount_amount'] : 0), $points),
                'coupon_applicable' => $coupon,
                'request type' => $tripRequest['type'],
                'encoded_polyline' => $routes[0]['encoded_polyline'],
                'return_fee' => $returnFee,
                'cancellation_fee' => $cancellationFee,
                'extra_estimated_fare' => round($extraEstFare ?? 0, $points),
                'extra_discount_fare' => round($extraDiscountEstFare ?? 0, $points),
                'extra_discount_amount' => round(($extraDiscount ? $extraDiscount['discount_amount'] : 0), $points),
                'extra_return_fee' => $extraReturnFee ?? 0,
                'extra_cancellation_fee' => $extraCancellationFee ?? 0,
                'extra_fare_amount' => round(($extraEstFareAmount ?? 0), $points),
                'extra_fare_fee' => $extraFare ? $extraFare['extraFareFee'] : 0,
                'extra_fare_reason' => $reason ? translate($reason) : '',
                'surge_multiplier' => $surgePrice['surge_multiplier'] ?? 0,
            ];

        } else {
            $scheduleTripPercentage = businessConfig('schedule_trip_status')?->value && businessConfig('increase_fare')?->value && (businessConfig('increase_fare_amount')?->value > 0) ? businessConfig('increase_fare_amount')?->value : 0;
            $estimated_fare = $tripFare->map(function ($trip) use ($routes, $tripRequest, $area_id, $beforeCreate, $zone, $scheduleTripPercentage, $surgePriceService) {
                $user = auth('api')->user();
                $extraFare = $this->checkZoneExtraFare($zone);
                $surgePrice = $surgePriceService->checkSurgePricing(zoneId: $zone->id, tripType: $tripRequest['type'], vehicleCategoryId: $trip->vehicle_category_id, scheduledAt: $tripRequest['scheduled_at']);
                $points = (int)getSession('currency_decimal_point') ?? 0;
                $vat_percent = (double)(get_cache('vat_percent') ?? 1);
                $baseFarePerKm = $trip->base_fare_per_km;
                $baseFare = $trip->base_fare;
                $extraDiscount = null;
                if ($tripRequest['ride_request_type'] == 'scheduled') {
                    $baseFarePerKm = $trip->base_fare_per_km + ($trip->base_fare_per_km * $scheduleTripPercentage / 100);
                    $baseFare = $trip->base_fare + ($trip->base_fare * $scheduleTripPercentage / 100);
                }
                foreach ($routes as $route) {
                    if ($route['drive_mode'] === 'DRIVE') {
                        $distance = $route['distance'];
                        $drive_fare = $baseFarePerKm * $distance;
                        $drive_est_distance = (double)$routes[0]['distance'];
                        $drive_est_duration = $route['duration'];
                        $drive_polyline = $route['encoded_polyline'];
                    } elseif ($route['drive_mode'] === 'TWO_WHEELER') {
                        $distance = $route['distance'];
                        $bike_fare = $baseFarePerKm * $distance;
                        $bike_est_distance = (double)$routes[0]['distance'];
                        $bike_est_duration = $route['duration'];
                        $bike_polyline = $route['encoded_polyline'];
                    }
                }

                $est_fare = $trip->vehicleCategory->type === 'car' ? round(($baseFare + $drive_fare), $points) : round(($baseFare + $bike_fare), $points);
                $extraEstFareAmount = $surgePriceAmount = 0;
                if (!empty($extraFare))
                {
                    $extraEstFareAmount = ($est_fare * $extraFare['extraFareFee']) / 100;
                }

                if (!empty($surgePrice))
                {
                    $surgePriceAmount = ($est_fare * $surgePrice['surge_multiplier']) / 100;
                }
                $extraEstFare = $est_fare + $extraEstFareAmount + $surgePriceAmount;
                $discount = $this->getEstimatedDiscount(user: $user, zoneId: $zone->id, tripType: $tripRequest['type'], vehicleCategoryId: $trip->vehicleCategory->id, estimatedAmount: $est_fare, beforeCreate: $beforeCreate);
                $discountEstFare = $est_fare - ($discount ? $discount['discount_amount'] : 0);
                $coupon = $this->getEstimatedCouponDiscount(user: $user, zoneId: $zone->id, tripType: $tripRequest['type'], vehicleCategoryId: $trip->vehicleCategory->id, estimatedAmount: $discountEstFare);

                if (!empty($extraFare) || !empty($surgePrice)) {
                    $extraDiscount = $this->getEstimatedDiscount(user: $user, zoneId: $zone->id, tripType: $tripRequest['type'], vehicleCategoryId: $trip->vehicleCategory->id, estimatedAmount: $extraEstFare, beforeCreate: $beforeCreate);
                    $extraDiscountEstFare = $extraEstFare - ($extraDiscount ? $extraDiscount['discount_amount'] : 0);
                    $coupon = $this->getEstimatedCouponDiscount(user: $user, zoneId: $zone->id, tripType: $tripRequest['type'], vehicleCategoryId: $trip->vehicleCategory->id, estimatedAmount: $extraDiscountEstFare);
                    $extraDiscountFareVat = ($extraDiscountEstFare * $vat_percent) / 100;
                    $extraDiscountEstFare += $extraDiscountFareVat;
                    $extraVat = ($extraEstFare * $vat_percent) / 100;
                    $extraEstFare += $extraVat;
                }
                $discountFareVat = ($discountEstFare * $vat_percent) / 100;
                $discountEstFare += $discountFareVat;
                $vat = ($est_fare * $vat_percent) / 100;
                $est_fare += $vat;
                $reason = '';

                if (!empty($surgePrice) && !empty($surgePrice['surge_pricing_customer_note'])) {
                    $surgeReason = strtolower(str_replace('.', '', '_' . $surgePrice['surge_pricing_customer_note']));
                    $reason .= $surgeReason;
                }

                if (!empty($extraFare) && !empty($extraFare['extraFareReason'])) {
                    $extraReason = strtolower($extraFare['extraFareReason']);
                    $reason .= ($reason ? ' and ' : '') . '_' . $extraReason;
                }

                $sharedDiscountPercent = (float)($trip->shared_discount_percent ?? 30);
                $estFareBeforeVat = $est_fare / (1 + ($vat_percent / 100));
                $sharedPerSeatFare = round($estFareBeforeVat * (1 - ($sharedDiscountPercent / 100)), $points);
                $sharedPerSeatFareWithVat = round($sharedPerSeatFare * (1 + ($vat_percent / 100)), $points);

                return [
                    "id" => $trip->id,
                    "zone_id" => $zone->id,
                    'area_id' => $area_id,
                    "vehicle_category_id" => $trip->vehicle_category_id,
                    'base_fare' => $baseFare,
                    'base_fare_per_km' => $baseFarePerKm,
                    'fare' => $trip->VehicleCategory->type === 'car' ? round($drive_fare, 2) : round($bike_fare, 2),
                    'estimated_distance' => $trip->VehicleCategory->type === 'car' ? $drive_est_distance : $bike_est_distance,
                    'estimated_duration' => $trip->VehicleCategory->type === 'car' ? $drive_est_duration : $bike_est_duration,
                    'vehicle_category_type' => $trip->VehicleCategory->type === 'car' ? 'Car' : 'Motorbike',
                    'estimated_fare' => round($est_fare, $points),
                    'shared_per_seat_fare' => $sharedPerSeatFareWithVat,
                    'shared_discount_percent' => $sharedDiscountPercent,
                    'discount_fare' => round($discountEstFare, $points),
                    'discount_amount' => round(($discount ? $discount['discount_amount'] : 0), $points),
                    'coupon_applicable' => $coupon,
                    'request_type' => $tripRequest['type'],
                    'ride_request_type' => $tripRequest['ride_request_type'] ?? null,
                    'encoded_polyline' => $trip->VehicleCategory->type === 'car' ? $drive_polyline : $bike_polyline,
                    'return_fee' => 0,
                    'extra_estimated_fare' => round($extraEstFare ?? 0, $points),
                    'extra_discount_fare' => round($extraDiscountEstFare ?? 0, $points),
                    'extra_discount_amount' => round(($extraDiscount ? $extraDiscount['discount_amount'] : 0), $points),
                    'extra_return_fee' => 0,
                    'extra_cancellation_fee' => 0,
                    'extra_fare_amount' => round(($extraEstFareAmount ?? 0), $points),
                    'extra_fare_fee' => $extraFare ? $extraFare['extraFareFee'] : 0,
                    'extra_fare_reason' => $reason ? translate($reason) : '',
                    'surge_multiplier' => $surgePrice['surge_multiplier'] ?? 0,
                ];
            });
        }

        return $estimated_fare;
    }

    public function checkZoneExtraFare($zone)
    {
        $extraFareFee = 0;
        $extraFareReason = "";
        if ($zone->extra_fare_status) {
            $extraFareFee = $zone->extra_fare_fee;
            $extraFareReason = $zone->extra_fare_reason;
        }
        if ($extraFareFee > 0) {
            return [
                'extraFareFee' => $extraFareFee,
                'extraFareReason' => $extraFareReason,
            ];
        }
        return [];
    }

}

