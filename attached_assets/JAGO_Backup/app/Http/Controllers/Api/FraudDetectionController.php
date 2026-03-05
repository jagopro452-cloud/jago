<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class FraudDetectionController extends Controller
{
    private const GPS_SPEED_LIMIT_KMH = 200;
    private const SAME_ROUTE_THRESHOLD = 5;
    private const SHORT_TRIP_THRESHOLD_KM = 0.3;
    private const FARE_DEVIATION_THRESHOLD = 3.0;

    public function scan(Request $request): JsonResponse
    {
        $hours = min($request->get('hours', 24), 168);
        $since = now()->subHours($hours);

        $alerts = Cache::remember("fraud_scan_{$hours}", 300, function () use ($since) {
            $alerts = [];

            $alerts = array_merge($alerts, $this->detectGpsSpoofing($since));
            $alerts = array_merge($alerts, $this->detectRepeatedRoutes($since));
            $alerts = array_merge($alerts, $this->detectFareAnomalies($since));
            $alerts = array_merge($alerts, $this->detectShortTripAbuse($since));
            $alerts = array_merge($alerts, $this->detectRapidTrips($since));

            usort($alerts, fn($a, $b) => $b['severity_level'] <=> $a['severity_level']);

            return $alerts;
        });

        $summary = [
            'scan_period_hours' => $hours,
            'total_alerts' => count($alerts),
            'critical' => count(array_filter($alerts, fn($a) => $a['severity'] === 'critical')),
            'high' => count(array_filter($alerts, fn($a) => $a['severity'] === 'high')),
            'medium' => count(array_filter($alerts, fn($a) => $a['severity'] === 'medium')),
            'low' => count(array_filter($alerts, fn($a) => $a['severity'] === 'low')),
        ];

        return response()->json(responseFormatter(DEFAULT_200, [
            'summary' => $summary,
            'alerts' => $alerts,
        ]));
    }

    public function driverRisk(string $driverId): JsonResponse
    {
        $cacheKey = "driver_risk_{$driverId}";
        $data = Cache::remember($cacheKey, 600, function () use ($driverId) {
            return $this->calculateDriverRisk($driverId);
        });

        if (!$data) {
            return response()->json(responseFormatter(DEFAULT_404, null), 404);
        }

        return response()->json(responseFormatter(DEFAULT_200, $data));
    }

    private function detectGpsSpoofing($since): array
    {
        $alerts = [];

        $trips = DB::table('trip_requests')
            ->where('current_status', 'completed')
            ->where('created_at', '>=', $since)
            ->where('actual_distance', '>', 0)
            ->whereNotNull('driver_id')
            ->whereRaw("EXTRACT(EPOCH FROM (updated_at - created_at)) > 0")
            ->whereRaw("(actual_distance / GREATEST(EXTRACT(EPOCH FROM (updated_at - created_at))/3600, 0.001)) > ?", [self::GPS_SPEED_LIMIT_KMH])
            ->select('id', 'ref_id', 'driver_id', 'actual_distance', 'created_at', 'updated_at')
            ->limit(50)
            ->get();

        foreach ($trips as $trip) {
            $durationMinutes = max(1, (strtotime($trip->updated_at) - strtotime($trip->created_at)) / 60);
            $speedKmh = ($trip->actual_distance / max($durationMinutes, 1)) * 60;
            $alerts[] = [
                'type' => 'gps_spoofing',
                'severity' => 'critical',
                'severity_level' => 4,
                'trip_id' => $trip->id,
                'ref_id' => $trip->ref_id,
                'driver_id' => $trip->driver_id,
                'detail' => "Impossible speed: " . round($speedKmh) . " km/h over " . round($durationMinutes) . " minutes",
                'detected_at' => now()->toIso8601String(),
            ];
        }

        return $alerts;
    }

    private function detectRepeatedRoutes($since): array
    {
        $alerts = [];

        $repeated = DB::table('trip_requests as t')
            ->join('trip_request_coordinates as c', 't.id', '=', 'c.trip_request_id')
            ->where('t.current_status', 'completed')
            ->where('t.created_at', '>=', $since)
            ->whereNotNull('t.driver_id')
            ->select(
                't.driver_id',
                DB::raw("ROUND(CAST(c.pickup_coordinates->>'latitude' AS numeric), 3) as plat"),
                DB::raw("ROUND(CAST(c.pickup_coordinates->>'longitude' AS numeric), 3) as plng"),
                DB::raw("ROUND(CAST(c.destination_coordinates->>'latitude' AS numeric), 3) as dlat"),
                DB::raw("ROUND(CAST(c.destination_coordinates->>'longitude' AS numeric), 3) as dlng"),
                DB::raw('COUNT(*) as trip_count')
            )
            ->groupBy('t.driver_id', 'plat', 'plng', 'dlat', 'dlng')
            ->havingRaw('COUNT(*) >= ?', [self::SAME_ROUTE_THRESHOLD])
            ->get();

        foreach ($repeated as $route) {
            $alerts[] = [
                'type' => 'repeated_route',
                'severity' => 'high',
                'severity_level' => 3,
                'driver_id' => $route->driver_id,
                'detail' => "Same route repeated {$route->trip_count} times (pickup: {$route->plat},{$route->plng} → dest: {$route->dlat},{$route->dlng})",
                'trip_count' => $route->trip_count,
                'detected_at' => now()->toIso8601String(),
            ];
        }

        return $alerts;
    }

    private function detectFareAnomalies($since): array
    {
        $alerts = [];

        $trips = DB::table('trip_requests')
            ->where('current_status', 'completed')
            ->where('created_at', '>=', $since)
            ->whereNotNull('driver_id')
            ->where('estimated_fare', '>', 0)
            ->where('paid_fare', '>', 0)
            ->select('id', 'ref_id', 'driver_id', 'estimated_fare', 'paid_fare', 'actual_fare')
            ->get();

        foreach ($trips as $trip) {
            $ratio = $trip->paid_fare / $trip->estimated_fare;
            if ($ratio > self::FARE_DEVIATION_THRESHOLD) {
                $alerts[] = [
                    'type' => 'fare_anomaly',
                    'severity' => 'high',
                    'severity_level' => 3,
                    'trip_id' => $trip->id,
                    'ref_id' => $trip->ref_id,
                    'driver_id' => $trip->driver_id,
                    'detail' => "Paid fare (₹" . round($trip->paid_fare, 2) . ") is " . round($ratio, 1) . "x estimated (₹" . round($trip->estimated_fare, 2) . ")",
                    'detected_at' => now()->toIso8601String(),
                ];
            }
        }

        return $alerts;
    }

    private function detectShortTripAbuse($since): array
    {
        $alerts = [];

        $drivers = DB::table('trip_requests')
            ->where('current_status', 'completed')
            ->where('created_at', '>=', $since)
            ->whereNotNull('driver_id')
            ->where('actual_distance', '<', self::SHORT_TRIP_THRESHOLD_KM)
            ->where('actual_distance', '>', 0)
            ->select('driver_id', DB::raw('COUNT(*) as short_count'))
            ->groupBy('driver_id')
            ->havingRaw('COUNT(*) >= 3')
            ->get();

        foreach ($drivers as $driver) {
            $alerts[] = [
                'type' => 'short_trip_abuse',
                'severity' => 'medium',
                'severity_level' => 2,
                'driver_id' => $driver->driver_id,
                'detail' => "{$driver->short_count} trips under " . (self::SHORT_TRIP_THRESHOLD_KM * 1000) . "m detected",
                'detected_at' => now()->toIso8601String(),
            ];
        }

        return $alerts;
    }

    private function detectRapidTrips($since): array
    {
        $alerts = [];

        $results = DB::select("
            WITH trip_gaps AS (
                SELECT driver_id,
                       created_at,
                       LAG(updated_at) OVER (PARTITION BY driver_id ORDER BY created_at) as prev_end,
                       EXTRACT(EPOCH FROM (created_at - LAG(updated_at) OVER (PARTITION BY driver_id ORDER BY created_at)))/60 as gap_minutes
                FROM trip_requests
                WHERE current_status = 'completed'
                  AND created_at >= ?
                  AND driver_id IS NOT NULL
            )
            SELECT driver_id, COUNT(*) as rapid_count
            FROM trip_gaps
            WHERE gap_minutes >= 0 AND gap_minutes < 2
            GROUP BY driver_id
            HAVING COUNT(*) >= 3
            LIMIT 50
        ", [$since]);

        foreach ($results as $row) {
            $alerts[] = [
                'type' => 'rapid_consecutive_trips',
                'severity' => 'medium',
                'severity_level' => 2,
                'driver_id' => $row->driver_id,
                'detail' => "{$row->rapid_count} trips completed within 2 minutes of each other",
                'detected_at' => now()->toIso8601String(),
            ];
        }

        return $alerts;
    }

    private function calculateDriverRisk(string $driverId): ?array
    {
        $driver = DB::table('users')->where('id', $driverId)->where('user_type', 'driver')->first();
        if (!$driver) return null;

        $overchargeReports = DB::table('driver_overcharge_reports')
            ->where('driver_id', $driverId)
            ->count();

        $cancelledTrips = DB::table('trip_requests')
            ->where('driver_id', $driverId)
            ->where('current_status', 'cancelled')
            ->count();

        $totalTrips = DB::table('trip_requests')
            ->where('driver_id', $driverId)
            ->count();

        $avgRating = DB::table('reviews')
            ->where('received_by', $driverId)
            ->whereNull('deleted_at')
            ->avg('rating') ?? 5;

        $riskScore = 0;
        $factors = [];

        if ($overchargeReports > 0) {
            $riskScore += min($overchargeReports * 15, 40);
            $factors[] = "Overcharge reports: {$overchargeReports}";
        }

        if ($totalTrips > 5) {
            $cancelRate = ($cancelledTrips / $totalTrips) * 100;
            if ($cancelRate > 30) {
                $riskScore += 20;
                $factors[] = "High cancellation rate: " . round($cancelRate) . "%";
            }
        }

        if ($avgRating < 3) {
            $riskScore += 25;
            $factors[] = "Low rating: " . round($avgRating, 1);
        } elseif ($avgRating < 4) {
            $riskScore += 10;
            $factors[] = "Below average rating: " . round($avgRating, 1);
        }

        $riskLevel = match(true) {
            $riskScore >= 60 => 'critical',
            $riskScore >= 40 => 'high',
            $riskScore >= 20 => 'medium',
            default => 'low',
        };

        return [
            'driver_id' => $driverId,
            'risk_score' => min($riskScore, 100),
            'risk_level' => $riskLevel,
            'factors' => $factors,
            'stats' => [
                'total_trips' => $totalTrips,
                'cancelled_trips' => $cancelledTrips,
                'overcharge_reports' => $overchargeReports,
                'average_rating' => round($avgRating, 2),
            ],
        ];
    }
}
