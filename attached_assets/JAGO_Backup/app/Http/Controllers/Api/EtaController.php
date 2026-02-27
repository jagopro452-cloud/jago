<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class EtaController extends Controller
{
    private const AVERAGE_CITY_SPEED_KMH = 25;
    private const PEAK_HOUR_MULTIPLIER = 1.4;
    private const OFF_PEAK_MULTIPLIER = 0.85;
    private const PICKUP_BASE_MINUTES = 3;

    public function estimate(Request $request): JsonResponse
    {
        $request->validate([
            'pickup_lat' => 'required|numeric|between:-90,90',
            'pickup_lng' => 'required|numeric|between:-180,180',
            'destination_lat' => 'required|numeric|between:-90,90',
            'destination_lng' => 'required|numeric|between:-180,180',
            'zone_id' => 'nullable|string',
        ]);

        $pickupLat = $request->pickup_lat;
        $pickupLng = $request->pickup_lng;
        $destLat = $request->destination_lat;
        $destLng = $request->destination_lng;
        $zoneId = $request->zone_id;

        $distance = $this->haversineDistance($pickupLat, $pickupLng, $destLat, $destLng);
        $roadDistance = $distance * 1.3;

        $currentHour = (int) now()->format('H');
        $dayOfWeek = (int) now()->format('w');

        $historicalSpeed = $this->getHistoricalSpeed($zoneId, $currentHour, $dayOfWeek);
        $effectiveSpeed = $historicalSpeed ?: $this->getTimeBasedSpeed($currentHour);

        $travelMinutes = ($roadDistance / $effectiveSpeed) * 60;

        $pickupEta = $this->estimatePickupTime($pickupLat, $pickupLng, $zoneId);

        $totalMinutes = ceil($pickupEta + $travelMinutes);

        $confidence = $historicalSpeed ? 'high' : 'medium';
        if ($roadDistance > 50) $confidence = 'low';

        return response()->json(responseFormatter(DEFAULT_200, [
            'pickup_eta_minutes' => (int) ceil($pickupEta),
            'travel_eta_minutes' => (int) ceil($travelMinutes),
            'total_eta_minutes' => (int) $totalMinutes,
            'distance' => [
                'straight_line_km' => round($distance, 2),
                'estimated_road_km' => round($roadDistance, 2),
            ],
            'speed' => [
                'effective_kmh' => round($effectiveSpeed, 1),
                'source' => $historicalSpeed ? 'historical_data' : 'time_based_estimate',
            ],
            'time_context' => [
                'hour' => $currentHour,
                'day_of_week' => $dayOfWeek,
                'is_peak' => $this->isPeakHour($currentHour),
                'period' => $this->getTimePeriod($currentHour),
            ],
            'confidence' => $confidence,
            'arrival_time' => now()->addMinutes($totalMinutes)->toIso8601String(),
        ]));
    }

    public function nearbyDrivers(Request $request): JsonResponse
    {
        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'radius_km' => 'nullable|numeric|min:0.5|max:10',
        ]);

        $lat = $request->lat;
        $lng = $request->lng;
        $radius = $request->get('radius_km', 5);

        $cacheKey = "nearby_drivers_" . round($lat, 3) . "_" . round($lng, 3) . "_{$radius}";

        $data = Cache::remember($cacheKey, 30, function () use ($lat, $lng, $radius) {
            $drivers = DB::table('users')
                ->join('driver_details', 'users.id', '=', 'driver_details.user_id')
                ->join('user_last_locations', 'users.id', '=', 'user_last_locations.user_id')
                ->where('users.user_type', 'driver')
                ->where('driver_details.is_online', 'true')
                ->where('driver_details.availability_status', 'available')
                ->where('driver_details.is_suspended', 0)
                ->whereNull('users.deleted_at')
                ->whereNotNull('user_last_locations.latitude')
                ->whereNotNull('user_last_locations.longitude')
                ->select('users.id', 'user_last_locations.latitude', 'user_last_locations.longitude')
                ->get();

            $nearby = [];
            foreach ($drivers as $driver) {
                $dist = $this->haversineDistance($lat, $lng, $driver->latitude, $driver->longitude);
                if ($dist <= $radius) {
                    $etaMinutes = max(1, ceil(($dist * 1.3 / self::AVERAGE_CITY_SPEED_KMH) * 60) + self::PICKUP_BASE_MINUTES);
                    $nearby[] = [
                        'driver_id' => $driver->id,
                        'distance_km' => round($dist, 2),
                        'eta_minutes' => (int) $etaMinutes,
                    ];
                }
            }

            usort($nearby, fn($a, $b) => $a['distance_km'] <=> $b['distance_km']);

            return [
                'count' => count($nearby),
                'nearest_eta_minutes' => !empty($nearby) ? $nearby[0]['eta_minutes'] : null,
                'drivers' => array_slice($nearby, 0, 10),
            ];
        });

        return response()->json(responseFormatter(DEFAULT_200, $data));
    }

    private function haversineDistance($lat1, $lon1, $lat2, $lon2): float
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadius * $c;
    }

    private function getHistoricalSpeed(?string $zoneId, int $hour, int $dayOfWeek): ?float
    {
        $query = DB::table('trip_requests')
            ->where('current_status', 'completed')
            ->where('actual_distance', '>', 0)
            ->whereRaw("EXTRACT(HOUR FROM created_at) = ?", [$hour])
            ->whereRaw("EXTRACT(DOW FROM created_at) = ?", [$dayOfWeek])
            ->where('created_at', '>=', now()->subDays(30));

        if ($zoneId) {
            $query->where('zone_id', $zoneId);
        }

        $trips = $query->select(
            DB::raw("AVG(actual_distance / GREATEST(EXTRACT(EPOCH FROM (updated_at - created_at))/3600, 0.01)) as avg_speed")
        )->first();

        $speed = $trips->avg_speed ?? null;

        if ($speed && $speed > 5 && $speed < 120) {
            return round((float) $speed, 1);
        }

        return null;
    }

    private function getTimeBasedSpeed(int $hour): float
    {
        if ($this->isPeakHour($hour)) {
            return self::AVERAGE_CITY_SPEED_KMH / self::PEAK_HOUR_MULTIPLIER;
        }

        if ($hour >= 22 || $hour < 5) {
            return self::AVERAGE_CITY_SPEED_KMH / self::OFF_PEAK_MULTIPLIER;
        }

        return self::AVERAGE_CITY_SPEED_KMH;
    }

    private function isPeakHour(int $hour): bool
    {
        return ($hour >= 8 && $hour <= 10) || ($hour >= 17 && $hour <= 20);
    }

    private function getTimePeriod(int $hour): string
    {
        if ($hour >= 8 && $hour <= 10) return 'morning_peak';
        if ($hour >= 17 && $hour <= 20) return 'evening_peak';
        if ($hour >= 11 && $hour <= 16) return 'midday';
        if ($hour >= 5 && $hour < 8) return 'early_morning';
        return 'night';
    }

    private function estimatePickupTime(float $lat, float $lng, ?string $zoneId): float
    {
        $nearbyCount = DB::table('users')
            ->join('driver_details', 'users.id', '=', 'driver_details.user_id')
            ->join('user_last_locations', 'users.id', '=', 'user_last_locations.user_id')
            ->where('users.user_type', 'driver')
            ->where('driver_details.is_online', 'true')
            ->where('driver_details.availability_status', 'available')
            ->where('driver_details.is_suspended', 0)
            ->whereNotNull('user_last_locations.latitude')
            ->whereNotNull('user_last_locations.longitude')
            ->whereRaw("(6371 * acos(cos(radians(?)) * cos(radians(CAST(user_last_locations.latitude AS float))) * cos(radians(CAST(user_last_locations.longitude AS float)) - radians(?)) + sin(radians(?)) * sin(radians(CAST(user_last_locations.latitude AS float))))) < 5", [$lat, $lng, $lat])
            ->count();

        if ($nearbyCount == 0) return 15;
        if ($nearbyCount <= 2) return 8;
        if ($nearbyCount <= 5) return 5;
        return self::PICKUP_BASE_MINUTES;
    }
}
